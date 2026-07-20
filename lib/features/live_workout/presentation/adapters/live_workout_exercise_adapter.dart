import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

/// Maps live-workout session exercises to workout-log [NormalExercise] cards.
abstract final class LiveWorkoutExerciseAdapter {
  static NormalExercise toNormalExercise(
    WorkoutExerciseSession exercise, {
    required int index,
  }) {
    return NormalExercise(
      id: exercise.id,
      exerciseId: exercise.exerciseId ?? (index + 1),
      tag: exercise.name,
      style: ExerciseStyle.setsReps,
      sets: exercise.sets
          .map(
            (set) => ExerciseSet(
              reps: set.targetReps,
              weight: set.targetWeightKg > 0 ? set.targetWeightKg : null,
            ),
          )
          .toList(growable: false),
    );
  }

  static String controllerKey(NormalExercise exercise) =>
      exercise.exerciseId.toString();
}
