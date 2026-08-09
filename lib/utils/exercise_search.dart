import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';

/// جستجوی تمرین با پوشش نام اصلی + نام‌های جایگزین (other_names).
///
/// نرمال‌سازی فارسی: ی/ك عربی، نیم‌فاصله، خط تیره، فاصله‌های اضافه.
abstract final class ExerciseSearch {
  const ExerciseSearch._();

  /// متن را برای مقایسهٔ سرچ یکدست می‌کند.
  static String normalize(String input) {
    var s = input.trim().toLowerCase();
    if (s.isEmpty) return '';

    s = s
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا');

    // نیم‌فاصله و جداکننده‌ها → فاصله
    s = s.replaceAll('\u200c', ' ');
    s = s.replaceAll(RegExp(r'[ـ_\-–—/\\]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// نسخهٔ بدون فاصله برای تطبیق «بالاسینه» با «بالا سینه».
  static String compact(String input) =>
      normalize(input).replaceAll(RegExp(r'\s+'), '');

  /// همهٔ رشته‌های قابل‌جستجو برای یک تمرین.
  static List<String> searchableFields(Exercise exercise) {
    final fields = <String>[
      exercise.name,
      exercise.title,
      exercise.mainMuscle,
      exercise.secondaryMuscles,
      ExerciseDisplayLabels.muscle(exercise.mainMuscle),
      ExerciseDisplayLabels.musclesCsv(exercise.secondaryMuscles),
      exercise.equipment,
      exercise.exerciseType,
      exercise.targetArea,
      exercise.shortDescription,
      ...exercise.otherNames,
      ...exercise.tags,
    ];
    return fields
        .map((f) => f.trim())
        .where((f) => f.isNotEmpty)
        .toList(growable: false);
  }

  static String _blob(Exercise exercise) {
    final parts = searchableFields(exercise).map(normalize);
    return parts.join(' | ');
  }

  static String _compactBlob(Exercise exercise) {
    final parts = searchableFields(exercise).map(compact);
    return parts.join('|');
  }

  /// آیا تمرین با کوئری مطابقت دارد (نام یا نام جایگزین کافی است).
  static bool matches(Exercise exercise, String query) {
    final q = normalize(query);
    if (q.isEmpty) return true;

    final blob = _blob(exercise);
    final blobCompact = _compactBlob(exercise);
    final qCompact = compact(query);

    if (blob.contains(q) || blobCompact.contains(qCompact)) {
      return true;
    }

    final tokens = q.split(' ').where((t) => t.length >= 2).toList();
    if (tokens.isEmpty) {
      return blob.contains(q) || blobCompact.contains(qCompact);
    }

    return tokens.every(
      (token) =>
          blob.contains(token) ||
          blobCompact.contains(token) ||
          (token.length >= 3 && blobCompact.contains(compact(token))),
    );
  }

  /// امتیاز جستجو — نام و other_names بالاترین وزن را دارند.
  static int score(Exercise exercise, String query) {
    final q = normalize(query);
    if (q.isEmpty) return 0;

    final qCompact = compact(query);
    final tokens = q.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return 0;

    var total = 0;
    for (final term in tokens) {
      final termCompact = compact(term);
      var termScore = 0;

      final nameN = normalize(exercise.name);
      final titleN = normalize(exercise.title);
      if (nameN == term || titleN == term || compact(exercise.name) == termCompact) {
        termScore = 12;
      } else if (nameN.contains(term) || titleN.contains(term)) {
        termScore = 10;
      } else {
        for (final alias in exercise.otherNames) {
          final a = normalize(alias);
          final ac = compact(alias);
          if (a == term || ac == termCompact) {
            termScore = 11;
            break;
          }
          if (a.contains(term) || ac.contains(termCompact)) {
            termScore = termScore < 10 ? 10 : termScore;
          }
        }
      }

      if (termScore == 0) {
        final muscleN = normalize(exercise.mainMuscle);
        final muscleLabel = normalize(
          ExerciseDisplayLabels.muscle(exercise.mainMuscle),
        );
        if (muscleN.contains(term) || muscleLabel.contains(term)) {
          termScore = 6;
        } else if (normalize(exercise.secondaryMuscles).contains(term)) {
          termScore = 4;
        } else if (exercise.tags.any((t) => normalize(t).contains(term))) {
          termScore = 3;
        } else if (normalize(exercise.equipment).contains(term) ||
            normalize(exercise.exerciseType).contains(term)) {
          termScore = 2;
        } else if (blobContains(exercise, term, termCompact)) {
          termScore = 1;
        }
      }

      total += termScore;
    }

    return total;
  }

  static bool blobContains(Exercise exercise, String term, String termCompact) {
    final blob = _blob(exercise);
    final cBlob = _compactBlob(exercise);
    return blob.contains(term) || cBlob.contains(termCompact);
  }

  /// فیلتر + مرتب‌سازی بر اساس امتیاز.
  static List<Exercise> filter(
    List<Exercise> source,
    String query, {
    bool sortByScore = true,
  }) {
    final q = query.trim();
    if (q.isEmpty) return List<Exercise>.from(source);

    final scored = <({Exercise exercise, int score})>[];
    for (final exercise in source) {
      if (!matches(exercise, q)) continue;
      scored.add((exercise: exercise, score: score(exercise, q)));
    }

    if (sortByScore) {
      scored.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return a.exercise.name.compareTo(b.exercise.name);
      });
    }

    return scored.map((e) => e.exercise).toList();
  }
}
