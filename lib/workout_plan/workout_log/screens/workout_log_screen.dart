import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/workout_plan/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_plan/workout_log/widgets/workout_log_widgets.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/services/workout_program_service.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final WorkoutProgramService _workoutProgramService = WorkoutProgramService();
  final ActiveProgramService _activeProgramService = ActiveProgramService();
  final ExerciseService _exerciseService = ExerciseService();

  Jalali _selectedDate = Jalali.now();
  WorkoutProgram? _selectedProgram;
  WorkoutSession? _selectedSession;

  // Exercise controllers for input fields
  final Map<String, List<Map<String, TextEditingController>>>
  _exerciseControllers = {};
  final Map<String, List<bool>> _setSavedStatus = {};

  // Exercise details cache
  final Map<int, Exercise> _exerciseDetails = {};

  // Add state for collapsed exercises - default to collapsed (true)
  final Map<String, bool> _collapsedExercises = {};

  bool _hasTodayLog = false;
  bool _isLoadingTodayLog = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeData());
  }

  Future<void> _initializeData() async {
    await _loadActiveProgram();
    await _checkTodayLog();
    await _loadHistory();
  }

  Future<void> _loadActiveProgram() async {
    try {
      final state = await _activeProgramService.getActiveProgramState();
      final String? activeProgramId = state?['active_program_id'] as String?;
      if (activeProgramId == null) {
        if (!mounted) return;
        setState(() {
          _selectedProgram = null;
          _selectedSession = null;
        });
        return;
      }

      final program = await _workoutProgramService.getProgramById(
        activeProgramId,
      );
      if (!mounted) return;
      setState(() {
        _selectedProgram = program;
        _selectedSession = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedProgram = null;
        _selectedSession = null;
      });
    }
  }

  void _navigateToExerciseTutorial(int exerciseId) {
    final exercise = _exerciseDetails[exerciseId];
    if (exercise != null) {
      unawaited(
        Navigator.pushNamed(
          context,
          '/exercise-detail',
          arguments: {'exercise': exercise},
        ),
      );
    } else {
      unawaited(_loadAndNavigateToExercise(exerciseId));
    }
  }

  void _toggleExerciseCollapse(String exerciseId) {
    setState(() {
      _collapsedExercises[exerciseId] =
          !(_collapsedExercises[exerciseId] ?? true);
    });
  }

  Future<void> _loadAndNavigateToExercise(int exerciseId) async {
    try {
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        ),
      );

      final exercises = await _exerciseService.getExercises();
      final exercise = exercises.firstWhere(
        (e) => e.id == exerciseId,
        orElse: () => throw Exception('تمرین پیدا نشد'),
      );

      _exerciseDetails[exerciseId] = exercise;

      if (mounted) Navigator.pop(context);

      if (mounted) {
        unawaited(
          Navigator.pushNamed(
            context,
            '/exercise-detail',
            arguments: {'exercise': exercise},
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری اطلاعات تمرین: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final exerciseControllers in _exerciseControllers.values) {
      for (final setControllers in exerciseControllers) {
        for (final controller in setControllers.values) {
          controller.dispose();
        }
      }
    }
    _exerciseControllers.clear();
    _setSavedStatus.clear();
  }

  Future<void> _loadHistory({Jalali? forDate}) async {
    // Load workout history for the selected date
    // This will be implemented later
  }

  Future<void> _initExerciseControllers() async {
    _disposeControllers();

    if (_selectedSession == null) return;

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
    for (final item in exercise.exercises) {
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

    for (final exercise in _selectedSession!.exercises) {
      if (exercise is NormalExercise) {
        exerciseIds.add(exercise.exerciseId);
      } else if (exercise is SupersetExercise) {
        for (final item in exercise.exercises) {
          exerciseIds.add(item.exerciseId);
        }
      }
    }

    for (final id in exerciseIds) {
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
          for (
            int i = 0;
            i < exerciseLog.sets.length && i < controllers.length;
            i++
          ) {
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
          final itemId = _findSupersetItemId(
            exerciseLog.id,
            itemLog.exerciseId,
          );
          debugPrint(
            'Loading superset item: exerciseId=${itemLog.exerciseId}, itemId=$itemId',
          );
          final controllers = _exerciseControllers[itemId];
          if (controllers != null) {
            debugPrint(
              'Found controllers for itemId: $itemId, sets: ${itemLog.sets.length}',
            );
            for (
              int i = 0;
              i < itemLog.sets.length && i < controllers.length;
              i++
            ) {
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
                'Found superset itemId: $itemId (original: ${supersetId}_$exerciseId)',
              );
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

        exercises.add(
          NormalExercise(
            exerciseId: exerciseLog.exerciseId,
            tag: exerciseLog.tag,
            style: ExerciseStyle.values.firstWhere(
              (e) => e.toString().split('.').last == exerciseLog.style,
              orElse: () => ExerciseStyle.setsReps,
            ),
            sets: sets,
          ),
        );
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

        exercises.add(
          SupersetExercise(
            id: exerciseLog.id,
            tag: exerciseLog.tag,
            style: ExerciseStyle.values.firstWhere(
              (e) => e.toString().split('.').last == exerciseLog.style,
              orElse: () => ExerciseStyle.setsReps,
            ),
            exercises: supersetItems,
          ),
        );
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
    unawaited(_initExerciseControllers());
    unawaited(_loadExerciseDetails());
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

      final today = DateTime.now();
      final todayStr = today.toIso8601String().substring(0, 10);

      // Check if daily log exists for today
      final existingLog = await Supabase.instance.client
          .from('workout_daily_logs')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', todayStr)
          .maybeSingle();

      if (existingLog != null) {
        // Update existing log with new set data
        await _updateExistingLog(
          existingLog,
          exerciseId,
          setIndex,
          weight,
          reps,
          timeSeconds,
        );
      } else {
        // Create new program log with this set
        await _createNewProgramLog(
          exerciseId,
          setIndex,
          weight,
          reps,
          timeSeconds,
        );
      }

      // Mark program as used (set is_used=true). We'll set first_used_at below if needed.
      try {
        await Supabase.instance.client
            .from('workout_programs')
            .update({'is_used': true})
            .eq('id', _selectedProgram!.id)
            .eq('is_used', false);
        // If first_used_at is null, set it explicitly (cannot be done conditionally easily here)
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
    Map<String, dynamic> existingLog,
    String exerciseId,
    int setIndex,
    double weight,
    int reps,
    int timeSeconds,
  ) async {
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
                updatedSets.add(
                  ExerciseSetLog(
                    reps: reps,
                    seconds: timeSeconds,
                    weight: weight,
                  ),
                );
              }
              updatedExercises.add(
                NormalExerciseLog(
                  id: exercise.id,
                  exerciseId: exercise.exerciseId,
                  exerciseName: exercise.exerciseName,
                  tag: exercise.tag,
                  style: exercise.style,
                  sets: updatedSets,
                ),
              );
            } else {
              updatedExercises.add(exercise);
            }
          } else if (exercise is SupersetExerciseLog) {
            final updatedSupersetItems = <SupersetItemLog>[];
            // removed itemUpdated as it was unused
            for (final item in exercise.exercises) {
              // Try both old and new itemId formats
              final oldItemId = '${exercise.id}_${item.exerciseId}';
              final newItemId = _findSupersetItemId(
                exercise.id,
                item.exerciseId,
              );

              if (oldItemId == exerciseId || newItemId == exerciseId) {
                final updatedSets = List<ExerciseSetLog>.from(item.sets);
                if (setIndex < updatedSets.length) {
                  updatedSets[setIndex] = ExerciseSetLog(
                    reps: reps,
                    seconds: timeSeconds,
                    weight: weight,
                  );
                } else {
                  updatedSets.add(
                    ExerciseSetLog(
                      reps: reps,
                      seconds: timeSeconds,
                      weight: weight,
                    ),
                  );
                }
                updatedSupersetItems.add(
                  SupersetItemLog(
                    exerciseId: item.exerciseId,
                    exerciseName: item.exerciseName,
                    sets: updatedSets,
                  ),
                );
                debugPrint(
                  'Updated superset item: ${item.exerciseId} at set $setIndex',
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
        exercises.add(
          NormalExerciseLog(
            id: const Uuid().v4(),
            exerciseId: exercise.exerciseId,
            exerciseName: exerciseDetails?.name ?? 'تمرین ناشناخته',
            tag: exercise.tag,
            style: exercise.style.toString().split('.').last,
            sets: sets,
            note: exercise.note, // Pass the note from the workout program
          ),
        );
      } else if (exercise is SupersetExercise) {
        final supersetExercises = <SupersetItemLog>[];
        for (final item in exercise.exercises) {
          final itemId = '${exercise.id}_${item.exerciseId}';
          final sets = _buildSetLogs(itemId);
          final exerciseDetails = _exerciseDetails[item.exerciseId];
          supersetExercises.add(
            SupersetItemLog(
              exerciseId: item.exerciseId,
              exerciseName: exerciseDetails?.name ?? 'تمرین ناشناخته',
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
            note: exercise.note, // Pass the note from the workout program
          ),
        );
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
        sets.add(
          ExerciseSetLog(
            reps: int.tryParse(setControllers['reps']?.text ?? '0'),
            seconds: int.tryParse(setControllers['time']?.text ?? '0'),
            weight: double.tryParse(setControllers['weight']?.text ?? '0'),
          ),
        );
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
    Map<String, dynamic>? response;
    try {
      response = await Supabase.instance.client
          .from('workout_daily_logs')
          .select()
          .eq('user_id', user.id)
          .eq('log_date', todayStr)
          .maybeSingle();
    } catch (e) {
      // Handle offline or network errors gracefully
      if (mounted) {
        setState(() {
          _hasTodayLog = false;
          _isLoadingTodayLog = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'عدم دسترسی به اینترنت. داده‌های امروز قابل بارگذاری نیست',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

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

        // Try to find session inside the active program by matching day
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
          setState(() {
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
    final bool hasExercises =
        _selectedProgram != null &&
        _selectedSession != null &&
        _selectedSession!.exercises.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E0E),
        appBar: WorkoutLogAppBar(
          persianDate: persianDate,
          onBackPressed: () => NavigationService.safePop(context),
          onDatePickerPressed: _showDatePicker,
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 8.h),
              if (_isLoadingTodayLog) ...[
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ] else if (_hasTodayLog) ...[
                LogStatusCard(onDeleteLog: _deleteTodayLog),
              ] else ...[
                if (_selectedProgram == null) ...[
                  EmptyStateWidgets.noActiveProgram(context),
                ] else ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: WorkoutSessionSelector(
                      programs: [_selectedProgram!],
                      selectedProgram: _selectedProgram,
                      selectedSession: _selectedSession,
                      onProgramSelected: (program) {},
                      onSessionSelected: _onSessionSelected,
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ],
              // Exercises list
              if (hasExercises)
                Expanded(child: _buildExercisesList())
              else
                _buildExercisesList(),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final gregorian = _selectedDate.toGregorian();
    final dateTime = gregorian.toDateTime();

    await showDialog<void>(
      context: context,
      builder: (context) => PersianDatePickerDialog(
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
    // If no program is selected, body already renders the empty state
    if (_selectedProgram == null) {
      return const SizedBox.shrink();
    }

    if (_selectedSession == null) {
      return EmptyStateWidgets.noSessionSelected();
    }

    if (_selectedSession!.exercises.isEmpty) {
      return EmptyStateWidgets.noExercisesInSession();
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      children: [
        if (_selectedSession!.notes != null &&
            _selectedSession!.notes!.isNotEmpty)
          ExerciseListHeader(sessionNotes: _selectedSession!.notes!),
        ...List.generate(_selectedSession!.exercises.length, (index) {
          final exercise = _selectedSession!.exercises[index];
          return ExerciseCard(
            exercise: exercise,
            exerciseDetails: _exerciseDetails,
            exerciseControllers: _exerciseControllers,
            setSavedStatus: _setSavedStatus,
            collapsedExercises: _collapsedExercises,
            onToggleCollapse: _toggleExerciseCollapse,
            onNavigateToTutorial: _navigateToExerciseTutorial,
            onSaveSet: _saveSet,
          );
        }),
      ],
    );
  }

  String _getPersianFormattedDate(Jalali date) {
    final weekDay = _getPersianWeekDay(date.weekDay);
    final monthName = _getPersianMonthName(date.month);
    return '$weekDay ${date.day} $monthName';
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
      'جمعه',
    ];
    return weekdays[weekday];
  }

  String _getPersianMonthName(int month) {
    const monthNames = [
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
      'اسفند',
    ];
    return monthNames[month];
  }

  // removed

  // removed
}
