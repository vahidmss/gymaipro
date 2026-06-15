import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyWeightService {
  static const String _tableName = 'weekly_weight_records';

  // بررسی اینکه آیا کاربر امروز وزنی ثبت کرده یا نه (همان روز)
  static Future<Map<String, dynamic>?> _getTodayRecord(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('recorded_at', startOfDay.toIso8601String())
          .lt('recorded_at', endOfDay.toIso8601String())
          .maybeSingle();

      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      debugPrint('خطا در بررسی رکورد امروز: $e');
      return null;
    }
  }

  // ثبت وزن: اگر امروز رکوردی وجود داشته باشد، همان رکورد به‌روزرسانی می‌شود؛ در غیر این صورت رکورد جدید درج می‌شود
  static Future<bool> recordWeeklyWeight(String userId, double weight) async {
    try {
      final now = DateTime.now();

      final todayRecord = await _getTodayRecord(userId);
      if (todayRecord != null) {
        // به‌روزرسانی رکورد امروز
        final String recordId = todayRecord['id'] as String;
        await Supabase.instance.client
            .from(_tableName)
            .update({
              'weight': weight,
              'recorded_at': now.toIso8601String(),
              'week_number': _getWeekNumber(now),
              'year': now.year,
            })
            .eq('id', recordId);
        debugPrint('وزن امروز به‌روزرسانی شد: $weight');
      } else {
        // درج رکورد جدید
        await Supabase.instance.client.from(_tableName).insert({
          'user_id': userId,
          'weight': weight,
          'recorded_at': now.toIso8601String(),
          'week_number': _getWeekNumber(now),
          'year': now.year,
        });
        debugPrint(
          'وزن جدید به تاریخچه اضافه شد: $weight در تاریخ ${now.toIso8601String()}',
        );
      }

      // به‌روزرسانی وزن در جدول پروفایل (همیشه پروفایل جاری)
      await _updateProfileWeight(weight);
      return true;
    } catch (e) {
      debugPrint('خطا در ثبت وزن هفتگی: $e');
      return false;
    }
  }

  // به‌روزرسانی وزن در جدول پروفایل
  static Future<void> _updateProfileWeight(double weight) async {
    try {
      await SimpleProfileService.updateProfile({'weight': weight});

      debugPrint('وزن در جدول پروفایل به‌روزرسانی شد: $weight');
    } catch (e) {
      debugPrint('خطا در به‌روزرسانی وزن در پروفایل: $e');
    }
  }

  // دریافت تمام تاریخچه وزن (برای نمودار)
  static Future<List<Map<String, dynamic>>> getFullWeightHistory(
    String userId,
  ) async {
    try {
      // بررسی اینکه userId خالی نباشد
      if (userId.isEmpty) {
        debugPrint('خطا: userId خالی است');
        return [];
      }

      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: true); // از قدیم به جدید

      debugPrint('تاریخچه کامل وزن: ${response.length} رکورد');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطا در دریافت تاریخچه کامل وزن: $e');
      return [];
    }
  }

  // دریافت تاریخچه وزن هفتگی (آخرین 12 هفته)
  static Future<List<Map<String, dynamic>>> getWeeklyWeightHistory(
    String userId, {
    int weeks = 12,
  }) async {
    try {
      // بازگرداندن تمام رکوردها (محدودیت دلخواه سمت UI فیلتر می‌شود)
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطا در دریافت تاریخچه وزن هفتگی: $e');
      return [];
    }
  }

  // دریافت آخرین وزن ثبت شده
  static Future<double?> getLatestWeight(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select('weight')
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return (response.first['weight'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      debugPrint('خطا در دریافت آخرین وزن: $e');
      return null;
    }
  }

  // دریافت آخرین تاریخ ثبت وزن
  static Future<DateTime?> getLastRecordDate(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select('recorded_at')
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return DateTime.parse(response.first['recorded_at'] as String);
      }
      return null;
    } catch (e) {
      debugPrint('خطا در دریافت آخرین تاریخ ثبت: $e');
      return null;
    }
  }

  // محاسبه روزهای باقی‌مانده تا ثبت بعدی
  static Future<int> getDaysUntilNextRecord(String userId) async {
    try {
      final lastRecordDate = await getLastRecordDate(userId);
      if (lastRecordDate == null) {
        return 0; // اگر قبلاً ثبت نکرده، الان می‌تونه ثبت کنه
      }

      final now = DateTime.now();
      final daysSinceLastRecord = now.difference(lastRecordDate).inDays;

      if (daysSinceLastRecord >= 7) {
        return 0; // 7 روز گذشته، الان می‌تونه ثبت کنه
      } else {
        return 7 - daysSinceLastRecord; // روزهای باقی‌مانده
      }
    } catch (e) {
      debugPrint('خطا در محاسبه روزهای باقی‌مانده: $e');
      return 0;
    }
  }

  // بررسی اینکه آیا کاربر الان می‌تونه وزن ثبت کنه
  static Future<bool> canRecordNow(String userId) async {
    final daysUntilNext = await getDaysUntilNextRecord(userId);
    return daysUntilNext == 0;
  }

  // محاسبه روند وزن (کاهش، افزایش، ثابت)
  static String calculateWeightTrend(List<Map<String, dynamic>> weightHistory) {
    if (weightHistory.length < 2) return 'ثابت';

    final latest = weightHistory.first['weight'] as double;
    final previous = weightHistory[1]['weight'] as double;
    final difference = latest - previous;

    if (difference > 0.5) return 'افزایش';
    if (difference < -0.5) return 'کاهش';
    return 'ثابت';
  }

  // دریافت آمار وزن
  static Future<Map<String, dynamic>> getWeightStats(String userId) async {
    try {
      final history = await getFullWeightHistory(userId);
      if (history.isEmpty) {
        return {
          'total_records': 0,
          'average_weight': 0.0,
          'min_weight': 0.0,
          'max_weight': 0.0,
          'trend': 'ثابت',
        };
      }

      final weights = history
          .map((record) => record['weight'] as double)
          .toList();
      final average = weights.reduce((a, b) => a + b) / weights.length;
      final min = weights.reduce((a, b) => a < b ? a : b);
      final max = weights.reduce((a, b) => a > b ? a : b);

      return {
        'total_records': history.length,
        'average_weight': average,
        'min_weight': min,
        'max_weight': max,
        'trend': calculateWeightTrend(history.reversed.toList()),
      };
    } catch (e) {
      debugPrint('خطا در محاسبه آمار وزن: $e');
      return {
        'total_records': 0,
        'average_weight': 0.0,
        'min_weight': 0.0,
        'max_weight': 0.0,
        'trend': 'ثابت',
      };
    }
  }

  // حذف رکورد وزن (برای مدیریت)
  static Future<bool> deleteWeightRecord(String userId, String recordId) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .delete()
          .eq('id', recordId)
          .eq('user_id', userId);

      debugPrint('رکورد وزن حذف شد: $recordId');
      return true;
    } catch (e) {
      debugPrint('خطا در حذف رکورد وزن: $e');
      return false;
    }
  }

  // محاسبه شماره هفته
  static int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year);
    final daysSinceStart = date.difference(startOfYear).inDays;
    return ((daysSinceStart + startOfYear.weekday - 1) / 7).ceil();
  }
}
