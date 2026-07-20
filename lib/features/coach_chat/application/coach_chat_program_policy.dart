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

  /// اگر intent اشتباه تشخیص داده شد، از روی متن کاربر هم قفل می‌کنیم.
  static bool looksLikeProgramRequest(String message) {
    final text = message.trim().toLowerCase();
    if (text.isEmpty) return false;

    const needles = <String>[
      'برنامه تمرینی',
      'برنامه تمرین',
      'برنامه ورزشی',
      'برنامه بدنسازی',
      'برام برنامه بساز',
      'برای من برنامه بساز',
      'برنامه برام بساز',
      'برنامه بده',
      'برنامه بساز',
      'workout plan',
      'training plan',
      'make me a program',
      'برنامه غذایی',
      'رژیم غذایی',
      'رژیم لاغری',
      'رژیم چاقی',
      'رژیم بده',
      'رژیم بساز',
      'meal plan',
      'diet plan',
      'برنامه تغذیه',
      'برنامه رژیم',
      'یه برنامه برام',
      'یک برنامه برام',
    ];

    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }

    final hasProgram = text.contains('برنامه') || text.contains('plan');
    if (!hasProgram) return false;
    return text.contains('تمرین') ||
        text.contains('ورزش') ||
        text.contains('غذا') ||
        text.contains('رژیم') ||
        text.contains('تغذیه') ||
        text.contains('workout') ||
        text.contains('diet') ||
        text.contains('meal') ||
        text.contains('بساز') ||
        text.contains('بده');
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
