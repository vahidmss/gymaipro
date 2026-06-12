import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/data/meal_log_guide_data.dart';
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
    super.key,
  });

  final FoodLog? currentLog;
  final List<Food> allFoods;
  final void Function(String) onAddFood;
  final void Function(FoodLogItem, String) onEditAmount;
  final void Function(String, FoodLogItem, String) onFoodAction;
  final Map<String, dynamic>? profileData;

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

    return Column(
      children: mealOrder.asMap().entries.map((entry) {
        final mealTitle = entry.value;
        final foodItems = _getFoodItemsForMeal(mealTitle);
        final mealNote = _getMealNote(mealTitle);
        
        // اضافه کردن key فقط برای صبحانه
        final GlobalKey? sectionKey = mealTitle == 'صبحانه' 
            ? MealLogGuideData.keys['breakfast_section']
            : null;
        
        return Column(
          children: [
            MealSection(
              key: sectionKey,
              title: mealTitle,
              icon: MealLogUtils.getMealIcon(mealTitle),
              foodItems: foodItems,
              allFoods: allFoods,
              onAddFood: () => onAddFood(mealTitle),
              onEditAmount: onEditAmount,
              onFoodAction: onFoodAction,
              dailyCalorieTarget: dailyCalorieTarget,
              note: mealNote,
            ),
            SizedBox(height: 16.h),
          ],
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
