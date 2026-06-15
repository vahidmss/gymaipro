import 'package:flutter/foundation.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/services/activity_tracking_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/streak_service.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس محاسبه امتیاز رتبه‌بندی بر اساس فعالیت‌های خودکار
class RankingScoreService {
  factory RankingScoreService() => _instance;
  RankingScoreService._internal();
  static final RankingScoreService _instance = RankingScoreService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final ActivityTrackingService _activityService = ActivityTrackingService();

  /// محاسبه امتیاز کل کاربر
  Future<int> calculateTotalScore(String userId) async {
    final breakdown = await getScoreBreakdown(userId);
    return breakdown?.totalScore ?? 0;
  }

  /// تفکیک امتیاز برای نمایش در پروفایل (پراگرس بار هر منبع)
  Future<RankingScoreBreakdown?> getScoreBreakdown(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activities = await _activityService.getUserActivitiesForUser(
        userId,
        startDate: thirtyDaysAgo,
      );

      int dailyActivitiesScore = 0;
      for (final activity in activities) {
        dailyActivitiesScore += activity.calculateDailyScore();
      }

      final streak = await StreakService.getStreakForUser(userId);
      final currentStreakScore = (streak.current * 10).clamp(0, 500);
      final longestStreakScore = (streak.longest * 5).clamp(0, 250);

      final activeDays = activities.where((a) => a.isActiveDay).length;
      final activeDaysScore = (activeDays * 5).clamp(0, 150);

      final totalWorkouts = await _getTotalWorkoutCount(userId);
      final totalWorkoutsScore = ((totalWorkouts / 10).floor() * 20).clamp(
        0,
        1000,
      );

      final totalMeals = await _getTotalMealCount(userId);
      final totalMealsScore = ((totalMeals / 20).floor() * 10).clamp(0, 500);

      final articlesReadCount = await _getArticlesReadCount(userId);
      final articlesReadScore = (articlesReadCount * RankingScoreBreakdown.pointsPerArticle)
          .clamp(0, RankingScoreBreakdown.maxArticlesReadScore);

      final totalScore =
          dailyActivitiesScore +
          currentStreakScore +
          longestStreakScore +
          activeDaysScore +
          totalWorkoutsScore +
          totalMealsScore +
          articlesReadScore;

      return RankingScoreBreakdown(
        totalScore: totalScore,
        dailyActivitiesScore: dailyActivitiesScore,
        currentStreak: streak.current,
        currentStreakScore: currentStreakScore,
        longestStreak: streak.longest,
        longestStreakScore: longestStreakScore,
        activeDays: activeDays,
        activeDaysScore: activeDaysScore,
        totalWorkouts: totalWorkouts,
        totalWorkoutsScore: totalWorkoutsScore,
        totalMeals: totalMeals,
        totalMealsScore: totalMealsScore,
        articlesReadCount: articlesReadCount,
        articlesReadScore: articlesReadScore,
      );
    } catch (e) {
      debugPrint('❌ Error getting score breakdown: $e');
      return null;
    }
  }

  /// دریافت تعداد کل تمرینات کاربر
  Future<int> _getTotalWorkoutCount(String userId) async {
    try {
      // از جدول workout_daily_logs
      final response = await _client
          .from('workout_daily_logs')
          .select('sessions')
          .eq('user_id', userId);

      int totalCount = 0;
      for (final row in response) {
        final sessions = row['sessions'] as List<dynamic>? ?? [];
        totalCount += sessions.length;
      }

      return totalCount;
    } catch (e) {
      debugPrint('❌ Error getting total workout count: $e');
      return 0;
    }
  }

  /// دریافت تعداد کل وعده‌های ثبت شده کاربر
  Future<int> _getTotalMealCount(String userId) async {
    try {
      // از جدول food_logs
      final response = await _client
          .from('food_logs')
          .select('meals')
          .eq('user_id', userId);

      int totalCount = 0;
      for (final row in response) {
        final meals = row['meals'] as List<dynamic>? ?? [];
        totalCount += meals.length;
      }

      return totalCount;
    } catch (e) {
      debugPrint('❌ Error getting total meal count: $e');
      return 0;
    }
  }

  /// شناسهٔ مورد استفاده در article_reads همیشه auth.uid() است (در آکادمی ذخیره می‌شود).
  /// اگر userId برابر profiles.id باشد، از profiles.auth_user_id استفاده می‌کنیم؛
  /// اگر پروفایل مربوط به کاربر لاگین‌شده باشد و auth_user_id خالی باشد از auth.uid() استفاده می‌کنیم.
  Future<String?> _resolveAuthUserIdForArticleReads(String userIdOrProfileId) async {
    if (userIdOrProfileId.isEmpty) return null;
    final currentAuthId = _client.auth.currentUser?.id;
    try {
      final profile = await UserProfileService.fetchProfile(userIdOrProfileId);
      if (profile != null) {
        final authStr = (profile['auth_user_id'] as String?)?.trim() ?? '';
        if (authStr.isNotEmpty) return authStr;
        final profileId = profile['id']?.toString() ?? '';
        if (profileId.isEmpty) return userIdOrProfileId;
        if (currentAuthId != null) {
          final currentProfile = await SimpleProfileService.getCurrentProfile();
          final currentProfileId = currentProfile?['id']?.toString();
          if (currentProfileId == profileId) return currentAuthId;
        }
        return profileId;
      }
      if (currentAuthId != null && userIdOrProfileId == currentAuthId) {
        return currentAuthId;
      }
      return userIdOrProfileId;
    } catch (_) {
      if (currentAuthId != null && userIdOrProfileId == currentAuthId) {
        return currentAuthId;
      }
      return userIdOrProfileId;
    }
  }

  /// تعداد مقالات یکتای خوانده‌شده توسط کاربر (از جدول article_reads).
  /// هر article_id فقط یک بار شمرده می‌شود. جدول با auth.uid() پر می‌شود، پس profile.id را به auth_user_id تبدیل می‌کنیم.
  Future<int> _getArticlesReadCount(String userId) async {
    try {
      final authUserId = await _resolveAuthUserIdForArticleReads(userId);
      if (authUserId == null || authUserId.isEmpty) return 0;

      final rows = await _client
          .from('article_reads')
          .select('article_id')
          .eq('user_id', authUserId);
      final seen = <int>{};
      for (final row in rows as List) {
        final m = row as Map<String, dynamic>;
        final raw = m['article_id'];
        if (raw is int) {
          seen.add(raw);
        } else if (raw != null) {
          final p = int.tryParse(raw.toString());
          if (p != null) seen.add(p);
        }
      }
      return seen.length;
    } catch (e) {
      debugPrint('❌ Error getting articles read count: $e');
      return 0;
    }
  }

  /// به‌روزرسانی امتیاز کاربر
  /// فقط برای ورزشکاران (athletes) اجرا می‌شود - مربیان حذف می‌شوند
  Future<void> updateUserScore(String userId) async {
    try {
      final role = await UserProfileService.getUserRole(userId);
      if (role != 'athlete') {
        debugPrint('⚠️ Skipping score update for non-athlete user: $userId (role: $role)');
        return;
      }

      final totalScore = await calculateTotalScore(userId);
      final league = _getLeagueByScore(totalScore);

      // دریافت رتبه فعلی
      final currentRanking = await _client
          .from('user_rankings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      String? previousLeague;
      if (currentRanking != null) {
        previousLeague = currentRanking['current_league'] as String?;
      }

      final leaguePoints = league.calculateLeaguePoints(totalScore);

      if (currentRanking != null) {
        // به‌روزرسانی
        await _client
            .from('user_rankings')
            .update({
              'total_score': totalScore,
              'current_league': league.id,
              'league_points': leaguePoints,
              'previous_league': previousLeague,
              'league_changed_at': previousLeague != league.id
                  ? DateTime.now().toIso8601String()
                  : currentRanking['league_changed_at'],
            })
            .eq('user_id', userId);
      } else {
        // ایجاد جدید
        await _client.from('user_rankings').insert({
          'user_id': userId,
          'total_score': totalScore,
          'current_league': league.id,
          'league_points': leaguePoints,
          'previous_league': previousLeague,
          'league_changed_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating user score: $e');
    }
  }

  /// پیدا کردن لیگ بر اساس امتیاز
  League _getLeagueByScore(int score) {
    return League.getLeagueByScore(score);
  }
}
