import 'food_meal_log.dart';
import 'logged_supplement.dart';

class FoodLog {
  final String id;
  final String userId;
  final DateTime logDate;
  final List<FoodMealLog> meals;
  final List<LoggedSupplement> supplements;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.meals,
    required this.supplements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['id'],
      userId: json['user_id'],
      logDate: DateTime.parse(json['log_date']),
      meals: (json['meals'] as List? ?? [])
          .map((m) => FoodMealLog.fromJson(m))
          .toList(),
      supplements: (json['supplements'] as List? ?? [])
          .map((s) => LoggedSupplement.fromJson(s))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'log_date': logDate.toIso8601String().substring(0, 10),
      'meals': meals.map((m) => m.toJson()).toList(),
      'supplements': supplements.map((s) => s.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FoodLog copyWith({
    String? id,
    String? userId,
    DateTime? logDate,
    List<FoodMealLog>? meals,
    List<LoggedSupplement>? supplements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      meals: meals ?? this.meals,
      supplements: supplements ?? this.supplements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodLog &&
        other.id == id &&
        other.userId == userId &&
        other.logDate == logDate &&
        other.meals == meals &&
        other.supplements == supplements &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        logDate.hashCode ^
        meals.hashCode ^
        supplements.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'FoodLog(id: $id, userId: $userId, logDate: $logDate, meals: $meals, supplements: $supplements, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
