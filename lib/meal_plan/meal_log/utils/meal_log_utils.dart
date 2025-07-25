import 'package:shamsi_date/shamsi_date.dart';
import '../../../models/food.dart';
import '../models/food_meal_log.dart';

class MealLogUtils {
  // Persian date formatting helpers
  static String getPersianFormattedDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    final weekDay = getPersianWeekDay(jalali.weekDay);
    return '$weekDay ${jalali.day}/${jalali.month}/${jalali.year}';
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
      'جمعه'
    ];
    return weekdays[weekday];
  }

  // Nutrition calculation helpers
  static Map<String, double> calculateTotals(
      List<FoodMealLog> meals, List<Food> allFoods) {
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
      'اسفند'
    ];
    return months[month];
  }

  // Days in Persian month
  static int getDaysInPersianMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  // Format nutrition values
  static String formatNutritionValue(double value) {
    return value.toStringAsFixed(1);
  }

  // Get meal type display name
  static String getMealTypeDisplayName(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'صبحانه';
      case 'lunch':
        return 'ناهار';
      case 'dinner':
        return 'شام';
      case 'snack':
        return 'میان‌وعده';
      default:
        return mealType;
    }
  }

  // Validate food amount
  static bool isValidFoodAmount(double amount) {
    return amount > 0 && amount <= 10000; // Max 10kg
  }

  // Calculate BMI
  static double calculateBMI(double weight, double height) {
    if (height <= 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'کم‌وزن';
    if (bmi < 25) return 'نرمال';
    if (bmi < 30) return 'اضافه‌وزن';
    return 'چاق';
  }
}
