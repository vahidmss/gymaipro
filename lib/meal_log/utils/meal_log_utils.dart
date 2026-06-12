import 'package:flutter/material.dart';
import 'package:gymaipro/meal_log/models/food_meal_log.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/fitness_calculator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class MealLogUtils {
  // ... existing code ...

  /// Returns appropriate icon for meal type based on title
  static IconData getMealIcon(String title) {
    if (title.contains('صبحانه')) return LucideIcons.sunrise;
    if (title.contains('ناهار')) return LucideIcons.sun;
    if (title.contains('شام')) return LucideIcons.moon;
    if (title.contains('میان‌وعده')) return LucideIcons.coffee;
    return LucideIcons.utensils;
  }

  /// Returns appropriate image asset path for meal type based on title
  static String getMealImageAsset(String title) {
    if (title.contains('صبحانه')) return 'images/breakfast.png';
    if (title.contains('ناهار')) return 'images/lunch.png';
    if (title.contains('شام')) return 'images/dinner.png';
    if (title.contains('میان‌وعده')) return 'images/snack.png';
    return 'images/gymaifoodplaceholder.png';
  }

  /// Returns recommended calorie range for a meal type
  /// Returns a map with 'min' and 'max' keys
  static Map<String, int> getRecommendedCalorieRange(
    String mealTitle,
    double? dailyCalorieTarget,
  ) {
    // If daily target is available, calculate based on percentages
    if (dailyCalorieTarget != null && dailyCalorieTarget > 0) {
      if (mealTitle.contains('صبحانه')) {
        return {
          'min': (dailyCalorieTarget * 0.20).round(),
          'max': (dailyCalorieTarget * 0.25).round(),
        };
      } else if (mealTitle.contains('ناهار')) {
        return {
          'min': (dailyCalorieTarget * 0.30).round(),
          'max': (dailyCalorieTarget * 0.35).round(),
        };
      } else if (mealTitle.contains('شام')) {
        return {
          'min': (dailyCalorieTarget * 0.25).round(),
          'max': (dailyCalorieTarget * 0.30).round(),
        };
      } else if (mealTitle.contains('میان‌وعده')) {
        return {
          'min': (dailyCalorieTarget * 0.05).round(),
          'max': (dailyCalorieTarget * 0.10).round(),
        };
      }
    }

    // Default ranges (for 2000 calorie diet)
    if (mealTitle.contains('صبحانه')) {
      return {'min': 400, 'max': 500};
    } else if (mealTitle.contains('ناهار')) {
      return {'min': 600, 'max': 700};
    } else if (mealTitle.contains('شام')) {
      return {'min': 500, 'max': 600};
    } else if (mealTitle.contains('میان‌وعده')) {
      return {'min': 100, 'max': 200};
    }

    return {'min': 200, 'max': 300};
  }

  /// Calculates daily calorie target (TDEE) from profile data
  static double calculateDailyCalorieTarget(
    Map<String, dynamic>? profileData,
  ) {
    if (profileData == null) return 2000.0; // مقدار پیش‌فرض

    final height =
        double.tryParse((profileData['height'] as String?) ?? '') ?? 0;
    // استفاده از آخرین وزن ثبت شده یا وزن پروفایل
    final latestWeight = profileData['latest_weight'] as double?;
    final weight =
        latestWeight ??
        double.tryParse((profileData['weight'] as String?) ?? '') ??
        0;
    final birthDateStr = profileData['birth_date'] as String?;
    final isMale = (profileData['gender'] as String?) == 'male';

    // محاسبه سن
    int age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        final now = DateTime.now();
        age =
            now.year -
            birthDate.year -
            ((now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day))
                ? 1
                : 0);
      } catch (_) {
        age = 25;
      }
    }

    // اگر اطلاعات کافی نداریم، مقدار پیش‌فرض برگردان
    if (height <= 0 || weight <= 0 || age <= 0) {
      return 2000.0;
    }

    // محاسبه BMR
    final bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);

    // محاسبه TDEE با استفاده از activity_level واقعی از پروفایل
    final activityLevelStr =
        (profileData['activity_level'] as String?) ?? 'moderate';
    final activityLevel = activityLevelStr.toActivityLevel();
    final tdee = FitnessCalculator.calculateTDEE(bmr, activityLevel);

    return tdee;
  }

  // Persian date formatting helpers
  static String getPersianFormattedDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    final weekDay = getPersianWeekDay(jalali.weekDay);
    final monthName = getPersianMonthName(jalali.month);
    return '$weekDay ${jalali.day} $monthName';
  }

  static String getPersianWeekDay(int weekday) {
    const weekdays = [
      '',
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنج‌شنبه',
      'جمعه',
    ];
    return weekdays[weekday];
  }

  // Nutrition calculation helpers
  static Map<String, double> calculateTotals(
    List<FoodMealLog> meals,
    List<Food> allFoods,
  ) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in meals) {
      for (final foodItem in meal.foods) {
        final food = allFoods.firstWhere(
          (f) => f.id == foodItem.foodId,
          orElse: () => createDefaultFood(foodItem.foodId),
        );
        if (food.id != 0) {
          final ratio = foodItem.amount / 100;
          totalCalories +=
              (double.tryParse(food.nutrition.calories) ?? 0) * ratio;
          totalProtein +=
              (double.tryParse(food.nutrition.protein) ?? 0) * ratio;
          totalCarbs +=
              (double.tryParse(food.nutrition.carbohydrates) ?? 0) * ratio;
          totalFat += (double.tryParse(food.nutrition.fat) ?? 0) * ratio;
        }
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  // Helper method to create default Food object
  static Food createDefaultFood(int id) {
    return Food(
      id: id,
      title: 'نامشخص',
      content: '',
      imageUrl: '',
      slug: '',
      date: DateTime.now(),
      modified: DateTime.now(),
      status: '',
      type: '',
      link: '',
      featuredMedia: 0,
      nutrition: FoodNutrition(
        protein: '0',
        calories: '0',
        carbohydrates: '0',
        fat: '0',
        saturatedFat: '0',
        fiber: '0',
        sugar: '0',
        cholesterol: '0',
        sodium: '0',
        potassium: '0',
      ),
      foodCategories: [],
      classList: [],
    );
  }

  // Persian number conversion
  static String convertToPersianNumbers(String text) {
    const persianNumbers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const englishNumbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    String result = text;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(englishNumbers[i], persianNumbers[i]);
    }
    return result;
  }

  // Persian month names
  static String getPersianMonthName(int month) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return months[month];
  }

}
