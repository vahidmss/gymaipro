import 'food_log_item.dart';

class FoodMealLog {
  final String title;
  final List<FoodLogItem> foods;

  FoodMealLog({required this.title, required this.foods});

  factory FoodMealLog.fromJson(Map<String, dynamic> json) {
    return FoodMealLog(
      title: json['title'],
      foods: (json['foods'] as List? ?? [])
          .map((f) => FoodLogItem.fromJson(f))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'foods': foods.map((f) => f.toJson()).toList(),
    };
  }

  FoodMealLog copyWith({
    String? title,
    List<FoodLogItem>? foods,
  }) {
    return FoodMealLog(
      title: title ?? this.title,
      foods: foods ?? this.foods,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodMealLog && other.title == title && other.foods == foods;
  }

  @override
  int get hashCode {
    return title.hashCode ^ foods.hashCode;
  }

  @override
  String toString() {
    return 'FoodMealLog(title: $title, foods: $foods)';
  }
}
