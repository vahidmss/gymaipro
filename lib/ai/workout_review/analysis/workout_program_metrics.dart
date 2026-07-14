import 'package:gymaipro/ai/knowledge/workout_science.dart';

/// Derived metrics from a workout program used by scoring and issue detection.
class WorkoutProgramMetrics {
  const WorkoutProgramMetrics({
    required this.exerciseCount,
    required this.totalSets,
    required this.weeklySetsByMuscle,
    required this.setsPerDay,
    required this.compoundCount,
    required this.isolationCount,
    required this.pushSets,
    required this.pullSets,
    required this.kneeStressTotal,
    required this.shoulderStressTotal,
    required this.spineStressTotal,
    required this.totalFatigueCost,
    required this.totalRecoveryCost,
    required this.equipmentUsed,
    required this.equipmentConflicts,
    required this.weekCount,
    required this.hasDeload,
    required this.hasProgression,
    required this.compatibleExerciseRatio,
    required this.safeExerciseRatio,
    required this.experienceMatchRatio,
    required this.avgReps,
    required this.coveredMajorMuscles,
    required this.majorMuscleCount,
    required this.legDayCount,
    required this.kneeHeavyExerciseCount,
    required this.rearDeltProxySets,
    required this.shoulderPushSets,
  });

  final int exerciseCount;
  final int totalSets;
  final Map<MuscleBucket, int> weeklySetsByMuscle;
  final Map<String, int> setsPerDay;
  final int compoundCount;
  final int isolationCount;
  final int pushSets;
  final int pullSets;
  final double kneeStressTotal;
  final double shoulderStressTotal;
  final double spineStressTotal;
  final double totalFatigueCost;
  final double totalRecoveryCost;
  final List<String> equipmentUsed;
  final List<String> equipmentConflicts;
  final int weekCount;
  final bool hasDeload;
  final bool hasProgression;
  final double compatibleExerciseRatio;
  final double safeExerciseRatio;
  final double experienceMatchRatio;
  final double avgReps;
  final int coveredMajorMuscles;
  final int majorMuscleCount;
  final int legDayCount;
  final int kneeHeavyExerciseCount;
  final int rearDeltProxySets;
  final int shoulderPushSets;

  int setsFor(MuscleBucket bucket) => weeklySetsByMuscle[bucket] ?? 0;

  double get compoundRatio =>
      exerciseCount == 0 ? 0 : compoundCount / exerciseCount;

  double get isolationRatio =>
      exerciseCount == 0 ? 0 : isolationCount / exerciseCount;

  double get pushPullRatio => pullSets == 0 ? pushSets.toDouble() : pushSets / pullSets;

  double get posteriorChainSets =>
      (weeklySetsByMuscle[MuscleBucket.hamstrings] ?? 0) +
      (weeklySetsByMuscle[MuscleBucket.glutes] ?? 0).toDouble();

  double get legSets =>
      (weeklySetsByMuscle[MuscleBucket.quads] ?? 0) +
      (weeklySetsByMuscle[MuscleBucket.hamstrings] ?? 0) +
      (weeklySetsByMuscle[MuscleBucket.glutes] ?? 0).toDouble();
}
