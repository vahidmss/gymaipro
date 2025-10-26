class TrainerRanking {
  TrainerRanking({
    required this.trainerId,
    required this.overallScore,
    required this.ratingScore,
    required this.experienceScore,
    required this.clientCountScore,
    required this.responseTimeScore,
    required this.profileCompletenessScore,
    required this.totalReviews,
    required this.activeClients,
    required this.experienceYears,
    required this.averageRating,
    required this.lastActive,
    required this.rankingFactors,
  });

  factory TrainerRanking.fromJson(Map<String, dynamic> json) {
    return TrainerRanking(
      trainerId: json['trainer_id'] as String,
      overallScore:
          double.tryParse((json['overall_score'] as String?) ?? '') ?? 0.0,
      ratingScore:
          double.tryParse((json['rating_score'] as String?) ?? '') ?? 0.0,
      experienceScore:
          double.tryParse((json['experience_score'] as String?) ?? '') ?? 0.0,
      clientCountScore:
          double.tryParse((json['client_count_score'] as String?) ?? '') ?? 0.0,
      responseTimeScore:
          double.tryParse((json['response_time_score'] as String?) ?? '') ??
          0.0,
      profileCompletenessScore:
          double.tryParse(
            (json['profile_completeness_score'] as String?) ?? '',
          ) ??
          0.0,
      totalReviews: (json['total_reviews'] as int?) ?? 0,
      activeClients: (json['active_clients'] as int?) ?? 0,
      experienceYears: (json['experience_years'] as int?) ?? 0,
      averageRating:
          double.tryParse((json['average_rating'] as String?) ?? '') ?? 0.0,
      lastActive: DateTime.parse(json['last_active'] as String),
      rankingFactors:
          (json['ranking_factors'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
    );
  }
  final String trainerId;
  final double overallScore;
  final double ratingScore;
  final double experienceScore;
  final double clientCountScore;
  final double responseTimeScore;
  final double profileCompletenessScore;
  final int totalReviews;
  final int activeClients;
  final int experienceYears;
  final double averageRating;
  final DateTime lastActive;
  final Map<String, dynamic> rankingFactors;

  Map<String, dynamic> toJson() {
    return {
      'trainer_id': trainerId,
      'overall_score': overallScore,
      'rating_score': ratingScore,
      'experience_score': experienceScore,
      'client_count_score': clientCountScore,
      'response_time_score': responseTimeScore,
      'profile_completeness_score': profileCompletenessScore,
      'total_reviews': totalReviews,
      'active_clients': activeClients,
      'experience_years': experienceYears,
      'average_rating': averageRating,
      'last_active': lastActive.toIso8601String(),
      'ranking_factors': rankingFactors,
    };
  }

  // محاسبه امتیاز کلی مربی
  static double calculateOverallScore({
    required double averageRating,
    required int totalReviews,
    required int experienceYears,
    required int activeClients,
    required double profileCompleteness,
    required DateTime lastActive,
  }) {
    final double ratingScore = _calculateRatingScore(
      averageRating,
      totalReviews,
    );
    final double experienceScore = _calculateExperienceScore(experienceYears);
    final double clientCountScore = _calculateClientCountScore(activeClients);
    final double responseTimeScore = _calculateResponseTimeScore(lastActive);
    final double completenessScore = profileCompleteness;

    // وزن‌دهی به عوامل مختلف (مجموع وزن‌ها باید 1 باشد)
    final double overallScore =
        (ratingScore * 0.4) + // 40% - امتیاز و تعداد نظرات
        (experienceScore * 0.25) + // 25% - تجربه کاری
        (clientCountScore * 0.15) + // 15% - تعداد مشتریان فعال
        (responseTimeScore * 0.10) + // 10% - فعالیت اخیر
        (completenessScore * 0.10); // 10% - کامل بودن پروفایل

    return double.parse(overallScore.toStringAsFixed(2));
  }

  // محاسبه امتیاز بر اساس رتبه‌بندی و تعداد نظرات
  static double _calculateRatingScore(double averageRating, int totalReviews) {
    // امتیاز پایه بر اساس رتبه‌بندی
    final double baseScore = averageRating / 5.0; // نرمال‌سازی به 0-1

    // بونوس بر اساس تعداد نظرات (هرچه نظرات بیشتر، قابل اعتمادتر)
    double reviewBonus = 0;
    if (totalReviews >= 50) {
      reviewBonus = 0.3;
    } else if (totalReviews >= 20) {
      reviewBonus = 0.2;
    } else if (totalReviews >= 10) {
      reviewBonus = 0.1;
    } else if (totalReviews >= 5) {
      reviewBonus = 0.05;
    } else if (totalReviews >= 1) {
      reviewBonus = 0.02;
    }

    return (baseScore + reviewBonus).clamp(0.0, 1.0);
  }

  // محاسبه امتیاز بر اساس تجربه
  static double _calculateExperienceScore(int experienceYears) {
    if (experienceYears >= 10) return 1;
    if (experienceYears >= 7) return 0.9;
    if (experienceYears >= 5) return 0.8;
    if (experienceYears >= 3) return 0.7;
    if (experienceYears >= 2) return 0.6;
    if (experienceYears >= 1) return 0.5;
    return 0.3; // کمتر از 1 سال
  }

  // محاسبه امتیاز بر اساس تعداد مشتریان فعال
  static double _calculateClientCountScore(int activeClients) {
    if (activeClients >= 50) return 1;
    if (activeClients >= 30) return 0.9;
    if (activeClients >= 20) return 0.8;
    if (activeClients >= 10) return 0.7;
    if (activeClients >= 5) return 0.6;
    if (activeClients >= 2) return 0.5;
    if (activeClients >= 1) return 0.4;
    return 0.2; // بدون مشتری فعال
  }

  // محاسبه امتیاز بر اساس فعالیت اخیر
  static double _calculateResponseTimeScore(DateTime lastActive) {
    final daysSinceActive = DateTime.now().difference(lastActive).inDays;

    if (daysSinceActive <= 1) return 1; // بسیار فعال
    if (daysSinceActive <= 3) return 0.9; // فعال
    if (daysSinceActive <= 7) return 0.8; // نسبتاً فعال
    if (daysSinceActive <= 14) return 0.7; // کم‌فعال
    if (daysSinceActive <= 30) return 0.6; // غیرفعال
    if (daysSinceActive <= 60) return 0.4; // بسیار غیرفعال
    return 0.2; // غیرفعال طولانی‌مدت
  }
}
