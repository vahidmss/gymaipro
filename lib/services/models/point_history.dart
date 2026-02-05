/// مدل تاریخچه امتیازات کسب شده
class PointHistory {
  PointHistory({
    required this.id,
    required this.points,
    required this.source,
    required this.sourceId,
    required this.sourceTitle,
    required this.sourceIcon,
    required this.earnedAt,
    this.description,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) {
    return PointHistory(
      id: json['id'] as String,
      points: (json['points'] as num).toInt(),
      source: PointSource.values.firstWhere(
        (e) => e.name == (json['source'] as String),
        orElse: () => PointSource.achievement,
      ),
      sourceId: json['source_id'] as String?,
      sourceTitle: json['source_title'] as String,
      sourceIcon: json['source_icon'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
      description: json['description'] as String?,
    );
  }

  final String id;
  final int points;
  final PointSource source;
  final String? sourceId; // ID دستاورد یا منبع دیگر
  final String sourceTitle; // عنوان دستاورد یا منبع
  final String sourceIcon; // آیکون دستاورد یا منبع
  final DateTime earnedAt;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points,
      'source': source.name,
      'sourceId': sourceId,
      'sourceTitle': sourceTitle,
      'sourceIcon': sourceIcon,
      'earnedAt': earnedAt.toIso8601String(),
      'description': description,
    };
  }
}

enum PointSource {
  achievement, // از دستاورد
  dailyCheckIn, // چک‌این روزانه
  workout, // تمرین
  nutrition, // تغذیه
  social, // فعالیت اجتماعی
  other, // سایر
}

extension PointSourceExtension on PointSource {
  String get displayName {
    switch (this) {
      case PointSource.achievement:
        return 'دستاورد';
      case PointSource.dailyCheckIn:
        return 'چک‌این روزانه';
      case PointSource.workout:
        return 'تمرین';
      case PointSource.nutrition:
        return 'تغذیه';
      case PointSource.social:
        return 'اجتماعی';
      case PointSource.other:
        return 'سایر';
    }
  }
}

