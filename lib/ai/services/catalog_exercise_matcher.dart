import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_meta_normalizer.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/utils/exercise_search.dart';

/// نتیجهٔ تطبیق گزینهٔ AI با تمرین کاتالوگ seeded.
class CatalogExerciseMatch {
  const CatalogExerciseMatch({
    required this.exercise,
    required this.score,
    required this.exact,
  });

  final Exercise exercise;
  final int score;
  final bool exact;

  /// دادهٔ علمی قابل‌اتکا برای کپی روی تمرین اختصاصی.
  bool get isScientificallyReliable =>
      exercise.met != null && MuscleTargets.hasData(exercise.muscleTargets);
}

/// تطبیق تفسیر AI با کاتالوگ `ai_exercises` (دادهٔ seeded علمی).
abstract final class CatalogExerciseMatcher {
  const CatalogExerciseMatcher._();

  /// بهترین match برای گزینهٔ شناسایی‌شده.
  ///
  /// اولویت: تطبیق دقیق نام FA/EN/alias → امتیاز فازی قوی.
  static CatalogExerciseMatch? findBest({
    required List<Exercise> catalog,
    required ExerciseIdentityOption option,
  }) {
    if (catalog.isEmpty) return null;

    final queries = <String>[
      option.standardNameFa.trim(),
      option.standardNameEn.trim(),
    ].where((q) => q.isNotEmpty).toList();

    // ۱) تطبیق دقیق نام / عنوان / alias
    for (final query in queries) {
      final nq = ExerciseSearch.normalize(query);
      final cq = ExerciseSearch.compact(query);
      if (nq.isEmpty) continue;

      for (final exercise in catalog) {
        if (_exactNameHit(exercise, nq, cq)) {
          return CatalogExerciseMatch(
            exercise: exercise,
            score: 100,
            exact: true,
          );
        }
      }
    }

    // ۲) فازی با ExerciseSearch + بونوس عضله
    Exercise? best;
    var bestScore = 0;
    final muscleHint = ExerciseSearch.normalize(option.mainMuscleGroup);

    for (final exercise in catalog) {
      var score = 0;
      for (final query in queries) {
        final s = ExerciseSearch.score(exercise, query);
        if (s > score) score = s;
      }

      if (muscleHint.isNotEmpty) {
        final muscle = ExerciseSearch.normalize(exercise.mainMuscle);
        if (muscle == muscleHint || muscle.contains(muscleHint)) {
          score += 3;
        }
      }

      if (option.equipmentHint.trim().isNotEmpty) {
        final eq = ExerciseSearch.normalize(exercise.equipment);
        final hint = ExerciseSearch.normalize(option.equipmentHint);
        if (eq.isNotEmpty && (eq == hint || eq.contains(hint) || hint.contains(eq))) {
          score += 1;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = exercise;
      }
    }

    if (best == null) return null;

    // آستانه: سیگنال نام قوی لازم است (exact-like / contains روی نام)
    final muscleAgreed = muscleHint.isNotEmpty &&
        (ExerciseSearch.normalize(best.mainMuscle) == muscleHint ||
            ExerciseSearch.normalize(best.mainMuscle).contains(muscleHint));

    if (bestScore >= 12 || (bestScore >= 10 && muscleAgreed)) {
      return CatalogExerciseMatch(
        exercise: best,
        score: bestScore,
        exact: false,
      );
    }

    return null;
  }

  /// ساخت پروفایل هسته از دادهٔ کاتالوگ (نه حدس LLM).
  static GeneratedMuscleProfile toProfile(Exercise exercise) {
    return ExerciseMetaNormalizer.normalizeProfile(
      GeneratedMuscleProfile(
        mainMuscle: exercise.mainMuscle.trim().isEmpty
            ? 'کل بدن'
            : exercise.mainMuscle.trim(),
        secondaryMuscles: exercise.secondaryMuscles.trim(),
        muscleTargets: Map<String, int>.from(exercise.muscleTargets),
        met: exercise.met,
        typicalRpe: exercise.typicalRpe,
        movementPattern: exercise.movementPattern.trim(),
        bodyEngagement: exercise.bodyEngagement.trim().isNotEmpty
            ? exercise.bodyEngagement.trim()
            : exercise.richMeta.bodyEngagementLabel.trim(),
        mechanicsType: exercise.richMeta.mechanicsType.trim(),
        forceType: exercise.richMeta.forceType.trim(),
        caloriesPer1000kg: exercise.caloriesPer1000kg,
        source: MuscleProfileSource.catalog,
        catalogExerciseId: exercise.id,
        catalogExerciseName: exercise.name.trim().isNotEmpty
            ? exercise.name.trim()
            : exercise.title.trim(),
      ),
    );
  }

  static bool _exactNameHit(Exercise exercise, String nq, String cq) {
    bool hit(String raw) {
      final n = ExerciseSearch.normalize(raw);
      final c = ExerciseSearch.compact(raw);
      return n == nq || c == cq;
    }

    if (hit(exercise.name) || hit(exercise.title)) return true;
    for (final alias in exercise.otherNames) {
      if (hit(alias)) return true;
    }
    return false;
  }
}
