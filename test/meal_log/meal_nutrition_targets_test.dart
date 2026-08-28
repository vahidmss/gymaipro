import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';

void main() {
  test('fromProfile accepts numeric height/weight without casting', () {
    final targets = MealNutritionTargets.fromProfile(<String, dynamic>{
      'height': 181,
      'weight': 90,
      'gender': 'male',
      'birth_date': '1995-01-01',
      'activity_level': 'moderate',
      'fitness_goals': 'weight_loss',
    });

    expect(targets.calorieTarget, greaterThan(1500));
    expect(targets.proteinTarget, closeTo(90 * 2.2, 0.1));
  });

  test('fromProfile accepts string height/weight', () {
    final targets = MealNutritionTargets.fromProfile(<String, dynamic>{
      'height': '175',
      'weight': '70',
      'gender': 'female',
      'activity_level': 'light',
    });

    expect(targets.calorieTarget, greaterThan(1000));
    expect(targets.proteinTarget, closeTo(70 * 1.9, 0.1));
  });

  test('fitness_goals alone does not create an active calorie goal', () {
    final targets = MealNutritionTargets.fromProfile(<String, dynamic>{
      'height': 180,
      'latest_weight': 85.5,
      'gender': 'male',
      'fitness_goals': <String>['weight_loss', 'strength'],
    });

    expect(targets.calorieTarget, greaterThan(1200));
    expect(targets.hasActiveGoal, isFalse);
    expect(targets.calorieTarget, targets.maintenanceKcal);
  });

  test('active nutrition goal uses goal kcal for progress', () {
    final targets = MealNutritionTargets.fromProfile(<String, dynamic>{
      'height': 180,
      'weight': 90,
      'gender': 'male',
      'birth_date': '1995-01-01',
      'activity_level': 'moderate',
      'nutrition_goal_mode': 'lose',
      'calorie_goal_kcal': 2100,
      'weekly_rate_kg': 0.5,
      'target_weight_kg': 80,
    });

    expect(targets.hasActiveGoal, isTrue);
    expect(targets.goalKcal, 2100);
    expect(targets.calorieTarget, 2100);
    expect(targets.maintenanceKcal, greaterThan(2100));
  });
}
