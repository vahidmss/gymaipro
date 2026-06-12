import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class WorkoutLogViewModel extends ChangeNotifier {
  final WorkoutProgramService _workoutProgramService = WorkoutProgramService();
  final ActiveProgramService _activeProgramService = ActiveProgramService();
  final ExerciseService _exerciseService = ExerciseService();
  final WorkoutDailyLogService _workoutLogService = WorkoutDailyLogService();

  Jalali _selectedDate = Jalali.now();
  WorkoutProgram? _selectedProgram;
  WorkoutSession? _selectedSession;

  final Map<String, List<Map<String, TextEditingController>>>
  _exerciseControllers = {};
  final Map<String, List<bool>> _setSavedStatus = {};
  final Map<String, List<Map<String, FocusNode>>> _exerciseFocusNodes = {};
  final Map<int, Exercise> _exerciseDetails = {};
  final Map<String, bool> _collapsedExercises = {};

  bool _hasTodayLog = false;
  bool _isLoadingTodayLog = true;
  String? _loggedSessionDay;
  final Map<String, Timer> _autoSaveTimers = {};
  bool _isLoadingData = false;
  bool _isDisposed = false;
  final ValueNotifier<int> _sessionHeatmapTick = ValueNotifier<int>(0);

  // Getters
  Jalali get selectedDate => _selectedDate;
  WorkoutProgram? get selectedProgram => _selectedProgram;
  WorkoutSession? get selectedSession => _selectedSession;
  Map<String, List<Map<String, TextEditingController>>>
  get exerciseControllers => _exerciseControllers;
  Map<String, List<bool>> get setSavedStatus => _setSavedStatus;
  Map<String, List<Map<String, FocusNode>>> get exerciseFocusNodes =>
      _exerciseFocusNodes;
  Map<int, Exercise> get exerciseDetails => _exerciseDetails;
  Map<String, bool> get collapsedExercises => _collapsedExercises;
  bool get hasTodayLog => _hasTodayLog;
  bool get isLoadingTodayLog => _isLoadingTodayLog;
  String? get loggedSessionDay => _loggedSessionDay;
  ValueNotifier<int> get sessionHeatmapTick => _sessionHeatmapTick;

  MuscleHeatmapSnapshot get sessionHeatmapSnapshot {
    if (_selectedSession == null) return MuscleHeatmapSnapshot.empty();
    return MuscleHeatmapAggregate.fromExerciseLogs(
      _buildExerciseLogs(),
      _exerciseDetails,
    );
  }

  void _bumpSessionHeatmap() {
    if (_isDisposed) return;
    _sessionHeatmapTick.value++;
  }

  Future<void> initialize() async {
    await loadActiveProgram();
    await checkLogForDate(_selectedDate);
  }

  Future<void> loadActiveProgram() async {
    try {
      final state = await _activeProgramService.getActiveProgramState();
      final String? activeProgramId = state?['active_program_id'] as String?;
      if (activeProgramId == null) {
        _selectedProgram = null;
        _selectedSession = null;
        _safeNotifyListeners();
        return;
      }

      final program = await _workoutProgramService.getProgramById(
        activeProgramId,
      );
      _selectedProgram = program;
      _selectedSession = null;
      _safeNotifyListeners();

      // پیش‌بارگذاری تمرینات سشن اول برای سرعت بیشتر
      if (program != null && program.sessions.isNotEmpty) {
        _preloadFirstSessionExercises(program.sessions.first);
      }
    } catch (_) {
      _selectedProgram = null;
      _selectedSession = null;
      _safeNotifyListeners();
    }
  }

  /// پیش‌بارگذاری تمرینات یک سشن در پس‌زمینه (غیرمسدودکننده)
  void _preloadFirstSessionExercises(WorkoutSession session) {
    // اجرا در پس‌زمینه بدون انتظار
    Future.microtask(() async {
      // چک کردن dispose قبل از شروع
      if (_isDisposed) return;

      final exerciseIds = <int>{};
      for (final exercise in session.exercises) {
        if (_isDisposed) return;
        if (exercise is NormalExercise) {
          exerciseIds.add(exercise.exerciseId);
        } else if (exercise is SupersetExercise) {
          for (final item in exercise.exercises) {
            exerciseIds.add(item.exerciseId);
          }
        }
      }

      if (_isDisposed) return;

      // فقط تمریناتی که هنوز بارگذاری نشده‌اند
      final idsToLoad = exerciseIds
          .where((id) => !_exerciseDetails.containsKey(id))
          .toList();

      if (idsToLoad.isEmpty || _isDisposed) return;

      // استفاده از getExercises برای استفاده از کش
      try {
        final allExercises = await _exerciseService.getExercises();
        if (_isDisposed) return;

        final exerciseMap = {for (final ex in allExercises) ex.id: ex};

        for (final id in idsToLoad) {
          if (_isDisposed) return;
          final exercise = exerciseMap[id];
          if (exercise != null) {
            _exerciseDetails[id] = exercise;
          }
        }
        // notifyListeners را صدا نزن چون در پس‌زمینه است
      } catch (_) {
        // Silently fail - preload is optional
      }
    });
  }

  void toggleExerciseCollapse(String exerciseId) {
    _collapsedExercises[exerciseId] =
        !(_collapsedExercises[exerciseId] ?? true);
    _safeNotifyListeners();
  }

  Future<void> loadExerciseDetails() async {
    if (_selectedSession == null) return;

    final exerciseIds = <int>{};
    for (final exercise in _selectedSession!.exercises) {
      if (exercise is NormalExercise) {
        exerciseIds.add(exercise.exerciseId);
      } else if (exercise is SupersetExercise) {
        for (final item in exercise.exercises) {
          exerciseIds.add(item.exerciseId);
        }
      }
    }

    // فیلتر کردن ID هایی که هنوز بارگذاری نشده‌اند
    final idsToLoad = exerciseIds
        .where((id) => !_exerciseDetails.containsKey(id))
        .toList();

    if (idsToLoad.isEmpty) {
      _safeNotifyListeners();
      return;
    }

    // بارگذاری تمرین‌های اختصاصی مربی برنامه (اگر برنامه توسط مربی ساخته شده باشد)
    if (_selectedProgram?.trainerId != null && _selectedProgram!.trainerId!.isNotEmpty) {
      try {
        final customExerciseService = CustomExerciseService();
        // دریافت تمرین‌های اختصاصی مربی برنامه
        final trainerCustomExercises = await customExerciseService
            .getTrainerExercisesById(_selectedProgram!.trainerId!);
        
        // تبدیل CustomExercise به Exercise و اضافه کردن به exerciseDetails
        final trainerExercises = await customExerciseService
            .customExercisesToExercises(trainerCustomExercises);
        
        for (final exercise in trainerExercises) {
          if (idsToLoad.contains(exercise.id) && !_exerciseDetails.containsKey(exercise.id)) {
            _exerciseDetails[exercise.id] = exercise;
            debugPrint('✅ تمرین اختصاصی مربی بارگذاری شد: ${exercise.name} (ID: ${exercise.id})');
          }
        }
      } catch (e) {
        debugPrint('⚠️ خطا در بارگذاری تمرین‌های اختصاصی مربی: $e');
        // ادامه می‌دهیم حتی اگر خطا رخ داد
      }
    }

    // فیلتر مجدد ID هایی که هنوز بارگذاری نشده‌اند
    final remainingIdsToLoad = idsToLoad
        .where((id) => !_exerciseDetails.containsKey(id))
        .toList();

    if (remainingIdsToLoad.isEmpty) {
      _safeNotifyListeners();
      return;
    }

    // استراتژی بهینه: اگر تعداد تمرینات کم است، از getExercises استفاده کن
    // و اگر زیاد است، بارگذاری موازی انجام بده
    if (remainingIdsToLoad.length <= 5) {
      // برای تعداد کم، بارگذاری موازی سریع‌تر است
      final futures = remainingIdsToLoad.map((id) async {
        if (_isDisposed) return;
        try {
          final exercise = await _exerciseService.getExerciseById(id);
          if (exercise != null && !_isDisposed) {
            _exerciseDetails[id] = exercise;
          }
        } catch (_) {
          // Silently handle error
        }
      });

      await Future.wait(futures);
    } else {
      // برای تعداد زیاد، از getExercises استفاده کن (از کش استفاده می‌کند)
      try {
        final allExercises = await _exerciseService.getExercises();
        if (_isDisposed) return;

        final exerciseMap = {for (final ex in allExercises) ex.id: ex};

        for (final id in remainingIdsToLoad) {
          if (_isDisposed) return;
          final exercise = exerciseMap[id];
          if (exercise != null) {
            _exerciseDetails[id] = exercise;
          }
        }
      } catch (_) {
        if (_isDisposed) return;
        // اگر getExercises خطا داد، به روش موازی برگرد
        final futures = remainingIdsToLoad.map((id) async {
          if (_isDisposed) return;
          try {
            final exercise = await _exerciseService.getExerciseById(id);
            if (exercise != null && !_isDisposed) {
              _exerciseDetails[id] = exercise;
            }
          } catch (_) {
            // Silently handle error
          }
        });

        await Future.wait(futures);
      }
    }

    _safeNotifyListeners();
  }

  void initExerciseControllers() {
    _isLoadingData = true;
    disposeControllers();

    if (_selectedSession == null) {
      _isLoadingData = false;
      return;
    }

    for (final exercise in _selectedSession!.exercises) {
      if (exercise is NormalExercise) {
        _initNormalExerciseControllers(exercise);
      } else if (exercise is SupersetExercise) {
        _initSupersetExerciseControllers(exercise);
      }
    }
  }

  void _initNormalExerciseControllers(NormalExercise exercise) {
    final exerciseId = exercise.exerciseId.toString();
    final sets = exercise.sets.length;

    _exerciseControllers[exerciseId] = [];
    _setSavedStatus[exerciseId] = [];
    _exerciseFocusNodes[exerciseId] = [];

    for (int i = 0; i < sets; i++) {
      final weightController = TextEditingController();
      final repsController = TextEditingController();
      final timeController = TextEditingController();

      final repsFocusNode = FocusNode();
      final timeFocusNode = FocusNode();
      final weightFocusNode = FocusNode();

      final setKey = '$exerciseId-$i';
      weightController.addListener(
        () => scheduleAutoSave(setKey, exerciseId, i),
      );
      repsController.addListener(() => scheduleAutoSave(setKey, exerciseId, i));
      timeController.addListener(() => scheduleAutoSave(setKey, exerciseId, i));

      _exerciseControllers[exerciseId]!.add({
        'weight': weightController,
        'reps': repsController,
        'time': timeController,
      });
      _setSavedStatus[exerciseId]!.add(false);
      _exerciseFocusNodes[exerciseId]!.add({
        'weight': weightFocusNode,
        'reps': repsFocusNode,
        'time': timeFocusNode,
      });
    }
  }

  void _initSupersetExerciseControllers(SupersetExercise exercise) {
    for (final item in exercise.exercises) {
      final exerciseId = '${exercise.id}_${item.exerciseId}';
      final sets = item.sets.length;

      _exerciseControllers[exerciseId] = [];
      _setSavedStatus[exerciseId] = [];
      _exerciseFocusNodes[exerciseId] = [];

      for (int i = 0; i < sets; i++) {
        final weightController = TextEditingController();
        final repsController = TextEditingController();
        final timeController = TextEditingController();

        final repsFocusNode = FocusNode();
        final timeFocusNode = FocusNode();
        final weightFocusNode = FocusNode();

        final setKey = '$exerciseId-$i';
        weightController.addListener(
          () => scheduleAutoSave(setKey, exerciseId, i),
        );
        repsController.addListener(
          () => scheduleAutoSave(setKey, exerciseId, i),
        );
        timeController.addListener(
          () => scheduleAutoSave(setKey, exerciseId, i),
        );

        _exerciseControllers[exerciseId]!.add({
          'weight': weightController,
          'reps': repsController,
          'time': timeController,
        });
        _setSavedStatus[exerciseId]!.add(false);
        _exerciseFocusNodes[exerciseId]!.add({
          'weight': weightFocusNode,
          'reps': repsFocusNode,
          'time': timeFocusNode,
        });
      }
    }
  }

  void disposeControllers() {
    for (final exerciseControllers in _exerciseControllers.values) {
      for (final setControllers in exerciseControllers) {
        for (final controller in setControllers.values) {
          controller.dispose();
        }
      }
    }
    _exerciseControllers.clear();
    _setSavedStatus.clear();

    for (final exerciseFocusNodes in _exerciseFocusNodes.values) {
      for (final setFocusNodes in exerciseFocusNodes) {
        for (final focusNode in setFocusNodes.values) {
          focusNode.dispose();
        }
      }
    }
    _exerciseFocusNodes.clear();
  }

  void scheduleAutoSave(String setKey, String exerciseId, int setIndex) {
    if (_isLoadingData) return;

    _autoSaveTimers[setKey]?.cancel();

    final controllers = _exerciseControllers[exerciseId];
    if (controllers == null || controllers.length <= setIndex) return;

    final setControllers = controllers[setIndex];
    final weight = setControllers['weight']?.text.trim() ?? '';
    final reps = setControllers['reps']?.text.trim() ?? '';
    final time = setControllers['time']?.text.trim() ?? '';

    if (weight.isEmpty && reps.isEmpty && time.isEmpty) {
      final savedStatus = _setSavedStatus[exerciseId];
      if (savedStatus != null &&
          savedStatus.length > setIndex &&
          savedStatus[setIndex]) {
        savedStatus[setIndex] = false;
        _safeNotifyListeners();
      }
      return;
    }

    _bumpSessionHeatmap();

    _autoSaveTimers[setKey] = Timer(const Duration(seconds: 1), () {
      saveSet(exerciseId, setIndex);
    });
  }

  Future<void> saveSet(String exerciseId, int setIndex) async {
    try {
      final controllers = _exerciseControllers[exerciseId]![setIndex];
      final weight = double.tryParse(controllers['weight']?.text ?? '0') ?? 0.0;
      final reps = int.tryParse(controllers['reps']?.text ?? '0') ?? 0;
      final timeSeconds = int.tryParse(controllers['time']?.text ?? '0') ?? 0;

      await _saveSetToDatabase(exerciseId, setIndex, weight, reps, timeSeconds);

      _setSavedStatus[exerciseId]![setIndex] = true;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error auto-saving set: $e');
    }
  }

  Future<void> _saveSetToDatabase(
    String exerciseId,
    int setIndex,
    double weight,
    int reps,
    int timeSeconds,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null ||
          _selectedProgram == null ||
          _selectedSession == null) {
        return;
      }

      final gregorian = _selectedDate.toGregorian();
      final selectedDateTime = gregorian.toDateTime();

      final existingDailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        selectedDateTime,
      );

      if (existingDailyLog != null) {
        await _updateExistingLog(
          existingDailyLog,
          exerciseId,
          setIndex,
          weight,
          reps,
          timeSeconds,
        );
      } else {
        await _createNewProgramLog(
          exerciseId,
          setIndex,
          weight,
          reps,
          timeSeconds,
        );
      }

      try {
        await Supabase.instance.client
            .from('workout_programs')
            .update({'is_used': true})
            .eq('id', _selectedProgram!.id)
            .eq('is_used', false);
        final programRow = await Supabase.instance.client
            .from('workout_programs')
            .select('first_used_at, is_used')
            .eq('id', _selectedProgram!.id)
            .maybeSingle();
        if (programRow != null && programRow['first_used_at'] == null) {
          await Supabase.instance.client
              .from('workout_programs')
              .update({'first_used_at': DateTime.now().toIso8601String()})
              .eq('id', _selectedProgram!.id);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Error saving set to database: $e');
    }
  }

  Future<void> _updateExistingLog(
    WorkoutDailyLog dailyLog,
    String exerciseId,
    int setIndex,
    double weight,
    int reps,
    int timeSeconds,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final updatedSessions = <WorkoutSessionLog>[];

      for (final session in dailyLog.sessions) {
        final updatedExercises = <WorkoutExerciseLog>[];
        for (final exercise in session.exercises) {
          if (exercise is NormalExerciseLog) {
            if (exercise.exerciseId.toString() == exerciseId) {
              final allSets = _buildSetLogs(exerciseId);
              updatedExercises.add(
                NormalExerciseLog(
                  id: exercise.id,
                  exerciseId: exercise.exerciseId,
                  exerciseName: exercise.exerciseName,
                  tag: exercise.tag,
                  style: exercise.style,
                  sets: allSets,
                ),
              );
            } else {
              updatedExercises.add(exercise);
            }
          } else if (exercise is SupersetExerciseLog) {
            final updatedSupersetItems = <SupersetItemLog>[];
            for (final item in exercise.exercises) {
              final oldItemId = '${exercise.id}_${item.exerciseId}';
              final newItemId = _findSupersetItemId(
                exercise.id,
                item.exerciseId,
              );

              if (oldItemId == exerciseId || newItemId == exerciseId) {
                final allSets = _buildSetLogs(exerciseId);
                updatedSupersetItems.add(
                  SupersetItemLog(
                    exerciseId: item.exerciseId,
                    exerciseName: item.exerciseName,
                    sets: allSets,
                  ),
                );
              } else {
                updatedSupersetItems.add(item);
              }
            }
            updatedExercises.add(
              SupersetExerciseLog(
                id: exercise.id,
                tag: exercise.tag,
                style: exercise.style,
                exercises: updatedSupersetItems,
              ),
            );
          }
        }
        updatedSessions.add(
          WorkoutSessionLog(
            id: session.id,
            day: session.day,
            exercises: updatedExercises,
            notes: _selectedSession?.notes ?? session.notes,
          ),
        );
      }

      final updatedDailyLog = WorkoutDailyLog(
        id: dailyLog.id,
        userId: dailyLog.userId,
        logDate: dailyLog.logDate,
        sessions: updatedSessions,
        createdAt: dailyLog.createdAt,
        updatedAt: DateTime.now(),
      );

      await _workoutLogService.updateDailyLog(updatedDailyLog);

      _loggedSessionDay = _selectedSession?.day;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error updating existing log: $e');
    }
  }

  Future<void> _createNewProgramLog(
    String exerciseId,
    int setIndex,
    double weight,
    int reps,
    int timeSeconds,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _selectedProgram == null || _selectedSession == null) {
      return;
    }

    final gregorian = _selectedDate.toGregorian();
    final selectedDateTime = gregorian.toDateTime();

    final sessionLog = WorkoutSessionLog(
      id: const Uuid().v4(),
      day: _selectedSession!.day,
      exercises: _buildExerciseLogs(),
      notes: _selectedSession!.notes,
    );

    final dailyLog = WorkoutDailyLog(
      userId: user.id,
      logDate: selectedDateTime,
      sessions: [sessionLog],
    );

    await _workoutLogService.saveDailyLog(dailyLog);

    _hasTodayLog = true;
    _loggedSessionDay = _selectedSession?.day;
    _safeNotifyListeners();
  }

  List<WorkoutExerciseLog> _buildExerciseLogs() {
    final exercises = <WorkoutExerciseLog>[];

    for (final exercise in _selectedSession!.exercises) {
      if (exercise is NormalExercise) {
        final sets = _buildSetLogs(exercise.exerciseId.toString());
        final exerciseDetails = _exerciseDetails[exercise.exerciseId];
        // استفاده از tag اگر exerciseDetails موجود نباشد
        final exerciseName =
            exerciseDetails?.name ??
            (exercise.tag.isNotEmpty ? exercise.tag : 'تمرین ناشناخته');
        exercises.add(
          NormalExerciseLog(
            id: const Uuid().v4(),
            exerciseId: exercise.exerciseId,
            exerciseName: exerciseName,
            tag: exercise.tag,
            style: exercise.style.toString().split('.').last,
            sets: sets,
            note: exercise.note,
          ),
        );
      } else if (exercise is SupersetExercise) {
        final supersetExercises = <SupersetItemLog>[];
        for (final item in exercise.exercises) {
          final itemId = '${exercise.id}_${item.exerciseId}';
          final sets = _buildSetLogs(itemId);
          final exerciseDetails = _exerciseDetails[item.exerciseId];
          // استفاده از tag superset اگر exerciseDetails موجود نباشد
          final exerciseName =
              exerciseDetails?.name ??
              (exercise.tag.isNotEmpty ? exercise.tag : 'تمرین ناشناخته');
          supersetExercises.add(
            SupersetItemLog(
              exerciseId: item.exerciseId,
              exerciseName: exerciseName,
              sets: sets,
            ),
          );
        }
        exercises.add(
          SupersetExerciseLog(
            id: const Uuid().v4(),
            tag: exercise.tag,
            style: exercise.style.toString().split('.').last,
            exercises: supersetExercises,
            note: exercise.note,
          ),
        );
      }
    }

    return exercises;
  }

  List<ExerciseSetLog> _buildSetLogs(String exerciseId) {
    final controllers = _exerciseControllers[exerciseId];
    if (controllers == null) return [];

    final sets = <ExerciseSetLog>[];
    for (int i = 0; i < controllers.length; i++) {
      final setControllers = controllers[i];
      final repsText = setControllers['reps']?.text.trim() ?? '';
      final timeText = setControllers['time']?.text.trim() ?? '';
      final weightText = setControllers['weight']?.text.trim() ?? '';

      final hasData =
          repsText.isNotEmpty || timeText.isNotEmpty || weightText.isNotEmpty;

      if (hasData) {
        sets.add(
          ExerciseSetLog(
            reps: repsText.isNotEmpty ? int.tryParse(repsText) : null,
            seconds: timeText.isNotEmpty ? int.tryParse(timeText) : null,
            weight: weightText.isNotEmpty ? double.tryParse(weightText) : null,
          ),
        );
      }
    }

    return sets;
  }

  String _findSupersetItemId(String supersetId, int exerciseId) {
    if (_selectedSession != null) {
      for (final exercise in _selectedSession!.exercises) {
        if (exercise is SupersetExercise) {
          for (final item in exercise.exercises) {
            if (item.exerciseId == exerciseId) {
              return '${exercise.id}_$exerciseId';
            }
          }
        }
      }
    }
    return '${supersetId}_$exerciseId';
  }

  Future<void> checkLogForDate(Jalali date) async {
    _isLoadingTodayLog = true;
    _safeNotifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _hasTodayLog = false;
      _isLoadingTodayLog = false;
      _safeNotifyListeners();
      return;
    }

    if (_selectedProgram == null) {
      await loadActiveProgram();
    }

    final gregorian = date.toGregorian();
    final dateTime = gregorian.toDateTime();

    try {
      final dailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        dateTime,
      );

      if (dailyLog != null) {
        _hasTodayLog = true;
        _isLoadingTodayLog = false;
        _safeNotifyListeners();

        if (dailyLog.sessions.isNotEmpty) {
          final sessionLog = dailyLog.sessions.first;
          _loggedSessionDay = sessionLog.day; // تنظیم loggedSessionDay

          WorkoutSession? foundSession;
          if (_selectedProgram != null) {
            for (final session in _selectedProgram!.sessions) {
              if (session.day == sessionLog.day) {
                foundSession = session;
                break;
              }
            }
          }

          if (foundSession != null && _selectedProgram != null) {
            _selectedSession = foundSession;
            _safeNotifyListeners();
            initExerciseControllers();
            await loadExerciseDetails();
            await loadSavedData(sessionLog);
          } else {
            _selectedSession = _reconstructSessionFromLog(sessionLog);
            _safeNotifyListeners();
            initExerciseControllers();
            await loadExerciseDetails();
            await loadSavedData(sessionLog);
          }
        } else {
          _selectedSession = null;
          _isLoadingTodayLog = false;
          _safeNotifyListeners();
          if (_selectedProgram != null) {
            initExerciseControllers();
            await loadExerciseDetails();
          }
        }
      } else {
        _hasTodayLog = false;
        _isLoadingTodayLog = false;
        _loggedSessionDay = null;
        if (_selectedProgram == null) {
          _selectedSession = null;
        }
        _safeNotifyListeners();
        if (_selectedProgram != null && _selectedSession != null) {
          initExerciseControllers();
          await loadExerciseDetails();
        }
      }
    } catch (e) {
      debugPrint('Error loading today log: $e');
      _hasTodayLog = false;
      _isLoadingTodayLog = false;
      _safeNotifyListeners();
    }
  }

  WorkoutSession _reconstructSessionFromLog(WorkoutSessionLog sessionLog) {
    final exercises = <WorkoutExercise>[];

    for (final exerciseLog in sessionLog.exercises) {
      if (exerciseLog is NormalExerciseLog) {
        final sets = exerciseLog.sets.map((setLog) {
          return ExerciseSet(
            reps: setLog.reps,
            timeSeconds: setLog.seconds,
            weight: setLog.weight,
          );
        }).toList();

        exercises.add(
          NormalExercise(
            exerciseId: exerciseLog.exerciseId,
            tag: exerciseLog.tag,
            style: ExerciseStyle.values.firstWhere(
              (e) => e.toString().split('.').last == exerciseLog.style,
              orElse: () => ExerciseStyle.setsReps,
            ),
            sets: sets,
            note: exerciseLog.note,
          ),
        );
      } else if (exerciseLog is SupersetExerciseLog) {
        final supersetItems = exerciseLog.exercises.map((itemLog) {
          final sets = itemLog.sets.map((setLog) {
            return ExerciseSet(
              reps: setLog.reps,
              timeSeconds: setLog.seconds,
              weight: setLog.weight,
            );
          }).toList();

          return SupersetItem(
            exerciseId: itemLog.exerciseId,
            style: ExerciseStyle.values.firstWhere(
              (e) => e.toString().split('.').last == exerciseLog.style,
              orElse: () => ExerciseStyle.setsReps,
            ),
            sets: sets,
          );
        }).toList();

        exercises.add(
          SupersetExercise(
            id: exerciseLog.id,
            tag: exerciseLog.tag,
            style: ExerciseStyle.values.firstWhere(
              (e) => e.toString().split('.').last == exerciseLog.style,
              orElse: () => ExerciseStyle.setsReps,
            ),
            exercises: supersetItems,
            note: exerciseLog.note,
          ),
        );
      }
    }

    return WorkoutSession(
      id: sessionLog.id,
      day: sessionLog.day,
      exercises: exercises,
      notes: sessionLog.notes,
    );
  }

  Future<void> loadSavedData(WorkoutSessionLog sessionLog) async {
    _isLoadingData = true;

    for (final exerciseLog in sessionLog.exercises) {
      if (exerciseLog is NormalExerciseLog) {
        await _loadNormalExerciseData(exerciseLog);
      } else if (exerciseLog is SupersetExerciseLog) {
        await _loadSupersetExerciseData(exerciseLog);
      }
    }

    _isLoadingData = false;
  }

  Future<void> _loadNormalExerciseData(NormalExerciseLog exerciseLog) async {
    final exerciseId = exerciseLog.exerciseId.toString();
    final controllers = _exerciseControllers[exerciseId];
    if (controllers == null) return;

    _clearControllers(controllers);
    _populateControllers(controllers, exerciseLog.sets, exerciseId);
  }

  Future<void> _loadSupersetExerciseData(
    SupersetExerciseLog exerciseLog,
  ) async {
    for (final itemLog in exerciseLog.exercises) {
      final itemId = _findSupersetItemId(exerciseLog.id, itemLog.exerciseId);
      final controllers = _exerciseControllers[itemId];
      if (controllers == null) continue;

      _clearControllers(controllers);
      _populateControllers(controllers, itemLog.sets, itemId);
    }
  }

  void _clearControllers(List<Map<String, TextEditingController>> controllers) {
    for (final setControllers in controllers) {
      setControllers['weight']?.clear();
      setControllers['reps']?.clear();
      setControllers['time']?.clear();
    }
  }

  void _populateControllers(
    List<Map<String, TextEditingController>> controllers,
    List<ExerciseSetLog> sets,
    String exerciseId,
  ) {
    for (int i = 0; i < sets.length && i < controllers.length; i++) {
      final set = sets[i];
      final setControllers = controllers[i];

      if (set.weight != null && set.weight! > 0) {
        setControllers['weight']?.text = set.weight.toString();
      }
      if (set.reps != null && set.reps! > 0) {
        setControllers['reps']?.text = set.reps.toString();
      }
      if (set.seconds != null && set.seconds! > 0) {
        setControllers['time']?.text = set.seconds.toString();
      }

      final hasData =
          (set.weight != null && set.weight! > 0) ||
          (set.reps != null && set.reps! > 0) ||
          (set.seconds != null && set.seconds! > 0);
      if (hasData && _setSavedStatus[exerciseId] != null) {
        if (_setSavedStatus[exerciseId]!.length > i) {
          _setSavedStatus[exerciseId]![i] = true;
        }
      }
    }
  }

  Future<void> onSessionSelected(WorkoutSession? session) async {
    if (session == null) {
      _selectedSession = null;
      _safeNotifyListeners();
      return;
    }

    _selectedSession = session;
    _safeNotifyListeners();

    initExerciseControllers();
    await loadExerciseDetails();
    await loadSavedDataForSession(session);
    _isLoadingData = false;
  }

  Future<void> loadSavedDataForSession(WorkoutSession session) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final gregorian = _selectedDate.toGregorian();
      final selectedDateTime = gregorian.toDateTime();

      final dailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        selectedDateTime,
      );

      if (dailyLog != null && dailyLog.sessions.isNotEmpty) {
        WorkoutSessionLog? matchingSessionLog;
        for (final sessionLog in dailyLog.sessions) {
          if (sessionLog.day == session.day) {
            matchingSessionLog = sessionLog;
            break;
          }
        }

        if (matchingSessionLog != null) {
          await loadSavedData(matchingSessionLog);
        }
      }
    } catch (e) {
      debugPrint('Error loading saved data for session: $e');
    }
  }

  Future<void> deleteSessionLog(String sessionDay) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final gregorian = _selectedDate.toGregorian();
      final selectedDateTime = gregorian.toDateTime();

      final dailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        selectedDateTime,
      );

      if (dailyLog != null && dailyLog.sessions.isNotEmpty) {
        final updatedSessions = dailyLog.sessions
            .where((s) => s.day != sessionDay)
            .toList();

        // اگر session حذف شده همان loggedSessionDay است، آن را null کن
        if (_loggedSessionDay == sessionDay) {
          _loggedSessionDay = null;
        }

        if (updatedSessions.isEmpty) {
          await _workoutLogService.deleteDailyLog(dailyLog.id);
          _hasTodayLog = false;
          _loggedSessionDay = null;
        } else {
          final updatedDailyLog = WorkoutDailyLog(
            id: dailyLog.id,
            userId: dailyLog.userId,
            logDate: dailyLog.logDate,
            sessions: updatedSessions,
            createdAt: dailyLog.createdAt,
            updatedAt: DateTime.now(),
          );
          await _workoutLogService.updateDailyLog(updatedDailyLog);
        }

        disposeControllers();
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting session log: $e');
    }
  }

  /// چک می‌کند که آیا داده‌هایی در فرم وارد شده یا نه
  bool hasUnsavedData() {
    if (_selectedSession == null) return false;

    // بررسی تمام controllers برای پیدا کردن داده‌های وارد شده
    for (final entry in _exerciseControllers.entries) {
      final exerciseId = entry.key;
      final controllers = entry.value;

      for (final setControllers in controllers) {
        final weight = setControllers['weight']?.text.trim() ?? '';
        final reps = setControllers['reps']?.text.trim() ?? '';
        final time = setControllers['time']?.text.trim() ?? '';

        // اگر حداقل یکی از فیلدها مقدار داشته باشد
        if (weight.isNotEmpty || reps.isNotEmpty || time.isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  /// تمام focus nodes را unfocus می‌کند و کیبورد را می‌بندد
  void unfocusAllFields() {
    for (final exerciseFocusNodes in _exerciseFocusNodes.values) {
      for (final setFocusNodes in exerciseFocusNodes) {
        for (final focusNode in setFocusNodes.values) {
          focusNode.unfocus();
        }
      }
    }
  }

  void updateSelectedDate(Jalali date) {
    _selectedDate = date;
    _safeNotifyListeners();
  }

  Future<void> clearCache() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await _workoutLogService.clearAllCache(user.id);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    disposeControllers();
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    _sessionHeatmapTick.dispose();
    super.dispose();
  }

  /// Safe notify listeners - checks if disposed before notifying
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
