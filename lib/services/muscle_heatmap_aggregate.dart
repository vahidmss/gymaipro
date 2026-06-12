import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// خروجی تجمیع هیت‌مپ — فقط نمایش بصری.
class MuscleHeatmapSnapshot {
  const MuscleHeatmapSnapshot({
    required this.targets,
    required this.completedSets,
    required this.exercisesWithSets,
  });

  factory MuscleHeatmapSnapshot.empty() => const MuscleHeatmapSnapshot(
        targets: {},
        completedSets: 0,
        exercisesWithSets: 0,
      );

  final Map<String, int> targets;
  final int completedSets;
  final int exercisesWithSets;

  bool get hasHeatmapData => MuscleTargets.hasData(targets);

  bool get hasAnySets => completedSets > 0;

  String? get topMuscleLabel {
    final sorted = MuscleTargets.sortedEntries(targets);
    if (sorted.isEmpty) return null;
    return MuscleTargets.label(sorted.first.key);
  }

  List<MapEntry<String, int>> get topMuscles {
    return MuscleTargets.sortedEntries(targets).take(3).toList();
  }
}

/// تجمیع `muscle_targets` از لاگ حرکات.
abstract final class MuscleHeatmapAggregate {
  static MuscleHeatmapSnapshot fromExerciseLogs(
    List<WorkoutExerciseLog> exercises,
    Map<int, Exercise> exerciseById, {
    Iterable<Exercise>? catalogFallback,
  }) {
    final byId = Map<int, Exercise>.from(exerciseById);
    if (catalogFallback != null) {
      for (final e in catalogFallback) {
        byId.putIfAbsent(e.id, () => e);
      }
    }

    final raw = <String, double>{};
    var completedSets = 0;
    var exercisesWithSets = 0;

    for (final exercise in exercises) {
      if (exercise is NormalExerciseLog) {
        final n = _accumulate(
          raw,
          byId,
          exercise.exerciseId,
          exercise.sets,
        );
        if (n > 0) exercisesWithSets++;
        completedSets += n;
      } else if (exercise is SupersetExerciseLog) {
        var supersetHadSets = false;
        for (final item in exercise.exercises) {
          final n = _accumulate(
            raw,
            byId,
            item.exerciseId,
            item.sets,
          );
          if (n > 0) supersetHadSets = true;
          completedSets += n;
        }
        if (supersetHadSets) exercisesWithSets++;
      }
    }

    return MuscleHeatmapSnapshot(
      targets: _normalize(raw),
      completedSets: completedSets,
      exercisesWithSets: exercisesWithSets,
    );
  }

  static bool setHasWork(ExerciseSetLog set) {
    return (set.reps != null && set.reps! > 0) ||
        (set.seconds != null && set.seconds! > 0) ||
        (set.weight != null && set.weight! > 0);
  }

  static int _accumulate(
    Map<String, double> raw,
    Map<int, Exercise> byId,
    int exerciseId,
    List<ExerciseSetLog> sets,
  ) {
    final completedSets = sets.where(setHasWork).length;
    if (completedSets == 0) return 0;

    if (exerciseId <= 0) return completedSets;

    final exercise = byId[exerciseId];
    if (exercise == null || !MuscleTargets.hasData(exercise.muscleTargets)) {
      // ست‌ها شمارش می‌شوند حتی اگر نقشهٔ عضلانی برای حرکت نباشد.
      return completedSets;
    }

    for (final entry in exercise.muscleTargets.entries) {
      if (entry.value <= 0) continue;
      raw[entry.key] = (raw[entry.key] ?? 0) + entry.value * completedSets;
    }
    return completedSets;
  }

  static Map<String, int> _normalize(Map<String, double> raw) {
    if (raw.isEmpty) return {};
    final max = raw.values.fold<double>(0, (a, b) => a > b ? a : b);
    if (max <= 0) return {};

    final out = <String, int>{};
    for (final e in raw.entries) {
      out[e.key] = ((e.value / max) * 100).round().clamp(0, 100);
    }
    return out;
  }
}
