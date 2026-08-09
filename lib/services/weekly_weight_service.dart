import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyWeightService {
  static const String _tableName = 'weekly_weight_records';

  /// ارقام فارسی/عربی و جداکننده اعشار محلی را برای [double.tryParse] نرمال می‌کند.
  static double? parseWeightInput(String raw) {
    final normalized = _normalizeNumericInput(raw);
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || value <= 0 || value >= 1000) return null;
    return value;
  }

  static String _normalizeNumericInput(String raw) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in raw.trim().runes) {
      final char = String.fromCharCode(rune);
      final p = persian.indexOf(char);
      if (p >= 0) {
        buffer.write(p);
        continue;
      }
      final a = arabic.indexOf(char);
      if (a >= 0) {
        buffer.write(a);
        continue;
      }
      if (char == '٫' || char == ',' || char == '/') {
        buffer.write('.');
        continue;
      }
      if (char == '٬' || char == ' ' || char == '\u00A0') {
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  /// `weekly_weight_records.user_id` به `auth.users(id)` اشاره دارد (نه لزوماً profiles.id).
  /// هرگز [SimpleProfileService.getCurrentProfile] را صدا نزن — خطر بن‌بست با `_inFlightProfile`.
  static Future<String?> resolveAuthUserId(String? profileOrAuthId) async {
    final authId = Supabase.instance.client.auth.currentUser?.id;
    final passed = profileOrAuthId?.trim();
    if (passed == null || passed.isEmpty) return authId;
    if (authId != null && passed == authId) return authId;

    final cached = SimpleProfileService.peekCachedProfile();
    if (cached != null && cached['id']?.toString() == passed) {
      final linked = cached['auth_user_id']?.toString().trim();
      if (linked != null && linked.isNotEmpty) return linked;
      if (authId != null) return authId;
    }

    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('auth_user_id')
          .eq('id', passed)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));
      final linked = row?['auth_user_id']?.toString().trim();
      if (linked != null && linked.isNotEmpty) return linked;
    } catch (e) {
      debugPrint('خطا در تبدیل profile→auth برای وزن: $e');
    }

    // برای کاربر جاری همیشه auth.uid را ترجیح بده
    return authId ?? passed;
  }

  // بررسی اینکه آیا کاربر امروز وزنی ثبت کرده یا نه (همان روز محلی)
  static Future<Map<String, dynamic>?> _getTodayRecord(String authUserId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', authUserId)
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

  /// ثبت وزن برای کاربر جاری.
  /// [userId] می‌تواند profiles.id یا auth.users.id باشد؛ ذخیره همیشه با auth.uid() است.
  static Future<bool> recordWeeklyWeight(String userId, double weight) async {
    final result = await recordWeeklyWeightDetailed(userId, weight);
    return result.success;
  }

  static Future<WeightSaveResult> recordWeeklyWeightDetailed(
    String userId,
    double weight,
  ) async {
    if (weight <= 0 || weight >= 1000) {
      return const WeightSaveResult(
        success: false,
        message: 'وزن واردشده معتبر نیست.',
      );
    }

    try {
      // ثبت همیشه برای نشست جاری — بدون resolve پیچیده / بدون getCurrentProfile
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      if (authUserId == null || authUserId.isEmpty) {
        return const WeightSaveResult(
          success: false,
          message: 'نشست کاربری معتبر نیست. دوباره وارد شوید.',
        );
      }
      if (userId.isNotEmpty &&
          userId != authUserId &&
          SimpleProfileService.peekCachedProfile()?['id']?.toString() !=
              userId) {
        debugPrint(
          'recordWeeklyWeight: caller id=$userId ≠ auth=$authUserId — using auth',
        );
      }

      final now = DateTime.now();
      final todayRecord = await _getTodayRecord(authUserId)
          .timeout(const Duration(seconds: 8));
      if (todayRecord != null) {
        final String recordId = todayRecord['id'] as String;
        await Supabase.instance.client
            .from(_tableName)
            .update({
              'weight': weight,
              'recorded_at': now.toIso8601String(),
              'week_number': _getWeekNumber(now),
              'year': now.year,
            })
            .eq('id', recordId)
            .eq('user_id', authUserId)
            .timeout(const Duration(seconds: 8));
        debugPrint('وزن امروز به‌روزرسانی شد: $weight (auth=$authUserId)');
      } else {
        await Supabase.instance.client
            .from(_tableName)
            .insert({
              'user_id': authUserId,
              'weight': weight,
              'recorded_at': now.toIso8601String(),
              'week_number': _getWeekNumber(now),
              'year': now.year,
            })
            .timeout(const Duration(seconds: 8));
        debugPrint(
          'وزن جدید ثبت شد: $weight در ${now.toIso8601String()} (auth=$authUserId)',
        );
      }

      await _updateProfileWeight(weight);
      return const WeightSaveResult(success: true);
    } on TimeoutException {
      debugPrint('Timeout در ثبت وزن هفتگی');
      return const WeightSaveResult(
        success: false,
        message: 'زمان ثبت وزن تمام شد. اتصال را بررسی کنید.',
      );
    } on PostgrestException catch (e) {
      debugPrint(
        'خطا در ثبت وزن هفتگی (Postgrest): ${e.message} code=${e.code}',
      );
      return WeightSaveResult(
        success: false,
        message: _friendlyDbError(e),
      );
    } catch (e) {
      debugPrint('خطا در ثبت وزن هفتگی: $e');
      return WeightSaveResult(
        success: false,
        message: 'ثبت وزن انجام نشد. دوباره تلاش کنید.',
      );
    }
  }

  static String _friendlyDbError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('row-level security') || e.code == '42501') {
      return 'دسترسی ثبت وزن برقرار نیست. دوباره وارد شوید.';
    }
    if (msg.contains('foreign key') || e.code == '23503') {
      return 'شناسه کاربر با جدول وزن هم‌خوان نیست.';
    }
    if (msg.contains('does not exist') || e.code == '42P01') {
      return 'جدول ثبت وزن در سرور موجود نیست.';
    }
    return 'ثبت وزن انجام نشد. دوباره تلاش کنید.';
  }

  static Future<void> _updateProfileWeight(double weight) async {
    try {
      await SimpleProfileService.updateProfile({'weight': weight});
      debugPrint('وزن در جدول پروفایل به‌روزرسانی شد: $weight');
    } catch (e) {
      debugPrint('خطا در به‌روزرسانی وزن در پروفایل: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getFullWeightHistory(
    String userId,
  ) async {
    try {
      if (userId.isEmpty) {
        debugPrint('خطا: userId خالی است');
        return [];
      }

      final authUserId = await resolveAuthUserId(userId);
      if (authUserId == null || authUserId.isEmpty) return [];

      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', authUserId)
          .order('recorded_at', ascending: true);

      debugPrint(
        'تاریخچه کامل وزن: ${response.length} رکورد (auth=$authUserId)',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطا در دریافت تاریخچه کامل وزن: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getWeeklyWeightHistory(
    String userId, {
    int weeks = 12,
  }) async {
    try {
      final authUserId = await resolveAuthUserId(userId);
      if (authUserId == null || authUserId.isEmpty) return [];

      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', authUserId)
          .order('recorded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('خطا در دریافت تاریخچه وزن هفتگی: $e');
      return [];
    }
  }

  static Future<double?> getLatestWeight(String userId) async {
    try {
      final authUserId = await resolveAuthUserId(userId);
      if (authUserId == null || authUserId.isEmpty) return null;

      final response = await Supabase.instance.client
          .from(_tableName)
          .select('weight')
          .eq('user_id', authUserId)
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

  static Future<DateTime?> getLastRecordDate(String userId) async {
    try {
      final authUserId = await resolveAuthUserId(userId);
      if (authUserId == null || authUserId.isEmpty) return null;

      final response = await Supabase.instance.client
          .from(_tableName)
          .select('recorded_at')
          .eq('user_id', authUserId)
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

  static Future<int> getDaysUntilNextRecord(String userId) async {
    try {
      final lastRecordDate = await getLastRecordDate(userId);
      if (lastRecordDate == null) {
        return 0;
      }

      final now = DateTime.now();
      final daysSinceLastRecord = now.difference(lastRecordDate).inDays;

      if (daysSinceLastRecord >= 7) {
        return 0;
      } else {
        return 7 - daysSinceLastRecord;
      }
    } catch (e) {
      debugPrint('خطا در محاسبه روزهای باقی‌مانده: $e');
      return 0;
    }
  }

  static Future<bool> canRecordNow(String userId) async {
    final daysUntilNext = await getDaysUntilNextRecord(userId);
    return daysUntilNext == 0;
  }

  static String calculateWeightTrend(List<Map<String, dynamic>> weightHistory) {
    if (weightHistory.length < 2) return 'ثابت';

    final latest = weightHistory.first['weight'] as double;
    final previous = weightHistory[1]['weight'] as double;
    final difference = latest - previous;

    if (difference > 0.5) return 'افزایش';
    if (difference < -0.5) return 'کاهش';
    return 'ثابت';
  }

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
          .map((record) => (record['weight'] as num).toDouble())
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

  static Future<bool> deleteWeightRecord(String userId, String recordId) async {
    try {
      final authUserId = await resolveAuthUserId(userId);
      if (authUserId == null || authUserId.isEmpty) return false;

      await Supabase.instance.client
          .from(_tableName)
          .delete()
          .eq('id', recordId)
          .eq('user_id', authUserId);

      debugPrint('رکورد وزن حذف شد: $recordId');
      return true;
    } catch (e) {
      debugPrint('خطا در حذف رکورد وزن: $e');
      return false;
    }
  }

  static int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year);
    final daysSinceStart = date.difference(startOfYear).inDays;
    return ((daysSinceStart + startOfYear.weekday - 1) / 7).ceil();
  }
}

class WeightSaveResult {
  const WeightSaveResult({required this.success, this.message});

  final bool success;
  final String? message;
}
