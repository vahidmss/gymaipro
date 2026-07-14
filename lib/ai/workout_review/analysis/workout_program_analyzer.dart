import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/exercise/intelligence/exercise_intelligence_evaluation.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_intelligence_runtime.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout_review/analysis/workout_program_metrics.dart';

/// Builds derived metrics from a program and exercise intelligence profiles.
class WorkoutProgramAnalyzer {
  const WorkoutProgramAnalyzer({
    this.intelligenceRuntime = const ExerciseIntelligenceRuntime(
      enforceCoachV2Gate: false,
    ),
  });

  final ExerciseIntelligenceRuntime intelligenceRuntime;

  WorkoutProgramMetrics analyze({
    required WorkoutProgram program,
    required CoachContext context,
    required Map<int, ExerciseProfile> profileById,
  }) {
    final weeklySetsByMuscle = <MuscleBucket, int>{};
    final setsPerDay = <String, int>{};
    var compoundCount = 0;
    var isolationCount = 0;
    var pushSets = 0;
    var pullSets = 0;
    var kneeStressTotal = 0.0;
    var shoulderStressTotal = 0.0;
    var spineStressTotal = 0.0;
    var totalFatigueCost = 0.0;
    var totalRecoveryCost = 0.0;
    var compatibleCount = 0;
    var safeCount = 0;
    var experienceMatchCount = 0;
    var totalReps = 0;
    var repSamples = 0;
    var kneeHeavyExerciseCount = 0;
    var rearDeltProxySets = 0;
    var shoulderPushSets = 0;
    final equipmentUsed = <String>{};
    final equipmentConflicts = <String>[];
    var exerciseCount = 0;
    var totalSets = 0;
    var legDayCount = 0;

    final experience =
        program.experienceLevel.isNotEmpty
            ? program.experienceLevel
            : (context.profile['experience_level'] as String?) ?? 'متوسط';
    final query = ExerciseIntelligenceQuery(
      goal: program.goal,
      experience: experience,
      availableEquipment: context.equipment,
      limitations: context.restrictions,
      recoveryScore: _recoveryFromHeatmap(context),
    );

    for (final day in program.allDays) {
      var daySets = 0;
      var dayHasLeg = false;
      for (final exercise in day.exercises) {
        exerciseCount++;
        final setCount = exercise.sets.length;
        totalSets += setCount;
        daySets += setCount;

        final profile = profileById[exercise.catalogExerciseId];
        final bucket = WorkoutScience.muscleBucket(exercise.primaryMuscle);
        weeklySetsByMuscle[bucket] =
            (weeklySetsByMuscle[bucket] ?? 0) + setCount;

        final isCompound = profile?.compound ?? exercise.isCompound;
        if (isCompound) {
          compoundCount++;
        } else {
          isolationCount++;
        }

        pushSets += _pushSets(bucket, setCount);
        pullSets += _pullSets(bucket, setCount);

        if (bucket == MuscleBucket.quads ||
            bucket == MuscleBucket.hamstrings ||
            bucket == MuscleBucket.glutes) {
          dayHasLeg = true;
        }

        if (profile != null) {
          kneeStressTotal += profile.kneeLoad * setCount;
          shoulderStressTotal += profile.shoulderLoad * setCount;
          spineStressTotal += profile.spineLoad * setCount;
          totalFatigueCost += profile.fatigueScore * setCount;
          totalRecoveryCost += profile.recoveryCost * setCount;

          if (profile.kneeLoad >= 0.65) kneeHeavyExerciseCount++;
          if (_isRearDeltProxy(exercise, profile)) {
            rearDeltProxySets += setCount;
          }
          if (_isShoulderPush(exercise, profile)) {
            shoulderPushSets += setCount;
          }

          final evaluation = intelligenceRuntime.evaluate(
            exercise: profile,
            query: query,
          );
          _accumulateIntelligence(
            evaluation: evaluation,
            compatibleCount: compatibleCount,
            safeCount: safeCount,
            experienceMatchCount: experienceMatchCount,
            experience: experience,
            profile: profile,
            onCompatible: (value) => compatibleCount = value,
            onSafe: (value) => safeCount = value,
            onExperience: (value) => experienceMatchCount = value,
          );
        }

        if (exercise.equipment.isNotEmpty) {
          equipmentUsed.add(exercise.equipment);
          if (!_equipmentMatches(context.equipment, exercise.equipment)) {
            equipmentConflicts.add(exercise.name);
          }
        }
        totalReps += _averageReps(exercise);
        repSamples++;
      }
      setsPerDay[day.label] = daySets;
      if (dayHasLeg) legDayCount++;
    }

    const majorBuckets = <MuscleBucket>[
      MuscleBucket.chest,
      MuscleBucket.back,
      MuscleBucket.shoulders,
      MuscleBucket.quads,
      MuscleBucket.hamstrings,
    ];
    var coveredMajor = 0;
    for (final bucket in majorBuckets) {
      if ((weeklySetsByMuscle[bucket] ?? 0) >= 4) coveredMajor++;
    }

    return WorkoutProgramMetrics(
      exerciseCount: exerciseCount,
      totalSets: totalSets,
      weeklySetsByMuscle: Map<MuscleBucket, int>.unmodifiable(weeklySetsByMuscle),
      setsPerDay: Map<String, int>.unmodifiable(setsPerDay),
      compoundCount: compoundCount,
      isolationCount: isolationCount,
      pushSets: pushSets,
      pullSets: pullSets,
      kneeStressTotal: kneeStressTotal,
      shoulderStressTotal: shoulderStressTotal,
      spineStressTotal: spineStressTotal,
      totalFatigueCost: totalFatigueCost,
      totalRecoveryCost: totalRecoveryCost,
      equipmentUsed: equipmentUsed.toList(growable: false),
      equipmentConflicts: List<String>.unmodifiable(equipmentConflicts),
      weekCount: program.weeks.length,
      hasDeload: _hasDeload(program),
      hasProgression: _hasProgression(program),
      compatibleExerciseRatio:
          exerciseCount == 0 ? 1 : compatibleCount / exerciseCount,
      safeExerciseRatio: exerciseCount == 0 ? 1 : safeCount / exerciseCount,
      experienceMatchRatio:
          exerciseCount == 0 ? 1 : experienceMatchCount / exerciseCount,
      avgReps: repSamples == 0 ? 0 : totalReps / repSamples,
      coveredMajorMuscles: coveredMajor,
      majorMuscleCount: majorBuckets.length,
      legDayCount: legDayCount,
      kneeHeavyExerciseCount: kneeHeavyExerciseCount,
      rearDeltProxySets: rearDeltProxySets,
      shoulderPushSets: shoulderPushSets,
    );
  }

  static double _recoveryFromHeatmap(CoachContext context) {
    final heatmap = context.weeklyHeatmap;
    if (heatmap == null || !heatmap.hasHeatmapData) return 0.85;
    final loadFactor = (heatmap.sessionCount / 10).clamp(0.0, 1.0);
    return (1 - loadFactor * 0.35).clamp(0.5, 1.0);
  }

  static int _pushSets(MuscleBucket bucket, int sets) {
    if (bucket == MuscleBucket.chest ||
        bucket == MuscleBucket.shoulders ||
        bucket == MuscleBucket.triceps) {
      return sets;
    }
    return 0;
  }

  static int _pullSets(MuscleBucket bucket, int sets) {
    if (bucket == MuscleBucket.back || bucket == MuscleBucket.biceps) {
      return sets;
    }
    return 0;
  }

  static bool _isRearDeltProxy(WorkoutExercise exercise, ExerciseProfile profile) {
    final name = exercise.name.toLowerCase();
    return name.contains('face pull') ||
        name.contains('فیس پول') ||
        name.contains('نشر خم') ||
        name.contains('reverse fly') ||
        profile.movementPattern == ExerciseMovementPattern.horizontalPull &&
            profile.isolation;
  }

  static bool _isShoulderPush(WorkoutExercise exercise, ExerciseProfile profile) {
    final bucket = WorkoutScience.muscleBucket(exercise.primaryMuscle);
    if (bucket != MuscleBucket.shoulders) return false;
    return profile.movementPattern == ExerciseMovementPattern.verticalPush ||
        exercise.name.contains('پرس') ||
        exercise.name.toLowerCase().contains('press');
  }

  static void _accumulateIntelligence({
    required ExerciseIntelligenceEvaluation evaluation,
    required int compatibleCount,
    required int safeCount,
    required int experienceMatchCount,
    required String experience,
    required ExerciseProfile profile,
    required void Function(int value) onCompatible,
    required void Function(int value) onSafe,
    required void Function(int value) onExperience,
  }) {
    if (evaluation.compatibility.isCompatible) {
      onCompatible(compatibleCount + 1);
    }
    if (evaluation.safety.isSafe) {
      onSafe(safeCount + 1);
    }
    if (_matchesExperience(experience, profile.difficulty)) {
      onExperience(experienceMatchCount + 1);
    }
  }

  static bool _matchesExperience(
    String experience,
    ExerciseDifficultyLevel difficulty,
  ) {
    if (WorkoutScience.isBeginnerExperience(experience)) {
      return difficulty == ExerciseDifficultyLevel.beginner ||
          difficulty == ExerciseDifficultyLevel.intermediate;
    }
    if (WorkoutScience.isAdvancedExperience(experience)) {
      return difficulty != ExerciseDifficultyLevel.beginner;
    }
    return true;
  }

  static bool _equipmentMatches(
    List<String> available,
    String exerciseEquipment,
  ) {
    if (available.isEmpty) return true;
    final normalizedAvailable = available.map((e) => e.toLowerCase()).toSet();
    final token = exerciseEquipment.toLowerCase();
    if (token.contains('بدون')) return true;
    return normalizedAvailable.any(token.contains);
  }

  static int _averageReps(WorkoutExercise exercise) {
    final reps = exercise.sets
        .where((set) => set.type == WorkoutSetType.reps && set.reps != null)
        .map((set) => set.reps!)
        .toList();
    if (reps.isEmpty) return 0;
    return reps.reduce((a, b) => a + b) ~/ reps.length;
  }

  static bool _hasDeload(WorkoutProgram program) {
    for (final week in program.weeks) {
      for (final day in week.days) {
        for (final exercise in day.exercises) {
          for (final note in exercise.notes) {
            if (note.text.toLowerCase().contains('deload') ||
                note.text.contains('دیلود')) {
              return true;
            }
          }
        }
      }
    }
    return program.weeks.length >= 4 &&
        program.weeks.any((week) => week.weekIndex >= 4);
  }

  static bool _hasProgression(WorkoutProgram program) {
    for (final day in program.allDays) {
      for (final exercise in day.exercises) {
        for (final set in exercise.sets) {
          if (set.progression != null) return true;
        }
      }
    }
    return program.weeks.length > 1;
  }
}
