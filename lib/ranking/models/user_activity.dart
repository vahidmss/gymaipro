/// مدل فعالیت روزانه کاربر
class UserActivity {
  UserActivity({
    required this.userId,
    required this.activityDate,
    this.articleReadingMinutes = 0,
    this.musicListeningMinutes = 0,
    this.videoWatchingMinutes = 0,
    this.workoutLogsCount = 0,
    this.mealLogsCount = 0,
    this.calorieCountingDays = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      userId: json['user_id'] as String,
      activityDate: DateTime.parse(json['activity_date'] as String),
      articleReadingMinutes: (json['article_reading_minutes'] as num?)?.toInt() ?? 0,
      musicListeningMinutes: (json['music_listening_minutes'] as num?)?.toInt() ?? 0,
      videoWatchingMinutes: (json['video_watching_minutes'] as num?)?.toInt() ?? 0,
      workoutLogsCount: (json['workout_logs_count'] as num?)?.toInt() ?? 0,
      mealLogsCount: (json['meal_logs_count'] as num?)?.toInt() ?? 0,
      calorieCountingDays: (json['calorie_counting_days'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  final String userId;
  final DateTime activityDate;
  final int articleReadingMinutes;
  final int musicListeningMinutes;
  final int videoWatchingMinutes;
  final int workoutLogsCount;
  final int mealLogsCount;
  final int calorieCountingDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'activity_date': activityDate.toIso8601String().substring(0, 10),
      'article_reading_minutes': articleReadingMinutes,
      'music_listening_minutes': musicListeningMinutes,
      'video_watching_minutes': videoWatchingMinutes,
      'workout_logs_count': workoutLogsCount,
      'meal_logs_count': mealLogsCount,
      'calorie_counting_days': calorieCountingDays,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// محاسبه امتیاز روزانه بر اساس فعالیت
  int calculateDailyScore() {
    int score = 0;

    // خواندن مقاله: هر 5 دقیقه = 1 امتیاز (حداکثر 10 امتیاز در روز)
    score += (articleReadingMinutes / 5).floor().clamp(0, 10);

    // گوش دادن موزیک: هر 10 دقیقه = 1 امتیاز (حداکثر 5 امتیاز در روز)
    score += (musicListeningMinutes / 10).floor().clamp(0, 5);

    // تماشای ویدیو: هر 5 دقیقه = 1 امتیاز (حداکثر 10 امتیاز در روز)
    score += (videoWatchingMinutes / 5).floor().clamp(0, 10);

    // ثبت تمرین: هر تمرین = 5 امتیاز (حداکثر 20 امتیاز در روز)
    score += (workoutLogsCount * 5).clamp(0, 20);

    // ثبت رژیم: هر وعده = 2 امتیاز (حداکثر 10 امتیاز در روز)
    score += (mealLogsCount * 2).clamp(0, 10);

    // کالری‌شماری: هر روز = 3 امتیاز
    if (calorieCountingDays > 0) {
      score += 3;
    }

    return score;
  }

  /// بررسی اینکه آیا روز فعال بوده یا نه
  bool get isActiveDay {
    return articleReadingMinutes > 0 ||
        musicListeningMinutes > 0 ||
        videoWatchingMinutes > 0 ||
        workoutLogsCount > 0 ||
        mealLogsCount > 0 ||
        calorieCountingDays > 0;
  }
}
