import 'package:flutter/widgets.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart'
    as program_models;

/// Converts dashboard workout-log state into a live [WorkoutSession]
/// so debrief / analysis can reuse the same engines.
abstract final class WorkoutLogSessionBridge {
  static WorkoutSession buildSession({
    required program_models.WorkoutSession planned,
    required Map<String, List<bool>> setSavedStatus,
    required Map<String, List<Map<String, TextEditingController>>> controllers,
    required Map<int, Exercise> exerciseDetails,
    required String? programId,
    required String? userId,
    DateTime? startedAt,
  }) {
    final exercises = <WorkoutExerciseSession>[];

    for (final exercise in planned.exercises) {
      if (exercise is program_models.NormalExercise) {
        exercises.add(
          _normalExercise(
            exercise: exercise,
            setSavedStatus: setSavedStatus,
            controllers: controllers,
            exerciseDetails: exerciseDetails,
          ),
        );
      } else if (exercise is program_models.SupersetExercise) {
        for (final item in exercise.exercises) {
          exercises.add(
            _supersetItem(
              parent: exercise,
              item: item,
              setSavedStatus: setSavedStatus,
              controllers: controllers,
              exerciseDetails: exerciseDetails,
            ),
          );
        }
      }
    }

    return WorkoutSession(
      id: 'log_${programId ?? 'program'}_${planned.day}',
      title: planned.day,
      focus: planned.day,
      estimatedMinutes: 0,
      exercises: exercises,
      // Prefer measured work time in assembler; avoid inventing a 60m session.
      startedAt: DateTime.now(),
      programId: programId,
      userId: userId,
    );
  }

  static Map<String, WorkoutExerciseCoachFeedback> buildFeedbackMap({
    required WorkoutSession session,
    Map<int, List<PreviousExerciseSet>> previousByExerciseId =
        const <int, List<PreviousExerciseSet>>{},
  }) {
    final out = <String, WorkoutExerciseCoachFeedback>{};
    for (final exercise in session.exercises) {
      final logged = <LoggedSetPerformance>[];
      for (final set in exercise.sets) {
        if (set.status != WorkoutSetSessionStatus.completed &&
            set.status != WorkoutSetSessionStatus.failed) {
          continue;
        }
        final reps = set.actualReps ?? 0;
        final weight = set.actualWeightKg ?? 0;
        final seconds = set.durationSeconds ?? 0;
        // Never invent a hit from the prescription when the user left fields empty.
        if (reps <= 0 && weight <= 0 && seconds <= 0) continue;
        logged.add(
          LoggedSetPerformance(
            targetReps: set.targetReps,
            targetWeightKg: set.targetWeightKg,
            actualReps: reps,
            actualWeightKg: weight,
            actualSeconds: seconds > 0 ? seconds : null,
            rpe: set.rpe,
          ),
        );
      }
      if (logged.isEmpty) continue;
      final previous = exercise.exerciseId == null
          ? null
          : previousByExerciseId[exercise.exerciseId!];
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: logged,
        isTimedStyle: logged.every(
          (s) => (s.actualSeconds ?? 0) > 0 && s.actualReps <= 0,
        ),
        previousSets: previous,
        prescribedSetCount: exercise.sets.length,
      );
      if (feedback != null) {
        out[exercise.id] = feedback;
      }
    }
    return out;
  }

  static WorkoutExerciseSession _normalExercise({
    required program_models.NormalExercise exercise,
    required Map<String, List<bool>> setSavedStatus,
    required Map<String, List<Map<String, TextEditingController>>> controllers,
    required Map<int, Exercise> exerciseDetails,
  }) {
    final key = exercise.exerciseId.toString();
    final catalog = exerciseDetails[exercise.exerciseId];
    final saved = setSavedStatus[key] ?? const <bool>[];
    final ctrls =
        controllers[key] ?? const <Map<String, TextEditingController>>[];
    final sets = <WorkoutSetSession>[];

    for (var i = 0; i < exercise.sets.length; i++) {
      final planned = exercise.sets[i];
      final isSaved = i < saved.length && saved[i];
      final map = i < ctrls.length ? ctrls[i] : null;
      final reps = _readInt(map?['reps']);
      final weight = _readDouble(map?['weight']);
      final seconds = _readInt(map?['time']);
      final rpe = _readInt(map?['rpe']);
      sets.add(
        WorkoutSetSession(
          index: i + 1,
          targetReps: planned.reps ?? 0,
          targetWeightKg: planned.weight ?? 0,
          actualReps: isSaved ? reps : null,
          actualWeightKg: isSaved ? weight : null,
          durationSeconds: isSaved && (seconds ?? 0) > 0 ? seconds : null,
          rpe: isSaved ? rpe : null,
          status: isSaved
              ? WorkoutSetSessionStatus.completed
              : WorkoutSetSessionStatus.pending,
        ),
      );
    }

    return WorkoutExerciseSession(
      id: key,
      name: catalog?.name ?? exercise.tag,
      primaryMuscle: catalog?.mainMuscle ?? '',
      exerciseId: exercise.exerciseId,
      sets: sets,
      defaultRestSeconds: exercise.restSeconds ?? 90,
    );
  }

  static WorkoutExerciseSession _supersetItem({
    required program_models.SupersetExercise parent,
    required program_models.SupersetItem item,
    required Map<String, List<bool>> setSavedStatus,
    required Map<String, List<Map<String, TextEditingController>>> controllers,
    required Map<int, Exercise> exerciseDetails,
  }) {
    final key = '${parent.id}_${item.exerciseId}';
    final catalog = exerciseDetails[item.exerciseId];
    final saved = setSavedStatus[key] ?? const <bool>[];
    final ctrls =
        controllers[key] ?? const <Map<String, TextEditingController>>[];
    final sets = <WorkoutSetSession>[];

    for (var i = 0; i < item.sets.length; i++) {
      final planned = item.sets[i];
      final isSaved = i < saved.length && saved[i];
      final map = i < ctrls.length ? ctrls[i] : null;
      final reps = _readInt(map?['reps']);
      final weight = _readDouble(map?['weight']);
      final seconds = _readInt(map?['time']);
      final rpe = _readInt(map?['rpe']);
      sets.add(
        WorkoutSetSession(
          index: i + 1,
          targetReps: planned.reps ?? 0,
          targetWeightKg: planned.weight ?? 0,
          actualReps: isSaved ? reps : null,
          actualWeightKg: isSaved ? weight : null,
          durationSeconds: isSaved && (seconds ?? 0) > 0 ? seconds : null,
          rpe: isSaved ? rpe : null,
          status: isSaved
              ? WorkoutSetSessionStatus.completed
              : WorkoutSetSessionStatus.pending,
        ),
      );
    }

    return WorkoutExerciseSession(
      id: key,
      name: catalog?.name ?? 'حرکت ${item.exerciseId}',
      primaryMuscle: catalog?.mainMuscle ?? '',
      exerciseId: item.exerciseId,
      sets: sets,
    );
  }

  static int? _readInt(TextEditingController? controller) {
    if (controller == null) return null;
    return int.tryParse(controller.text.trim());
  }

  static double? _readDouble(TextEditingController? controller) {
    if (controller == null) return null;
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }
}
