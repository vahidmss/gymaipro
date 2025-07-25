class MealPlan {
  final String id;
  final String userId;
  final String planName;
  final List<MealPlanDay> days;
  final List<String>? restrictions; // new: list of restrictions
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlan({
    required this.id,
    required this.userId,
    required this.planName,
    required this.days,
    this.restrictions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'],
      userId: json['user_id'],
      planName: json['plan_name'],
      days: (json['days'] as List? ?? [])
          .map((d) => MealPlanDay.fromJson(d))
          .toList(),
      restrictions:
          (json['restrictions'] as List?)?.map((e) => e.toString()).toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'plan_name': planName,
      'days': days.map((d) => d.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (restrictions != null) {
      json['restrictions'] = restrictions as List<dynamic>;
    }
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    return json;
  }
}

// Base class for all day items (meals and supplements)
abstract class DayItem {
  final String id;
  final String type; // 'meal' or 'supplement'

  DayItem({required this.id, required this.type});

  Map<String, dynamic> toJson();

  factory DayItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (type == 'meal') {
      return MealItem.fromJson(json);
    } else if (type == 'supplement') {
      return SupplementEntry.fromJson(json);
    }
    throw Exception('Unknown DayItem type: $type');
  }
}

class MealPlanDay {
  final int dayOfWeek; // 0=شنبه ... 6=جمعه
  final List<DayItem> items; // unified list of meals and supplements

  MealPlanDay({required this.dayOfWeek, required this.items});

  // Helper getters for backward compatibility
  List<MealItem> get meals => items.whereType<MealItem>().toList();
  List<SupplementEntry> get supplements =>
      items.whereType<SupplementEntry>().toList();

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    List<DayItem> items = [];

    // Handle new unified format
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => DayItem.fromJson(item))
          .toList();
    } else {
      // Handle legacy format for backward compatibility
      if (json['meals'] != null) {
        items.addAll(
            (json['meals'] as List).map((m) => MealItem.fromJson(m)).toList());
      }
      if (json['supplements'] != null) {
        items.addAll((json['supplements'] as List)
            .map((s) => SupplementEntry.fromJson(s))
            .toList());
      }
    }

    return MealPlanDay(
      dayOfWeek: json['day_of_week'],
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class MealItem extends DayItem {
  final String
      mealType; // 'breakfast', 'lunch', 'dinner', 'snack1', 'snack2', etc.
  final String title;
  final List<MealFood> foods;
  final String? note;

  MealItem({
    String? id,
    required this.mealType,
    required this.title,
    required this.foods,
    this.note,
  }) : super(id: id ?? _generateId(), type: 'meal');

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'],
      mealType:
          json['meal_type'] ?? json['type'] ?? 'main', // backward compatibility
      title: json['title'],
      foods: (json['foods'] as List? ?? [])
          .map((f) => MealFood.fromJson(f))
          .toList(),
      note: json['note'],
    );
  }

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
      json['note'] = note!;
    }
    return json;
  }
}

class MealFood {
  final int foodId;
  final double amount;
  final String? unit; // new: custom unit (e.g. گرم، عدد، کف دست)
  final List<Map<String, dynamic>>? alternatives; // [{food_id, amount}]

  MealFood({
    required this.foodId,
    required this.amount,
    this.unit,
    this.alternatives,
  });

  factory MealFood.fromJson(Map<String, dynamic> json) {
    return MealFood(
      foodId: json['food_id'],
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'],
      alternatives: (json['alternatives'] as List?)
          ?.map((e) => {
                'food_id': e['food_id'],
                'amount': (e['amount'] as num).toDouble(),
              })
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'food_id': foodId,
      'amount': amount,
    };
    if (unit != null) {
      json['unit'] = unit as String;
    }
    if (alternatives != null) {
      json['alternatives'] = alternatives;
    }
    return json;
  }
}

// Supplement/Drug entry for a day
class SupplementEntry extends DayItem {
  final String name;
  final double? amount;
  final String? unit;
  final String? time;
  final String? note;
  final String supplementType; // "مکمل" یا "دارو"
  final double? protein; // گرم پروتئین
  final double? carbs; // گرم کربوهیدرات

  SupplementEntry({
    String? id,
    required this.name,
    this.amount,
    this.unit,
    this.time,
    this.note,
    required this.supplementType,
    this.protein,
    this.carbs,
  }) : super(id: id ?? _generateId(), type: 'supplement');

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  factory SupplementEntry.fromJson(Map<String, dynamic> json) {
    return SupplementEntry(
      id: json['id'],
      name: json['name'],
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      unit: json['unit'],
      time: json['time'],
      note: json['note'],
      supplementType: json['supplement_type'] ??
          json['type'] ??
          'مکمل', // backward compatibility
      protein:
          json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
    );
  }

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
