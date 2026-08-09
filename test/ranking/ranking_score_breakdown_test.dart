import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';

void main() {
  group('RankingScoreBreakdown single currency', () {
    test('totalScore includes achievementBonusScore in expected composition', () {
      const activity = 100;
      const streak = 50;
      const longest = 20;
      const active = 30;
      const workouts = 40;
      const meals = 15;
      const articles = 10;
      const bonus = 75;

      final total = activity +
          streak +
          longest +
          active +
          workouts +
          meals +
          articles +
          bonus;

      final breakdown = RankingScoreBreakdown(
        totalScore: total,
        dailyActivitiesScore: activity,
        currentStreak: 5,
        currentStreakScore: streak,
        longestStreak: 4,
        longestStreakScore: longest,
        activeDays: 6,
        activeDaysScore: active,
        totalWorkouts: 20,
        totalWorkoutsScore: workouts,
        totalMeals: 30,
        totalMealsScore: meals,
        articlesReadCount: 2,
        articlesReadScore: articles,
        achievementBonusScore: bonus,
      );

      expect(breakdown.totalScore, 340);
      expect(breakdown.achievementBonusScore, 75);
      expect(
        breakdown.dailyActivitiesScore +
            breakdown.currentStreakScore +
            breakdown.longestStreakScore +
            breakdown.activeDaysScore +
            breakdown.totalWorkoutsScore +
            breakdown.totalMealsScore +
            breakdown.articlesReadScore +
            breakdown.achievementBonusScore,
        breakdown.totalScore,
      );
    });

    test('achievementBonusScore defaults to zero', () {
      final breakdown = RankingScoreBreakdown(
        totalScore: 10,
        dailyActivitiesScore: 10,
        currentStreak: 0,
        currentStreakScore: 0,
        longestStreak: 0,
        longestStreakScore: 0,
        activeDays: 0,
        activeDaysScore: 0,
        totalWorkouts: 0,
        totalWorkoutsScore: 0,
        totalMeals: 0,
        totalMealsScore: 0,
      );
      expect(breakdown.achievementBonusScore, 0);
    });
  });
}
