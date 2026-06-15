import 'package:flutter/foundation.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت streak (روزهای پشت سر هم استفاده از اپ)
class StreakService {
  factory StreakService() => _instance;
  StreakService._internal();
  static final StreakService _instance = StreakService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// به‌روزرسانی streak هنگام ورود کاربر
  /// این متد باید در app startup یا login صدا زده شود
  Future<void> updateLoginStreak() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, skipping streak update');
        return;
      }

      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) {
        debugPrint('⚠️ Profile not found, skipping streak update');
        return;
      }
      final profileId = profile['id'] as String?;
      if (profileId == null || profileId.isEmpty) {
        debugPrint('⚠️ Profile id not found, skipping streak update');
        return;
      }

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // دریافت آخرین تاریخ ورود و streak فعلی
      final lastLoginDateStr = profile['last_login_date'] as String?;
      final currentStreak = (profile['login_streak'] as int?) ?? 0;
      final longestStreak = (profile['longest_streak'] as int?) ?? 0;

      DateTime? lastLoginDate;
      if (lastLoginDateStr != null && lastLoginDateStr.isNotEmpty) {
        try {
          lastLoginDate = DateTime.parse(lastLoginDateStr);
          lastLoginDate = DateTime(
            lastLoginDate.year,
            lastLoginDate.month,
            lastLoginDate.day,
          );
        } catch (e) {
          debugPrint('⚠️ Error parsing last_login_date: $e');
        }
      }

      int newStreak = currentStreak;
      bool streakUpdated = false;

      if (lastLoginDate == null) {
        // اولین ورود - streak را 1 کن
        newStreak = 1;
        streakUpdated = true;
        debugPrint('✅ First login detected, setting streak to 1');
      } else {
        final daysDifference = todayDate.difference(lastLoginDate).inDays;

        if (daysDifference == 0) {
          // همان روز - streak تغییر نمی‌کند
          debugPrint(
            'ℹ️ Already logged in today, streak unchanged: $currentStreak',
          );
        } else if (daysDifference == 1) {
          // روز بعد - streak ادامه دارد
          newStreak = currentStreak + 1;
          streakUpdated = true;
          debugPrint('✅ Consecutive day! Streak increased to: $newStreak');
        } else {
          // streak شکسته شده - از 1 شروع کن
          newStreak = 1;
          streakUpdated = true;
          debugPrint(
            '⚠️ Streak broken ($daysDifference days gap), resetting to 1',
          );
        }
      }

      // به‌روزرسانی longest streak اگر لازم باشد
      final newLongestStreak = newStreak > longestStreak
          ? newStreak
          : longestStreak;

      // ذخیره در دیتابیس
      if (streakUpdated || lastLoginDate == null) {
        await SimpleProfileService.updateProfile({
          'login_streak': newStreak,
          'longest_streak': newLongestStreak,
          'last_login_date': todayDate.toIso8601String().substring(0, 10),
          'last_active_at': DateTime.now().toIso8601String(),
        });

        debugPrint(
          '✅ Streak updated: $newStreak days (longest: $newLongestStreak)',
        );
      }

      // به‌روزرسانی دستاوردهای streak
      await _updateStreakAchievements(newStreak);
    } catch (e) {
      debugPrint('❌ Error updating login streak: $e');
    }
  }

  /// به‌روزرسانی دستاوردهای streak
  Future<void> _updateStreakAchievements(int currentStreak) async {
    try {
      final achievementService = AchievementService.instance;

      // به‌روزرسانی دستاوردهای streak
      await achievementService.updateProgress('streak_3_days', currentStreak);
      await achievementService.updateProgress('streak_10_days', currentStreak);
      await achievementService.updateProgress('streak_30_days', currentStreak);

      debugPrint('✅ Streak achievements updated: $currentStreak days');
    } catch (e) {
      debugPrint('❌ Error updating streak achievements: $e');
    }
  }

  /// محاسبه و به‌روزرسانی دستاوردهای membership (روزهای عضویت)
  Future<void> updateMembershipAchievements() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) {
        debugPrint('⚠️ Profile not found, skipping membership achievements');
        return;
      }

      final createdAtStr = profile['created_at'] as String?;
      if (createdAtStr == null || createdAtStr.isEmpty) {
        debugPrint(
          '⚠️ Created date not found, skipping membership achievements',
        );
        return;
      }

      final createdAt = DateTime.parse(createdAtStr);
      final today = DateTime.now();
      final daysSinceMembership = today.difference(createdAt).inDays;

      debugPrint('📅 Days since membership: $daysSinceMembership');

      final achievementService = AchievementService.instance;

      // به‌روزرسانی دستاوردهای membership
      await achievementService.updateProgress(
        'membership_10_days',
        daysSinceMembership,
      );
      await achievementService.updateProgress(
        'membership_30_days',
        daysSinceMembership,
      );
      await achievementService.updateProgress(
        'membership_90_days',
        daysSinceMembership,
      );
      await achievementService.updateProgress(
        'membership_1_year',
        daysSinceMembership,
      );

      debugPrint(
        '✅ Membership achievements updated: $daysSinceMembership days',
      );
    } catch (e) {
      debugPrint('❌ Error updating membership achievements: $e');
    }
  }

  /// دریافت streak فعلی کاربر
  Future<int> getCurrentStreak() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return 0;

      return (profile['login_streak'] as int?) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting current streak: $e');
      return 0;
    }
  }

  /// دریافت longest streak کاربر
  Future<int> getLongestStreak() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return 0;

      return (profile['longest_streak'] as int?) ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting longest streak: $e');
      return 0;
    }
  }

  /// دریافت زنجیره (فعلی و طولانی‌ترین) برای یک پروفایل مشخص (مثلاً در پروفایل دیگران)
  static Future<({int current, int longest})> getStreakForUser(
    String profileId,
  ) async {
    try {
      final row = await ProfileRepository.instance.fetchProfile(profileId);
      if (row == null) return (current: 0, longest: 0);
      return (
        current: (row['login_streak'] as num?)?.toInt() ?? 0,
        longest: (row['longest_streak'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Error getting streak for user: $e');
      return (current: 0, longest: 0);
    }
  }
}
