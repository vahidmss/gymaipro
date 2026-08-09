import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// خروجی تجمیع هیت‌مپ.
///
/// [stimulus] واحد خام علمی (جمع‌پذیر بین جلسات).
/// [targets] فقط برای نمایش: نسبت به داغ‌ترین عضلهٔ همان بازه (۰–۱۰۰).
class MuscleHeatmapSnapshot {
  const MuscleHeatmapSnapshot({
    required this.targets,
    required this.stimulus,
    required this.completedSets,
    required this.exercisesWithSets,
  });

  factory MuscleHeatmapSnapshot.empty() => const MuscleHeatmapSnapshot(
        targets: {},
        stimulus: {},
        completedSets: 0,
        exercisesWithSets: 0,
      );

  /// شدت نسبی نمایش (۰–۱۰۰) — یک‌بار نرمال‌شده روی [stimulus].
  final Map<String, int> targets;

  /// محرک خام: Σ (سهم‌عضله × ضریب‌بار ست).
  final Map<String, double> stimulus;

  final int completedSets;
  final int exercisesWithSets;

  bool get hasHeatmapData => MuscleTargets.hasData(targets);

  bool get hasAnySets => completedSets > 0;

  double get stimulusTotal =>
      stimulus.values.fold<double>(0, (a, b) => a + b);

  String? get topMuscleLabel {
    final sorted = MuscleTargets.sortedEntries(targets);
    if (sorted.isEmpty) return null;
    return MuscleTargets.label(sorted.first.key);
  }

  List<MapEntry<String, int>> get topMuscles {
    return MuscleTargets.sortedEntries(targets).take(3).toList();
  }
}

/// تجمیع علمی محرک عضله از لاگ حرکات.
///
/// فرمول هر ست کارشده:
/// `S(m) += (c_m / 100) × loadFactor`
/// که `c_m` درصد کاتالوگ عضله است و
/// `loadFactor = max(weightKg, 1)` اگر وزن ثبت شده، وگرنه `1`
/// (بدن‌وزن / زمان‌محور).
///
/// نرمال‌سازی فقط یک‌بار در انتها برای نمایش انجام می‌شود.
abstract final class MuscleHeatmapAggregate {
  /// حداقل ضریب بار وقتی وزن ثبت شده.
  static const double minLoadFactor = 1;

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

    final stimulus = <String, double>{};
    var completedSets = 0;
    var exercisesWithSets = 0;

    for (final exercise in exercises) {
      if (exercise is NormalExerciseLog) {
        final n = _accumulateSets(
          stimulus,
          byId,
          exercise.exerciseId,
          exercise.sets,
          tagFallback: exercise.tag,
        );
        if (n > 0) exercisesWithSets++;
        completedSets += n;
      } else if (exercise is SupersetExerciseLog) {
        var supersetHadSets = false;
        for (final item in exercise.exercises) {
          final n = _accumulateSets(
            stimulus,
            byId,
            item.exerciseId,
            item.sets,
            tagFallback: exercise.tag,
          );
          if (n > 0) supersetHadSets = true;
          completedSets += n;
        }
        if (supersetHadSets) exercisesWithSets++;
      }
    }

    return MuscleHeatmapSnapshot(
      targets: normalizeForDisplay(stimulus),
      stimulus: Map<String, double>.unmodifiable(stimulus),
      completedSets: completedSets,
      exercisesWithSets: exercisesWithSets,
    );
  }

  /// Live workout runtime session → همان فرمول لاگ.
  static MuscleHeatmapSnapshot fromLiveSession(
    WorkoutSession session,
    Map<int, Exercise> exerciseById,
  ) {
    final stimulus = <String, double>{};
    var completedSets = 0;
    var exercisesWithSets = 0;

    for (final exercise in session.exercises) {
      final workedSets = exercise.sets.where(_liveSetHasWork).toList();
      if (workedSets.isEmpty) continue;
      exercisesWithSets++;
      completedSets += workedSets.length;

      final targets = _targetsForLiveExercise(exercise, exerciseById);
      if (targets.isEmpty) continue;

      for (final set in workedSets) {
        final load = loadFactorForKg(set.actualWeightKg);
        for (final entry in targets.entries) {
          if (entry.value <= 0) continue;
          stimulus[entry.key] =
              (stimulus[entry.key] ?? 0) + (entry.value / 100.0) * load;
        }
      }
    }

    return MuscleHeatmapSnapshot(
      targets: normalizeForDisplay(stimulus),
      stimulus: Map<String, double>.unmodifiable(stimulus),
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

  /// ضریب بار ست — وزن سنگین‌تر = محرک بیشتر؛ بدون وزن = ۱.
  static double loadFactorForKg(double? weightKg) {
    if (weightKg == null || weightKg <= 0) return minLoadFactor;
    return weightKg < minLoadFactor ? minLoadFactor : weightKg;
  }

  static int _accumulateSets(
    Map<String, double> stimulus,
    Map<int, Exercise> byId,
    int exerciseId,
    List<ExerciseSetLog> sets, {
    String? tagFallback,
  }) {
    final worked = sets.where(setHasWork).toList();
    if (worked.isEmpty) return 0;

    if (exerciseId <= 0) return worked.length;

    final targets = _resolveTargets(byId[exerciseId], tagFallback);
    if (targets.isEmpty) return worked.length;

    for (final set in worked) {
      final load = loadFactorForKg(set.weight);
      for (final entry in targets.entries) {
        if (entry.value <= 0) continue;
        stimulus[entry.key] =
            (stimulus[entry.key] ?? 0) + (entry.value / 100.0) * load;
      }
    }
    return worked.length;
  }

  /// اول کاتالوگ علمی؛ اگر نبود از تگ حرکت با سهم ۷۰٪.
  static Map<String, int> _resolveTargets(Exercise? exercise, String? tag) {
    if (exercise != null && MuscleTargets.hasData(exercise.muscleTargets)) {
      return exercise.muscleTargets;
    }
    final key = MuscleTargets.keyForTag(tag);
    if (key == null) return const <String, int>{};
    return <String, int>{key: 70};
  }

  /// نرمال نمایش: داغ‌ترین عضلهٔ بازه = ۱۰۰.
  static Map<String, int> normalizeForDisplay(Map<String, double> stimulus) {
    if (stimulus.isEmpty) return {};
    final max = stimulus.values.fold<double>(0, (a, b) => a > b ? a : b);
    if (max <= 0) return {};

    final out = <String, int>{};
    for (final e in stimulus.entries) {
      out[e.key] = ((e.value / max) * 100).round().clamp(0, 100);
    }
    return out;
  }

  /// جمع خام چند اسنپ‌شات (مثلاً جلسات یک هفته) قبل از نرمال نهایی.
  static Map<String, double> mergeStimulus(
    Iterable<Map<String, double>> parts,
  ) {
    final out = <String, double>{};
    for (final part in parts) {
      for (final e in part.entries) {
        out[e.key] = (out[e.key] ?? 0) + e.value;
      }
    }
    return out;
  }
}
