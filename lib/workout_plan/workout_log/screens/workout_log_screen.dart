import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/services/workout_program_service.dart';
import '../widgets/workout_log_widgets.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_program_log.dart';
import 'package:gymaipro/utils/safe_set_state.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final WorkoutProgramService _workoutProgramService = WorkoutProgramService();
  final ExerciseService _exerciseService = ExerciseService();

  Jalali _selectedDate = Jalali.now();
  List<WorkoutProgram> _programs = [];
  WorkoutProgram? _selectedProgram;
  WorkoutSession? _selectedSession;
  int? _selectedProgramIndex;

  // Exercise controllers for input fields
  final Map<String, List<Map<String, TextEditingController>>>
      _exerciseControllers = {};
  final Map<String, List<bool>> _setSavedStatus = {};

  // Exercise details cache
  final Map<int, Exercise> _exerciseDetails = {};

  // Add state for collapsed exercises
  final Map<String, bool> _collapsedExercises = {};

  bool _hasTodayLog = false;
  bool _isLoadingTodayLog = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadPrograms();
    await _checkTodayLog();
    await _loadHistory();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var exerciseControllers in _exerciseControllers.values) {
      for (var setControllers in exerciseControllers) {
        for (var controller in setControllers.values) {
          controller.dispose();
        }
      }
    }
    _exerciseControllers.clear();
    _setSavedStatus.clear();
  }

  Future<void> _loadPrograms() async {
    try {
      final programs = await _workoutProgramService.getPrograms();

      // Debug: Print programs and their notes
      for (final program in programs) {
        debugPrint('Program: ${program.name}');
        for (final session in program.sessions) {
          debugPrint('  Session: ${session.day}');
          for (final exercise in session.exercises) {
            if (exercise is NormalExercise) {
              debugPrint(
                  '    Normal Exercise ${exercise.exerciseId}: note = "${exercise.note}"');
            } else if (exercise is SupersetExercise) {
              debugPrint(
                  '    Superset Exercise ${exercise.id}: note = "${exercise.note}"');
            }
          }
        }
      }

      if (!mounted) return;
      SafeSetState.call(this, () {
        _programs = programs;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading programs: $e');
    }
  }

  Future<void> _loadHistory({Jalali? forDate}) async {
    // Load workout history for the selected date
    // This will be implemented later
  }

  Future<void> _initExerciseControllers() async {
    _disposeControllers();

    if (_selectedSession == null) return;

    for (var exercise in _selectedSession!.exercises) {
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

    for (int i = 0; i < sets; i++) {
      _exerciseControllers[exerciseId]!.add({
        'weight': TextEditingController(),
        'reps': TextEditingController(),
        'time': TextEditingController(),
      });
      _setSavedStatus[exerciseId]!.add(false);
    }
  }

  void _initSupersetExerciseControllers(SupersetExercise exercise) {
    for (var item in exercise.exercises) {
      final exerciseId = '${exercise.id}_${item.exerciseId}';
      final sets = item.sets.length;

      _exerciseControllers[exerciseId] = [];
      _setSavedStatus[exerciseId] = [];

      for (int i = 0; i < sets; i++) {
        _exerciseControllers[exerciseId]!.add({
          'weight': TextEditingController(),
          'reps': TextEditingController(),
          'time': TextEditingController(),
        });
        _setSavedStatus[exerciseId]!.add(false);
      }
    }
  }

  Future<void> _loadExerciseDetails() async {
    if (_selectedSession == null) return;

    final exerciseIds = <int>{};

    for (var exercise in _selectedSession!.exercises) {
      if (exercise is NormalExercise) {
        exerciseIds.add(exercise.exerciseId);
      } else if (exercise is SupersetExercise) {
        for (var item in exercise.exercises) {
          exerciseIds.add(item.exerciseId);
        }
      }
    }

    for (var id in exerciseIds) {
      if (!_exerciseDetails.containsKey(id)) {
        try {
          final exercise = await _exerciseService.getExerciseById(id);
          if (exercise != null) {
            _exerciseDetails[id] = exercise;
          }
        } catch (e) {
          // Silently handle error
        }
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSavedData(WorkoutSessionLog sessionLog) async {
    // Load saved data into controllers
    for (final exerciseLog in sessionLog.exercises) {
      if (exerciseLog is NormalExerciseLog) {
        final exerciseId = exerciseLog.exerciseId.toString();
        final controllers = _exerciseControllers[exerciseId];
        if (controllers != null) {
          for (int i = 0;
              i < exerciseLog.sets.length && i < controllers.length;
              i++) {
            final set = exerciseLog.sets[i];
            final setControllers = controllers[i];

            if (set.weight != null) {
              setControllers['weight']?.text = set.weight.toString();
            }
            if (set.reps != null) {
              setControllers['reps']?.text = set.reps.toString();
            }
            if (set.seconds != null) {
              setControllers['time']?.text = set.seconds.toString();
            }

            // Mark as saved
            _setSavedStatus[exerciseId]![i] = true;
          }
        }
      } else if (exerciseLog is SupersetExerciseLog) {
        debugPrint('Loading superset exercise: ${exerciseLog.id}');
        for (final itemLog in exerciseLog.exercises) {
          // For superset, we need to find the original superset exercise to get the correct itemId
          final itemId =
              _findSupersetItemId(exerciseLog.id, itemLog.exerciseId);
          debugPrint(
              'Loading superset item: exerciseId=${itemLog.exerciseId}, itemId=$itemId');
          final controllers = _exerciseControllers[itemId];
          if (controllers != null) {
            debugPrint(
                'Found controllers for itemId: $itemId, sets: ${itemLog.sets.length}');
            for (int i = 0;
                i < itemLog.sets.length && i < controllers.length;
                i++) {
              final set = itemLog.sets[i];
              final setControllers = controllers[i];

              if (set.weight != null) {
                setControllers['weight']?.text = set.weight.toString();
              }
              if (set.reps != null) {
                setControllers['reps']?.text = set.reps.toString();
              }
              if (set.seconds != null) {
                setControllers['time']?.text = set.seconds.toString();
              }

              // Mark as saved
              _setSavedStatus[itemId]![i] = true;
              debugPrint('Marked set $i as saved for itemId: $itemId');
            }
          } else {
            debugPrint('No controllers found for itemId: $itemId');
          }
        }
      }
    }
  }

  String _findSupersetItemId(String supersetId, int exerciseId) {
    // Find the original superset exercise in the selected session
    if (_selectedSession != null) {
      for (final exercise in _selectedSession!.exercises) {
        if (exercise is SupersetExercise) {
          // Find the item with matching exerciseId (ignore supersetId)
          for (final item in exercise.exercises) {
            if (item.exerciseId == exerciseId) {
              final itemId = '${exercise.id}_$exerciseId';
              debugPrint(
                  'Found superset itemId: $itemId (original: ${supersetId}_$exerciseId)');
              return itemId;
            }
          }
        }
      }
    }
    // Fallback: try to find any superset with this exerciseId
    if (_selectedSession != null) {
      for (final exercise in _selectedSession!.exercises) {
        if (exercise is SupersetExercise) {
          for (final item in exercise.exercises) {
            if (item.exerciseId == exerciseId) {
              final itemId = '${exercise.id}_$exerciseId';
              debugPrint('Found fallback superset itemId: $itemId');
              return itemId;
            }
          }
        }
      }
    }
    // Last fallback: return the original format
    final fallbackId = '${supersetId}_$exerciseId';
    debugPrint('Using last fallback superset itemId: $fallbackId');
    return fallbackId;
  }

  WorkoutSession _reconstructSessionFromLog(WorkoutSessionLog sessionLog) {
    final exercises = <WorkoutExercise>[];

    for (final exerciseLog in sessionLog.exercises) {
      if (exerciseLog is NormalExerciseLog) {
        // Reconstruct NormalExercise
        final sets = exerciseLog.sets.map((setLog) {
          return ExerciseSet(
            reps: setLog.reps,
            timeSeconds: setLog.seconds,
            weight: setLog.weight,
          );
        }).toList();

        exercises.add(NormalExercise(
          exerciseId: exerciseLog.exerciseId,
          tag: exerciseLog.tag,
          style: ExerciseStyle.values.firstWhere(
            (e) => e.toString().split('.').last == exerciseLog.style,
            orElse: () => ExerciseStyle.setsReps,
          ),
          sets: sets,
        ));
      } else if (exerciseLog is SupersetExerciseLog) {
        // Reconstruct SupersetExercise
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

        exercises.add(SupersetExercise(
          id: exerciseLog.id,
          tag: exerciseLog.tag,
          style: ExerciseStyle.values.firstWhere(
            (e) => e.toString().split('.').last == exerciseLog.style,
            orElse: () => ExerciseStyle.setsReps,
          ),
          exercises: supersetItems,
        ));
      }
    }

    return WorkoutSession(
      id: sessionLog.id,
      day: sessionLog.day,
      exercises: exercises,
    );
  }

  Future<void> _deleteTodayLog() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);

      // Delete from database
      await Supabase.instance.client
          .from('workout_daily_logs')
          .delete()
          .eq('user_id', user.id)
          .eq('log_date', todayStr);

      // Reset UI state
      setState(() {
        _hasTodayLog = false;
        _selectedProgram = null;
        _selectedSession = null;
        _selectedProgramIndex = null;
        _collapsedExercises.clear();
      });

      // Clear controllers
      _disposeControllers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لاگ امروز حذف شد'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در حذف لاگ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSessionSelected(WorkoutSession? session) {
    setState(() {
      _selectedSession = session;
    });
    _initExerciseControllers();
    _loadExerciseDetails();
  }

  Future<void> _saveSet(String exerciseId, int setIndex) async {
    try {
      debugPrint('Saving set for exerciseId: $exerciseId, setIndex: $setIndex');
      final controllers = _exerciseControllers[exerciseId]![setIndex];
      final weight = double.tryParse(controllers['weight']?.text ?? '0') ?? 0.0;
      final reps = int.tryParse(controllers['reps']?.text ?? '0') ?? 0;
      final timeSeconds = int.tryParse(controllers['time']?.text ?? '0') ?? 0;

      // Save to local state first
      setState(() {
        _setSavedStatus[exerciseId]![setIndex] = true;
      });

      // Save individual set to database
      await _saveSetToDatabase(exerciseId, setIndex, weight, reps, timeSeconds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ست ${setIndex + 1} ذخیره شد'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving set: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در ذخیره ست'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSetToDatabase(String exerciseId, int setIndex,
      double weight, int reps, int timeSeconds) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null ||
          _selectedProgram == null ||
          _selectedSession == null) {
        return;
      }

      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);

      // Check if daily log exists for today
      final existingLog = await Supabase.instance.client
          .from('workout_daily_logs')
          .select('*')
          .eq('user_id', user.id)
          .eq('log_date', todayStr)
          .maybeSingle();

      if (existingLog != null) {
        // Update existing log with new set data
        await _updateExistingLog(
            existingLog, exerciseId, setIndex, weight, reps, timeSeconds);
      } else {
        // Create new program log with this set
        await _createNewProgramLog(
            exerciseId, setIndex, weight, reps, timeSeconds);
      }
    } catch (e) {
      debugPrint('Error saving set to database: $e');
    }
  }

  Future<void> _updateExistingLog(
      Map<String, dynamic> existingLog,
      String exerciseId,
      int setIndex,
      double weight,
      int reps,
      int timeSeconds) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Rebuild the entire log with updated set data
      final dailyLog = WorkoutDailyLog.fromJson(existingLog);
      final updatedSessions = <WorkoutSessionLog>[];

      for (final session in dailyLog.sessions) {
        final updatedExercises = <WorkoutExerciseLog>[];
        for (final exercise in session.exercises) {
          if (exercise is NormalExerciseLog) {
            if (exercise.exerciseId.toString() == exerciseId) {
              final updatedSets = List<ExerciseSetLog>.from(exercise.sets);
              if (setIndex < updatedSets.length) {
                updatedSets[setIndex] = ExerciseSetLog(
                  reps: reps,
                  seconds: timeSeconds,
                  weight: weight,
                );
              } else {
                updatedSets.add(ExerciseSetLog(
                  reps: reps,
                  seconds: timeSeconds,
                  weight: weight,
                ));
              }
              updatedExercises.add(NormalExerciseLog(
                id: exercise.id,
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                tag: exercise.tag,
                style: exercise.style,
                sets: updatedSets,
              ));
            } else {
              updatedExercises.add(exercise);
            }
          } else if (exercise is SupersetExerciseLog) {
            final updatedSupersetItems = <SupersetItemLog>[];
            bool itemUpdated = false;
            for (final item in exercise.exercises) {
              // Try both old and new itemId formats
              final oldItemId = '${exercise.id}_${item.exerciseId}';
              final newItemId =
                  _findSupersetItemId(exercise.id, item.exerciseId);

              if (oldItemId == exerciseId || newItemId == exerciseId) {
                final updatedSets = List<ExerciseSetLog>.from(item.sets);
                if (setIndex < updatedSets.length) {
                  updatedSets[setIndex] = ExerciseSetLog(
                    reps: reps,
                    seconds: timeSeconds,
                    weight: weight,
                  );
                } else {
                  updatedSets.add(ExerciseSetLog(
                    reps: reps,
                    seconds: timeSeconds,
                    weight: weight,
                  ));
                }
                updatedSupersetItems.add(SupersetItemLog(
                  exerciseId: item.exerciseId,
                  exerciseName: item.exerciseName,
                  sets: updatedSets,
                ));
                itemUpdated = true;
                debugPrint(
                    'Updated superset item: ${item.exerciseId} at set $setIndex');
              } else {
                updatedSupersetItems.add(item);
              }
            }
            updatedExercises.add(SupersetExerciseLog(
              id: exercise.id,
              tag: exercise.tag,
              style: exercise.style,
              exercises: updatedSupersetItems,
            ));
          }
        }
        updatedSessions.add(WorkoutSessionLog(
          id: session.id,
          day: session.day,
          exercises: updatedExercises,
        ));
      }

      final updatedDailyLog = WorkoutDailyLog(
        id: dailyLog.id,
        userId: dailyLog.userId,
        logDate: dailyLog.logDate,
        sessions: updatedSessions,
        createdAt: dailyLog.createdAt,
        updatedAt: DateTime.now(),
      );

      await Supabase.instance.client
          .from('workout_daily_logs')
          .update(updatedDailyLog.toJson())
          .eq('id', updatedDailyLog.id);

      // Re-load data to refresh UI
      await _checkTodayLog();
    } catch (e) {
      debugPrint('Error updating existing log: $e');
    }
  }

  Future<void> _createNewProgramLog(String exerciseId, int setIndex,
      double weight, int reps, int timeSeconds) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _selectedProgram == null || _selectedSession == null) {
      return;
    }

    final today = DateTime.now();

    // Create workout session log with only the saved sets
    final sessionLog = WorkoutSessionLog(
      id: const Uuid().v4(),
      day: _selectedSession!.day,
      exercises: _buildExerciseLogs(),
    );

    // Create daily log
    final dailyLog = WorkoutDailyLog(
      userId: user.id,
      logDate: today,
      sessions: [sessionLog],
    );

    // Save to database
    await Supabase.instance.client
        .from('workout_daily_logs')
        .insert(dailyLog.toJson());

    // Update UI state
    await _checkTodayLog();
  }

  List<WorkoutExerciseLog> _buildExerciseLogs() {
    final exercises = <WorkoutExerciseLog>[];

    for (final exercise in _selectedSession!.exercises) {
      if (exercise is NormalExercise) {
        final sets = _buildSetLogs(exercise.exerciseId.toString());
        final exerciseDetails = _exerciseDetails[exercise.exerciseId];
        exercises.add(NormalExerciseLog(
          id: const Uuid().v4(),
          exerciseId: exercise.exerciseId,
          exerciseName: exerciseDetails?.name ?? 'تمرین ناشناخته',
          tag: exercise.tag,
          style: exercise.style.toString().split('.').last,
          sets: sets,
          note: exercise.note, // Pass the note from the workout program
        ));
      } else if (exercise is SupersetExercise) {
        final supersetExercises = <SupersetItemLog>[];
        for (final item in exercise.exercises) {
          final itemId = '${exercise.id}_${item.exerciseId}';
          final sets = _buildSetLogs(itemId);
          final exerciseDetails = _exerciseDetails[item.exerciseId];
          supersetExercises.add(SupersetItemLog(
            exerciseId: item.exerciseId,
            exerciseName: exerciseDetails?.name ?? 'تمرین ناشناخته',
            sets: sets,
          ));
        }
        exercises.add(SupersetExerciseLog(
          id: const Uuid().v4(),
          tag: exercise.tag,
          style: exercise.style.toString().split('.').last,
          exercises: supersetExercises,
          note: exercise.note, // Pass the note from the workout program
        ));
      }
    }

    return exercises;
  }

  List<ExerciseSetLog> _buildSetLogs(String exerciseId) {
    final controllers = _exerciseControllers[exerciseId];
    final savedStatus = _setSavedStatus[exerciseId];
    if (controllers == null || savedStatus == null) return [];

    final sets = <ExerciseSetLog>[];
    for (int i = 0; i < controllers.length; i++) {
      // Only include sets that have been saved
      if (savedStatus.length > i && savedStatus[i]) {
        final setControllers = controllers[i];
        sets.add(ExerciseSetLog(
          reps: int.tryParse(setControllers['reps']?.text ?? '0'),
          seconds: int.tryParse(setControllers['time']?.text ?? '0'),
          weight: double.tryParse(setControllers['weight']?.text ?? '0'),
        ));
      }
    }

    return sets;
  }

  Future<void> _checkTodayLog() async {
    setState(() {
      _isLoadingTodayLog = true;
    });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _hasTodayLog = false;
        _isLoadingTodayLog = false;
      });
      return;
    }
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    final response = await Supabase.instance.client
        .from('workout_daily_logs')
        .select('*')
        .eq('user_id', user.id)
        .eq('log_date', todayStr)
        .maybeSingle();

    if (response != null) {
      // Load existing log data
      final dailyLog = WorkoutDailyLog.fromJson(response);
      setState(() {
        _hasTodayLog = true;
        _isLoadingTodayLog = false;
      });

      // Load the session from the log
      if (dailyLog.sessions.isNotEmpty) {
        final sessionLog = dailyLog.sessions.first;

        // Find the original program and session
        // We need to find which program this session belongs to
        // For now, let's try to find it by matching the day
        WorkoutSession? foundSession;
        WorkoutProgram? foundProgram;

        for (final program in _programs) {
          for (final session in program.sessions) {
            if (session.day == sessionLog.day) {
              foundSession = session;
              foundProgram = program;
              break;
            }
          }
          if (foundSession != null) break;
        }

        if (foundSession != null && foundProgram != null) {
          setState(() {
            _selectedProgram = foundProgram;
            _selectedSession = foundSession;
          });

          // Initialize controllers with saved data
          await _initExerciseControllers();
          await _loadExerciseDetails();
          await _loadSavedData(sessionLog);
        } else {
          // If we can't find the original session, use reconstructed one
          final reconstructedSession = _reconstructSessionFromLog(sessionLog);
          setState(() {
            _selectedSession = reconstructedSession;
          });

          await _initExerciseControllers();
          await _loadExerciseDetails();
          await _loadSavedData(sessionLog);
        }
      }
    } else {
      setState(() {
        _hasTodayLog = false;
        _isLoadingTodayLog = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final persianDate = _getPersianFormattedDate(_selectedDate);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: WorkoutLogAppBar(
          persianDate: persianDate,
          onBackPressed: () => Navigator.pop(context),
          onDatePickerPressed: _showDatePicker,
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            // Mode selector (Program selection only)
            if (_isLoadingTodayLog) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_hasTodayLog) ...[
              // Show delete button and info when log exists
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber[700]!.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber[700]!.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.checkCircle,
                          color: Colors.green[400],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'برنامه امروز ثبت شده',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'برای حذف و ثبت مجدد، دکمه زیر را بزنید',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _deleteTodayLog,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red[400],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'حذف',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: WorkoutModeSelector(
                  selectedProgram: _selectedProgram,
                  selectedProgramIndex: _selectedProgramIndex,
                  availablePrograms: _programs,
                  onProgramSelected: (program, index) {
                    setState(() {
                      _selectedProgram = program;
                      _selectedProgramIndex = index;
                      _selectedSession =
                          null; // Reset session when program changes
                    });
                    _initExerciseControllers();
                  },
                  isDisabled: false,
                ),
              ),
              const SizedBox(height: 20),
              // Session selector (if program is selected)
              if (_selectedProgram != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WorkoutSessionSelector(
                    programs: [_selectedProgram!],
                    selectedProgram: _selectedProgram,
                    selectedSession: _selectedSession,
                    onProgramSelected:
                        (program) {}, // No need to handle program change here
                    onSessionSelected: _onSessionSelected,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
            // Exercises list
            Expanded(
              child: _buildExercisesList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    await _showPersianDatePicker();
  }

  Future<void> _showPersianDatePicker() async {
    final gregorian = _selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();

    await showDialog(
      context: context,
      builder: (context) => _PersianDatePickerDialog(
        selectedDate: dateTime,
        onDateSelected: (date) async {
          final gregorian = Gregorian.fromDateTime(date);
          final jalali = gregorian.toJalali();
          SafeSetState.call(this, () => _selectedDate = jalali);
          await _loadHistory(forDate: jalali);
          await _initExerciseControllers();
        },
      ),
    );
  }

  Widget _buildExercisesList() {
    // If no program is selected, show empty state guide
    if (_selectedProgram == null) {
      return const WorkoutEmptyStateGuide();
    }

    // If program is selected but no session is selected, show session selection prompt
    if (_selectedSession == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendar,
              size: 64,
              color: Colors.amber[300],
            ),
            const SizedBox(height: 16),
            Text(
              'جلسه مورد نظر را انتخاب کنید',
              style: TextStyle(
                color: Colors.amber[200],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'برای شروع ثبت تمرین، یکی از جلسه‌های برنامه را برگزینید',
              style: TextStyle(
                color: Colors.amber[300],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_selectedSession!.exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.dumbbell,
              size: 64,
              color: Colors.amber[300],
            ),
            const SizedBox(height: 16),
            Text(
              'هیچ تمرینی برای این جلسه تعریف نشده است',
              style: TextStyle(
                color: Colors.amber[200],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لطفاً برنامه تمرینی خود را در بخش ساخت برنامه تنظیم کنید',
              style: TextStyle(
                color: Colors.amber[300],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _selectedSession!.exercises.length,
      itemBuilder: (context, index) {
        final exercise = _selectedSession!.exercises[index];

        if (exercise is NormalExercise) {
          return _buildNormalExerciseCard(exercise);
        } else if (exercise is SupersetExercise) {
          return _buildSupersetExerciseCard(exercise);
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _getPersianFormattedDate(Jalali date) {
    final weekDay = _getPersianWeekDay(date.weekDay);
    return '$weekDay ${date.day}/${date.month}/${date.year}';
  }

  String _getPersianWeekDay(int weekday) {
    // Jalali: 1=Saturday, 2=Sunday, ..., 7=Friday
    const weekdays = [
      '',
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنج‌شنبه',
      'جمعه'
    ];
    return weekdays[weekday];
  }

  Widget _buildNormalExerciseCard(NormalExercise exercise) {
    final exerciseId = exercise.exerciseId.toString();
    final controllers = _exerciseControllers[exerciseId] ?? [];
    final savedStatus = _setSavedStatus[exerciseId] ?? [];
    final exerciseDetails = _exerciseDetails[exercise.exerciseId];
    final isCollapsed = _collapsedExercises[exerciseId] ?? false;
    final completedSets = savedStatus.where((s) => s).length;
    final totalSets = exercise.sets.length;

    // Debug: Print exercise note
    debugPrint('Exercise ${exercise.exerciseId} note: "${exercise.note}"');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber[700]!.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header - Always visible
          InkWell(
            onTap: () {
              setState(() {
                _collapsedExercises[exerciseId] = !isCollapsed;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Exercise icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber[700]!.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: exerciseDetails?.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              exerciseDetails!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                LucideIcons.dumbbell,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.dumbbell,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Exercise info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getExerciseName(exercise.exerciseId),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    Colors.amber[700]!.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                exercise.tag,
                                style: TextStyle(
                                  color: Colors.amber[300],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$totalSets ست',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            if (completedSets > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• $completedSets تکمیل شده',
                                style: TextStyle(
                                  color: Colors.green[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Display exercise note if available
                        if (exercise.note != null &&
                            exercise.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]!.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    Colors.amber[700]!.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.messageCircle,
                                  color: Colors.amber[700],
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    exercise.note!.length > 110
                                        ? '${exercise.note!.substring(0, 80)}...'
                                        : exercise.note!,
                                    style: TextStyle(
                                      color: Colors.amber[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Collapse/Expand icon
                  Icon(
                    isCollapsed
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronUp,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Sets - Collapsible
          if (!isCollapsed) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                children: List.generate(exercise.sets.length, (setIndex) {
                  return _buildCompactSetRow(
                    exerciseId,
                    setIndex,
                    exercise.style,
                    savedStatus.length > setIndex
                        ? savedStatus[setIndex]
                        : false,
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactSetRow(
    String exerciseId,
    int setIndex,
    ExerciseStyle style,
    bool isSaved,
  ) {
    final controllers = _exerciseControllers[exerciseId];
    if (controllers == null || controllers.length <= setIndex) {
      return const SizedBox.shrink();
    }

    final setControllers = controllers[setIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isSaved ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Set number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSaved
                  ? Colors.green
                  : Colors.amber[700]!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: isSaved
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text(
                      '${setIndex + 1}',
                      style: TextStyle(
                        color: isSaved ? Colors.white : Colors.amber[300],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Reps/Time input (FIRST)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style == ExerciseStyle.setsReps ? 'تکرار' : 'زمان',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: style == ExerciseStyle.setsReps
                      ? setControllers['reps']
                      : setControllers['time'],
                  enabled: !isSaved,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Weight input (SECOND)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وزن',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: setControllers['weight'],
                  enabled: !isSaved,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Save button
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSaved
                  ? Colors.green
                  : Colors.amber[700]!.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: isSaved ? null : () => _saveSet(exerciseId, setIndex),
                child: Center(
                  child: isSaved
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Icon(
                          LucideIcons.save,
                          color: Colors.amber[300],
                          size: 16,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupersetExerciseCard(SupersetExercise exercise) {
    final exerciseId = exercise.id;
    final isCollapsed = _collapsedExercises[exerciseId] ?? false;
    final totalSets = exercise.exercises.first.sets.length;
    final completedSets = exercise.exercises.map((item) {
      final itemId = '${exercise.id}_${item.exerciseId}';
      final savedStatus = _setSavedStatus[itemId] ?? [];
      final completed = savedStatus.where((s) => s).length;
      debugPrint('Superset item $itemId: $completed sets completed');
      return completed;
    }).reduce((a, b) => a + b);
    debugPrint(
        'Total completed sets for superset ${exercise.id}: $completedSets');

    // Debug: Print superset exercise note
    debugPrint('Superset exercise ${exercise.id} note: "${exercise.note}"');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber[700]!.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header - Always visible
          InkWell(
            onTap: () {
              setState(() {
                _collapsedExercises[exerciseId] = !isCollapsed;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Superset icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber[700]!.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.zap,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Superset info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    Colors.amber[700]!.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'سوپرست',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              exercise.tag,
                              style: TextStyle(
                                color: Colors.amber[300],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${exercise.exercises.length} تمرین • $totalSets ست',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            if (completedSets > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• $completedSets تکمیل شده',
                                style: TextStyle(
                                  color: Colors.green[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Display superset exercise note if available
                        if (exercise.note != null &&
                            exercise.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]!.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    Colors.amber[700]!.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.messageCircle,
                                  color: Colors.amber[700],
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    exercise.note!.length > 80
                                        ? '${exercise.note!.substring(0, 80)}...'
                                        : exercise.note!,
                                    style: TextStyle(
                                      color: Colors.amber[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Collapse/Expand icon
                  Icon(
                    isCollapsed
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronUp,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Exercises - Collapsible
          if (!isCollapsed) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                children: exercise.exercises.map((item) {
                  final itemId = '${exercise.id}_${item.exerciseId}';
                  final controllers = _exerciseControllers[itemId] ?? [];
                  final savedStatus = _setSavedStatus[itemId] ?? [];
                  final exerciseDetails = _exerciseDetails[item.exerciseId];

                  return Column(
                    children: [
                      // Exercise header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    Colors.amber[700]!.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: exerciseDetails?.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        exerciseDetails!.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          LucideIcons.dumbbell,
                                          color: Colors.amber[700],
                                          size: 16,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      LucideIcons.dumbbell,
                                      color: Colors.amber[700],
                                      size: 16,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getExerciseName(item.exerciseId),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sets for this exercise
                      ...List.generate(item.sets.length, (setIndex) {
                        return _buildCompactSetRow(
                          itemId,
                          setIndex,
                          item.style,
                          savedStatus.length > setIndex
                              ? savedStatus[setIndex]
                              : false,
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSetRow(
      String exerciseId, int setIndex, ExerciseStyle style, bool isSaved) {
    final controllers = _exerciseControllers[exerciseId];
    if (controllers == null || controllers.length <= setIndex) {
      return const SizedBox.shrink();
    }

    final setControllers = controllers[setIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSaved
              ? Colors.green
              : Colors.amber[700]!.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Set number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSaved ? Colors.green : Colors.amber[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isSaved
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${setIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Weight input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وزن (کیلو)',
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: setControllers['weight'],
                  enabled: !isSaved,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Reps or Time input based on style
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style == ExerciseStyle.setsReps ? 'تکرار' : 'زمان (ثانیه)',
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: style == ExerciseStyle.setsReps
                      ? setControllers['reps']
                      : setControllers['time'],
                  enabled: !isSaved,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Save button
          if (!isSaved)
            GestureDetector(
              onTap: () => _saveSet(exerciseId, setIndex),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[600]!, Colors.amber[700]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.save,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getExerciseHint(NormalExercise exercise) {
    if (exercise.style == ExerciseStyle.setsReps) {
      final firstSet = exercise.sets.first;
      return '${exercise.sets.length} ست × ${firstSet.reps ?? 0} تکرار';
    } else {
      final firstSet = exercise.sets.first;
      return '${exercise.sets.length} ست × ${firstSet.timeSeconds ?? 0} ثانیه';
    }
  }

  String _getSupersetItemHint(SupersetItem item) {
    if (item.style == ExerciseStyle.setsReps) {
      final firstSet = item.sets.first;
      return '${item.sets.length} ست × ${firstSet.reps ?? 0} تکرار';
    } else {
      final firstSet = item.sets.first;
      return '${item.sets.length} ست × ${firstSet.timeSeconds ?? 0} ثانیه';
    }
  }

  String _getExerciseName(int exerciseId) {
    final exerciseDetails = _exerciseDetails[exerciseId];
    if (exerciseDetails != null) {
      return exerciseDetails.name;
    }
    // Fallback: return a simple name based on ID
    return 'تمرین شماره $exerciseId';
  }
}

// --- Persian Date Picker Dialog (copied from food_log_screen.dart) ---
class _PersianDatePickerDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _PersianDatePickerDialog({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_PersianDatePickerDialog> createState() =>
      _PersianDatePickerDialogState();
}

class _PersianDatePickerDialogState extends State<_PersianDatePickerDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  Map<DateTime, bool> _workoutLogDates = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDate;
    _selectedDate = widget.selectedDate;
    _loadWorkoutLogDates();
  }

  Future<void> _loadWorkoutLogDates() async {
    // Load dates that have workout logs for the current user in the visible month
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    final startJalali = Jalali(jalali.year, jalali.month, 1);
    final endJalali = Jalali(
        jalali.year, jalali.month, _getDaysInMonth(jalali.year, jalali.month));
    final startDate = startJalali.toGregorian().toDateTime();
    final endDate = endJalali.toGregorian().toDateTime();
    try {
      final response = await Supabase.instance.client
          .from('workout_daily_logs')
          .select('log_date')
          .eq('user_id', user.id)
          .gte('log_date', startDate.toIso8601String().substring(0, 10))
          .lte('log_date', endDate.toIso8601String().substring(0, 10));
      final logDates = <DateTime, bool>{};
      for (final row in response) {
        final logDate = DateTime.parse(row['log_date']);
        logDates[logDate] = true;
      }
      setState(() {
        _workoutLogDates = logDates;
      });
    } catch (e) {
      setState(() {
        _workoutLogDates = {};
      });
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber[700]!.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCalendarHeader(),
            const SizedBox(height: 16),
            _buildCalendarGrid(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    child:
                        Text('لغو', style: TextStyle(color: Colors.amber[300])),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.amber[600]!,
                          Colors.amber[700]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber[700]!.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDateSelected(_selectedDate);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'انتخاب',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.amber[700]!.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: Colors.amber[100]),
            onPressed: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
              _loadWorkoutLogDates();
            },
          ),
        ),
        Column(
          children: [
            Text(
              _getPersianMonthName(_getPersianMonthNumber()),
              style: TextStyle(
                color: Colors.amber[100],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _convertToPersianNumbers(_getPersianYear().toString()),
              style: TextStyle(
                color: Colors.amber[300],
                fontSize: 14,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.amber[700]!.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(LucideIcons.chevronRight, color: Colors.amber[100]),
            onPressed: () {
              setState(() {
                _currentMonth =
                    DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
              _loadWorkoutLogDates();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    int daysInMonth = _getDaysInMonth(jalali.year, jalali.month);
    final firstDayOfPersianMonth = Jalali(jalali.year, jalali.month, 1);
    final firstWeekdayPersian = firstDayOfPersianMonth.weekDay;
    final emptyBoxes = firstWeekdayPersian - 1;
    final totalCells = emptyBoxes + daysInMonth;
    final weeks = (totalCells / 7).ceil();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _buildWeekdayHeaders(),
          ...List.generate(
            weeks,
            (weekIndex) => _buildWeekRow(
                weekIndex, emptyBoxes, daysInMonth, jalali.year, jalali.month),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Colors.amber[100],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWeekRow(
      int weekIndex, int emptyBoxes, int daysInMonth, int year, int month) {
    final startCell = weekIndex * 7;
    return Row(
      children: List.generate(7, (dayIndex) {
        final cellIndex = startCell + dayIndex;
        final dayNumber = cellIndex - emptyBoxes + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return Expanded(child: Container());
        }
        final persianDate = Jalali(year, month, dayNumber);
        final gregorianDate = persianDate.toGregorian().toDateTime();
        final hasWorkoutLog = _workoutLogDates.containsKey(DateTime(
            gregorianDate.year, gregorianDate.month, gregorianDate.day));
        final isSelected = _selectedDate.year == gregorianDate.year &&
            _selectedDate.month == gregorianDate.month &&
            _selectedDate.day == gregorianDate.day;
        final now = DateTime.now();
        final isToday = now.year == gregorianDate.year &&
            now.month == gregorianDate.month &&
            now.day == gregorianDate.day;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = gregorianDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.amber[600]!
                    : hasWorkoutLog
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday ? Colors.amber[600]! : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      _convertToPersianNumbers(dayNumber.toString()),
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1A1A1A)
                            : hasWorkoutLog
                                ? Colors.green
                                : Colors.amber[100],
                        fontWeight: isSelected || hasWorkoutLog || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (hasWorkoutLog)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getPersianMonthName(int month) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];
    return months[month];
  }

  String _convertToPersianNumbers(String text) {
    const persianNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = text;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(englishNumbers[i], persianNumbers[i]);
    }
    return result;
  }

  int _getPersianMonthNumber() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    return jalali.month;
  }

  int _getPersianYear() {
    final gregorian = Gregorian.fromDateTime(_currentMonth);
    final jalali = gregorian.toJalali();
    return jalali.year;
  }
}
