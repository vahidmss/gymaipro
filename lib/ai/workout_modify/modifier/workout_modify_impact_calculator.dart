import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_impact.dart';

/// Computes before/after impact deltas for a modification run.
class WorkoutModifyImpactCalculator {
  const WorkoutModifyImpactCalculator();

  WorkoutModificationImpact calculate({
    required WorkoutProgram before,
    required WorkoutProgram after,
    required CoachContext context,
    required Map<int, ExerciseProfile> profileById,
  }) {
    final beforeMetrics = _metrics(before, profileById);
    final afterMetrics = _metrics(after, profileById);

    return WorkoutModificationImpact(
      beforeVolume: beforeMetrics.volume,
      afterVolume: afterMetrics.volume,
      volumeDelta: afterMetrics.volume - beforeMetrics.volume,
      beforeFatigue: beforeMetrics.fatigue,
      afterFatigue: afterMetrics.fatigue,
      fatigueDelta: afterMetrics.fatigue - beforeMetrics.fatigue,
      beforeRecovery: beforeMetrics.recovery,
      afterRecovery: afterMetrics.recovery,
      recoveryDelta: afterMetrics.recovery - beforeMetrics.recovery,
      beforeJointStress: beforeMetrics.jointStress,
      afterJointStress: afterMetrics.jointStress,
      jointStressDelta: afterMetrics.jointStress - beforeMetrics.jointStress,
      beforeGoalAlignment: beforeMetrics.goalAlignment,
      afterGoalAlignment: afterMetrics.goalAlignment,
      goalAlignmentDelta:
          afterMetrics.goalAlignment - beforeMetrics.goalAlignment,
    );
  }

  _ProgramMetrics _metrics(
    WorkoutProgram program,
    Map<int, ExerciseProfile> profileById,
  ) {
    var totalSets = 0;
    var fatigue = 0.0;
    var recovery = 0.0;
    var jointStress = 0.0;
    var totalReps = 0;
    var repSamples = 0;

    for (final day in program.allDays) {
      for (final exercise in day.exercises) {
        final setCount = exercise.sets.length;
        totalSets += setCount;
        final profile = profileById[exercise.catalogExerciseId];
        if (profile != null) {
          fatigue += profile.fatigueScore * setCount;
          recovery += profile.recoveryCost * setCount;
          jointStress +=
              (profile.kneeLoad + profile.shoulderLoad + profile.spineLoad) *
              setCount;
        }
        for (final set in exercise.sets) {
          if (set.type == WorkoutSetType.reps && set.reps != null) {
            totalReps += set.reps!;
            repSamples++;
          }
        }
      }
    }

    final avgReps = repSamples == 0 ? 0.0 : totalReps / repSamples;
    final idealReps = switch (program.goal) {
      TrainingGoal.strength => 5,
      TrainingGoal.hypertrophy => 10,
      TrainingGoal.fatLoss => 12,
      TrainingGoal.endurance => 15,
      TrainingGoal.general => 10,
    };
    final goalAlignment = avgReps == 0
        ? 50.0
        : (100 - (avgReps - idealReps).abs() * 4).clamp(0, 100).toDouble();

    return _ProgramMetrics(
      volume: totalSets.toDouble(),
      fatigue: fatigue,
      recovery: recovery,
      jointStress: jointStress,
      goalAlignment: goalAlignment,
    );
  }
}

class _ProgramMetrics {
  const _ProgramMetrics({
    required this.volume,
    required this.fatigue,
    required this.recovery,
    required this.jointStress,
    required this.goalAlignment,
  });

  final double volume;
  final double fatigue;
  final double recovery;
  final double jointStress;
  final double goalAlignment;
}
