import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/workout_questionnaire/models/workout_questionnaire_models.dart';

/// سرویس بارگذاری سوال‌های پرسشنامه از فایل JSON محلی
class QuestionnaireQuestionsService {
  factory QuestionnaireQuestionsService() => _instance;
  QuestionnaireQuestionsService._internal();
  static final QuestionnaireQuestionsService _instance =
      QuestionnaireQuestionsService._internal();

  List<WorkoutQuestion>? _cachedQuestions;

  /// دریافت همه سوالات از فایل JSON
  ///
  /// نکته: برای اینکه تغییرات فایل JSON حین توسعه سریع دیده شود، در حالت Debug
  /// cache نادیده گرفته می‌شود (یا با forceReload=true).
  Future<List<WorkoutQuestion>> getQuestions({bool forceReload = false}) async {
    final shouldBypassCache = forceReload || kDebugMode;

    // استفاده از cache در صورت وجود (فقط در Release/Profile)
    if (!shouldBypassCache && _cachedQuestions != null) {
      debugPrint('بازگشت سوالات از cache: ${_cachedQuestions!.length} سوال');
      return _cachedQuestions!;
    }

    try {
      debugPrint('شروع بارگذاری سوالات از فایل JSON...');

      // خواندن فایل JSON از assets
      final jsonString = await rootBundle.loadString(
        'lib/workout_questionnaire/data/workout_questions.json',
      );

      // تبدیل JSON به لیست
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

      // تبدیل به WorkoutQuestion
      final questions = jsonList
          .map(
            (json) => WorkoutQuestion.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      // مرتب‌سازی بر اساس order_index
      questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      // ذخیره در cache (فقط وقتی از cache استفاده می‌کنیم)
      if (!shouldBypassCache) {
        _cachedQuestions = questions;
      }

      debugPrint(
        'تعداد سوالات بارگذاری شده: ${questions.length} | firstId: ${questions.isNotEmpty ? questions.first.id : '-'}',
      );
      return questions;
    } catch (e) {
      debugPrint('خطا در بارگذاری سوالات از JSON: $e');
      return [];
    }
  }

  /// دریافت سوالات بر اساس دسته‌بندی
  Future<List<WorkoutQuestion>> getQuestionsByCategory(String category) async {
    final allQuestions = await getQuestions();
    return allQuestions.where((q) => q.category == category).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  /// پاک کردن cache (برای تست یا بروزرسانی)
  void clearCache() {
    _cachedQuestions = null;
    debugPrint('Cache سوالات پاک شد');
  }
}
