/// مدل لیگ برای سیستم رتبه‌بندی
class League {
  const League({
    required this.id,
    required this.name,
    required this.nameFa,
    required this.minScore,
    required this.maxScore,
    required this.color,
    required this.icon,
    required this.description,
  });

  final String id;
  final String name;
  final String nameFa;
  final int minScore;
  final int? maxScore; // null یعنی بی‌نهایت
  final int color;
  final String icon;
  final String description;

  /// لیست تمام لیگ‌ها
  static const List<League> all = [
    bronze,
    silver,
    gold,
    platinum,
    diamond,
  ];

  /// برنز
  static const League bronze = League(
    id: 'bronze',
    name: 'Bronze',
    nameFa: 'برنز',
    minScore: 0,
    maxScore: 1000,
    color: 0xFFCD7F32, // Bronze color
    icon: '🥉',
    description: 'شروع سفر شما به سوی موفقیت',
  );

  /// نقره
  static const League silver = League(
    id: 'silver',
    name: 'Silver',
    nameFa: 'نقره',
    minScore: 1001,
    maxScore: 3000,
    color: 0xFFC0C0C0, // Silver color
    icon: '🥈',
    description: 'در حال پیشرفت و رشد',
  );

  /// طلا
  static const League gold = League(
    id: 'gold',
    name: 'Gold',
    nameFa: 'طلا',
    minScore: 3001,
    maxScore: 7000,
    color: 0xFFFFD700, // Gold color
    icon: '🥇',
    description: 'سطح حرفه‌ای و متعهد',
  );

  /// پلاتینیوم
  static const League platinum = League(
    id: 'platinum',
    name: 'Platinum',
    nameFa: 'پلاتینیوم',
    minScore: 7001,
    maxScore: 15000,
    color: 0xFFE5E4E2, // Platinum color
    icon: '💎',
    description: 'سطح استادی و تخصص',
  );

  /// الماس
  static const League diamond = League(
    id: 'diamond',
    name: 'Diamond',
    nameFa: 'الماس',
    minScore: 15001,
    maxScore: null, // بی‌نهایت
    color: 0xFFB9F2FF, // Diamond color
    icon: '💠',
    description: 'سطح افسانه‌ای و برتر',
  );

  /// پیدا کردن لیگ بر اساس امتیاز
  static League getLeagueByScore(int score) {
    for (final league in all.reversed) {
      if (score >= league.minScore) {
        return league;
      }
    }
    return bronze;
  }

  /// بررسی اینکه آیا امتیاز در این لیگ است
  bool isScoreInLeague(int score) {
    if (score < minScore) return false;
    if (maxScore == null) return true;
    return score <= maxScore!;
  }

  /// محاسبه امتیاز لیگ (امتیاز منهای حداقل لیگ)
  int calculateLeaguePoints(int totalScore) {
    return (totalScore - minScore).clamp(0, double.infinity).toInt();
  }

  /// درصد پیشرفت به سمت لیگ بعدی
  double getProgressToNextLeague(int currentScore) {
    if (maxScore == null) return 1; // الماس - حداکثر
    if (currentScore < minScore) return 0;
    if (currentScore >= maxScore!) return 1;
    
    final range = maxScore! - minScore;
    final progress = currentScore - minScore;
    return (progress / range).clamp(0.0, 1.0);
  }

  /// لیگ بعدی
  League? get nextLeague {
    final index = all.indexOf(this);
    if (index < 0 || index >= all.length - 1) return null;
    return all[index + 1];
  }

  /// لیگ قبلی
  League? get previousLeague {
    final index = all.indexOf(this);
    if (index <= 0) return null;
    return all[index - 1];
  }
}
