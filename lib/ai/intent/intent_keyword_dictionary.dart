/// One weighted keyword entry in the intent dictionary.
class IntentKeywordEntry {
  const IntentKeywordEntry({
    required this.term,
    required this.weight,
    this.locale,
  });

  final String term;
  final double weight;
  final String? locale;
}

/// Extensible keyword dictionary for data-driven intent rules.
///
/// All keyword terms live here. The rule registry references dictionary keys
/// instead of hardcoding terms inside detectors.
class IntentKeywordDictionary {
  const IntentKeywordDictionary._();

  static const Map<String, List<IntentKeywordEntry>> entries =
      <String, List<IntentKeywordEntry>>{
        'workout_generation': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'برنامه تمرین', weight: 1.4),
          IntentKeywordEntry(term: 'برنامه بدنسازی', weight: 1.3),
          IntentKeywordEntry(term: 'برنامه ورزشی', weight: 1.2),
          IntentKeywordEntry(term: 'workout plan', weight: 1.1),
          IntentKeywordEntry(term: 'training program', weight: 1),
        ],
        'workout_today': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'تمرین امروز', weight: 1.3),
          IntentKeywordEntry(term: 'امروز چی تمرین', weight: 1.2),
          IntentKeywordEntry(term: 'today workout', weight: 1.1),
          IntentKeywordEntry(term: 'what should i train', weight: 1),
        ],
        'workout_modification': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'تغییر برنامه', weight: 1.3),
          IntentKeywordEntry(term: 'اصلاح برنامه', weight: 1.2),
          IntentKeywordEntry(term: 'modify program', weight: 1.1),
        ],
        'exercise_question': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'فرم حرکت', weight: 1.2),
          IntentKeywordEntry(term: 'تکنیک', weight: 1),
          IntentKeywordEntry(term: 'exercise form', weight: 1.1),
          IntentKeywordEntry(term: 'how to do', weight: 0.9),
        ],
        'workout_question': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'سوال تمرینی', weight: 1.1),
          IntentKeywordEntry(term: 'workout question', weight: 1),
          IntentKeywordEntry(term: 'sets and reps', weight: 0.9),
        ],
        'progress_analysis': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'تحلیل پیشرفت', weight: 1.4),
          IntentKeywordEntry(term: 'پیشرفت', weight: 1),
          IntentKeywordEntry(term: 'progress analysis', weight: 1.2),
          IntentKeywordEntry(term: 'my progress', weight: 1),
        ],
        'recovery': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'ریکاوری', weight: 1.3),
          IntentKeywordEntry(term: 'استراحت', weight: 1),
          IntentKeywordEntry(term: 'recovery', weight: 1.2),
          IntentKeywordEntry(term: 'rest day', weight: 1),
        ],
        'nutrition': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'تغذیه', weight: 1.3),
          IntentKeywordEntry(term: 'رژیم', weight: 1.1),
          IntentKeywordEntry(term: 'nutrition', weight: 1.2),
          IntentKeywordEntry(term: 'meal plan', weight: 1),
        ],
        'supplement': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'مکمل', weight: 1.3),
          IntentKeywordEntry(term: 'supplement', weight: 1.2),
          IntentKeywordEntry(term: 'creatine', weight: 0.9),
        ],
        'motivation': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'انگیزه', weight: 1.3),
          IntentKeywordEntry(term: 'motivation', weight: 1.2),
          IntentKeywordEntry(term: 'encourage me', weight: 1),
        ],
        'general_fitness': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'فیتنس', weight: 1),
          IntentKeywordEntry(term: 'fitness', weight: 1),
          IntentKeywordEntry(term: 'health', weight: 0.8),
        ],
        'app_help': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'راهنما', weight: 1.2),
          IntentKeywordEntry(term: 'کمک اپ', weight: 1.3),
          IntentKeywordEntry(term: 'app help', weight: 1.2),
          IntentKeywordEntry(term: 'how to use', weight: 1),
        ],
        'bug_report': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'باگ', weight: 1.3),
          IntentKeywordEntry(term: 'خطا', weight: 1),
          IntentKeywordEntry(term: 'bug report', weight: 1.2),
          IntentKeywordEntry(term: 'crash', weight: 1.1),
        ],
        'feedback': <IntentKeywordEntry>[
          IntentKeywordEntry(term: 'بازخورد', weight: 1.3),
          IntentKeywordEntry(term: 'feedback', weight: 1.2),
          IntentKeywordEntry(term: 'suggestion', weight: 1),
        ],
      };

  /// Returns dictionary entries for [key].
  static List<IntentKeywordEntry> forKey(String key) {
    return List<IntentKeywordEntry>.unmodifiable(
      entries[key] ?? const <IntentKeywordEntry>[],
    );
  }
}
