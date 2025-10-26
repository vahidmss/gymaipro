import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/workout_plan/models/workout_questionnaire_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutQuestionnaireService {
  factory WorkoutQuestionnaireService() => _instance;
  WorkoutQuestionnaireService._internal();
  static final WorkoutQuestionnaireService _instance =
      WorkoutQuestionnaireService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// دریافت همه سوالات پرسشنامه
  Future<List<WorkoutQuestion>> getQuestions() async {
    try {
      debugPrint('شروع دریافت سوالات پرسشنامه...');

      // تست دسترسی مستقیم به جدول
      try {
        final testResponse = await _client
            .from('workout_questionnaire_questions')
            .select('id, question_text')
            .limit(1);
        debugPrint('تست دسترسی موفق: ${testResponse.length} سوال');
        if (testResponse.isNotEmpty) {
          debugPrint('اولین سوال تست: ${testResponse.first['question_text']}');
        }
      } catch (testError) {
        debugPrint('خطا در تست دسترسی: $testError');
        debugPrint('نوع خطا: ${testError.runtimeType}');
        if (testError.toString().contains('RLS')) {
          debugPrint('مشکل RLS: سوالات قابل دسترسی نیستند');
        }
      }

      final response = await _client
          .from('workout_questionnaire_questions')
          .select()
          .order('order_index');

      debugPrint('تعداد سوالات دریافت شده: ${response.length}');
      if (response.isNotEmpty) {
        debugPrint('اولین سوال: ${response.first['question_text']}');
      }
      return response.map(WorkoutQuestion.fromJson).toList();
    } catch (e) {
      debugPrint('خطا در دریافت سوالات: $e');
      debugPrint('نوع خطا: ${e.runtimeType}');
      if (e.toString().contains('RLS')) {
        debugPrint('مشکل RLS: سوالات قابل دسترسی نیستند');
      }
      return [];
    }
  }

  /// دریافت سوالات بر اساس دسته‌بندی
  Future<List<WorkoutQuestion>> getQuestionsByCategory(String category) async {
    try {
      final response = await _client
          .from('workout_questionnaire_questions')
          .select()
          .eq('category', category)
          .order('order_index');

      return response.map(WorkoutQuestion.fromJson).toList();
    } catch (e) {
      debugPrint('خطا در دریافت سوالات دسته $category: $e');
      return [];
    }
  }

  /// دریافت پاسخ‌های کاربر
  Future<Map<String, WorkoutQuestionResponse>> getUserResponses(
    String userId,
  ) async {
    try {
      debugPrint('دریافت پاسخ‌های کاربر: $userId');

      final response = await _client
          .from('workout_questionnaire_responses')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('هیچ پاسخی برای کاربر یافت نشد');
        return {};
      }

      debugPrint('پاسخ‌های خام از دیتابیس: ${response.keys.toList()}');

      // بررسی وجود responses_json
      if (response['responses_json'] == null) {
        debugPrint('فیلد responses_json موجود نیست');
        return {};
      }

      final responsesJson = response['responses_json'] as Map<String, dynamic>;
      debugPrint('تعداد پاسخ‌های ذخیره شده: ${responsesJson.length}');
      debugPrint('کلیدهای پاسخ‌ها: ${responsesJson.keys.toList()}');

      // تبدیل به WorkoutQuestionResponse
      final responses = <String, WorkoutQuestionResponse>{};
      for (final entry in responsesJson.entries) {
        try {
          final responseData = entry.value as Map<String, dynamic>;
          responses[entry.key] = WorkoutQuestionResponse.fromJson(responseData);
        } catch (e) {
          debugPrint('خطا در پردازش پاسخ ${entry.key}: $e');
        }
      }

      debugPrint('پاسخ‌های پردازش شده: ${responses.keys.toList()}');
      return responses;
    } catch (e) {
      debugPrint('خطا در دریافت پاسخ‌های کاربر: $e');
      return {};
    }
  }

  /// ذخیره پاسخ کاربر (تک سوال) - نسخه امن
  Future<bool> saveResponse(
    String userId,
    String questionId,
    dynamic answer, {
    String? sessionId,
  }) async {
    try {
      debugPrint('شروع ذخیره پاسخ برای سوال: $questionId, پاسخ: $answer');

      // ایجاد پاسخ جدید
      final newResponse = WorkoutQuestionResponse(
        questionId: questionId,
        answerText: answer is String ? answer : null,
        answerNumber: answer is double ? answer : null,
        answerChoices: answer is List<String> ? answer : null,
      );

      // ذخیره مستقیم در دیتابیس بدون race condition
      final result = await _saveSingleResponseSafely(
        userId,
        newResponse,
        sessionId,
      );

      if (result) {
        debugPrint('پاسخ با موفقیت ذخیره شد: $questionId');
      } else {
        debugPrint('خطا در ذخیره پاسخ: $questionId');
      }

      return result;
    } catch (e) {
      debugPrint('خطا در ذخیره پاسخ: $e');
      return false;
    }
  }

  /// ذخیره امن یک پاسخ بدون race condition
  Future<bool> _saveSingleResponseSafely(
    String userId,
    WorkoutQuestionResponse response,
    String? sessionId,
  ) async {
    try {
      // دریافت پاسخ‌های موجود از دیتابیس
      final existing = await _client
          .from('workout_questionnaire_responses')
          .select('responses_json')
          .eq('user_id', userId)
          .maybeSingle();

      Map<String, dynamic> responsesJson;

      if (existing != null) {
        // بارگذاری پاسخ‌های موجود
        responsesJson = Map<String, dynamic>.from(
          existing['responses_json'] as Map<String, dynamic>,
        );
        debugPrint(
          'پاسخ‌های موجود بارگذاری شدند: ${responsesJson.keys.toList()}',
        );
      } else {
        // ایجاد map جدید
        responsesJson = <String, dynamic>{};
        debugPrint('ایجاد map جدید برای پاسخ‌ها');
      }

      // اضافه کردن پاسخ جدید
      responsesJson[response.questionId] = response.toJson();
      debugPrint(
        'پاسخ جدید اضافه شد. تعداد کل پاسخ‌ها: ${responsesJson.length}',
      );

      // ذخیره در دیتابیس
      if (existing != null) {
        // بروزرسانی
        await _client
            .from('workout_questionnaire_responses')
            .update({
              'responses_json': responsesJson,
              'session_id': sessionId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
        debugPrint('رکورد بروزرسانی شد');
      } else {
        // ایجاد جدید
        await _client.from('workout_questionnaire_responses').insert({
          'user_id': userId,
          'responses_json': responsesJson,
          'session_id': sessionId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('رکورد جدید ایجاد شد');
      }

      return true;
    } catch (e) {
      debugPrint('خطا در ذخیره امن پاسخ: $e');
      return false;
    }
  }

  /// ذخیره تمام پاسخ‌های کاربر
  Future<bool> saveAllResponses(
    String userId,
    Map<String, WorkoutQuestionResponse> responses, {
    String? sessionId,
  }) async {
    try {
      debugPrint('شروع ذخیره ${responses.length} پاسخ برای کاربر: $userId');

      // تبدیل پاسخ‌ها به JSON
      final responsesJson = <String, dynamic>{};
      for (final entry in responses.entries) {
        responsesJson[entry.key] = entry.value.toJson();
      }
      debugPrint('پاسخ‌ها به JSON تبدیل شدند: ${responsesJson.keys.toList()}');

      // بررسی وجود رکورد
      final existing = await _client
          .from('workout_questionnaire_responses')
          .select('id, updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('بروزرسانی رکورد موجود با ID: ${existing['id']}');
        // بروزرسانی رکورد موجود
        await _client
            .from('workout_questionnaire_responses')
            .update({
              'responses_json': responsesJson,
              'session_id': sessionId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);

        debugPrint('رکورد بروزرسانی شد');
      } else {
        debugPrint('ایجاد رکورد جدید');
        // ایجاد رکورد جدید
        await _client.from('workout_questionnaire_responses').insert({
          'user_id': userId,
          'responses_json': responsesJson,
          'session_id': sessionId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('رکورد جدید ایجاد شد');
      }

      // تأیید ذخیره‌سازی با خواندن مجدد
      final verification = await _client
          .from('workout_questionnaire_responses')
          .select('responses_json')
          .eq('user_id', userId)
          .maybeSingle();

      if (verification != null) {
        final savedResponses =
            verification['responses_json'] as Map<String, dynamic>;
        debugPrint(
          'تأیید ذخیره‌سازی: ${savedResponses.keys.length} پاسخ ذخیره شد',
        );
        return true;
      } else {
        debugPrint('خطا در تأیید ذخیره‌سازی');
        return false;
      }
    } catch (e) {
      debugPrint('خطا در ذخیره پاسخ‌ها: $e');
      return false;
    }
  }

  /// ایجاد جلسه جدید پرسشنامه
  Future<WorkoutQuestionnaireSession?> createSession(String userId) async {
    try {
      final response = await _client
          .from('workout_questionnaire_sessions')
          .insert({
            'user_id': userId,
            'status': 'in_progress',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return WorkoutQuestionnaireSession.fromJson(response);
    } catch (e) {
      debugPrint('خطا در ایجاد جلسه: $e');
      return null;
    }
  }

  /// دریافت جلسه فعال کاربر
  Future<WorkoutQuestionnaireSession?> getActiveSession(String userId) async {
    try {
      final response = await _client
          .from('workout_questionnaire_sessions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'in_progress')
          .maybeSingle();

      if (response != null) {
        return WorkoutQuestionnaireSession.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('خطا در دریافت جلسه فعال: $e');
      return null;
    }
  }

  /// تکمیل جلسه پرسشنامه
  Future<bool> completeSession(String sessionId) async {
    try {
      await _client
          .from('workout_questionnaire_sessions')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      debugPrint('خطا در تکمیل جلسه: $e');
      return false;
    }
  }

  /// دریافت پرسشنامه کامل کاربر
  Future<WorkoutQuestionnaire?> getQuestionnaire(String userId) async {
    try {
      debugPrint('شروع دریافت پرسشنامه برای کاربر: $userId');
      final questions = await getQuestions();
      debugPrint('سوالات دریافت شد: ${questions.length}');

      final responses = await getUserResponses(userId);
      debugPrint('پاسخ‌ها دریافت شد: ${responses.length}');

      final session = await getActiveSession(userId);
      debugPrint('جلسه دریافت شد: ${session != null}');

      return WorkoutQuestionnaire(
        questions: questions,
        responses: responses,
        session: session,
      );
    } catch (e) {
      debugPrint('خطا در دریافت پرسشنامه: $e');
      return null;
    }
  }

  /// بررسی تکمیل بودن پرسشنامه کاربر
  Future<bool> isQuestionnaireCompleted(String userId) async {
    try {
      final response = await _client
          .from('workout_questionnaire_sessions')
          .select('status')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('خطا در بررسی تکمیل پرسشنامه: $e');
      return false;
    }
  }

  /// دریافت آمار پاسخ‌ها برای تحلیل
  Future<Map<String, dynamic>> getResponseStats(String userId) async {
    try {
      final questionnaire = await getQuestionnaire(userId);
      if (questionnaire == null) return {};

      final stats = <String, dynamic>{};

      // آمار کلی
      stats['total_questions'] = questionnaire.questions.length;
      stats['answered_questions'] = questionnaire.responses.length;
      stats['completion_percentage'] = questionnaire.completionPercentage;
      stats['is_completed'] = questionnaire.isCompleted;

      // آمار بر اساس دسته‌بندی
      final categoryStats = <String, Map<String, int>>{};
      for (final question in questionnaire.questions) {
        if (!categoryStats.containsKey(question.category)) {
          categoryStats[question.category] = {'total': 0, 'answered': 0};
        }
        categoryStats[question.category]!['total'] =
            (categoryStats[question.category]!['total'] ?? 0) + 1;

        if (questionnaire.responses.containsKey(question.id)) {
          categoryStats[question.category]!['answered'] =
              (categoryStats[question.category]!['answered'] ?? 0) + 1;
        }
      }
      stats['category_stats'] = categoryStats;

      return stats;
    } catch (e) {
      debugPrint('خطا در دریافت آمار: $e');
      return {};
    }
  }
}
