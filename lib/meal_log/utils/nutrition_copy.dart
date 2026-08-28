import 'package:gymaipro/meal_log/models/nutrition_goal.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';

/// Single voice for nutrition calorie copy (meal log / coach / tools).
///
/// Framing: daily calorie **budget / ceiling**, not a race to 100%.
/// - «نیاز روزانه» = calories to keep current weight (no separate goal)
/// - «سقف روزانه» = active goal calorie ceiling
/// - Remaining = budget left today, never «تا هدف»
/// Never say «نگهداری» or dump «TDEE» into short UI copy.
class NutritionCopy {
  const NutritionCopy._();

  /// Citation-ready Persian summary for coach context & tools.
  static String summaryFa({
    required MealNutritionTargets targets,
    Map<String, Object?>? today,
  }) {
    final need = targets.maintenanceKcal.round();
    final budget = targets.calorieTarget.round();
    final protein = targets.proteinTarget.round();
    final consumed = today != null ? today['consumed'] : null;
    final logged = today != null && today['logged'] == true;

    final buffer = StringBuffer();
    if (targets.hasActiveGoal) {
      buffer.write(
        'سقف کالری روزانه‌ات $budget است '
        '(برای حفظ وزن فعلی حدود $need لازم داری)؛ '
        'پروتئین پیشنهادی حدود $protein گرم',
      );
    } else {
      buffer.write(
        'نیاز تقریبی روزانه‌ات برای حفظ وزن حدود $need کالری است '
        'و هنوز بودجه کالری جدا نگذاشتی؛ '
        'پروتئین پیشنهادی حدود $protein گرم',
      );
    }

    if (consumed is Map) {
      final usedCal = _asInt(consumed['calories_kcal']) ?? 0;
      final usedPro = _asInt(consumed['protein_g']) ?? 0;
      final remainCal = (budget - usedCal).clamp(0, budget);
      final remainPro = (protein - usedPro).clamp(0, protein);
      buffer.write(
        '؛ امروز تا الان $usedCal کالری و $usedPro گرم پروتئین ثبت شده',
      );
      if (targets.hasActiveGoal) {
        buffer.write(
          '؛ حدود $remainCal کالری و $remainPro گرم پروتئین از بودجه مانده',
        );
      } else {
        buffer.write(
          '؛ حدود $remainCal کالری نسبت به نیاز روزانه مانده',
        );
      }
    } else if (logged) {
      buffer.write('؛ امروز وعده ثبت شده ولی مجموع کالری محاسبه نشد');
    } else {
      buffer.write('؛ امروز هنوز غذایی ثبت نشده');
    }

    buffer.write('.');
    return buffer.toString();
  }

  /// Hero label when under the ceiling.
  static String remainingLabel({required bool hasActiveGoal}) => 'هنوز جا داری';

  /// Hero label when over the ceiling.
  static String overLabel({required bool hasActiveGoal}) =>
      hasActiveGoal ? 'از سقف رد شدی' : 'از نیاز روزانه رد شدی';

  /// Short name for the daily ceiling number.
  static String budgetTitle({required bool hasActiveGoal}) =>
      hasActiveGoal ? 'سقف روزانه' : 'نیاز روزانه';

  /// Compact used / budget line (no percentage race).
  static String usedOfBudget({
    required int consumed,
    required int budget,
  }) =>
      '$consumed از $budget';

  static Map<String, Object?> dailyTargetsMap(MealNutritionTargets targets) {
    return <String, Object?>{
      'calories_kcal': targets.calorieTarget.round(),
      'protein_g': targets.proteinTarget.round(),
      'carbs_g': targets.carbsTarget.round(),
      'fat_g': targets.fatTarget.round(),
      'maintenance_kcal': targets.maintenanceKcal.round(),
      'has_active_goal': targets.hasActiveGoal,
      if (targets.goalKcal != null) 'goal_kcal': targets.goalKcal!.round(),
      if (targets.goal != null) 'goal_mode': targets.goal!.mode.storageValue,
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}
