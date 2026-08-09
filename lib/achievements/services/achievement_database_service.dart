import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس دیتابیس برای ذخیره و بازیابی دستاوردهای کاربر
/// از Supabase برای ذخیره‌سازی اصلی و SharedPreferences برای cache محلی استفاده می‌کند
class AchievementDatabaseService {
  AchievementDatabaseService();
  final String _tableName = 'achievements';
  final String _localCacheKeyPrefix = 'achievements_cache_';
  final String _lastSyncKeyPrefix = 'achievements_last_sync_';

  Future<String?> _getProfileId() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final id = profile?['id'] as String?;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    // fallback: اگر پروفایل نداریم، حداقل auth id را برگردانیم
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// ساخت کلید کش با user ID
  Future<String> _getLocalCacheKey() async {
    final profileId = await _getProfileId();
    if (profileId != null) {
      return '$_localCacheKeyPrefix$profileId';
    }
    // اگر user ID نداریم، از کلید عمومی استفاده می‌کنیم (برای backward compatibility)
    return '${_localCacheKeyPrefix}default';
  }

  /// ساخت کلید last sync با user ID
  Future<String> _getLastSyncKey() async {
    final profileId = await _getProfileId();
    if (profileId != null) {
      return '$_lastSyncKeyPrefix$profileId';
    }
    return '${_lastSyncKeyPrefix}default';
  }

  /// دریافت تمام دستاوردهای کاربر از دیتابیس
  Future<Map<String, AchievementProgress>> getUserAchievements() async {
    try {
      final client = Supabase.instance.client;
      final profileId = await _getProfileId();

      if (profileId == null) {
        debugPrint('⚠️ User not authenticated, returning cached achievements');
        return await _loadFromLocalCache();
      }

      // اگر offline است، از cache محلی استفاده کن
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        debugPrint('📴 Offline mode: Loading achievements from local cache');
        return await _loadFromLocalCache();
      }

      // دریافت از دیتابیس
      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', profileId);

      final Map<String, AchievementProgress> achievements = {};

      for (final item in response) {
        final progress = AchievementProgress.fromJson(item);
        achievements[progress.achievementId] = progress;
      }

      // ذخیره در cache محلی
      await _saveToLocalCache(achievements);
      await _updateLastSyncTime();

      return achievements;
    } catch (e) {
      debugPrint('❌ Error loading achievements from database: $e');
      // Fallback به cache محلی در صورت خطا
      return _loadFromLocalCache();
    }
  }

  /// ذخیره یا به‌روزرسانی پیشرفت یک دستاورد
  Future<void> saveAchievementProgress(
    String achievementId,
    int currentValue, {
    DateTime? unlockedAt,
    int? bonusPoints,
  }) async {
    try {
      final client = Supabase.instance.client;
      final profileId = await _getProfileId();

      if (profileId == null) {
        debugPrint('⚠️ User not authenticated, saving to local cache only');
        await _saveProgressToLocalCache(
          achievementId,
          currentValue,
          unlockedAt,
          bonusPoints: bonusPoints,
        );
        return;
      }

      final isOnline = await ConnectivityService.instance.checkNow();

      // اگر offline است، فقط در cache محلی ذخیره کن
      if (!isOnline) {
        debugPrint('📴 Offline mode: Saving achievement progress to local cache');
        await _saveProgressToLocalCache(
          achievementId,
          currentValue,
          unlockedAt,
          bonusPoints: bonusPoints,
        );
        return;
      }

      // بررسی وجود رکورد
      final existing = await client
          .from(_tableName)
          .select('id, bonus_points')
          .eq('user_id', profileId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      final existingBonus = (existing?['bonus_points'] as num?)?.toInt() ?? 0;
      final resolvedBonus = bonusPoints ?? existingBonus;

      final data = <String, dynamic>{
        'user_id': profileId,
        'achievement_id': achievementId,
        'current_value': currentValue,
        'unlocked_at': unlockedAt?.toIso8601String(),
        'bonus_points': resolvedBonus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // به‌روزرسانی رکورد موجود
        await client
            .from(_tableName)
            .update(data)
            .eq('user_id', profileId)
            .eq('achievement_id', achievementId);
      } else {
        // ایجاد رکورد جدید
        data['created_at'] = DateTime.now().toIso8601String();
        await client.from(_tableName).insert(data);
      }

      // به‌روزرسانی cache محلی
      await _saveProgressToLocalCache(
        achievementId,
        currentValue,
        unlockedAt,
        bonusPoints: resolvedBonus,
      );

      debugPrint('✅ Achievement progress saved: $achievementId = $currentValue');
    } catch (e) {
      debugPrint('❌ Error saving achievement progress: $e');
      // در صورت خطا، حداقل در cache محلی ذخیره کن
      await _saveProgressToLocalCache(
        achievementId,
        currentValue,
        unlockedAt,
        bonusPoints: bonusPoints,
      );
      rethrow;
    }
  }

  /// اعطای بونوس لیگ فقط یک‌بار (idempotent). true اگر تازه اعطا شد.
  Future<bool> grantBonusPointsIfNeeded(
    String achievementId,
    int bonusPoints,
  ) async {
    if (bonusPoints <= 0) return false;

    try {
      final client = Supabase.instance.client;
      final profileId = await _getProfileId();
      if (profileId == null) return false;

      final existing = await client
          .from(_tableName)
          .select('id, current_value, unlocked_at, bonus_points')
          .eq('user_id', profileId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      if (existing == null) return false;

      final already = (existing['bonus_points'] as num?)?.toInt() ?? 0;
      if (already > 0) return false;

      final currentValue = (existing['current_value'] as num?)?.toInt() ?? 0;
      final unlockedAt = existing['unlocked_at'] != null
          ? DateTime.parse(existing['unlocked_at'] as String)
          : DateTime.now();

      await saveAchievementProgress(
        achievementId,
        currentValue,
        unlockedAt: unlockedAt,
        bonusPoints: bonusPoints,
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error granting achievement bonus: $e');
      return false;
    }
  }

  /// جمع بونوس لیگ کاربر فعلی از دستاوردها
  Future<int> getTotalBonusPoints() async {
    try {
      final map = await getUserAchievements();
      return map.values
          .where((p) => p.unlockedAt != null)
          .fold<int>(0, (sum, p) => sum + p.bonusPoints);
    } catch (_) {
      return 0;
    }
  }

  /// سینک cache محلی به دیتابیس (برای استفاده در زمان اتصال مجدد)
  Future<void> syncLocalCacheToDatabase() async {
    try {
      final client = Supabase.instance.client;
      final profileId = await _getProfileId();

      if (profileId == null) {
        debugPrint('⚠️ User not authenticated, skipping sync');
        return;
      }

      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        debugPrint('📴 Offline mode: Skipping sync');
        return;
      }

      final localCache = await _loadFromLocalCache();
      if (localCache.isEmpty) {
        debugPrint('ℹ️ No local cache to sync');
        return;
      }

      debugPrint('🔄 Syncing ${localCache.length} achievements to database...');

      for (final entry in localCache.entries) {
        try {
          final existing = await client
              .from(_tableName)
              .select('id, current_value, unlocked_at')
              .eq('user_id', profileId)
              .eq('achievement_id', entry.key)
              .maybeSingle();

          final data = {
            'user_id': profileId,
            'achievement_id': entry.key,
            'current_value': entry.value.currentValue,
            'unlocked_at': entry.value.unlockedAt?.toIso8601String(),
            'bonus_points': entry.value.bonusPoints,
            'updated_at': DateTime.now().toIso8601String(),
          };

          if (existing != null) {
            // فقط اگر داده محلی جدیدتر یا متفاوت است، به‌روزرسانی کن
            final localValue = entry.value.currentValue;
            final localUnlocked = entry.value.unlockedAt;
            final dbValue = existing['current_value'] as int;
            final dbUnlocked = existing['unlocked_at'] != null
                ? DateTime.parse(existing['unlocked_at'] as String)
                : null;

            if (localValue != dbValue ||
                (localUnlocked != null && dbUnlocked == null) ||
                (localUnlocked != null &&
                    dbUnlocked != null &&
                    localUnlocked.isAfter(dbUnlocked))) {
              await client
                  .from(_tableName)
                  .update(data)
                  .eq('user_id', profileId)
                  .eq('achievement_id', entry.key);
              debugPrint('✅ Synced: ${entry.key}');
            }
          } else {
            // ایجاد رکورد جدید
            data['created_at'] = DateTime.now().toIso8601String();
            await client.from(_tableName).insert(data);
            debugPrint('✅ Created: ${entry.key}');
          }
        } catch (e) {
          debugPrint('❌ Error syncing ${entry.key}: $e');
        }
      }

      await _updateLastSyncTime();
      debugPrint('✅ Sync completed');
    } catch (e) {
      debugPrint('❌ Error during sync: $e');
    }
  }

  /// دریافت آمار دستاوردهای کاربر
  Future<AchievementStats> getUserAchievementStats() async {
    try {
      final client = Supabase.instance.client;
      final profileId = await _getProfileId();

      if (profileId == null) {
        return AchievementStats(
          totalAchievements: 0,
          unlockedCount: 0,
          totalPoints: 0,
        );
      }

      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        // محاسبه از cache محلی
        final cache = await _loadFromLocalCache();
        return _calculateStatsFromCache(cache);
      }

      // استفاده از function دیتابیس
      final response = await client.rpc<List<dynamic>>(
        'get_user_achievement_stats',
        params: {'p_user_id': profileId},
      );

      if (response.isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        return AchievementStats(
          totalAchievements: (data['total_achievements'] as int?) ?? 0,
          unlockedCount: (data['unlocked_count'] as int?) ?? 0,
          totalPoints: (data['total_points'] as int?) ?? 0,
        );
      }

      return AchievementStats(
        totalAchievements: 0,
        unlockedCount: 0,
        totalPoints: 0,
      );
    } catch (e) {
      debugPrint('❌ Error getting achievement stats: $e');
      // Fallback به محاسبه از cache
      final cache = await _loadFromLocalCache();
      return _calculateStatsFromCache(cache);
    }
  }

  /// پاک کردن cache محلی
  Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = await _getLocalCacheKey();
      final syncKey = await _getLastSyncKey();
      await prefs.remove(cacheKey);
      await prefs.remove(syncKey);
      debugPrint('✅ Local cache cleared for key: $cacheKey');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// پاک کردن تمام کش‌های achievement (برای logout)
  static Future<void> clearAllAchievementCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final keysToRemove = <String>[];

      // پیدا کردن تمام کلیدهای achievement (شامل کلیدهای قدیمی بدون user ID)
      for (final key in keys) {
        if (key.startsWith('achievements_cache_') || 
            key.startsWith('achievements_last_sync_') ||
            key == 'achievements_cache' || // کلید قدیمی (backward compatibility)
            key == 'achievements_last_sync') { // کلید قدیمی (backward compatibility)
          keysToRemove.add(key);
        }
      }

      // پاک کردن تمام کلیدها
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      debugPrint('✅ All achievement caches cleared (${keysToRemove.length} keys)');
    } catch (e) {
      debugPrint('❌ Error clearing all achievement caches: $e');
    }
  }

  // ========== متدهای کمکی برای cache محلی ==========

  Future<void> _saveToLocalCache(Map<String, AchievementProgress> achievements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = await _getLocalCacheKey();
      final jsonMap = <String, dynamic>{};
      for (final entry in achievements.entries) {
        jsonMap[entry.key] = entry.value.toJson();
      }
      await prefs.setString(cacheKey, jsonEncode(jsonMap));
    } catch (e) {
      debugPrint('❌ Error saving to local cache: $e');
    }
  }

  Future<Map<String, AchievementProgress>> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = await _getLocalCacheKey();
      final jsonStr = prefs.getString(cacheKey);
      
      // اگر cache با user ID فعلی وجود ندارد، بررسی کن که cache قدیمی (بدون user ID) وجود دارد یا نه
      // اگر وجود دارد، آن را پاک کن تا از استفاده نادرست جلوگیری شود
      if (jsonStr == null) {
        // بررسی وجود cache قدیمی (بدون user ID)
        const oldCacheKey = 'achievements_cache';
        if (prefs.containsKey(oldCacheKey)) {
          debugPrint('⚠️ Old cache format detected, removing it');
          await prefs.remove(oldCacheKey);
          await prefs.remove('achievements_last_sync');
        }
        return {};
      }

      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final achievements = <String, AchievementProgress>{};

      for (final entry in jsonMap.entries) {
        try {
          achievements[entry.key] =
              AchievementProgress.fromJson(entry.value as Map<String, dynamic>);
        } catch (e) {
          debugPrint('❌ Error parsing achievement ${entry.key}: $e');
        }
      }

      return achievements;
    } catch (e) {
      debugPrint('❌ Error loading from local cache: $e');
      return {};
    }
  }

  Future<void> _saveProgressToLocalCache(
    String achievementId,
    int currentValue,
    DateTime? unlockedAt, {
    int? bonusPoints,
  }) async {
    try {
      final cache = await _loadFromLocalCache();
      final previous = cache[achievementId];
      cache[achievementId] = AchievementProgress(
        achievementId: achievementId,
        currentValue: currentValue,
        unlockedAt: unlockedAt,
        bonusPoints: bonusPoints ?? previous?.bonusPoints ?? 0,
      );
      await _saveToLocalCache(cache);
    } catch (e) {
      debugPrint('❌ Error saving progress to local cache: $e');
    }
  }

  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = await _getLastSyncKey();
      await prefs.setString(syncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error updating last sync time: $e');
    }
  }

  AchievementStats _calculateStatsFromCache(
    Map<String, AchievementProgress> cache,
  ) {
    // اینجا باید امتیازها را از achievement definitions محاسبه کنیم
    // برای سادگی، فقط تعداد را برمی‌گردانیم
    final unlocked = cache.values.where((p) => p.unlockedAt != null).length;
    return AchievementStats(
      totalAchievements: cache.length,
      unlockedCount: unlocked,
      totalPoints: 0, // باید از AchievementService محاسبه شود
    );
  }
}

/// مدل پیشرفت دستاورد
class AchievementProgress {
  AchievementProgress({
    required this.achievementId,
    required this.currentValue,
    this.unlockedAt,
    this.bonusPoints = 0,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    final rawValue = json['current_value'] ?? json['currentValue'];
    final rawUnlocked = json['unlocked_at'] ?? json['unlockedAt'];
    final rawBonus = json['bonus_points'] ?? json['bonusPoints'];
    return AchievementProgress(
      achievementId: (json['achievement_id'] ?? json['achievementId']) as String,
      currentValue: (rawValue as num?)?.toInt() ?? 0,
      unlockedAt: rawUnlocked != null
          ? DateTime.parse(rawUnlocked as String)
          : null,
      bonusPoints: (rawBonus as num?)?.toInt() ?? 0,
    );
  }

  final String achievementId;
  final int currentValue;
  final DateTime? unlockedAt;
  final int bonusPoints;

  Map<String, dynamic> toJson() {
    return {
      'achievement_id': achievementId,
      'current_value': currentValue,
      'unlocked_at': unlockedAt?.toIso8601String(),
      'bonus_points': bonusPoints,
    };
  }
}

/// آمار دستاوردهای کاربر
class AchievementStats {
  AchievementStats({
    required this.totalAchievements,
    required this.unlockedCount,
    required this.totalPoints,
  });

  final int totalAchievements;
  final int unlockedCount;
  final int totalPoints;
}


