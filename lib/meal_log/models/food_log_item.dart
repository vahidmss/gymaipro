class FoodLogItem {
  // جایگزین‌های غذا

  FoodLogItem({
    required this.foodId,
    required this.amount,
    this.plannedAmount,
    this.mealPlanId,
    this.followedPlan = false,
    this.alternatives,
    this.unit = 'گرم',
  });

  factory FoodLogItem.fromJson(Map<String, dynamic> json) {
    return FoodLogItem(
      foodId: (json['food_id'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
      plannedAmount: json['planned_amount'] != null
          ? (json['planned_amount'] as num).toDouble()
          : null,
      mealPlanId: json['meal_plan_id'] as String?,
      followedPlan: (json['followed_plan'] as bool?) ?? false,
      alternatives: (json['alternatives'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(
            (e) => {
              'food_id': (e['food_id'] as num).toInt(),
              'amount': (e['amount'] as num).toDouble(),
            },
          )
          .toList(),
      unit: json['unit'] as String? ?? 'گرم',
    );
  }
  final int foodId;
  final double amount;
  final double? plannedAmount; // مقدار برنامه‌ریزی شده
  final String? mealPlanId; // شناسه برنامه غذایی
  final bool followedPlan; // آیا برنامه رعایت شده
  final List<Map<String, dynamic>>? alternatives;
  final String unit; // واحد (گرم یا عدد)

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'amount': amount,
      'planned_amount': plannedAmount,
      'meal_plan_id': mealPlanId,
      'followed_plan': followedPlan,
      'unit': unit,
      if (alternatives != null) 'alternatives': alternatives,
    };
  }

  FoodLogItem copyWith({
    int? foodId,
    double? amount,
    double? plannedAmount,
    Object? mealPlanId = _noValue,
    bool? followedPlan,
    List<Map<String, dynamic>>? alternatives,
    String? unit,
  }) {
    return FoodLogItem(
      foodId: foodId ?? this.foodId,
      amount: amount ?? this.amount,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      mealPlanId: mealPlanId == _noValue
          ? this.mealPlanId
          : mealPlanId as String?,
      followedPlan: followedPlan ?? this.followedPlan,
      alternatives: alternatives ?? this.alternatives,
      unit: unit ?? this.unit,
    );
  }

  static const _noValue = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodLogItem &&
        other.foodId == foodId &&
        other.amount == amount &&
        other.plannedAmount == plannedAmount &&
        other.mealPlanId == mealPlanId &&
        other.followedPlan == followedPlan &&
        other.alternatives == alternatives &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return foodId.hashCode ^
        amount.hashCode ^
        plannedAmount.hashCode ^
        mealPlanId.hashCode ^
        followedPlan.hashCode ^
        alternatives.hashCode ^
        unit.hashCode;
  }

  @override
  String toString() {
    return 'FoodLogItem(foodId: $foodId, amount: $amount, plannedAmount: $plannedAmount, mealPlanId: $mealPlanId, followedPlan: $followedPlan, alternatives: $alternatives)';
  }
}
