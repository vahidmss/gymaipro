import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
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
  final Map<String, WorkoutExerciseCoachFeedback> _exerciseCoachFeedback = {};

  bool _hasTodayLog = false;
  bool _isLoadingTodayLog = true;
  bool _isLoadingDayLog = false;
  bool _awaitingSessionPickAfterDateChange = false;
  String? _loggedSessionDay;
  int? _loggedSessionDateKey;
  final Map<String, Timer> _autoSaveTimers = {};
  final Map<String, Timer> _heatmapPreviewTimers = {};
  int _dbSaveGeneration = 0;
  bool _isLoadingData = false;
  bool _isDisposed = false;
  MuscleHeatmapSnapshot? _sessionHeatmapCache;
  bool _sessionHeatmapDirty = true;

  /// فقط برای به‌روزرسانی چیپ/شیت نقشه — بدون rebuild کل صفحه.
  final ValueNotifier<int> sessionHeatmapTick = ValueNotifier(0);

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
  Map<String, WorkoutExerciseCoachFeedback> get exerciseCoachFeedback =>
      _exerciseCoachFeedback;
  bool get hasTodayLog => _hasTodayLog;
  bool get isLoadingTodayLog => _isLoadingTodayLog;
  bool get isLoadingDayLog => _isLoadingDayLog;
  String? get loggedSessionDay => _loggedSessionDay;

  /// هیت‌مپ جلسه — با کش؛ فقط وقتی لاگ عوض می‌شود دوباره حساب می‌شود.
  MuscleHeatmapSnapshot get sessionHeatmapSnapshot {
    if (_selectedSession == null) return MuscleHeatmapSnapshot.empty();
    if (!_sessionHeatmapDirty && _sessionHeatmapCache != null) {
      return _sessionHeatmapCache!;
    }
    _sessionHeatmapCache = MuscleHeatmapAggregate.fromExerciseLogs(
      _buildExerciseLogs(),
      _exerciseDetails,
      catalogFallback: _exerciseService.cachedExercisesSync,
    );
    _sessionHeatmapDirty = false;
    return _sessionHeatmapCache!;
  }

  void _invalidateSessionHeatmap() {
    _sessionHeatmapDirty = true;
    _sessionHeatmapCache = null;
  }

  void bumpSessionHeatmapPreview() {
    if (_isDisposed) return;
    _invalidateSessionHeatmap();
    sessionHeatmapTick.value++;
  }

  DateTime get _selectedDateOnly {
    final g = _selectedDate.toGregorian();
    return DateTime(g.year, g.month, g.day);
  }

  int get _selectedDateKey => _selectedDateOnly.millisecondsSinceEpoch;

  bool get _hasLoggedSessionOnSelectedDate =>
      _loggedSessionDay != null && _loggedSessionDateKey == _selectedDateKey;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _logMatchesDate(WorkoutDailyLog log, DateTime expected) {
    return _dateOnly(log.logDate) == _dateOnly(expected);
  }

  void _bindLoggedSession(String sessionDay, DateTime logDate) {
    _loggedSessionDay = sessionDay;
    _loggedSessionDateKey = _dateOnly(logDate).millisecondsSinceEpoch;
  }

  void _clearLoggedSessionMeta() {
    _loggedSessionDay = null;
    _loggedSessionDateKey = null;
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
        !(_collapsedExercises[exerciseId] ?? false);
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
      _refreshAllExerciseCoachFeedback();
      bumpSessionHeatmapPreview();
      _safeNotifyListeners();
      return;
    }

    // بارگذاری تمرین‌های اختصاصی مربی برنامه (اگر برنامه توسط مربی ساخته شده باشد)
    if (_selectedProgram?.trainerId != null &&
        _selectedProgram!.trainerId!.isNotEmpty) {
      try {
        final customExerciseService = CustomExerciseService();
        // دریافت تمرین‌های اختصاصی مربی برنامه
        final trainerCustomExercises = await customExerciseService
            .getTrainerExercisesById(_selectedProgram!.trainerId!);

        // تبدیل CustomExercise به Exercise و اضافه کردن به exerciseDetails
        final trainerExercises = await customExerciseService
            .customExercisesToExercises(trainerCustomExercises);

        for (final exercise in trainerExercises) {
          if (idsToLoad.contains(exercise.id) &&
              !_exerciseDetails.containsKey(exercise.id)) {
            _exerciseDetails[exercise.id] = exercise;
            debugPrint(
              '✅ تمرین اختصاصی مربی بارگذاری شد: ${exercise.name} (ID: ${exercise.id})',
            );
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
      _refreshAllExerciseCoachFeedback();
      bumpSessionHeatmapPreview();
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

    _refreshAllExerciseCoachFeedback();
    bumpSessionHeatmapPreview();
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
      final rpeController = TextEditingController();

      final repsFocusNode = FocusNode();
      final timeFocusNode = FocusNode();
      final weightFocusNode = FocusNode();
      final rpeFocusNode = FocusNode();

      final setKey = '$exerciseId-$i';
      weightController.addListener(
        () => scheduleAutoSave(setKey, exerciseId, i),
      );
      repsController.addListener(() => scheduleAutoSave(setKey, exerciseId, i));
      timeController.addListener(() => scheduleAutoSave(setKey, exerciseId, i));
      rpeController.addListener(() => scheduleAutoSave(setKey, exerciseId, i));

      _exerciseControllers[exerciseId]!.add({
        'weight': weightController,
        'reps': repsController,
        'time': timeController,
        'rpe': rpeController,
      });
      _setSavedStatus[exerciseId]!.add(false);
      _exerciseFocusNodes[exerciseId]!.add({
        'weight': weightFocusNode,
        'reps': repsFocusNode,
        'time': timeFocusNode,
        'rpe': rpeFocusNode,
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
        final rpeController = TextEditingController();

        final repsFocusNode = FocusNode();
        final timeFocusNode = FocusNode();
        final weightFocusNode = FocusNode();
        final rpeFocusNode = FocusNode();

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
        rpeController.addListener(
          () => scheduleAutoSave(setKey, exerciseId, i),
        );

        _exerciseControllers[exerciseId]!.add({
          'weight': weightController,
          'reps': repsController,
          'time': timeController,
          'rpe': rpeController,
        });
        _setSavedStatus[exerciseId]!.add(false);
        _exerciseFocusNodes[exerciseId]!.add({
          'weight': weightFocusNode,
          'reps': repsFocusNode,
          'time': timeFocusNode,
          'rpe': rpeFocusNode,
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
    _exerciseCoachFeedback.clear();

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
        bumpSessionHeatmapPreview();
        _refreshExerciseCoachFeedback(exerciseId);
        _safeNotifyListeners();
      }
      return;
    }

    _heatmapPreviewTimers[setKey]?.cancel();
    _heatmapPreviewTimers[setKey] = Timer(
      const Duration(milliseconds: 350),
      bumpSessionHeatmapPreview,
    );

    _autoSaveTimers[setKey] = Timer(const Duration(seconds: 1), () {
      saveSet(exerciseId, setIndex);
    });
  }

  Future<void> saveSet(String exerciseId, int setIndex) async {
    final savedStatus = _setSavedStatus[exerciseId];
    final wasSaved =
        savedStatus != null &&
        savedStatus.length > setIndex &&
        savedStatus[setIndex];
    try {
      final controllers = _exerciseControllers[exerciseId]![setIndex];
      final weightText = controllers['weight']?.text.trim() ?? '';
      final repsText = controllers['reps']?.text.trim() ?? '';
      final timeText = controllers['time']?.text.trim() ?? '';
      final weight = weightText.isNotEmpty
          ? (double.tryParse(weightText) ?? 0.0)
          : 0.0;
      final reps = repsText.isNotEmpty ? (int.tryParse(repsText) ?? 0) : 0;
      final timeSeconds = timeText.isNotEmpty
          ? (int.tryParse(timeText) ?? 0)
          : 0;

      if (savedStatus != null && savedStatus.length > setIndex) {
        savedStatus[setIndex] = true;
      }

      bumpSessionHeatmapPreview();
      _refreshExerciseCoachFeedback(exerciseId);
      if (!wasSaved) {
        _safeNotifyListeners();
      }

      final sessionDay = _selectedSession!.day;
      final generation = _dbSaveGeneration;
      await _saveSetToDatabase(
        exerciseId,
        setIndex,
        weight,
        reps,
        timeSeconds,
        sessionDay: sessionDay,
        generation: generation,
      );
    } catch (e) {
      debugPrint('Error auto-saving set: $e');
      // Rollback optimistic update on failure
      if (savedStatus != null && savedStatus.length > setIndex && !wasSaved) {
        savedStatus[setIndex] = false;
        _refreshExerciseCoachFeedback(exerciseId, notify: false);
        _safeNotifyListeners();
      }
    }
  }

  void _refreshAllExerciseCoachFeedback() {
    _exerciseCoachFeedback.clear();
    if (_selectedProgram?.isSelfServiceAi != true) return;
    for (final exerciseKey in _exerciseControllers.keys) {
      _refreshExerciseCoachFeedback(exerciseKey, notify: false);
    }
  }

  void _refreshExerciseCoachFeedback(String exerciseKey, {bool notify = true}) {
    if (_isDisposed) return;

    // نکته مربی فقط برای برنامه‌های هوش مصنوعی / شروع باشگاه
    if (_selectedProgram?.isSelfServiceAi != true) {
      _exerciseCoachFeedback.remove(exerciseKey);
      if (notify) _safeNotifyListeners();
      return;
    }

    final resolved = _resolveExerciseForCoachFeedback(exerciseKey);
    final controllers = _exerciseControllers[exerciseKey];
    final savedStatus = _setSavedStatus[exerciseKey];
    if (resolved == null || controllers == null || savedStatus == null) {
      _exerciseCoachFeedback.remove(exerciseKey);
      if (notify) _safeNotifyListeners();
      return;
    }

    final details = _exerciseDetails[resolved.exerciseId];
    final feedback = WorkoutExerciseCoachFeedbackEngine.fromControllers(
      prescription: resolved.sets,
      setValues: controllers
          .map(
            (setControllers) => <String, String>{
              'weight': setControllers['weight']?.text.trim() ?? '',
              'reps': setControllers['reps']?.text.trim() ?? '',
              'time': setControllers['time']?.text.trim() ?? '',
              'rpe': setControllers['rpe']?.text.trim() ?? '',
            },
          )
          .toList(),
      savedStatus: savedStatus,
      style: resolved.style,
      formTipSource: WorkoutExerciseCoachFeedbackEngine.resolveFormTipSource(
        tips: details?.tips ?? const <String>[],
        programNote: resolved.note,
      ),
    );

    if (feedback == null) {
      _exerciseCoachFeedback.remove(exerciseKey);
    } else {
      _exerciseCoachFeedback[exerciseKey] = feedback;
    }
    if (notify) _safeNotifyListeners();
  }

  ({int exerciseId, List<ExerciseSet> sets, ExerciseStyle style, String? note})?
  _resolveExerciseForCoachFeedback(String exerciseKey) {
    final session = _selectedSession;
    if (session == null) return null;

    for (final exercise in session.exercises) {
      if (exercise is NormalExercise) {
        if (exercise.exerciseId.toString() == exerciseKey) {
          return (
            exerciseId: exercise.exerciseId,
            sets: exercise.sets,
            style: exercise.style,
            note: exercise.note,
          );
        }
      } else if (exercise is SupersetExercise) {
        for (final item in exercise.exercises) {
          final itemId = '${exercise.id}_${item.exerciseId}';
          if (itemId == exerciseKey) {
            return (
              exerciseId: item.exerciseId,
              sets: item.sets,
              style: item.style,
              note: exercise.note,
            );
          }
        }
      }
    }
    return null;
  }

  Future<void> _saveSetToDatabase(
    String exerciseId,
    int setIndex,
    double weight,
    int reps,
    int timeSeconds, {
    required String sessionDay,
    required int generation,
  }) async {
    try {
      if (!_isDbSaveStillValid(generation, sessionDay)) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null ||
          _selectedProgram == null ||
          _selectedSession == null) {
        return;
      }

      final selectedDateTime = _selectedDateOnly;

      final existingDailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        selectedDateTime,
        preferRemote: true,
      );

      if (!_isDbSaveStillValid(generation, sessionDay)) return;

      if (existingDailyLog != null) {
        await _updateExistingLog(
          existingDailyLog,
          sessionDay: sessionDay,
          generation: generation,
        );
      } else {
        await _createNewProgramLog(
          sessionDay: sessionDay,
          generation: generation,
        );
      }

      if (!_isDbSaveStillValid(generation, sessionDay)) return;

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
    WorkoutDailyLog dailyLog, {
    required String sessionDay,
    required int generation,
  }) async {
    try {
      if (!_isDbSaveStillValid(generation, sessionDay)) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _selectedSession == null) return;

      final activeDay = sessionDay;
      var activeFound = false;

      final updatedSessions = <WorkoutSessionLog>[];
      for (final session in dailyLog.sessions) {
        if (session.day == activeDay) {
          activeFound = true;
          updatedSessions.add(_buildCurrentSessionLog(existingId: session.id));
        } else {
          updatedSessions.add(session);
        }
      }

      if (!activeFound) {
        updatedSessions.add(_buildCurrentSessionLog());
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

      if (!_isDbSaveStillValid(generation, sessionDay)) return;

      _hasTodayLog = updatedSessions.isNotEmpty;
      _bindLoggedSession(activeDay, _selectedDateOnly);
    } catch (e) {
      debugPrint('Error updating existing log: $e');
    }
  }

  Future<void> _createNewProgramLog({
    required String sessionDay,
    required int generation,
  }) async {
    if (!_isDbSaveStillValid(generation, sessionDay)) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _selectedProgram == null || _selectedSession == null) {
      return;
    }

    final selectedDateTime = _selectedDateOnly;

    final sessionLog = WorkoutSessionLog(
      id: const Uuid().v4(),
      day: sessionDay,
      exercises: _buildExerciseLogs(),
      notes: _selectedSession!.notes,
      programId: _selectedProgram?.id,
    );

    final dailyLog = WorkoutDailyLog(
      userId: user.id,
      logDate: selectedDateTime,
      sessions: [sessionLog],
    );

    await _workoutLogService.saveDailyLog(dailyLog);

    if (!_isDbSaveStillValid(generation, sessionDay)) return;

    _hasTodayLog = true;
    _bindLoggedSession(sessionDay, selectedDateTime);
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

  bool _sessionLogHasSavedSets(WorkoutSessionLog sessionLog) {
    for (final exercise in sessionLog.exercises) {
      if (exercise is NormalExerciseLog) {
        if (exercise.sets.any(MuscleHeatmapAggregate.setHasWork)) {
          return true;
        }
      } else if (exercise is SupersetExerciseLog) {
        for (final item in exercise.exercises) {
          if (item.sets.any(MuscleHeatmapAggregate.setHasWork)) {
            return true;
          }
        }
      }
    }
    return false;
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
      final rpeText = setControllers['rpe']?.text.trim() ?? '';

      final hasData =
          repsText.isNotEmpty ||
          timeText.isNotEmpty ||
          weightText.isNotEmpty ||
          rpeText.isNotEmpty;

      if (hasData) {
        sets.add(
          ExerciseSetLog(
            reps: repsText.isNotEmpty ? int.tryParse(repsText) : null,
            seconds: timeText.isNotEmpty ? int.tryParse(timeText) : null,
            weight: weightText.isNotEmpty ? double.tryParse(weightText) : null,
            rpe: rpeText.isNotEmpty ? int.tryParse(rpeText) : null,
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

  void _cancelPendingAutoSaves() {
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    for (final timer in _heatmapPreviewTimers.values) {
      timer.cancel();
    }
    _heatmapPreviewTimers.clear();
    _dbSaveGeneration++;
  }

  bool _isDbSaveStillValid(int generation, String sessionDay) {
    return !_isDisposed &&
        generation == _dbSaveGeneration &&
        _selectedSession?.day == sessionDay;
  }

  /// لاگ سشن فعال از روی فرم — فقط همان روز/سشن انتخاب‌شده.
  WorkoutSessionLog _buildCurrentSessionLog({String? existingId}) {
    return WorkoutSessionLog(
      id: existingId ?? const Uuid().v4(),
      day: _selectedSession!.day,
      exercises: _buildExerciseLogs(),
      notes: _selectedSession?.notes,
      programId: _selectedProgram?.id,
    );
  }

  /// پاک‌سازی سشن و فرم — قبل از بارگذاری روز جدید.
  void _clearSessionFormState() {
    _cancelPendingAutoSaves();
    disposeControllers();
    bumpSessionHeatmapPreview();
    _selectedSession = null;
    _clearLoggedSessionMeta();
    _hasTodayLog = false;
    _collapsedExercises.clear();
    _isLoadingData = false;
  }

  /// تغییر تاریخ تقویم: فرم خالی + بارگذاری لاگ همان روز (در صورت وجود).
  Future<void> changeSelectedDate(Jalali date) async {
    final sameDay =
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    if (sameDay) return;

    _awaitingSessionPickAfterDateChange = true;
    await checkLogForDate(date, showFullScreenLoader: false);
    if (_selectedSession != null && _hasLoggedSessionOnSelectedDate) {
      _awaitingSessionPickAfterDateChange = false;
    }
  }

  Future<void> checkLogForDate(
    Jalali date, {
    bool showFullScreenLoader = true,
  }) async {
    _selectedDate = date;
    _clearSessionFormState();
    if (showFullScreenLoader) {
      _isLoadingTodayLog = true;
    } else {
      _isLoadingDayLog = true;
    }
    _safeNotifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    if (_selectedProgram == null) {
      await loadActiveProgram();
    }

    final dateTime = DateTime(
      date.toGregorian().year,
      date.toGregorian().month,
      date.toGregorian().day,
    );

    try {
      final dailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        dateTime,
      );

      if (dailyLog != null && _logMatchesDate(dailyLog, dateTime)) {
        _hasTodayLog = true;

        if (dailyLog.sessions.isNotEmpty) {
          final sessionLog = _pickSessionLogForDayLoad(dailyLog);
          _bindLoggedSession(sessionLog.day, dailyLog.logDate);

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
            initExerciseControllers();
            await loadExerciseDetails();
            await loadSavedData(sessionLog);
          } else {
            _selectedSession = _reconstructSessionFromLog(sessionLog);
            initExerciseControllers();
            await loadExerciseDetails();
            await loadSavedData(sessionLog);
          }
        } else {
          _selectedSession = null;
        }
      } else {
        _hasTodayLog = false;
        _clearLoggedSessionMeta();
        _selectedSession = null;
      }
    } catch (e) {
      debugPrint('Error loading today log: $e');
      _hasTodayLog = false;
      _clearLoggedSessionMeta();
      _selectedSession = null;
    } finally {
      if (showFullScreenLoader) {
        _isLoadingTodayLog = false;
      } else {
        _isLoadingDayLog = false;
      }
      bumpSessionHeatmapPreview();
      _safeNotifyListeners();
    }
  }

  /// اگر چند سشن در یک روز ثبت شده، آخرین سشن را بارگذاری می‌کند.
  WorkoutSessionLog _pickSessionLogForDayLoad(WorkoutDailyLog dailyLog) {
    if (dailyLog.sessions.length == 1) {
      return dailyLog.sessions.first;
    }
    return dailyLog.sessions.last;
  }

  /// آیا برای تعویض سشن در **همین روز** باید از کاربر تأیید گرفت؟
  /// (تغییر تاریخ تقویم = انتخاب اول سشن، بدون آلارم حذف)
  SessionChangePrompt evaluateSessionChange(WorkoutSession newSession) {
    // بعد از عوض کردن تاریخ تقویم، اولین انتخاب سشن بدون آلارم.
    if (_awaitingSessionPickAfterDateChange) {
      return const SessionChangePrompt.none();
    }

    final hasUnsaved = hasUnsavedData();
    final currentSessionDay = _selectedSession?.day;

    // فقط تداخل سشن‌های همان روز تقویم (نه نام سشن در روز دیگر).
    final conflictWithSavedLog =
        _hasTodayLog &&
        _hasLoggedSessionOnSelectedDate &&
        _loggedSessionDay != null &&
        _loggedSessionDay != newSession.day;

    final conflictWithDraft =
        hasUnsaved &&
        currentSessionDay != null &&
        currentSessionDay != newSession.day;

    if (!conflictWithSavedLog && !conflictWithDraft) {
      return const SessionChangePrompt.none();
    }

    // سشن فعلی (پیش‌نویس یا ثبت‌شده) که باید حذف/پاک شود.
    final sessionToReplace = currentSessionDay ?? _loggedSessionDay;

    final dialogLoggedDay = sessionToReplace ?? '';

    final dayToDelete = conflictWithSavedLog
        ? _loggedSessionDay
        : (conflictWithDraft ? currentSessionDay : null);

    return SessionChangePrompt.needConfirm(
      sessionDayToDelete: dayToDelete,
      hasUnsavedData: hasUnsaved,
      loggedSessionDayForDialog: dialogLoggedDay,
    );
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
    _refreshAllExerciseCoachFeedback();
    bumpSessionHeatmapPreview();
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
      setControllers['rpe']?.clear();
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
      if (set.rpe != null && set.rpe! > 0) {
        setControllers['rpe']?.text = set.rpe.toString();
      }

      final hasData =
          (set.weight != null && set.weight! > 0) ||
          (set.reps != null && set.reps! > 0) ||
          (set.seconds != null && set.seconds! > 0) ||
          (set.rpe != null && set.rpe! > 0);
      if (hasData && _setSavedStatus[exerciseId] != null) {
        if (_setSavedStatus[exerciseId]!.length > i) {
          _setSavedStatus[exerciseId]![i] = true;
        }
      }
    }
  }

  Future<void> onSessionSelected(
    WorkoutSession? session, {
    bool startFresh = false,
  }) async {
    _cancelPendingAutoSaves();

    if (session == null) {
      _selectedSession = null;
      disposeControllers();
      bumpSessionHeatmapPreview();
      _safeNotifyListeners();
      return;
    }

    _awaitingSessionPickAfterDateChange = false;
    _isLoadingData = true;
    _selectedSession = session;
    initExerciseControllers();
    await loadExerciseDetails();
    if (startFresh) {
      _clearLoggedSessionMeta();
    } else {
      await loadSavedDataForSession(session);
    }
    _isLoadingData = false;
    bumpSessionHeatmapPreview();
    _safeNotifyListeners();

    final programId = _selectedProgram?.id;
    if (programId != null && programId.isNotEmpty) {
      unawaited(
        ActiveWorkoutSessionService().saveSelection(
          programId: programId,
          sessionDay: session.day,
        ),
      );
    }
  }

  Future<void> loadSavedDataForSession(WorkoutSession session) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final selectedDateTime = _selectedDateOnly;

      final dailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        selectedDateTime,
        preferRemote: true,
      );

      if (dailyLog != null &&
          _logMatchesDate(dailyLog, selectedDateTime) &&
          dailyLog.sessions.isNotEmpty) {
        WorkoutSessionLog? matchingSessionLog;
        for (final sessionLog in dailyLog.sessions) {
          if (sessionLog.day == session.day) {
            matchingSessionLog = sessionLog;
            break;
          }
        }

        if (matchingSessionLog != null &&
            _sessionLogHasSavedSets(matchingSessionLog)) {
          _bindLoggedSession(matchingSessionLog.day, dailyLog.logDate);
          await loadSavedData(matchingSessionLog);
        } else {
          _clearLoggedSessionMeta();
          _hasTodayLog = dailyLog.sessions.any(_sessionLogHasSavedSets);
        }
      } else {
        _clearLoggedSessionMeta();
        _hasTodayLog = false;
      }
    } catch (e) {
      debugPrint('Error loading saved data for session: $e');
    }
  }

  Future<void> deleteSessionLog(String sessionDay) async {
    try {
      _cancelPendingAutoSaves();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final selectedDateTime = _selectedDateOnly;

      await _workoutLogService.deleteLogLocal(user.id, selectedDateTime);

      final dailyLog = await _workoutLogService.getDailyLogByDate(
        user.id,
        selectedDateTime,
        preferRemote: true,
      );

      if (dailyLog != null &&
          _logMatchesDate(dailyLog, selectedDateTime) &&
          dailyLog.sessions.isNotEmpty) {
        final updatedSessions = dailyLog.sessions
            .where((s) => s.day != sessionDay)
            .toList();

        if (_loggedSessionDay == sessionDay &&
            _loggedSessionDateKey == _selectedDateKey) {
          _clearLoggedSessionMeta();
        }

        if (updatedSessions.isEmpty) {
          await _workoutLogService.deleteDailyLog(dailyLog.id);
          _hasTodayLog = false;
          _clearLoggedSessionMeta();
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
          _hasTodayLog = updatedSessions.any(_sessionLogHasSavedSets);
        }
      } else {
        _hasTodayLog = false;
        _clearLoggedSessionMeta();
      }

      disposeControllers();
      bumpSessionHeatmapPreview();
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error deleting session log: $e');
    }
  }

  /// چک می‌کند که آیا داده‌هایی در فرم وارد شده یا نه
  bool hasUnsavedData() {
    if (_selectedSession == null) return false;

    // بررسی تمام controllers برای پیدا کردن داده‌های وارد شده
    for (final entry in _exerciseControllers.entries) {
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

  /// فقط فوکوس فعال را آزاد می‌کند (بدون loop روی همهٔ فیلدها).
  void unfocusAllFields() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.hasFocus) {
      primary.unfocus();
    }
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
    for (final timer in _heatmapPreviewTimers.values) {
      timer.cancel();
    }
    _heatmapPreviewTimers.clear();
    sessionHeatmapTick.dispose();
    super.dispose();
  }

  /// Safe notify listeners - checks if disposed before notifying
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}

/// نتیجه بررسی تعویض سشن در همان روز تقویم.
class SessionChangePrompt {
  const SessionChangePrompt._({
    required this.requiresConfirmation,
    this.sessionDayToDelete,
    this.hasUnsavedData = false,
    this.loggedSessionDayForDialog = '',
  });

  const SessionChangePrompt.none()
    : requiresConfirmation = false,
      sessionDayToDelete = null,
      hasUnsavedData = false,
      loggedSessionDayForDialog = '';

  factory SessionChangePrompt.needConfirm({
    required String? sessionDayToDelete,
    required bool hasUnsavedData,
    required String loggedSessionDayForDialog,
  }) {
    return SessionChangePrompt._(
      requiresConfirmation: true,
      sessionDayToDelete: sessionDayToDelete,
      hasUnsavedData: hasUnsavedData,
      loggedSessionDayForDialog: loggedSessionDayForDialog,
    );
  }

  final bool requiresConfirmation;
  final String? sessionDayToDelete;
  final bool hasUnsavedData;
  final String loggedSessionDayForDialog;
}
