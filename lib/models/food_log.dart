class FoodLog {
  final String id;
  final String userId;
  final DateTime logDate;
  final List<FoodMealLog> meals;
  final List<LoggedSupplement> supplements; // NEW
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.meals,
    required this.supplements, // NEW
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
      supplements: [], // REMOVE: not in DB schema
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
      // 'supplements': supplements.map((s) => s.toJson()).toList(), // REMOVE: not in DB schema
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

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
}

class FoodLogItem {
  final int foodId;
  final double amount;
  final double? plannedAmount; // مقدار برنامه‌ریزی شده
  final String? mealPlanId; // شناسه برنامه غذایی
  final bool followedPlan; // آیا برنامه رعایت شده
  final List<Map<String, dynamic>>? alternatives; // NEW

  FoodLogItem({
    required this.foodId,
    required this.amount,
    this.plannedAmount,
    this.mealPlanId,
    this.followedPlan = false,
    this.alternatives, // NEW
  });

  factory FoodLogItem.fromJson(Map<String, dynamic> json) {
    return FoodLogItem(
      foodId: json['food_id'],
      amount: (json['amount'] as num).toDouble(),
      plannedAmount: json['planned_amount'] != null
          ? (json['planned_amount'] as num).toDouble()
          : null,
      mealPlanId: json['meal_plan_id'],
      followedPlan: json['followed_plan'] ?? false,
      alternatives: (json['alternatives'] as List?)
          ?.map((e) => {
                'food_id': e['food_id'],
                'amount': (e['amount'] as num).toDouble(),
              })
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'amount': amount,
      'planned_amount': plannedAmount,
      'meal_plan_id': mealPlanId,
      'followed_plan': followedPlan,
      if (alternatives != null) 'alternatives': alternatives,
    };
  }
}

class LoggedSupplement {
  final String name;
  final double? amount;
  final String? unit;
  final String? time;
  final String? note;
  final String supplementType;
  final double? protein;
  final double? carbs;

  LoggedSupplement({
    required this.name,
    this.amount,
    this.unit,
    this.time,
    this.note,
    required this.supplementType,
    this.protein,
    this.carbs,
  });

  factory LoggedSupplement.fromJson(Map<String, dynamic> json) {
    return LoggedSupplement(
      name: json['name'],
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      unit: json['unit'],
      time: json['time'],
      note: json['note'],
      supplementType: json['supplement_type'] ?? 'مکمل',
      protein:
          json['protein'] != null ? (json['protein'] as num).toDouble() : null,
      carbs: json['carbs'] != null ? (json['carbs'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
