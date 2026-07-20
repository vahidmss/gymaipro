import 'package:gymaipro/features/live_workout/domain/live_workout_domain_model.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/product_experience/coach_resolved_program.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:uuid/uuid.dart';

/// Builds typed runtime sessions from preview/resolved workout data.
class LiveWorkoutSessionFactory {
  const LiveWorkoutSessionFactory();

  WorkoutSession fromResolved({
    required CoachResolvedTodayWorkout resolved,
    required String userId,
    String? programId,
  }) {
    final exercises = resolved.exercises
        .map(
          (exercise) => WorkoutExerciseSession(
            id: const Uuid().v4(),
            name: ProductExperienceFormatter.displayExerciseName(
              name: exercise.name,
              primaryMuscle: exercise.primaryMuscle,
              exerciseId: exercise.exerciseId,
            ),
            primaryMuscle: exercise.primaryMuscle,
            exerciseId: exercise.exerciseId,
            defaultRestSeconds: exercise.restSeconds ?? 90,
            sets: List<WorkoutSetSession>.generate(
              exercise.sets,
              (index) => WorkoutSetSession(
                index: index + 1,
                targetReps: exercise.reps,
                targetWeightKg: exercise.weightKg ?? 0,
                restSeconds: exercise.restSeconds ?? 90,
              ),
            ),
          ),
        )
        .toList(growable: false);

    return WorkoutSession(
      id: const Uuid().v4(),
      title: resolved.title,
      focus: resolved.focus,
      estimatedMinutes: resolved.durationMinutes,
      exercises: exercises,
      startedAt: DateTime.now(),
      programId: programId,
      userId: userId,
    );
  }

  WorkoutSession fromPreview({
    required LiveWorkoutSession preview,
    required String userId,
    String? programId,
  }) {
    final exercises = preview.exercises
        .map(
          (exercise) => WorkoutExerciseSession(
            id: const Uuid().v4(),
            name: exercise.name,
            primaryMuscle: exercise.primaryMuscle,
            sets: exercise.sets
                .map(
                  (set) => WorkoutSetSession(
                    index: set.index,
                    targetReps: set.reps,
                    targetWeightKg: set.weightKg,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    return WorkoutSession(
      id: const Uuid().v4(),
      title: preview.title,
      focus: preview.focus,
      estimatedMinutes: preview.estimatedMinutes,
      exercises: exercises,
      startedAt: DateTime.now(),
      programId: programId,
      userId: userId,
    );
  }

  WorkoutSession withDisplayNames(WorkoutSession session) {
    return session.copyWith(
      exercises: session.exercises
          .asMap()
          .entries
          .map(
            (entry) => WorkoutExerciseSession(
              id: entry.value.id,
              name: ProductExperienceFormatter.displayExerciseName(
                name: entry.value.name,
                primaryMuscle: entry.value.primaryMuscle,
                exerciseId: entry.value.exerciseId,
                orderIndex: entry.key,
              ),
              primaryMuscle: entry.value.primaryMuscle,
              exerciseId: entry.value.exerciseId,
              defaultRestSeconds: entry.value.defaultRestSeconds,
              sets: entry.value.sets,
            ),
          )
          .toList(growable: false),
    );
  }
}
