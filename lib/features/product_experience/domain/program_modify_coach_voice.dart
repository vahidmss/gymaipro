import 'package:gymaipro/features/product_experience/domain/program_modify_options.dart';

/// Detects program-critical lifts and builds clear Persian coach copy.
abstract final class ProgramModifyCoachVoice {
  static final List<RegExp> _keyLiftPatterns = <RegExp>[
    RegExp(r'پرس\s*سینه'),
    RegExp(r'bench\s*press', caseSensitive: false),
    RegExp(r'اسکوات|squat', caseSensitive: false),
    RegExp(r'ددلیفت|deadlift', caseSensitive: false),
    RegExp(r'بارفیکس|pull[\s-]?up', caseSensitive: false),
    RegExp(r'زیربغل\s*هلتر|bent[\s-]?over\s*row', caseSensitive: false),
    RegExp(r'پرس\s*سرشانه|overhead\s*press|military\s*press', caseSensitive: false),
    RegExp(r'دیپ|dip', caseSensitive: false),
  ];

  static bool isKeyLift(String? exerciseName, {bool? compound}) {
    final name = (exerciseName ?? '').trim();
    if (name.isEmpty) return compound ?? false;
    for (final pattern in _keyLiftPatterns) {
      if (pattern.hasMatch(name)) return true;
    }
    return compound ?? false;
  }

  /// Reasons that justify removing/heavily changing a key lift.
  static bool isProtectedReason(String? reasonId) {
    return switch (reasonId) {
      'pain' ||
      'cant_do' ||
      'no_equipment' ||
      'shoulder' ||
      'knee' ||
      'back' ||
      'wrist' ||
      'elbow' ||
      'other' => true,
      _ => false,
    };
  }

  /// Short request summary — shown once as «درخواست تو».
  static String requestSummary({
    required ProgramModifyGoal goal,
    String? sessionDay,
    String? exerciseName,
    String? reasonLabel,
  }) {
    final day = (sessionDay != null && sessionDay.isNotEmpty)
        ? ' ($sessionDay)'
        : '';
    final exercise = (exerciseName != null && exerciseName.isNotEmpty)
        ? '«$exerciseName»'
        : null;
    final reason = (reasonLabel != null && reasonLabel.isNotEmpty)
        ? reasonLabel
        : null;

    return switch (goal) {
      ProgramModifyGoal.replaceExercise =>
        'عوض کردن ${exercise ?? 'یک حرکت'}$day'
            '${reason != null ? ' — $reason' : ''}',
      ProgramModifyGoal.removeExercise =>
        'حذف ${exercise ?? 'یک حرکت'}$day'
            '${reason != null ? ' — $reason' : ''}',
      ProgramModifyGoal.reduceVolume =>
        'کم کردن ست‌های ${exercise ?? 'جلسه'}$day',
      ProgramModifyGoal.increaseVolume =>
        'زیاد کردن ست‌های ${exercise ?? 'جلسه'}$day',
      ProgramModifyGoal.easierSession => 'سبک‌تر کردن جلسه$day',
      ProgramModifyGoal.harderSession => 'سنگین‌تر کردن جلسه$day',
      ProgramModifyGoal.shorterSession => 'کوتاه‌تر کردن جلسه$day',
      ProgramModifyGoal.homeVersion => 'نسخه خانگی برای جلسه$day',
      ProgramModifyGoal.injuryAdapt =>
        'سازگاری با آسیب'
            '${reason != null ? ' ($reason)' : ''}',
      ProgramModifyGoal.tiredAdapt =>
        'سبک کردن جلسه به‌خاطر '
            '${reason ?? 'خستگی / ریکاوری پایین'}',
    };
  }

  /// Soft-refuse removing a key lift without a real constraint.
  static ProgramModifyCoachDecision? softRefuseRemove({
    required String? exerciseName,
    required String? reasonId,
    bool? compound,
  }) {
    if (!isKeyLift(exerciseName, compound: compound)) return null;
    if (isProtectedReason(reasonId)) return null;

    final name = (exerciseName ?? 'این حرکت').trim();
    return ProgramModifyCoachDecision(
      softRefused: true,
      title: 'حذف نمی‌کنم',
      message:
          '«$name» حرکت اصلی برنامه‌ات است. بدون درد یا کمبود تجهیزات، '
          'حذفش جلسه را ناقص می‌کند.\n\n'
          'بهتر است جایگزین بگیریم یا فقط ست‌ها را کم کنیم. '
          'اگر آسیب داری، همان را به‌عنوان دلیل بگو.',
      tips: const <String>[
        'جایگزین حرکت را با دلیل درد یا تجهیزات امتحان کن',
        'یا فقط «کم کردن ست» را بزن',
      ],
      suggestedGoals: const <ProgramModifyGoal>[
        ProgramModifyGoal.replaceExercise,
        ProgramModifyGoal.reduceVolume,
        ProgramModifyGoal.injuryAdapt,
      ],
    );
  }

  /// Soft-refuse weak reasons on key lifts for replace (e.g. boring).
  static ProgramModifyCoachDecision? softRefuseWeakReplace({
    required String? exerciseName,
    required String? reasonId,
    bool? compound,
  }) {
    if (!isKeyLift(exerciseName, compound: compound)) return null;
    if (reasonId != 'boring') return null;

    final name = (exerciseName ?? 'این حرکت').trim();
    return ProgramModifyCoachDecision(
      softRefused: true,
      title: 'فقط برای حوصله عوضش نمی‌کنم',
      message:
          '«$name» حرکت اصلی است. فقط چون خسته‌کننده است معمولاً عوضش نمی‌کنم.\n\n'
          'اگر درد داری یا تجهیزات نداری بگو تا جایگزین بدهم؛ '
          'وگرنه با کم‌کردن ست همان الگو را نگه می‌داریم.',
      tips: const <String>[
        'دلیل را به درد یا کمبود تجهیزات تغییر بده',
        'یا «کم کردن ست» را انتخاب کن',
      ],
      suggestedGoals: const <ProgramModifyGoal>[
        ProgramModifyGoal.replaceExercise,
        ProgramModifyGoal.reduceVolume,
      ],
    );
  }

  /// Decision text only — do not dump change lists here (UI shows them once).
  static String decisionMessage({
    required ProgramModifyGoal goal,
    String? reasonLabel,
    String? afterName,
    int replaceCount = 0,
    bool volumeReduced = false,
  }) {
    final reason = (reasonLabel != null && reasonLabel.isNotEmpty)
        ? 'به‌خاطر $reasonLabel، '
        : '';

    return switch (goal) {
      ProgramModifyGoal.replaceExercise =>
        '${reason}جایگزین مناسب گذاشتم'
            '${afterName != null && afterName.isNotEmpty ? ': «$afterName»' : ''}. '
            'با تأیید، روی برنامه ذخیره می‌شود.',
      ProgramModifyGoal.removeExercise =>
        '${reason}حرکت را طوری حذف کردم که جلسه خالی نماند. '
            'با تأیید ذخیره می‌شود.',
      ProgramModifyGoal.reduceVolume =>
        '${reason}ست‌ها را کمی کم کردم تا جلسه سبک‌تر شود.',
      ProgramModifyGoal.increaseVolume =>
        '${reason}ست‌ها را کمی زیاد کردم؛ اگر فرم خراب شد وزنه را کم کن.',
      ProgramModifyGoal.easierSession =>
        '${reason}جلسه را سبک‌تر کردم؛ هدف اصلی حفظ شد.',
      ProgramModifyGoal.harderSession =>
        '${reason}جلسه را کمی سنگین‌تر کردم. فرم را فدای وزنه نکن.',
      ProgramModifyGoal.shorterSession =>
        '${reason}جلسه را کوتاه‌تر کردم و حرکت‌های اصلی ماندند.',
      ProgramModifyGoal.homeVersion =>
        '${reason}فقط همان روز انتخاب‌شده را برای خانه تطبیق دادم '
            '(دمبل / کش / وزن بدن). دستگاه و سیم‌کش برای خانه نیست.',
      ProgramModifyGoal.injuryAdapt =>
        '${reason}اولویت با ایمنی بود؛ حرکات پرریسک سبک یا عوض شدند.',
      ProgramModifyGoal.tiredAdapt =>
        '${reason}جلسه را سبک‌تر کردم: از حرکت‌ها حدود ۱ ست کم شد. '
            'حرکت‌ها عوض نشدند.',
    };
  }

  static List<String> coachingTips({
    required ProgramModifyGoal goal,
    String? reasonId,
  }) {
    return switch (goal) {
      ProgramModifyGoal.replaceExercise => <String>[
          if (reasonId == 'pain')
            'اگر درد تیز بود، همان جلسه را قطع کن.',
          'دو ست اول را سبک‌تر بزن تا فرم جا بیفتد.',
        ],
      ProgramModifyGoal.removeExercise => <String>[
          'بعد از حذف، روی فرم حرکت‌های باقی‌مانده تمرکز کن.',
        ],
      ProgramModifyGoal.reduceVolume ||
      ProgramModifyGoal.easierSession ||
      ProgramModifyGoal.tiredAdapt => <String>[
          'امروز کیفیت ست مهم‌تر از رکورد است.',
          if (reasonId == 'sleep') 'امشب زودتر بخواب تا فردا بهتر برگردی.',
        ],
      ProgramModifyGoal.increaseVolume || ProgramModifyGoal.harderSession =>
        <String>[
          'اگر فرم خراب شد، وزنه را کم کن.',
        ],
      ProgramModifyGoal.injuryAdapt => <String>[
          'درد تیز علامت توقف است؛ دامنه دردناک را رد نکن.',
        ],
      _ => <String>[
          'بعد از تأیید، تغییر روی خود برنامه می‌ماند.',
        ],
    };
  }

  static String aiAdvicePrompt({
    required ProgramModifyGoal goal,
    required String programName,
    String? exerciseName,
    String? reasonLabel,
    String? outcomeSummary,
    bool softRefused = false,
  }) {
    return '''
تو مربی بدنسازی فارسی‌زبان GymAI هستی.
فقط فارسی بنویس. هیچ کلمه انگلیسی ننویس.
حداکثر ۲ جمله کوتاه و واضح.
کاربر: ${goal.label}
برنامه: $programName
حرکت: ${exerciseName ?? '—'}
دلیل: ${reasonLabel ?? '—'}
نتیجه: ${softRefused ? 'رد نرم' : (outcomeSummary ?? 'پیشنهاد آماده')}
اگر رد نرم است یک پیشنهاد جایگزین بده. لحن گرم و قاطع.
''';
  }
}

class ProgramModifyCoachDecision {
  const ProgramModifyCoachDecision({
    required this.softRefused,
    required this.title,
    required this.message,
    this.tips = const <String>[],
    this.suggestedGoals = const <ProgramModifyGoal>[],
  });

  final bool softRefused;
  final String title;
  final String message;
  final List<String> tips;
  final List<ProgramModifyGoal> suggestedGoals;
}
