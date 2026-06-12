import 'package:gymaipro/meal_log/models/food_log_item.dart';

class FoodMealLog {
  FoodMealLog({
    required this.title,
    required this.foods,
    this.note,
  });

  factory FoodMealLog.fromJson(Map<String, dynamic> json) {
    return FoodMealLog(
      title: (json['title'] as String?) ?? json['title'].toString(),
      foods: (json['foods'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FoodLogItem.fromJson)
          .toList(),
      note: json['note'] as String?,
    );
  }
  final String title;
  final List<FoodLogItem> foods;
  final String? note;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'foods': foods.map((f) => f.toJson()).toList(),
    };
    if (note != null) {
      json['note'] = note;
    }
    return json;
  }

  FoodMealLog copyWith({
    String? title,
    List<FoodLogItem>? foods,
    String? note,
  }) {
    return FoodMealLog(
      title: title ?? this.title,
      foods: foods ?? this.foods,
      note: note ?? this.note,
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
