import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
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

  /// Live workout runtime session → same visual heatmap as dashboard/log.
  static MuscleHeatmapSnapshot fromLiveSession(
    WorkoutSession session,
    Map<int, Exercise> exerciseById,
  ) {
    final raw = <String, double>{};
    var completedSets = 0;
    var exercisesWithSets = 0;

    for (final exercise in session.exercises) {
      final workedSets = exercise.sets.where(_liveSetHasWork).toList();
      if (workedSets.isEmpty) continue;
      exercisesWithSets++;
      completedSets += workedSets.length;

      final targets = _targetsForLiveExercise(exercise, exerciseById);
      if (targets.isEmpty) continue;
      for (final entry in targets.entries) {
        if (entry.value <= 0) continue;
        raw[entry.key] =
            (raw[entry.key] ?? 0) + entry.value * workedSets.length;
      }
    }

    return MuscleHeatmapSnapshot(
      targets: _normalize(raw),
      completedSets: completedSets,
      exercisesWithSets: exercisesWithSets,
    );
  }

  static Map<String, int> _targetsForLiveExercise(
    WorkoutExerciseSession exercise,
    Map<int, Exercise> exerciseById,
  ) {
    final exerciseId = exercise.exerciseId ?? 0;
    if (exerciseId > 0) {
      final catalog = exerciseById[exerciseId];
      if (catalog != null && MuscleTargets.hasData(catalog.muscleTargets)) {
        return catalog.muscleTargets;
      }
    }
    final key = MuscleTargets.keyForTag(exercise.primaryMuscle);
    if (key == null) return const <String, int>{};
    return <String, int>{key: 70};
  }

  static bool setHasWork(ExerciseSetLog set) {
    return (set.reps != null && set.reps! > 0) ||
        (set.seconds != null && set.seconds! > 0) ||
        (set.weight != null && set.weight! > 0);
  }

  static bool _liveSetHasWork(WorkoutSetSession set) {
    if (set.status == WorkoutSetSessionStatus.completed ||
        set.status == WorkoutSetSessionStatus.failed) {
      return true;
    }
    return (set.actualReps != null && set.actualReps! > 0) ||
        (set.actualWeightKg != null && set.actualWeightKg! > 0) ||
        (set.durationSeconds != null && set.durationSeconds! > 0);
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
