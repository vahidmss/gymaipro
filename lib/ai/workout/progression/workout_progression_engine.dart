import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_complexity.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_intensity_strategy.dart';
import 'package:gymaipro/ai/workout/models/workout_progression.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/models/exercise.dart';

/// Builds sets and progression metadata for selected exercises.
class WorkoutProgressionEngine {
  const WorkoutProgressionEngine();

  List<WorkoutSet> buildSets({
    required Exercise exercise,
    required WorkoutBlueprint blueprint,
    required int exerciseOrder,
  }) {
    final compound = WorkoutScience.isCompoundExercise(
      exercise.name,
      exercise.exerciseType,
    );
    final goal = blueprint.goal;
    final isCardio = exercise.exerciseType.contains('کاردیو') ||
        exercise.exerciseType.contains('هوازی');
    final setCount = _setCountFromBlueprint(blueprint, compound);
    final strategy = blueprint.progressionStrategy;
    final progression = WorkoutProgression(
      strategy: strategy,
      description: _strategyDescription(strategy),
      targetDeltaPercent: strategy == WorkoutProgressionStrategy.increaseWeight
          ? 2.5
          : null,
      targetRepDelta: strategy == WorkoutProgressionStrategy.increaseReps
          ? 1
          : null,
    );

    return List<WorkoutSet>.generate(setCount, (index) {
      if (isCardio) {
        return WorkoutSet(
          id: 'set_${exercise.id}_${exerciseOrder}_$index',
          order: index + 1,
          type: WorkoutSetType.time,
          timeSeconds: 45 + (index * 15),
          progression: index == setCount - 1 ? progression : null,
        );
      }
      return WorkoutSet(
        id: 'set_${exercise.id}_${exerciseOrder}_$index',
        order: index + 1,
        type: WorkoutSetType.reps,
        reps: WorkoutScience.repsForGoal(
          goal,
          _intensityLabel(blueprint.intensity),
          index,
        ),
        rir: goal == TrainingGoal.strength ? 2 : 1,
        progression: index == setCount - 1 ? progression : null,
      );
    });
  }

  int _setCountFromBlueprint(WorkoutBlueprint blueprint, bool isCompound) {
    final perExercise =
        (blueprint.weeklySetsTarget / (blueprint.daysPerWeek * blueprint.exercisesPerSession))
            .round()
            .clamp(2, 6);
    if (blueprint.preferredExerciseComplexity ==
            WorkoutExerciseComplexity.basic &&
        !isCompound) {
      return perExercise.clamp(2, 3);
    }
    return perExercise;
  }

  String _strategyDescription(WorkoutProgressionStrategy strategy) {
    switch (strategy) {
      case WorkoutProgressionStrategy.increaseWeight:
        return 'Increase load when all sets hit target reps with RIR 1-2.';
      case WorkoutProgressionStrategy.increaseReps:
        return 'Add reps before increasing load for hypertrophy.';
      case WorkoutProgressionStrategy.increaseVolume:
        return 'Add a set or reduce rest to increase weekly volume.';
      case WorkoutProgressionStrategy.deload:
        return 'Reduce load 10-20% this week due to low recovery.';
      case WorkoutProgressionStrategy.maintenance:
        return 'Maintain current load and focus on form.';
    }
  }

  String _intensityLabel(WorkoutIntensityStrategy intensity) {
    return switch (intensity) {
      WorkoutIntensityStrategy.light => 'سبک',
      WorkoutIntensityStrategy.moderate => 'متوسط',
      WorkoutIntensityStrategy.hard => 'سنگین',
      WorkoutIntensityStrategy.maximum => 'سنگین',
    };
  }
}
