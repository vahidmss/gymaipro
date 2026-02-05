import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت محدودیت استفاده از تحلیل پیشرفت
class ProgressAnalysisLimitService {
  static const String _freeUsageCountKey = 'progress_analysis_free_usage_count';
  static const String _lastUsageDateKey = 'progress_analysis_last_usage_date';
  static const int _maxFreeUsage = 3; // حداکثر 3 بار استفاده رایگان
  static const String _featureName = 'progress_analysis';
  static const String _usageType = 'total';

  final SubscriptionService _subscriptionService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'user_feature_usage';

  /// بررسی امکان استفاده از تحلیل پیشرفت
  Future<ProgressAnalysisLimitResult> canUseAnalysis() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return ProgressAnalysisLimitResult(
          canUse: false,
          reason: ProgressAnalysisLimitReason.notLoggedIn,
          remainingFree: 0,
          message: 'لطفاً ابتدا وارد حساب کاربری خود شوید',
        );
      }

      // بررسی اشتراک فعال
      final hasSubscription = await _subscriptionService.hasFeatureAccess(
        featureName: 'progress_analysis',
      );

      if (hasSubscription) {
        // کاربر اشتراک دارد - دسترسی نامحدود
        return ProgressAnalysisLimitResult(
          canUse: true,
          reason: null,
          remainingFree: 0,
          message: null,
          hasSubscription: true,
        );
      }

      // بررسی استفاده رایگان (اول از دیتابیس، سپس از لوکال)
      int freeUsageCount = 0;
      try {
        // تلاش برای دریافت از دیتابیس
        final response = await _supabase
            .from(_tableName)
            .select('usage_count')
            .eq('user_id', userId)
            .eq('feature_name', _featureName)
            .eq('usage_type', _usageType)
            .maybeSingle();

        if (response != null && response['usage_count'] != null) {
          freeUsageCount = response['usage_count'] as int;
          // همگام‌سازی با لوکال
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_freeUsageCountKey, freeUsageCount);
        } else {
          // اگر در دیتابیس نبود، از لوکال بگیر
          final prefs = await SharedPreferences.getInstance();
          freeUsageCount = prefs.getInt(_freeUsageCountKey) ?? 0;
          // همگام‌سازی با دیتابیس
          await _syncToDatabase(userId, freeUsageCount);
        }
      } catch (e) {
        // در صورت خطا، از لوکال بگیر
        if (kDebugMode) {
          print('Error getting usage from database, using local: $e');
        }
        final prefs = await SharedPreferences.getInstance();
        freeUsageCount = prefs.getInt(_freeUsageCountKey) ?? 0;
      }

      if (freeUsageCount >= _maxFreeUsage) {
        // استفاده رایگان تمام شده
        return ProgressAnalysisLimitResult(
          canUse: false,
          reason: ProgressAnalysisLimitReason.freeLimitExceeded,
          remainingFree: 0,
          message:
              'شما از $_maxFreeUsage استفاده رایگان خود استفاده کرده‌اید. برای استفاده نامحدود، اشتراک تهیه کنید.',
          hasSubscription: false,
        );
      }

      // هنوز می‌تواند استفاده کند
      final remaining = _maxFreeUsage - freeUsageCount;
      return ProgressAnalysisLimitResult(
        canUse: true,
        reason: null,
        remainingFree: remaining,
        message: null,
        hasSubscription: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error checking analysis limit: $e');
      }
      // در صورت خطا، اجازه استفاده بده
      return ProgressAnalysisLimitResult(
        canUse: true,
        reason: null,
        remainingFree: _maxFreeUsage,
        message: null,
      );
    }
  }

  /// ثبت استفاده از تحلیل
  Future<void> recordUsage() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // بررسی اشتراک - اگر اشتراک دارد، نیازی به ثبت استفاده نیست
      final hasSubscription = await _subscriptionService.hasFeatureAccess(
        featureName: 'progress_analysis',
      );

      if (hasSubscription) {
        return; // کاربر اشتراک دارد - نیازی به ثبت استفاده نیست
      }

      // دریافت مقدار فعلی از دیتابیس (source of truth) برای جلوگیری از race condition
      int currentCount = 0;
      try {
        final response = await _supabase
            .from(_tableName)
            .select('usage_count')
            .eq('user_id', userId)
            .eq('feature_name', _featureName)
            .eq('usage_type', _usageType)
            .maybeSingle();

        if (response != null && response['usage_count'] != null) {
          currentCount = response['usage_count'] as int;
        } else {
          // اگر در دیتابیس نبود، از لوکال بگیر
          final prefs = await SharedPreferences.getInstance();
          currentCount = prefs.getInt(_freeUsageCountKey) ?? 0;
        }
      } catch (e) {
        // در صورت خطا، از لوکال بگیر
        if (kDebugMode) {
          print('Error getting usage from database, using local: $e');
        }
        final prefs = await SharedPreferences.getInstance();
        currentCount = prefs.getInt(_freeUsageCountKey) ?? 0;
      }

      // بررسی محدودیت قبل از افزایش
      if (currentCount >= _maxFreeUsage) {
        if (kDebugMode) {
          print(
            'Progress Analysis: Usage limit already reached. Current: $currentCount/$_maxFreeUsage',
          );
        }
        return;
      }

      final newCount = currentCount + 1;

      // ذخیره در دیتابیس اول (source of truth)
      try {
        await _updateUsageInDatabase(userId, newCount);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to save usage to database: $e');
        }
        // اگر دیتابیس خطا داد، throw کنیم تا تحلیل دوباره انجام نشود
        throw Exception('خطا در ثبت استفاده در دیتابیس');
      }

      // ذخیره در لوکال برای همگام‌سازی
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_freeUsageCountKey, newCount);
      await prefs.setString(
        _lastUsageDateKey,
        DateTime.now().toIso8601String(),
      );

      if (kDebugMode) {
        print(
          'Progress Analysis: Recorded usage. Total: $newCount/$_maxFreeUsage',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording usage: $e');
      }
      rethrow; // rethrow برای اطلاع به caller
    }
  }

  /// دریافت آمار استفاده
  Future<ProgressAnalysisLimitStats> getUsageStats() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return ProgressAnalysisLimitStats(
          freeUsed: 0,
          freeLimit: _maxFreeUsage,
          remainingFree: _maxFreeUsage,
          hasSubscription: false,
        );
      }

      final hasSubscription = await _subscriptionService.hasFeatureAccess(
        featureName: 'progress_analysis',
      );

      if (hasSubscription) {
        return ProgressAnalysisLimitStats(
          freeUsed: 0,
          freeLimit: _maxFreeUsage,
          remainingFree: 0,
          hasSubscription: true,
        );
      }

      // دریافت از دیتابیس یا لوکال
      int freeUsed = 0;
      try {
        final response = await _supabase
            .from(_tableName)
            .select('usage_count')
            .eq('user_id', userId)
            .eq('feature_name', _featureName)
            .eq('usage_type', _usageType)
            .maybeSingle();

        if (response != null && response['usage_count'] != null) {
          freeUsed = response['usage_count'] as int;
          // همگام‌سازی با لوکال
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_freeUsageCountKey, freeUsed);
        } else {
          final prefs = await SharedPreferences.getInstance();
          freeUsed = prefs.getInt(_freeUsageCountKey) ?? 0;
          // همگام‌سازی با دیتابیس
          await _syncToDatabase(userId, freeUsed);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting usage stats from database: $e');
        }
        final prefs = await SharedPreferences.getInstance();
        freeUsed = prefs.getInt(_freeUsageCountKey) ?? 0;
      }

      return ProgressAnalysisLimitStats(
        freeUsed: freeUsed,
        freeLimit: _maxFreeUsage,
        remainingFree: _maxFreeUsage - freeUsed,
        hasSubscription: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting usage stats: $e');
      }
      return ProgressAnalysisLimitStats(
        freeUsed: 0,
        freeLimit: _maxFreeUsage,
        remainingFree: _maxFreeUsage,
        hasSubscription: false,
      );
    }
  }

  /// ریست استفاده رایگان (برای تست یا مدیریت)
  Future<void> resetFreeUsage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // ریست در لوکال
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_freeUsageCountKey);
      await prefs.remove(_lastUsageDateKey);

      // ریست در دیتابیس
      if (userId != null) {
        try {
          await _updateUsageInDatabase(userId, 0);
        } catch (e) {
          if (kDebugMode) {
            print('Error resetting usage in database: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting free usage: $e');
      }
    }
  }

  /// همگام‌سازی با دیتابیس (upsert)
  Future<void> _syncToDatabase(String userId, int count) async {
    try {
      await _supabase.from(_tableName).upsert({
        'user_id': userId,
        'feature_name': _featureName,
        'usage_type': _usageType,
        'usage_count': count,
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
  Future<void> _updateUsageInDatabase(String userId, int count) async {
    try {
      await _supabase.from(_tableName).upsert({
        'user_id': userId,
        'feature_name': _featureName,
        'usage_type': _usageType,
        'usage_count': count,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,feature_name,usage_type');
    } catch (e) {
      if (kDebugMode) {
        print('Error updating usage in database: $e');
      }
      rethrow;
    }
  }
}

/// نتیجه بررسی محدودیت
class ProgressAnalysisLimitResult {
  const ProgressAnalysisLimitResult({
    required this.canUse,
    this.reason,
    required this.remainingFree,
    this.message,
    this.hasSubscription = false,
  });

  final bool canUse;
  final ProgressAnalysisLimitReason? reason;
  final int remainingFree;
  final String? message;
  final bool hasSubscription;
}

/// دلیل محدودیت
enum ProgressAnalysisLimitReason { notLoggedIn, freeLimitExceeded }

/// آمار استفاده
class ProgressAnalysisLimitStats {
  const ProgressAnalysisLimitStats({
    required this.freeUsed,
    required this.freeLimit,
    required this.remainingFree,
    required this.hasSubscription,
  });

  final int freeUsed;
  final int freeLimit;
  final int remainingFree;
  final bool hasSubscription;

  double get freeUsagePercent => (freeUsed / freeLimit) * 100;
}
