import 'package:flutter/material.dart';
import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/meal_section.dart';
import 'package:gymaipro/models/food.dart';

class MealsListWidget extends StatelessWidget {
  const MealsListWidget({
    required this.currentLog,
    required this.allFoods,
    required this.onAddFood,
    required this.onEditAmount,
    required this.onFoodAction,
    this.profileData,
    this.highlightMealTitle,
    super.key,
  });

  final FoodLog? currentLog;
  final List<Food> allFoods;
  final void Function(String) onAddFood;
  final void Function(FoodLogItem, String) onEditAmount;
  final void Function(String, FoodLogItem, String) onFoodAction;
  final Map<String, dynamic>? profileData;
  final String? highlightMealTitle;

  @override
  Widget build(BuildContext context) {
    // ترتیب وعده‌ها: صبحانه، میان‌وعده 1، ناهار، میان‌وعده 2، شام، میان‌وعده 3
    final mealOrder = [
      'صبحانه',
      'میان‌وعده 1',
      'ناهار',
      'میان‌وعده 2',
      'شام',
      'میان‌وعده 3',
    ];

    // محاسبه daily calorie target
    final dailyCalorieTarget = MealLogUtils.calculateDailyCalorieTarget(
      profileData,
    );

    final firstEmptyTitle = mealOrder.cast<String?>().firstWhere(
      (title) => _getFoodItemsForMeal(title!).isEmpty,
      orElse: () => null,
    );

    return Column(
      children: mealOrder.map((mealTitle) {
        final foodItems = _getFoodItemsForMeal(mealTitle);
        final mealNote = _getMealNote(mealTitle);
        final isHighlighted = highlightMealTitle == mealTitle;

        return MealSection(
          title: mealTitle,
          icon: MealLogUtils.getMealIcon(mealTitle),
          foodItems: foodItems,
          allFoods: allFoods,
          onAddFood: () => onAddFood(mealTitle),
          onEditAmount: onEditAmount,
          onFoodAction: onFoodAction,
          dailyCalorieTarget: dailyCalorieTarget,
          note: mealNote,
          isHighlighted: isHighlighted,
          showEmptyHint: foodItems.isEmpty && firstEmptyTitle == mealTitle,
        );
      }).toList(),
    );
  }

  List<FoodLogItem> _getFoodItemsForMeal(String mealTitle) {
    if (currentLog == null) {
      return [];
    }

    return currentLog!.meals
        .where((meal) => meal.title == mealTitle)
        .expand((meal) => meal.foods)
        .toList();
  }

  String? _getMealNote(String mealTitle) {
    if (currentLog == null) {
      return null;
    }

    final meal = currentLog!.meals.firstWhere(
      (meal) => meal.title == mealTitle,
      orElse: () => FoodMealLog(title: mealTitle, foods: []),
    );
    return meal.note;
  }
}
