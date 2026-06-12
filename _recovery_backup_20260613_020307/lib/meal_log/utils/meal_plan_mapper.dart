import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/models/food_log_item.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/meal_log/models/logged_supplement.dart';
import 'package:gymaipro/models/meal_plan.dart';

class MealPlanMapper {
  /// Maps a meal plan to a food log, preserving existing free foods and consumed plan foods
  static FoodLog? mapPlanToLog({
    required MealPlan selectedPlan,
    required int selectedSession,
    required FoodLog? currentLog,
  }) {
    if (currentLog == null) return null;

    // استخراج غذاهای آزاد (غیر برنامه‌ای) و غذاهای برنامه‌ای قبلی که مصرف شده‌اند
    final freeFoodsByMeal = <String, List<FoodLogItem>>{};
    for (final meal in currentLog.meals) {
      for (final food in meal.foods) {
        // غذای آزاد یا برنامه‌ای قبلی که مصرف شده (amount > 0)
        final isFree = food.mealPlanId == null;
        final isPrevPlan = food.mealPlanId != null;
        if (isFree || (isPrevPlan && food.amount > 0)) {
          freeFoodsByMeal
              .putIfAbsent(meal.title, () => [])
              .add(
                isFree
                    ? food
                    : food.copyWith(
                        mealPlanId: null,
                      ), // برنامه‌ای قبلی به آزاد تبدیل می‌شود (تگ آزاد)
              );
        }
      }
    }

    try {
      final planDay = selectedPlan.days.firstWhere(
        (d) => d.dayOfWeek == selectedSession,
      );
      
      // ساخت وعده‌های برنامه
      final planMeals = planDay.items.whereType<MealItem>().map((meal) {
        // غذاهای آزاد مرتبط با این وعده را پیدا کن
        final freeFoods = freeFoodsByMeal[meal.title] ?? [];
        // لیست غذاهای برنامه‌ای جدید
        final planFoods = meal.foods
            .map(
              (f) => FoodLogItem(
                foodId: f.foodId,
                amount: 0, // Start with 0, user needs to log actual consumption
                plannedAmount: f.amount, // Set planned amount for tracking
                mealPlanId: selectedPlan.id,
                alternatives: f.alternatives,
                unit: 'گرم', // Default unit for plan foods
              ),
            )
            .toList();

        // ادغام غذاهای آزاد و برنامه‌ای قبلی با برنامه جدید (بر اساس foodId و mealTitle)
        for (final freeFood in freeFoods) {
          final idx = planFoods.indexWhere(
            (pf) => pf.foodId == freeFood.foodId,
          );
          if (idx != -1) {
            // اگر غذا در برنامه هست، مقدار مصرفی را جمع بزن
            final planFood = planFoods[idx];
            planFoods[idx] = planFood.copyWith(
              amount: planFood.amount + freeFood.amount,
            );
          } else {
            // اگر نبود، به عنوان غذای آزاد اضافه کن (حتماً mealPlanId و plannedAmount را null کن)
            planFoods.add(freeFood.copyWith(mealPlanId: null));
          }
        }

        return FoodMealLog(
          title: meal.title,
          foods: planFoods,
          note: meal.note,
        );
      }).toList();

      // اگر وعده‌ای از غذاهای آزاد وجود دارد که در برنامه نیست، آن وعده را هم اضافه کن
      for (final entry in freeFoodsByMeal.entries) {
        final mealTitle = entry.key;
        final alreadyInPlan = planMeals.any((m) => m.title == mealTitle);
        if (!alreadyInPlan) {
          // هنگام اضافه کردن وعده آزاد، همه غذاها را به صورت آزاد (mealPlanId/plannedAmount=null) اضافه کن
          planMeals.add(
            FoodMealLog(
              title: mealTitle,
              foods: entry.value
                  .map((f) => f.copyWith(mealPlanId: null))
                  .toList(),
              note: null, // وعده‌های آزاد کامنت ندارند
            ),
          );
        }
      }

      // اطمینان از وجود همه وعده‌های استاندارد (حتی اگر خالی باشند)
      final standardMeals = [
        'صبحانه',
        'میان‌وعده 1',
        'ناهار',
        'میان‌وعده 2',
        'شام',
        'میان‌وعده 3',
      ];
      
      for (final mealTitle in standardMeals) {
        final exists = planMeals.any((m) => m.title == mealTitle);
        if (!exists) {
          planMeals.add(
            FoodMealLog(title: mealTitle, foods: [], note: null),
          );
        }
      }

      // مکمل‌های برنامه
      final supplements = planDay.items.whereType<SupplementEntry>().map((s) {
        return LoggedSupplement(
          name: s.name,
          amount: s.amount,
          unit: s.unit,
          time: s.time,
          note: s.note,
          supplementType: s.supplementType,
          protein: s.protein,
          carbs: s.carbs,
        );
      }).toList();

      return FoodLog(
        id: currentLog.id,
        userId: currentLog.userId,
        logDate: currentLog.logDate,
        meals: planMeals,
        supplements: supplements,
        createdAt: currentLog.createdAt,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }
}
