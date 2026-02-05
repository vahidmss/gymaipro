class Achievement {
  // راهنمای دستاوردهای مخفی

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.points,
    this.tier = AchievementTier.bronze,
    this.unlockedAt,
    this.isSecret = false,
    this.secretHint,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.general,
      ),
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int,
      unit: json['unit'] as String,
      points: json['points'] as int,
      tier: AchievementTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => AchievementTier.bronze,
      ),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      isSecret: (json['isSecret'] as bool?) ?? false,
      secretHint: json['secretHint'] as String?,
    );
  }
  final String id;
  final String title;
  final String description;
  final String icon; // emoji or icon name
  final AchievementCategory category;
  final int targetValue;
  final int currentValue;
  final String unit; // مثلا "تمرین"، "روز"، "کیلوگرم"
  final int points; // امتیاز دستاورد
  final AchievementTier tier; // سطح دستاورد
  final DateTime? unlockedAt;
  final bool isSecret; // دستاوردهای مخفی
  final String? secretHint;

  bool get isUnlocked => currentValue >= targetValue;

  double get progress {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  int get progressPercentage => (progress * 100).round();

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementCategory? category,
    int? targetValue,
    int? currentValue,
    String? unit,
    int? points,
    AchievementTier? tier,
    DateTime? unlockedAt,
    bool? isSecret,
    String? secretHint,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      points: points ?? this.points,
      tier: tier ?? this.tier,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isSecret: isSecret ?? this.isSecret,
      secretHint: secretHint ?? this.secretHint,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'points': points,
      'tier': tier.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isSecret': isSecret,
      'secretHint': secretHint,
    };
  }
}

enum AchievementCategory {
  workout, // تمرین و فعالیت
  nutrition, // تغذیه
  progress, // پیشرفت شخصی
  social, // اجتماعی
  platform, // پلتفرم
  general, // عمومی
}

enum AchievementTier {
  bronze, // برنزی
  silver, // نقره‌ای
  gold, // طلایی
  platinum, // پلاتینیوم
  diamond, // الماس
}

extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.workout:
        return 'تمرین و فعالیت';
      case AchievementCategory.nutrition:
        return 'تغذیه و سلامت';
      case AchievementCategory.progress:
        return 'پیشرفت شخصی';
      case AchievementCategory.social:
        return 'اجتماعی';
      case AchievementCategory.platform:
        return 'استفاده از اپ';
      case AchievementCategory.general:
        return 'عمومی';
    }
  }

  String get icon {
    switch (this) {
      case AchievementCategory.workout:
        return '💪';
      case AchievementCategory.nutrition:
        return '🥗';
      case AchievementCategory.progress:
        return '📈';
      case AchievementCategory.social:
        return '👥';
      case AchievementCategory.platform:
        return '⭐';
      case AchievementCategory.general:
        return '🎯';
    }
  }
}

extension AchievementTierExtension on AchievementTier {
  String get displayName {
    switch (this) {
      case AchievementTier.bronze:
        return 'برنزی';
      case AchievementTier.silver:
        return 'نقره‌ای';
      case AchievementTier.gold:
        return 'طلایی';
      case AchievementTier.platinum:
        return 'پلاتینیوم';
      case AchievementTier.diamond:
        return 'الماس';
    }
  }

  int get colorValue {
    switch (this) {
      case AchievementTier.bronze:
        return 0xFFCD7F32;
      case AchievementTier.silver:
        return 0xFFC0C0C0;
      case AchievementTier.gold:
        return 0xFFFFD700;
      case AchievementTier.platinum:
        return 0xFFE5E4E2;
      case AchievementTier.diamond:
        return 0xFFB9F2FF;
    }
  }
}
