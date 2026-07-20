/// Expands short UI / profile equipment presets into catalog matcher tokens.
///
/// The offline selector matches substrings like «هالتر», «دمبل», «دستگاه»,
/// «بدون», «کش» — not product labels like «باشگاه کامل».
abstract final class WorkoutEquipmentTokens {
  const WorkoutEquipmentTokens._();

  static const List<String> fullGym = <String>[
    'باشگاه کامل',
    'هالتر',
    'دمبل',
    'دستگاه',
    'کابل',
    'اسمیت',
    'بدون تجهیزات',
  ];

  static const List<String> homeDumbbell = <String>[
    'خانه',
    'دمبل',
    'کش',
    'بدون تجهیزات',
    'بارفیکس',
  ];

  static const List<String> bodyweightOnly = <String>[
    'فقط وزن بدن',
    'وزن بدن',
    'بدون تجهیزات',
    'بدون',
    'bodyweight',
  ];

  static const List<String> bands = <String>[
    'کش ورزشی',
    'کش',
    'بدون تجهیزات',
    'band',
  ];

  /// Expand one or more user-facing labels into matcher tokens.
  static List<String> expand(Iterable<String> raw) {
    final out = <String>{};
    for (final item in raw) {
      final text = item.trim();
      if (text.isEmpty) continue;
      out.add(text);
      out.addAll(_tokensFor(text));
    }
    return List<String>.unmodifiable(out);
  }

  static List<String> _tokensFor(String text) {
    final lower = text.toLowerCase();

    if (text.contains('باشگاه کامل') ||
        (text.contains('باشگاه') &&
            text.contains('دمبل') &&
            text.contains('هالتر')) ||
        lower.contains('full gym')) {
      return fullGym;
    }

    if (text.contains('باشگاه معمولی') ||
        (text.contains('باشگاه') && !text.contains('کامل'))) {
      return const <String>[
        'باشگاه',
        'دمبل',
        'دستگاه',
        'کابل',
        'بدون تجهیزات',
      ];
    }

    if (text.contains('دمبل در خانه') ||
        (text.contains('خانه') && text.contains('دمبل')) ||
        (text.contains('خانه') && !text.contains('خیلی محدود'))) {
      return homeDumbbell;
    }

    if (text.contains('فقط وزن بدن') ||
        text.contains('وزن بدن') ||
        text.contains('خیلی محدود') ||
        lower.contains('bodyweight')) {
      return bodyweightOnly;
    }

    if (text.contains('کش')) {
      return bands;
    }

    if (text.contains('باشگاه') || lower.contains('gym')) {
      return fullGym;
    }

    return const <String>[];
  }
}
