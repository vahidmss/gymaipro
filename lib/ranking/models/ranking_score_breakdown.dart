/// مدل تفکیک امتیاز رتبه‌بندی برای نمایش در پروفایل (پراگرس بار هر منبع امتیاز)
class RankingScoreBreakdown {
  RankingScoreBreakdown({
    required this.totalScore,
    required this.dailyActivitiesScore,
    required this.currentStreak,
    required this.currentStreakScore,
    required this.longestStreak,
    required this.longestStreakScore,
    required this.activeDays,
    required this.activeDaysScore,
    required this.totalWorkouts,
    required this.totalWorkoutsScore,
    required this.totalMeals,
    required this.totalMealsScore,
  });

  final int totalScore;

  /// امتیاز از فعالیت‌های روزانه (۳۰ روز گذشته)
  final int dailyActivitiesScore;

  /// زنجیره فعلی (روز)
  final int currentStreak;

  /// امتیاز زنجیره فعلی (حداکثر ۵۰۰)
  final int currentStreakScore;

  /// طولانی‌ترین زنجیره (روز)
  final int longestStreak;

  /// امتیاز طولانی‌ترین زنجیره (حداکثر ۲۵۰)
  final int longestStreakScore;

  /// تعداد روزهای فعال در ۳۰ روز گذشته
  final int activeDays;

  /// امتیاز روزهای فعال (حداکثر ۱۵۰)
  final int activeDaysScore;

  /// تعداد کل تمرینات ثبت‌شده
  final int totalWorkouts;

  /// امتیاز تمرینات (حداکثر ۱۰۰۰)
  final int totalWorkoutsScore;

  /// تعداد کل وعده‌های ثبت‌شده
  final int totalMeals;

  /// امتیاز وعده‌ها (حداکثر ۵۰۰)
  final int totalMealsScore;

  static const int maxDailyActivitiesScore = 1740; // 30 days * ~58 max/day
  static const int maxCurrentStreakScore = 500;
  static const int maxLongestStreakScore = 250;
  static const int maxActiveDaysScore = 150;
  static const int maxTotalWorkoutsScore = 1000;
  static const int maxTotalMealsScore = 500;
}
