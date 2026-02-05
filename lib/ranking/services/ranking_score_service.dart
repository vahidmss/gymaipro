import 'package:flutter/foundation.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/services/activity_tracking_service.dart';
import 'package:gymaipro/services/streak_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس محاسبه امتیاز رتبه‌بندی بر اساس فعالیت‌های خودکار
class RankingScoreService {
  static final RankingScoreService _instance = RankingScoreService._internal();
  factory RankingScoreService() => _instance;
  RankingScoreService._internal();

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

      final totalScore =
          dailyActivitiesScore +
          currentStreakScore +
          longestStreakScore +
          activeDaysScore +
          totalWorkoutsScore +
          totalMealsScore;

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

  /// به‌روزرسانی امتیاز کاربر
  Future<void> updateUserScore(String userId) async {
    try {
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
