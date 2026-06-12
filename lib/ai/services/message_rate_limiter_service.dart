import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت محدودیت پیام‌های کاربر
class MessageRateLimiterService {
  static const String _dailyMessagesKey = 'ai_chat_daily_messages';
  static const String _lastResetDateKey = 'ai_chat_last_reset_date';
  static const String _featureName = 'ai_chat';
  static const String _usageType = 'daily';

  // محدودیت‌های پیش‌فرض
  static const int defaultDailyLimit = 10; // 10 پیام در روز

  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'user_feature_usage';

  /// بررسی امکان ارسال پیام
  Future<RateLimitResult> canSendMessage({int? dailyLimit}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int dailyMessages = 0;
      DateTime? lastResetDate;

      // تلاش برای دریافت از دیتابیس
      if (userId != null) {
        try {
          final response = await _supabase
              .from(_tableName)
              .select('usage_count, last_reset_date')
              .eq('user_id', userId)
              .eq('feature_name', _featureName)
              .eq('usage_type', _usageType)
              .maybeSingle();

          if (response != null) {
            dailyMessages = response['usage_count'] as int? ?? 0;
            if (response['last_reset_date'] != null) {
              lastResetDate = DateTime.parse(
                response['last_reset_date'] as String,
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting usage from database: $e');
          }
        }
      }

      // اگر از دیتابیس چیزی نگرفتیم، از لوکال بگیر
      if (lastResetDate == null) {
        final prefs = await SharedPreferences.getInstance();
        final lastResetDateStr = prefs.getString(_lastResetDateKey);
        if (lastResetDateStr != null) {
          lastResetDate = DateTime.parse(lastResetDateStr);
        }
        if (dailyMessages == 0) {
          dailyMessages = prefs.getInt(_dailyMessagesKey) ?? 0;
        }
      }

      // بررسی و ریست محدودیت روزانه
      if (lastResetDate != null && !_isSameDay(lastResetDate, now)) {
        // روز جدید - ریست محدودیت روزانه
        dailyMessages = 0;
        lastResetDate = today;

        // ذخیره در لوکال
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_dailyMessagesKey, 0);
        await prefs.setString(_lastResetDateKey, today.toIso8601String());

        // ذخیره در دیتابیس
        if (userId != null) {
          try {
            await _updateUsageInDatabase(userId, 0, today);
          } catch (e) {
            if (kDebugMode) {
              print('Error resetting usage in database: $e');
            }
          }
        }
      } else if (lastResetDate == null) {
        // اولین بار - تنظیم تاریخ
        lastResetDate = today;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastResetDateKey, today.toIso8601String());

        if (userId != null) {
          try {
            await _syncToDatabase(userId, dailyMessages, today);
          } catch (e) {
            if (kDebugMode) {
              print('Error syncing to database: $e');
            }
          }
        }
      }

      // استفاده از محدودیت پیش‌فرض اگر مشخص نشده باشد
      final effectiveDailyLimit = dailyLimit ?? defaultDailyLimit;

      // بررسی محدودیت
      if (dailyMessages >= effectiveDailyLimit) {
        final nextReset = _getNextDayReset(now);
        return RateLimitResult(
          canSend: false,
          reason: RateLimitReason.dailyLimitExceeded,
          remaining: 0,
          resetAt: nextReset,
          message:
              'شما به محدودیت روزانه ($effectiveDailyLimit پیام) رسیده‌اید. لطفاً فردا دوباره تلاش کنید.',
        );
      }

      // محاسبه تعداد باقی‌مانده
      final remaining = effectiveDailyLimit - dailyMessages;

      return RateLimitResult(
        canSend: true,
        remaining: remaining,
        resetAt: _getNextDayReset(now),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error checking rate limit: $e');
      }
      // در صورت خطا، اجازه ارسال بده (fail-open)
      return const RateLimitResult(
        canSend: true,
        remaining: 999,
      );
    }
  }

  /// ثبت ارسال پیام
  Future<void> recordMessageSent() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int dailyMessages = 0;
      DateTime? lastResetDate;

      // اول از دیتابیس بگیر (اگر وجود دارد)
      if (userId != null) {
        try {
          final response = await _supabase
              .from(_tableName)
              .select('usage_count, last_reset_date')
              .eq('user_id', userId)
              .eq('feature_name', _featureName)
              .eq('usage_type', _usageType)
              .maybeSingle();

          if (response != null) {
            dailyMessages = response['usage_count'] as int? ?? 0;
            if (response['last_reset_date'] != null) {
              final dateStr = response['last_reset_date'] as String;
              // اگر فقط تاریخ است (YYYY-MM-DD)، به DateTime تبدیل کن
              if (dateStr.length == 10) {
                lastResetDate = DateTime.parse(dateStr);
              } else {
                lastResetDate = DateTime.parse(dateStr);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting usage from database: $e');
          }
        }
      }

      // اگر از دیتابیس چیزی نگرفتیم، از لوکال بگیر
      if (lastResetDate == null) {
        final prefs = await SharedPreferences.getInstance();
        final lastResetDateStr = prefs.getString(_lastResetDateKey);
        if (lastResetDateStr != null) {
          lastResetDate = DateTime.parse(lastResetDateStr);
        } else {
          lastResetDate = today;
        }
        if (dailyMessages == 0) {
          dailyMessages = prefs.getInt(_dailyMessagesKey) ?? 0;
        }
      }

      // بررسی ریست روزانه
      // lastResetDate در اینجا همیشه مقدار دارد (یا از دیتابیس یا از لوکال یا today)
      if (!_isSameDay(lastResetDate, now)) {
        // روز جدید - ریست
        dailyMessages = 0;
        lastResetDate = today;
      }

      // افزایش تعداد
      dailyMessages += 1;

      // ذخیره در لوکال
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyMessagesKey, dailyMessages);
      await prefs.setString(_lastResetDateKey, today.toIso8601String());

      // ذخیره در دیتابیس
      if (userId != null) {
        try {
          await _updateUsageInDatabase(userId, dailyMessages, today);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to save usage to database, but saved locally: $e');
          }
          // ادامه می‌دهیم حتی اگر دیتابیس خطا بدهد
        }
      }

      if (kDebugMode) {
        print(
          'Rate Limiter: Daily messages: $dailyMessages (saved to DB and local)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording message: $e');
      }
    }
  }

  /// دریافت آمار استفاده
  Future<RateLimitStats> getStats({int? dailyLimit}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int dailyMessages = 0;
      DateTime? lastResetDate;

      // تلاش برای دریافت از دیتابیس
      if (userId != null) {
        try {
          final response = await _supabase
              .from(_tableName)
              .select('usage_count, last_reset_date')
              .eq('user_id', userId)
              .eq('feature_name', _featureName)
              .eq('usage_type', _usageType)
              .maybeSingle();

          if (response != null) {
            dailyMessages = response['usage_count'] as int? ?? 0;
            if (response['last_reset_date'] != null) {
              final dateStr = response['last_reset_date'] as String;
              // اگر فقط تاریخ است (YYYY-MM-DD)، به DateTime تبدیل کن
              if (dateStr.length == 10) {
                lastResetDate = DateTime.parse(dateStr);
              } else {
                lastResetDate = DateTime.parse(dateStr);
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting stats from database: $e');
          }
        }
      }

      // اگر از دیتابیس چیزی نگرفتیم، از لوکال بگیر
      if (lastResetDate == null) {
        final prefs = await SharedPreferences.getInstance();
        final lastResetDateStr = prefs.getString(_lastResetDateKey);
        if (lastResetDateStr != null) {
          lastResetDate = DateTime.parse(lastResetDateStr);
        }
        if (dailyMessages == 0) {
          dailyMessages = prefs.getInt(_dailyMessagesKey) ?? 0;
        }
      }

      // بررسی و ریست محدودیت روزانه
      if (lastResetDate != null && !_isSameDay(lastResetDate, now)) {
        // روز جدید - ریست محدودیت روزانه
        dailyMessages = 0;
        lastResetDate = today;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_dailyMessagesKey, 0);
        await prefs.setString(_lastResetDateKey, today.toIso8601String());

        if (userId != null) {
          try {
            await _updateUsageInDatabase(userId, 0, today);
          } catch (e) {
            if (kDebugMode) {
              print('Error resetting usage in database: $e');
            }
          }
        }
      } else if (lastResetDate == null) {
        lastResetDate = today;
        if (userId != null) {
          try {
            await _syncToDatabase(userId, dailyMessages, today);
          } catch (e) {
            if (kDebugMode) {
              print('Error syncing to database: $e');
            }
          }
        }
      }

      final effectiveDailyLimit = dailyLimit ?? defaultDailyLimit;

      return RateLimitStats(
        dailyUsed: dailyMessages,
        dailyLimit: effectiveDailyLimit,
        nextDailyReset: _getNextDayReset(now),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stats: $e');
      }
      final now = DateTime.now();
      return RateLimitStats(
        dailyUsed: 0,
        dailyLimit: dailyLimit ?? defaultDailyLimit,
        nextDailyReset: _getNextDayReset(now),
      );
    }
  }

  /// ریست دستی محدودیت‌ها (برای تست)
  Future<void> resetLimits() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ریست در لوکال
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyMessagesKey, 0);
      await prefs.setString(_lastResetDateKey, today.toIso8601String());

      // ریست در دیتابیس
      if (userId != null) {
        try {
          await _updateUsageInDatabase(userId, 0, today);
        } catch (e) {
          if (kDebugMode) {
            print('Error resetting limits in database: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting limits: $e');
      }
    }
  }

  /// همگام‌سازی با دیتابیس (upsert)
  Future<void> _syncToDatabase(
    String userId,
    int count,
    DateTime resetDate,
  ) async {
    try {
      await _supabase.from(_tableName).upsert({
        'user_id': userId,
        'feature_name': _featureName,
        'usage_type': _usageType,
        'usage_count': count,
        'last_reset_date': resetDate.toIso8601String().substring(
          0,
          10,
        ), // فقط تاریخ
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,feature_name,usage_type');
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing to database: $e');
      }
      rethrow;
    }
  }

  /// به‌روزرسانی استفاده در دیتابیس
  Future<void> _updateUsageInDatabase(
    String userId,
    int count,
    DateTime resetDate,
  ) async {
    try {
      await _supabase.from(_tableName).upsert({
        'user_id': userId,
        'feature_name': _featureName,
        'usage_type': _usageType,
        'usage_count': count,
        'last_reset_date': resetDate.toIso8601String().substring(
          0,
          10,
        ), // فقط تاریخ
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,feature_name,usage_type');
    } catch (e) {
      if (kDebugMode) {
        print('Error updating usage in database: $e');
      }
      rethrow;
    }
  }

  /// بررسی یکسان بودن روز
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// محاسبه زمان ریست روزانه بعدی
  DateTime _getNextDayReset(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
  }
}

/// نتیجه بررسی محدودیت
class RateLimitResult {
  const RateLimitResult({
    required this.canSend,
    required this.remaining, this.reason,
    this.resetAt,
    this.message,
  });

  final bool canSend;
  final RateLimitReason? reason;
  final int remaining;
  final DateTime? resetAt;
  final String? message;
}

/// دلیل محدودیت
enum RateLimitReason { dailyLimitExceeded }

/// آمار استفاده
class RateLimitStats {
  const RateLimitStats({
    required this.dailyUsed,
    required this.dailyLimit,
    required this.nextDailyReset,
  });

  final int dailyUsed;
  final int dailyLimit;
  final DateTime nextDailyReset;

  int get dailyRemaining => dailyLimit - dailyUsed;
  double get dailyUsagePercent => (dailyUsed / dailyLimit) * 100;
}
