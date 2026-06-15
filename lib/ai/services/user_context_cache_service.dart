import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/my_club/services/confidential_user_info_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس کش کردن اطلاعات کاربر برای استفاده در هوش مصنوعی
/// این سرویس اطلاعات پروفایل، اطلاعات محرمانه و وزن را در حافظه داخلی ذخیره می‌کند
/// تا سرعت پاسخ‌دهی هوش مصنوعی افزایش یابد
class UserContextCacheService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // کلیدهای SharedPreferences
  static const String _cacheKey = 'ai_user_context_cache';
  static const String _cacheTimestampKey = 'ai_user_context_cache_timestamp';
  
  /// دریافت اطلاعات کاربر از کش
  static Future<Map<String, dynamic>?> getCachedUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson == null) {
        if (kDebugMode) {
          print('AI Context Cache: No cached data found');
        }
        return null;
      }
      
      final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
      
      if (kDebugMode) {
        print('AI Context Cache: Loaded from cache');
      }
      
      return cacheData;
    } catch (e) {
      if (kDebugMode) {
        print('AI Context Cache: Error loading cache: $e');
      }
      return null;
    }
  }
  
  /// به‌روزرسانی کش اطلاعات کاربر (در بک‌گراند)
  /// این متد تمام اطلاعات لازم را از دیتابیس می‌گیرد و در حافظه داخلی ذخیره می‌کند
  static Future<void> refreshUserContextCache() async {
    final now = DateTime.now();
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }
    if (_lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < _refreshCooldown) {
      if (kDebugMode) {
        debugPrint('AI Context Cache: refresh skipped (cooldown active)');
      }
      return;
    }

    _refreshInFlight = _refreshUserContextCacheInternal();
    try {
      await _refreshInFlight!;
      _lastRefreshAt = DateTime.now();
    } finally {
      _refreshInFlight = null;
    }
  }

  static Future<void>? _refreshInFlight;
  static DateTime? _lastRefreshAt;
  static const Duration _refreshCooldown = Duration(minutes: 10);

  static Future<void> _refreshUserContextCacheInternal() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) {
          print('AI Context Cache: No user logged in, skipping cache refresh');
        }
        return;
      }
      
      if (kDebugMode) {
        print('AI Context Cache: Starting cache refresh...');
      }
      
      // دریافت پروفایل کاربر
      Map<String, dynamic>? profile;
      try {
        profile = await ProfileRepository.instance.fetchProfile(userId);
      } catch (e) {
        if (kDebugMode) {
          print('AI Context Cache: Error fetching profile: $e');
        }
      }
      
      // دریافت اطلاعات محرمانه
      Map<String, dynamic>? confidentialData;
      try {
        confidentialData = await ConfidentialUserInfoService.loadUserData();
        if (kDebugMode) {
          if (confidentialData != null) {
            print('AI Context Cache: Confidential data loaded successfully');
            final lifestylePrefs = confidentialData['lifestyle_preferences'] as Map<String, dynamic>?;
            if (lifestylePrefs != null && lifestylePrefs.isNotEmpty) {
              print('AI Context Cache: Lifestyle preferences found: ${lifestylePrefs.keys.toList()}');
            } else {
              print('AI Context Cache: No lifestyle preferences in confidential data');
            }
          } else {
            print('AI Context Cache: No confidential data found (user may not have consented)');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('AI Context Cache: Error fetching confidential data: $e');
        }
      }
      
      // دریافت آخرین وزن
      double? latestWeight;
      Map<String, dynamic>? weightStats;
      try {
        latestWeight = await WeeklyWeightService.getLatestWeight(userId);
        if (latestWeight != null) {
          weightStats = await WeeklyWeightService.getWeightStats(userId);
        }
      } catch (e) {
        if (kDebugMode) {
          print('AI Context Cache: Error fetching weight data: $e');
        }
      }
      
      // ساخت داده کش
      final cacheData = <String, dynamic>{
        'profile': profile,
        'confidential_data': confidentialData,
        'latest_weight': latestWeight,
        'weight_stats': weightStats,
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      // ذخیره در SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      
      if (kDebugMode) {
        print('AI Context Cache: Cache refreshed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI Context Cache: Error refreshing cache: $e');
      }
    }
  }
  
  /// پاک کردن کش
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      
      if (kDebugMode) {
        print('AI Context Cache: Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI Context Cache: Error clearing cache: $e');
      }
    }
  }
  
  /// دریافت زمان آخرین به‌روزرسانی کش
  static Future<DateTime?> getCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheTimestampKey);
      
      if (timestampStr == null) {
        return null;
      }
      
      return DateTime.parse(timestampStr);
    } catch (e) {
      if (kDebugMode) {
        print('AI Context Cache: Error getting cache timestamp: $e');
      }
      return null;
    }
  }
  
  /// بررسی اینکه آیا کش منقضی شده است یا نه
  /// اگر کش قدیمی‌تر از 1 ساعت باشد، باید به‌روزرسانی شود
  static Future<bool> isCacheExpired() async {
    try {
      final timestamp = await getCacheTimestamp();
      if (timestamp == null) {
        return true;
      }
      
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      // اگر کش قدیمی‌تر از 1 ساعت باشد، منقضی شده است
      return difference.inHours >= 1;
    } catch (e) {
      return true;
    }
  }
}

