import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/food_serving_units.dart';

/// Converts logged amount + unit to grams and scales nutrition values.
class FoodAmountUtils {
  FoodAmountUtils._();

  static double gramsFromAmount(Food food, double amount, String unit) {
    if (amount <= 0) return 0;
    final resolved = food.meta.servingUnits.resolve(unit);
    if (resolved != null) {
      return amount * resolved.gramsPerUnit;
    }
    if (unit == 'gram' || unit == 'گرم') return amount;
    if (unit == 'عدد' || unit == 'piece') {
      final servingG =
          double.tryParse(food.meta.servingSizeGrams.replaceAll(',', '.')) ??
              100;
      return amount * servingG;
    }
    return amount;
  }

  static double nutritionScaleFactor(Food food, double amount, String unit) {
    final grams = gramsFromAmount(food, amount, unit);
    if (grams <= 0) return 0;

    if (food.meta.nutritionBasis == 'per_serving') {
      final servingG =
          double.tryParse(food.meta.servingSizeGrams.replaceAll(',', '.')) ??
              100;
      if (servingG <= 0) return 0;
      return grams / servingG;
    }
    return grams / 100.0;
  }

  static double scaledCalories(Food food, double amount, String unit) {
    final factor = nutritionScaleFactor(food, amount, unit);
    return (double.tryParse(food.nutrition.calories) ?? 0) * factor;
  }

  static double scaledMacro(
    Food food,
    double amount,
    String unit,
    String macroValue,
  ) {
    final factor = nutritionScaleFactor(food, amount, unit);
    return (double.tryParse(macroValue) ?? 0) * factor;
  }

  static Map<String, double> scaledMacros(
    Food food,
    double amount,
    String unit,
  ) {
    return {
      'calories': scaledCalories(food, amount, unit),
      'protein': scaledMacro(food, amount, unit, food.nutrition.protein),
      'carbs': scaledMacro(food, amount, unit, food.nutrition.carbohydrates),
      'fat': scaledMacro(food, amount, unit, food.nutrition.fat),
    };
  }

  static String formatAmountForUnit(FoodServingUnit unit, double amount) {
    if (unit.decimals <= 0 || amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(unit.decimals);
  }
}
