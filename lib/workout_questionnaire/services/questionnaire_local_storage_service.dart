import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/workout_questionnaire/models/workout_questionnaire_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مدیریت ذخیره محلی پاسخ‌های پرسشنامه با SharedPreferences
class QuestionnaireLocalStorageService {
  factory QuestionnaireLocalStorageService() => _instance;
  QuestionnaireLocalStorageService._internal();
  static final QuestionnaireLocalStorageService _instance =
      QuestionnaireLocalStorageService._internal();

  static const String _keyPrefix = 'workout_questionnaire_responses_';

  /// دریافت کلید ذخیره‌سازی برای کاربر
  String _getStorageKey(String userId) => '$_keyPrefix$userId';

  /// ذخیره پاسخ‌ها در SharedPreferences
  Future<bool> saveResponses(
    String userId,
    Map<String, WorkoutQuestionResponse> responses,
  ) async {
    try {
      debugPrint('ذخیره ${responses.length} پاسخ در SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(userId);

      // تبدیل پاسخ‌ها به JSON
      final responsesJson = <String, dynamic>{};
      for (final entry in responses.entries) {
        responsesJson[entry.key] = entry.value.toJson();
      }

      // ذخیره به صورت JSON string
      final jsonString = jsonEncode(responsesJson);
      final success = await prefs.setString(key, jsonString);

      if (success) {
        debugPrint('پاسخ‌ها با موفقیت در SharedPreferences ذخیره شدند');
      } else {
        debugPrint('خطا در ذخیره پاسخ‌ها در SharedPreferences');
      }

      return success;
    } catch (e) {
      debugPrint('خطا در ذخیره پاسخ‌ها: $e');
      return false;
    }
  }

  /// دریافت پاسخ‌ها از SharedPreferences
  Future<Map<String, WorkoutQuestionResponse>> getResponses(
    String userId,
  ) async {
    try {
      debugPrint('دریافت پاسخ‌ها از SharedPreferences برای کاربر: $userId');
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(userId);

      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('هیچ پاسخی در SharedPreferences یافت نشد');
        return {};
      }

      // تبدیل JSON string به Map
      final responsesJson = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('تعداد پاسخ‌های یافت شده: ${responsesJson.length}');

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
      debugPrint('خطا در دریافت پاسخ‌ها: $e');
      return {};
    }
  }

  /// ذخیره یک پاسخ واحد
  Future<bool> saveSingleResponse(
    String userId,
    String questionId,
    WorkoutQuestionResponse response,
  ) async {
    try {
      // دریافت پاسخ‌های موجود
      final existingResponses = await getResponses(userId);

      // اضافه کردن پاسخ جدید
      existingResponses[questionId] = response;

      // ذخیره مجدد
      return await saveResponses(userId, existingResponses);
    } catch (e) {
      debugPrint('خطا در ذخیره پاسخ واحد: $e');
      return false;
    }
  }

  /// پاک کردن پاسخ‌های کاربر
  Future<bool> clearResponses(String userId) async {
    try {
      debugPrint('پاک کردن پاسخ‌های کاربر: $userId');
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(userId);
      return await prefs.remove(key);
    } catch (e) {
      debugPrint('خطا در پاک کردن پاسخ‌ها: $e');
      return false;
    }
  }

  /// بررسی وجود پاسخ‌های ذخیره شده
  Future<bool> hasResponses(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(userId);
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('خطا در بررسی وجود پاسخ‌ها: $e');
      return false;
    }
  }
}
