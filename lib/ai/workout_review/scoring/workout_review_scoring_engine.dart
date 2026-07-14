import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_review/analysis/workout_program_metrics.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_score.dart';

/// Computes multi-dimensional review scores from program metrics.
class WorkoutReviewScoringEngine {
  const WorkoutReviewScoringEngine();

  WorkoutReviewScore score({
    required WorkoutProgram program,
    required WorkoutProgramMetrics metrics,
  }) {
    final volume = _volumeScore(program, metrics);
    final recovery = _recoveryScore(metrics);
    final balance = _balanceScore(metrics);
    final goalAlignment = _goalAlignmentScore(program, metrics);
    final safety = _safetyScore(metrics);
    final progression = _progressionScore(metrics);
    final equipment = _equipmentScore(metrics);
    final experience = _experienceScore(metrics);
    final distribution = _weeklyDistributionScore(metrics);
    final coverage = _muscleCoverageScore(metrics);

    final overall = _average(<double>[
      volume,
      recovery,
      balance,
      goalAlignment,
      safety,
      progression,
      equipment,
      experience,
      distribution,
      coverage,
    ]);

    return WorkoutReviewScore(
      volumeScore: volume,
      recoveryScore: recovery,
      balanceScore: balance,
      goalAlignmentScore: goalAlignment,
      safetyScore: safety,
      progressionScore: progression,
      equipmentCompatibility: equipment,
      experienceMatch: experience,
      weeklyDistribution: distribution,
      muscleCoverage: coverage,
      overall: overall,
    );
  }

  double _volumeScore(WorkoutProgram program, WorkoutProgramMetrics metrics) {
    if (metrics.exerciseCount == 0) return 0;
    final targetPerMuscle = WorkoutScience.weeklySetsForGoal(
      program.goal,
      program.experienceLevel,
    );
    const tracked = <MuscleBucket>[
      MuscleBucket.chest,
      MuscleBucket.back,
      MuscleBucket.shoulders,
      MuscleBucket.quads,
      MuscleBucket.hamstrings,
    ];
    var deviation = 0.0;
    for (final bucket in tracked) {
      final actual = metrics.setsFor(bucket);
      final delta = (actual - targetPerMuscle).abs();
      deviation += delta / targetPerMuscle;
    }
    final avgDeviation = deviation / tracked.length;
    return (100 - avgDeviation * 35).clamp(0, 100);
  }

  double _recoveryScore(WorkoutProgramMetrics metrics) {
    if (metrics.exerciseCount == 0) return 0;
    final fatiguePenalty = (metrics.totalFatigueCost / metrics.totalSets) * 40;
    final legPenalty = metrics.legDayCount > 2 ? (metrics.legDayCount - 2) * 12 : 0;
    final kneePenalty = metrics.kneeStressTotal > 25 ? 15 : 0;
    return (100 - fatiguePenalty - legPenalty - kneePenalty).clamp(0, 100);
  }

  double _balanceScore(WorkoutProgramMetrics metrics) {
    if (metrics.exerciseCount == 0) return 0;
    final pushPullPenalty = _ratioPenalty(metrics.pushPullRatio, ideal: 1);
    final chestBackRatio = metrics.setsFor(MuscleBucket.back) == 0
        ? 100.toDouble()
        : metrics.setsFor(MuscleBucket.chest) /
            metrics.setsFor(MuscleBucket.back);
    final chestBackPenalty = _ratioPenalty(chestBackRatio, ideal: 1);
    final compoundPenalty = _ratioPenalty(metrics.compoundRatio, ideal: 0.6);
    return (100 - pushPullPenalty - chestBackPenalty - compoundPenalty)
        .clamp(0, 100);
  }

  double _goalAlignmentScore(
    WorkoutProgram program,
    WorkoutProgramMetrics metrics,
  ) {
    if (metrics.exerciseCount == 0) return 0;
    final idealReps = switch (program.goal) {
      TrainingGoal.strength => 5,
      TrainingGoal.hypertrophy => 10,
      TrainingGoal.fatLoss => 12,
      TrainingGoal.endurance => 15,
      TrainingGoal.general => 10,
    };
    final repDelta = (metrics.avgReps - idealReps).abs();
    final repPenalty = metrics.avgReps == 0 ? 20.0 : repDelta * 4;
    final goalFromContext = program.goal;
    final mismatch = goalFromContext == TrainingGoal.general ? 0.0 : 0.0;
    return (100 - repPenalty - mismatch).clamp(0, 100);
  }

  double _safetyScore(WorkoutProgramMetrics metrics) {
    if (metrics.exerciseCount == 0) return 0;
    final intelligenceSafety = metrics.safeExerciseRatio * 70;
    final jointPenalty = metrics.kneeStressTotal > 30
        ? 20
        : metrics.kneeStressTotal > 20
        ? 10
        : 0;
    return (intelligenceSafety + 30 - jointPenalty).clamp(0, 100);
  }

  double _progressionScore(WorkoutProgramMetrics metrics) {
    var score = 50.0;
    if (metrics.hasProgression) score += 25;
    if (metrics.hasDeload) score += 15;
    if (metrics.weekCount >= 4 && !metrics.hasDeload) score -= 20;
    return score.clamp(0, 100);
  }

  double _equipmentScore(WorkoutProgramMetrics metrics) {
    if (metrics.exerciseCount == 0) return 0;
    final ratio = metrics.compatibleExerciseRatio;
    final conflictPenalty = metrics.equipmentConflicts.isNotEmpty ? 25 : 0;
    return (ratio * 100 - conflictPenalty).clamp(0, 100);
  }

  double _experienceScore(WorkoutProgramMetrics metrics) {
    if (metrics.exerciseCount == 0) return 0;
    return (metrics.experienceMatchRatio * 100).clamp(0, 100);
  }

  double _weeklyDistributionScore(WorkoutProgramMetrics metrics) {
    if (metrics.setsPerDay.isEmpty) return 0;
    final values = metrics.setsPerDay.values.toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    if (avg == 0) return 0;
    var variance = 0.0;
    for (final value in values) {
      variance += ((value - avg) / avg).abs();
    }
    final avgVariance = variance / values.length;
    return (100 - avgVariance * 45).clamp(0, 100);
  }

  double _muscleCoverageScore(WorkoutProgramMetrics metrics) {
    if (metrics.majorMuscleCount == 0) return 0;
    return (metrics.coveredMajorMuscles / metrics.majorMuscleCount * 100)
        .clamp(0, 100);
  }

  double _ratioPenalty(double ratio, {required double ideal}) {
    if (ratio == 0) return 35;
    final delta = (ratio - ideal).abs();
    return (delta * 30).clamp(0, 40);
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
