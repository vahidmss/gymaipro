import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/meal_log/services/meal_log_service.dart';
import 'package:gymaipro/models/food.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealLogController {
  final MealLogService _foodLogService = MealLogService();

  /// Adds a meal with specific type to the log
  FoodLog addMealWithType({
    required String mealType,
    required FoodLog? currentLog,
    required DateTime selectedDate,
  }) {
    // Initialize log if needed
    final FoodLog log =
        currentLog ??
        FoodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: Supabase.instance.client.auth.currentUser?.id ?? '',
          logDate: selectedDate,
          meals: [],
          supplements: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    // Check if meal already exists (for non-snack meals)
    if (mealType != 'میان‌وعده') {
      final existingMeal = log.meals.firstWhere(
        (meal) => meal.title == mealType,
        orElse: () => FoodMealLog(title: '', foods: []),
      );

      if (existingMeal.title.isNotEmpty) {
        return log; // Meal already exists
      }
    }

    // Count existing snacks to generate next number
    int snackCount = 0;
    for (final meal in log.meals) {
      if (meal.title.startsWith('میان‌وعده')) {
        snackCount++;
      }
    }

    String title;
    if (mealType == 'میان‌وعده') {
      title = 'میان‌وعده ${snackCount + 1}';
    } else {
      title = mealType;
    }

    log.meals.add(FoodMealLog(title: title, foods: []));
    _foodLogService.saveLogLocal(log);
    return log;
  }

  /// Adds food to a specific meal
  Future<FoodLog> addFoodToMeal({
    required FoodLog currentLog,
    required String mealTitle,
    required Food food,
    required double amount,
    String unit = 'گرم',
  }) async {
    // Find or create meal
    FoodMealLog? meal = currentLog.meals.firstWhere(
      (m) => m.title == mealTitle,
      orElse: () => FoodMealLog(title: mealTitle, foods: []),
    );

    if (meal.title.isEmpty) {
      meal = FoodMealLog(title: mealTitle, foods: []);
      currentLog.meals.add(meal);
    }

    // Add the food to the meal
    final newFoodItem = FoodLogItem(
      foodId: food.id,
      amount: amount,
      unit: unit,
    );
    meal.foods.add(newFoodItem);

    _foodLogService.saveLogLocal(currentLog);
    // ذخیره در سرور در پس‌زمینه تا UI فوراً به‌روز شود
    _foodLogService.saveLog(currentLog).catchError((e) {
      // خطا فقط local ذخیره شده؛ در لاگ بی‌صدا نگه می‌داریم
    });
    return currentLog;
  }

  /// Removes food from a specific meal
  Future<FoodLog> removeFoodFromMeal({
    required FoodLog currentLog,
    required FoodLogItem foodItem,
    required String mealTitle,
  }) async {
    final meal = currentLog.meals.firstWhere((m) => m.title == mealTitle);
    meal.foods.remove(foodItem);
    _foodLogService.saveLogLocal(currentLog);
    // سعی در sync به دیتابیس (اگر آنلاین باشیم)
    try {
      await _foodLogService.saveLog(currentLog);
    } catch (e) {
      // اگر آنلاین نبودیم، فقط local ذخیره شده
    }
    return currentLog;
  }

  /// Updates food amount in a specific meal
  Future<FoodLog> updateFoodAmount({
    required FoodLog currentLog,
    required FoodLogItem foodItem,
    required String mealTitle,
    required double newAmount,
    String? unit,
  }) async {
    final meal = currentLog.meals.firstWhere(
      (m) => m.title == mealTitle,
      orElse: () => FoodMealLog(title: mealTitle, foods: []),
    );

    final index = meal.foods.indexOf(foodItem);
    if (index != -1) {
      meal.foods[index] = foodItem.copyWith(
        amount: newAmount,
        unit: unit ?? foodItem.unit,
      );
    }

    _foodLogService.saveLogLocal(currentLog);
    // سعی در sync به دیتابیس (اگر آنلاین باشیم)
    try {
      await _foodLogService.saveLog(currentLog);
    } catch (e) {
      // اگر آنلاین نبودیم، فقط local ذخیره شده
    }
    return currentLog;
  }

  /// Marks food as complete (sets amount to planned amount)
  Future<FoodLog> markFoodAsComplete({
    required FoodLog currentLog,
    required FoodLogItem foodItem,
    required String mealTitle,
  }) async {
    final plannedAmount = foodItem.plannedAmount ?? foodItem.amount;
    final meal = currentLog.meals.firstWhere(
      (m) => m.title == mealTitle,
      orElse: () => FoodMealLog(title: mealTitle, foods: []),
    );

    final index = meal.foods.indexOf(foodItem);
    if (index != -1) {
      meal.foods[index] = FoodLogItem(
        foodId: foodItem.foodId,
        amount: plannedAmount,
        plannedAmount: foodItem.plannedAmount,
        mealPlanId: foodItem.mealPlanId,
        followedPlan: true,
        alternatives: foodItem.alternatives,
        unit: foodItem.unit,
      );
    }

    _foodLogService.saveLogLocal(currentLog);
    // سعی در sync به دیتابیس (اگر آنلاین باشیم)
    try {
      await _foodLogService.saveLog(currentLog);
    } catch (e) {
      // اگر آنلاین نبودیم، فقط local ذخیره شده
    }
    return currentLog;
  }

  /// Substitutes food with an alternative
  Future<FoodLog> substituteFood({
    required FoodLog currentLog,
    required FoodLogItem foodItem,
    required String mealTitle,
    required Map<String, dynamic> selectedAlternative,
  }) async {
    final meal = currentLog.meals.firstWhere(
      (m) => m.title == mealTitle,
      orElse: () => FoodMealLog(title: mealTitle, foods: []),
    );

    final index = meal.foods.indexOf(foodItem);
    if (index != -1) {
      final alternatives = foodItem.alternatives ?? [];
      final newAlternatives = List<Map<String, dynamic>>.from(alternatives);
      newAlternatives.removeWhere(
        (alt) => alt['food_id'] == selectedAlternative['food_id'],
      );
      newAlternatives.add({
        'food_id': foodItem.foodId,
        'amount': foodItem.plannedAmount ?? foodItem.amount,
      });

      meal.foods[index] = FoodLogItem(
        foodId: selectedAlternative['food_id'] as int,
        amount: 0,
        plannedAmount:
            (selectedAlternative['amount'] as num?)?.toDouble() ?? 0.0,
        mealPlanId: foodItem.mealPlanId,
        alternatives: newAlternatives,
        unit: foodItem.unit,
      );
    }

    _foodLogService.saveLogLocal(currentLog);
    // سعی در sync به دیتابیس (اگر آنلاین باشیم)
    try {
      await _foodLogService.saveLog(currentLog);
    } catch (e) {
      // اگر آنلاین نبودیم، فقط local ذخیره شده
    }
    return currentLog;
  }
}
