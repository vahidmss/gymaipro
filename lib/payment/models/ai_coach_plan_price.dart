/// مدل قیمت فروش پلن مربی هوشمند (تنظیمات ادمین)
class AiCoachPlanPrice {
  const AiCoachPlanPrice({
    required this.id,
    required this.planId,
    required this.title,
    required this.description,
    required this.priceRial,
    required this.validityDays,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory AiCoachPlanPrice.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = <String>[];
    if (rawFeatures is List) {
      for (final item in rawFeatures) {
        final text = item?.toString().trim();
        if (text != null && text.isNotEmpty) features.add(text);
      }
    }

    return AiCoachPlanPrice(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      title: json['title'] as String? ?? json['plan_id'] as String,
      description: json['description'] as String? ?? '',
      priceRial: (json['price_rial'] as num).toInt(),
      validityDays: (json['validity_days'] as num?)?.toInt() ?? 31,
      features: features,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String planId;
  final String title;
  final String description;
  final int priceRial;
  final int validityDays;
  final List<String> features;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'title': title,
      'description': description,
      'price_rial': priceRial,
      'validity_days': validityDays,
      'features': features,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
