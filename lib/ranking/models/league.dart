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

  static const List<League> all = [
    bronze,
    silver,
    gold,
    platinum,
    diamond,
  ];

  /// آستانه‌ها با مقیاس امتیاز واقعی اپ هم‌خوان شده‌اند
  /// (کاربر تازه‌کار سریع از برنز خالی خارج می‌شود).
  static const League bronze = League(
    id: 'bronze',
    name: 'Bronze',
    nameFa: 'برنز',
    minScore: 0,
    maxScore: 299,
    color: 0xFFCD7F32,
    icon: '🥉',
    description: 'شروع مسیر',
  );

  static const League silver = League(
    id: 'silver',
    name: 'Silver',
    nameFa: 'نقره',
    minScore: 300,
    maxScore: 999,
    color: 0xFF9E9E9E,
    icon: '🥈',
    description: 'در حال رشد',
  );

  static const League gold = League(
    id: 'gold',
    name: 'Gold',
    nameFa: 'طلا',
    minScore: 1000,
    maxScore: 2499,
    color: 0xFFD4AF37,
    icon: '🥇',
    description: 'سطح جدی',
  );

  static const League platinum = League(
    id: 'platinum',
    name: 'Platinum',
    nameFa: 'پلاتینیوم',
    minScore: 2500,
    maxScore: 5999,
    color: 0xFF7A7A80,
    icon: '💎',
    description: 'سطح بالا',
  );

  static const League diamond = League(
    id: 'diamond',
    name: 'Diamond',
    nameFa: 'الماس',
    minScore: 6000,
    maxScore: null,
    color: 0xFF5BC0DE,
    icon: '💠',
    description: 'بالاترین سطح',
  );

  static League getLeagueByScore(int score) {
    for (final league in all.reversed) {
      if (score >= league.minScore) return league;
    }
    return bronze;
  }

  static League byId(String id) {
    return all.firstWhere((l) => l.id == id, orElse: () => bronze);
  }

  bool isScoreInLeague(int score) {
    if (score < minScore) return false;
    if (maxScore == null) return true;
    return score <= maxScore!;
  }

  int calculateLeaguePoints(int totalScore) {
    return (totalScore - minScore).clamp(0, double.infinity).toInt();
  }

  double getProgressToNextLeague(int currentScore) {
    if (maxScore == null) return 1;
    if (currentScore < minScore) return 0;
    if (currentScore >= maxScore!) return 1;
    final range = maxScore! - minScore;
    if (range <= 0) return 1;
    return ((currentScore - minScore) / range).clamp(0.0, 1.0);
  }

  League? get nextLeague {
    final index = all.indexOf(this);
    if (index < 0 || index >= all.length - 1) return null;
    return all[index + 1];
  }

  League? get previousLeague {
    final index = all.indexOf(this);
    if (index <= 0) return null;
    return all[index - 1];
  }
}
