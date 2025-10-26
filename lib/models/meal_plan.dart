class MealPlan {
  const MealPlan({
    required this.id,
    required this.userId,
    required this.planName,
    required this.days,
    required this.createdAt,
    required this.updatedAt,
    this.restrictions,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    // Handle new schema with 'data' field
    Map<String, dynamic> data;
    if (json['data'] != null && json['data'] is Map) {
      data = json['data'] as Map<String, dynamic>;
    } else {
      // Fallback to old schema for backward compatibility
      data = json;
    }

    return MealPlan(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      planName: (json['plan_name'] as String?) ?? '',
      days: (data['days'] as List<dynamic>? ?? [])
          .map((d) => MealPlanDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      restrictions: (data['restrictions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }
  final String id;
  final String userId;
  final String planName;
  final List<MealPlanDay> days;
  final List<String>? restrictions; // new: list of restrictions
  final DateTime createdAt;
  final DateTime updatedAt;

  // Helper method to get the data object for JSON storage
  Map<String, dynamic> get dataObject {
    final data = <String, dynamic>{
      'days': days.map((d) => d.toJson()).toList(),
    };
    if (restrictions != null) {
      data['restrictions'] = restrictions;
    }
    return data;
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'plan_name': planName,
      'data': dataObject, // Use the data object for JSONB storage
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }
}

// Base class for all day items (meals and supplements)
abstract class DayItem {
  // 'meal' or 'supplement'

  const DayItem({required this.id, required this.type});

  factory DayItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (type == 'meal') {
      return MealItem.fromJson(json);
    } else if (type == 'supplement') {
      return SupplementEntry.fromJson(json);
    }
    throw Exception('Unknown DayItem type: $type');
  }
  final String id;
  final String type;

  Map<String, dynamic> toJson();
}

class MealPlanDay {
  // unified list of meals and supplements

  const MealPlanDay({required this.dayOfWeek, required this.items});

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    List<DayItem> items = [];

    // Handle new unified format
    if (json['items'] != null) {
      items = (json['items'] as List<dynamic>)
          .map((item) => DayItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Handle legacy format for backward compatibility
      if (json['meals'] != null) {
        items.addAll(
          (json['meals'] as List<dynamic>)
              .map((m) => MealItem.fromJson(m as Map<String, dynamic>))
              .toList(),
        );
      }
      if (json['supplements'] != null) {
        items.addAll(
          (json['supplements'] as List<dynamic>)
              .map((s) => SupplementEntry.fromJson(s as Map<String, dynamic>))
              .toList(),
        );
      }
    }

    return MealPlanDay(dayOfWeek: json['day_of_week'] as int, items: items);
  }
  final int dayOfWeek; // 0=شنبه ... 6=جمعه
  final List<DayItem> items;

  // Helper getters for backward compatibility
  List<MealItem> get meals => items.whereType<MealItem>().toList();
  List<SupplementEntry> get supplements =>
      items.whereType<SupplementEntry>().toList();

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class MealItem extends DayItem {
  MealItem({
    required this.mealType,
    required this.title,
    required this.foods,
    String? id,
    this.note,
  }) : super(id: id ?? _generateId(), type: 'meal');

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] as String,
      mealType:
          (json['meal_type'] as String?) ??
          (json['type'] as String?) ??
          'main', // backward compatibility
      title: json['title'] as String,
      foods: (json['foods'] as List<dynamic>? ?? <dynamic>[])
          .map((f) => MealFood.fromJson(f as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
    );
  }
  final String
  mealType; // 'breakfast', 'lunch', 'dinner', 'snack1', 'snack2', etc.
  final String title;
  final List<MealFood> foods;
  final String? note;

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': type,
      'meal_type': mealType,
      'title': title,
      'foods': foods.map((f) => f.toJson()).toList(),
    };
    if (note != null) {
      json['note'] = note;
    }
    return json;
  }
}

class MealFood {
  // [{food_id, amount}]

  const MealFood({
    required this.foodId,
    required this.amount,
    this.unit,
    this.alternatives,
  });

  factory MealFood.fromJson(Map<String, dynamic> json) {
    return MealFood(
      foodId: json['food_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String?,
      alternatives: (json['alternatives'] as List<dynamic>?)
          ?.map(
            (e) => <String, dynamic>{
              'food_id': (e as Map<String, dynamic>)['food_id'] as int,
              'amount': (e['amount'] as num).toDouble(),
            },
          )
          .toList(),
    );
  }
  final int foodId;
  final double amount;
  final String? unit; // new: custom unit (e.g. گرم، عدد، کف دست)
  final List<Map<String, dynamic>>? alternatives;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'food_id': foodId, 'amount': amount};
    if (unit != null) {
      json['unit'] = unit;
    }
    if (alternatives != null) {
      json['alternatives'] = alternatives;
    }
    return json;
  }
}

// Supplement/Drug entry for a day
class SupplementEntry extends DayItem {
  // گرم کربوهیدرات

  SupplementEntry({
    required this.name,
    required this.supplementType,
    String? id,
    this.amount,
    this.unit,
    this.time,
    this.note,
    this.protein,
    this.carbs,
  }) : super(id: id ?? _generateId(), type: 'supplement');

  factory SupplementEntry.fromJson(Map<String, dynamic> json) {
    return SupplementEntry(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      unit: json['unit'] as String?,
      time: json['time'] as String?,
      note: json['note'] as String?,
      supplementType:
          (json['supplement_type'] as String?) ??
          (json['type'] as String?) ??
          'مکمل', // backward compatibility
      protein: json['protein'] != null
          ? (json['protein'] as num).toDouble()
          : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
    );
  }
  final String name;
  final double? amount;
  final String? unit;
  final String? time;
  final String? note;
  final String supplementType; // "مکمل" یا "دارو"
  final double? protein; // گرم پروتئین
  final double? carbs;

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (time != null) 'time': time,
      if (note != null) 'note': note,
      'supplement_type': supplementType,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
    };
  }
}
