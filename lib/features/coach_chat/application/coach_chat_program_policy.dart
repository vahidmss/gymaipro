import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

/// چت جای ساخت/تحویل برنامه تمرینی یا غذایی کامل نیست.
abstract final class CoachChatProgramPolicy {
  const CoachChatProgramPolicy._();

  /// پاسخ ثابت برای هر درخواست ساخت برنامه داخل چت.
  static String get redirectMessage => ProductCopy.chatNoProgramRedirect;

  static bool isWorkoutGenerationIntent(AIIntent? intent) =>
      intent == AIIntent.workoutGeneration;

  static bool isWorkoutGenerationKnowledge(String? knowledgeId) =>
      knowledgeId == 'workout_generation';

  /// نشانه‌های سوال مشورتی — کاربر نظر می‌خواهد، نه تحویل برنامه.
  ///
  /// مثال: «به نظرت من رژیم می‌خوام؟» باید جواب مشاوره‌ای بگیرد،
  /// نه پیام «برنامه داخل چت نمی‌دهیم».
  static const List<String> _consultativeMarkers = <String>[
    'به نظرت',
    'به نظر تو',
    'به نظر شما',
    'نظرت چیه',
    'نظرت چی',
    'فکر می‌کنی',
    'فکر میکنی',
    'فک می‌کنی',
    'فک میکنی',
    'آیا من',
    'ایا من',
    'لازم دارم',
    'لازمه',
    'نیاز دارم',
    'نیازه',
    'احتیاج دارم',
    'بهتره که',
    'خوبه که',
    'do i need',
    'should i',
  ];

  /// فعل‌های ساخت/تحویل — نشانهٔ قطعی درخواست برنامه.
  static const List<String> _buildVerbs = <String>[
    'بساز',
    'بده',
    'بنویس',
    'بچین',
    'طراحی کن',
    'تنظیم کن',
    'آماده کن',
    'اماده کن',
    'درست کن',
    'make me',
    'create',
    'write me',
    'give me',
  ];

  /// اگر intent اشتباه تشخیص داده شد، از روی متن کاربر هم قفل می‌کنیم.
  static bool looksLikeProgramRequest(String message) {
    final text = message.trim().toLowerCase();
    if (text.isEmpty) return false;

    final hasBuildVerb = _containsAny(text, _buildVerbs);

    // سوال مشورتی بدون فعل ساخت → مشاوره است، بلاک نکن.
    if (!hasBuildVerb && _containsAny(text, _consultativeMarkers)) {
      return false;
    }

    const planNouns = <String>[
      'برنامه تمرینی',
      'برنامه تمرین',
      'برنامه ورزشی',
      'برنامه بدنسازی',
      'برنامه غذایی',
      'برنامه تغذیه',
      'برنامه رژیم',
      'رژیم غذایی',
      'رژیم لاغری',
      'رژیم چاقی',
      'رژیم',
      'برنامه',
      'workout plan',
      'training plan',
      'meal plan',
      'diet plan',
      'program',
      'plan',
    ];

    // فعل ساخت + اسم برنامه/رژیم → درخواست تحویل برنامه.
    if (hasBuildVerb && _containsAny(text, planNouns)) return true;

    // درخواست‌های صریح بدون فعل ساخت.
    const explicitRequests = <String>[
      'برام برنامه',
      'برای من برنامه',
      'یه برنامه برام',
      'یک برنامه برام',
      'یه برنامه کامل',
      'یک برنامه کامل',
      'برنامه شخصی',
      'می‌خوام برنامه',
      'میخوام برنامه',
      'برنامه می‌خوام',
      'برنامه میخوام',
      'رژیم می‌خوام',
      'رژیم میخوام',
      'می‌خوام رژیم',
      'میخوام رژیم',
      'make me a program',
    ];
    return _containsAny(text, explicitRequests);
  }

  static bool _containsAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }
    return false;
  }

  static bool shouldBlockChatProgramDelivery({
    AIIntent? intent,
    String? knowledgeId,
    String? userMessage,
  }) {
    if (isWorkoutGenerationIntent(intent) ||
        isWorkoutGenerationKnowledge(knowledgeId)) {
      return true;
    }
    if (userMessage != null && looksLikeProgramRequest(userMessage)) {
      return true;
    }
    // Intent تغذیه به تنهایی کافی نیست (نکته کوتاه OK)؛ فقط درخواست برنامه کامل.
    if (intent == AIIntent.nutrition || knowledgeId == 'nutrition') {
      return userMessage != null && looksLikeProgramRequest(userMessage);
    }
    return false;
  }
}
