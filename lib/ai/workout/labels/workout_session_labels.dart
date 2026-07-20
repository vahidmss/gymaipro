import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';

/// Canonical, unique Persian session labels for workout programs.
///
/// Rules:
/// - Every label starts with `روز N — …`
/// - Repeated focus words get a serial (فشار ۱ / فشار ۲) so two days
///   are never identical and never collide in UI/routing.
abstract final class WorkoutSessionLabels {
  const WorkoutSessionLabels._();

  /// Default labels by days/week (used by rule-based / science paths).
  static List<String> forDaysPerWeek(int daysPerWeek) {
    final d = daysPerWeek.clamp(2, 6);
    return switch (d) {
      2 => ensureUnique(const <String>['تمام‌بدن', 'تمام‌بدن']),
      3 => ensureUnique(const <String>['فشار', 'کشش', 'پا']),
      4 => ensureUnique(const <String>[
          'بالاتنه',
          'پایین‌تنه',
          'بالاتنه',
          'پایین‌تنه',
        ]),
      5 => ensureUnique(const <String>[
          'سینه و شانه',
          'پشت',
          'پا',
          'بالاتنه',
          'پایین‌تنه',
        ]),
      _ => ensureUnique(const <String>[
          'فشار',
          'کشش',
          'پا',
          'فشار',
          'کشش',
          'پا',
        ]),
    };
  }

  static List<String> forStrategy(WorkoutSplitStrategy strategy, int days) {
    return switch (strategy) {
      WorkoutSplitStrategy.fullBody => ensureUnique(
          List<String>.filled(days, 'تمام‌بدن'),
        ),
      WorkoutSplitStrategy.upperLower => ensureUnique(
          List<String>.generate(
            days,
            (i) => i.isEven ? 'بالاتنه' : 'پایین‌تنه',
          ),
        ),
      WorkoutSplitStrategy.pushPullLegs => ensureUnique(
          List<String>.generate(
            days,
            (i) => const <String>['فشار', 'کشش', 'پا'][i % 3],
          ),
        ),
      WorkoutSplitStrategy.broSplit ||
      WorkoutSplitStrategy.phul ||
      WorkoutSplitStrategy.phat ||
      WorkoutSplitStrategy.custom =>
        forDaysPerWeek(days),
    };
  }

  /// Rewrites [raw] so every label is unique and follows `روز N — focus`.
  static List<String> ensureUnique(List<String> raw) {
    if (raw.isEmpty) return const <String>[];

    final cores = raw.map(_coreFocus).toList(growable: false);
    final totalByCore = <String, int>{};
    for (final core in cores) {
      totalByCore[core] = (totalByCore[core] ?? 0) + 1;
    }
    final seenByCore = <String, int>{};

    return List<String>.generate(raw.length, (index) {
      final core = cores[index];
      final total = totalByCore[core] ?? 1;
      final seen = (seenByCore[core] ?? 0) + 1;
      seenByCore[core] = seen;

      final focus = total > 1 ? '$core ${_toPersianDigits(seen)}' : core;
      return 'روز ${_toPersianDigits(index + 1)} — $focus';
    });
  }

  static String _toPersianDigits(int value) {
    const western = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.toString().split('').map((ch) {
      final i = western.indexOf(ch);
      return i >= 0 ? persian[i] : ch;
    }).join();
  }

  /// Apply unique labels onto an existing list of day labels (LLM output).
  static List<String> normalizeParsed(List<String> parsed) {
    return ensureUnique(parsed);
  }

  static bool hasDuplicateLabels(Iterable<String> labels) {
    final seen = <String>{};
    for (final label in labels) {
      final key = label.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (!seen.add(key)) return true;
    }
    return false;
  }

  /// Focus token without day prefix / serial suffix (for classification).
  static String coreFocus(String label) => _coreFocus(label);

  static String _coreFocus(String label) {
    var text = label.trim();
    if (text.isEmpty) return 'جلسه';

    text = text.replaceFirst(
      RegExp(r'^روز\s*[0-9۰-۹]+\s*[—\-–:|٫.]?\s*'),
      '',
    );
    text = text.replaceFirst(
      RegExp(r'^day\s*\d+\s*[—\-–:|]?\s*', caseSensitive: false),
      '',
    );
    // Strip trailing serial: "فشار 2", "بالاتنه ۲", "A", "B"
    text = text.replaceFirst(
      RegExp(r'\s*[0-9۰-۹]+\s*$'),
      '',
    );
    text = text.replaceFirst(
      RegExp(r'\s*[A-Da-d]\s*$'),
      '',
    );
    text = text.replaceFirst(
      RegExp(r'\s*[\(（][^\)）]*[\)）]\s*$'),
      '',
    );
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return text.isEmpty ? 'جلسه' : text;
  }
}
