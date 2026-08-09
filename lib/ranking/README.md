# سیستم رتبه‌بندی و لیگ

امتیاز لیگ (`user_rankings.total_score`) تنها ارز گیمیفیکیشن است.

## فرمول

```
totalScore =
  dailyActivities +
  streakScores +
  activeDays +
  workouts +
  meals +
  articles +
  achievementBonus   // SUM(achievements.bonus_points)
```

## ورودی UI

- چیپ فشرده روی داشبورد (`DashboardRankChip`)
- More → رتبه‌بندی / امتیاز / دستاوردها
- پروفایل → کارت لیگ
- `/ranking` و `/leaderboard`

## ردیابی

- `RankingTrackerHelper.trackMealLog` از meal log
- `RankingTrackerHelper.trackWorkoutLog` از workout log
- بقیه ترکرها در صورت نیاز از همان helper

## SQL

- `sql/create_user_rankings_table.sql`
- `sql/migrate_gamification_single_currency.sql` (bonus_points روی achievements)
