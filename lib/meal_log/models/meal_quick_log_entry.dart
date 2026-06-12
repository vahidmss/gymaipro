class MealQuickLogEntry {
  const MealQuickLogEntry({
    required this.foodId,
    required this.amount,
    required this.unit,
    required this.mealTitle,
    required this.lastUsed,
  });

  final int foodId;
  final double amount;
  final String unit;
  final String mealTitle;
  final DateTime lastUsed;
}
