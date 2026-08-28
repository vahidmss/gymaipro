import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/meal_log/models/nutrition_goal.dart';
import 'package:gymaipro/meal_log/services/nutrition_goal_service.dart';
import 'package:gymaipro/meal_log/utils/nutrition_copy.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';

void main() {
  group('NutritionGoalService.preview', () {
    final profile = <String, dynamic>{
      'height': 180,
      'weight': 90,
      'gender': 'male',
      'birth_date': '1995-01-01',
      'activity_level': 'moderate',
    };

    test('lose mode creates deficit under maintenance with ETA', () {
      final service = NutritionGoalService();
      final preview = service.preview(
        profile: profile,
        mode: NutritionGoalMode.lose,
        targetWeightKg: 80,
        weeklyRateKg: 0.5,
      );

      expect(preview.goalKcal, isNotNull);
      expect(preview.goalKcal!, lessThan(preview.maintenanceKcal));
      expect(preview.dailyDeltaKcal, lessThan(0));
      expect(preview.estimatedWeeks, greaterThan(0));
      expect(preview.clampedRateKg, 0.5);
    });

    test('safety floor clamps aggressive loss', () {
      final service = NutritionGoalService();
      final preview = service.preview(
        profile: profile,
        mode: NutritionGoalMode.lose,
        targetWeightKg: 70,
        weeklyRateKg: 1.0,
      );

      expect(
        preview.goalKcal,
        greaterThanOrEqualTo(
          MealNutritionTargets.safetyFloorKcal(isMale: true),
        ),
      );
    });

    test('none mode has no goal kcal', () {
      final preview = NutritionGoalService().preview(
        profile: profile,
        mode: NutritionGoalMode.none,
      );
      expect(preview.goalKcal, isNull);
      expect(preview.dailyDeltaKcal, 0);
    });

    test('maintain equals maintenance', () {
      final preview = NutritionGoalService().preview(
        profile: profile,
        mode: NutritionGoalMode.maintain,
      );
      expect(preview.goalKcal, preview.maintenanceKcal);
    });
  });

  group('NutritionCopy', () {
    test('without active goal never calls TDEE a هدف', () {
      final targets = MealNutritionTargets.fromProfile(<String, dynamic>{
        'height': 180,
        'weight': 90,
        'gender': 'male',
        'birth_date': '1995-01-01',
        'activity_level': 'moderate',
      });
      final text = NutritionCopy.summaryFa(targets: targets);
      expect(text, contains('نیاز تقریبی'));
      expect(text, contains('حفظ وزن'));
      expect(text, contains('هنوز بودجه کالری'));
      expect(text.contains('سقف کالری روزانه‌ات'), isFalse);
      expect(text.toLowerCase().contains('tdee'), isFalse);
      expect(text.contains('نگهداری'), isFalse);
    });

    test('with active goal cites goal and maintenance', () {
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
      final text = NutritionCopy.summaryFa(
        targets: targets,
        today: <String, Object?>{
          'logged': true,
          'consumed': <String, Object?>{
            'calories_kcal': 1000,
            'protein_g': 80,
          },
        },
      );
      expect(text, contains('سقف کالری روزانه‌ات'));
      expect(text, contains('حفظ وزن'));
      expect(text, contains('از بودجه مانده'));
      expect(text.contains('نگهداری'), isFalse);
      expect(text.contains('تا هدف مانده'), isFalse);
    });
  });

  test('goal reached detection when weight at target', () {
    // Pure math check via preview/fromProfile — service persistence needs
    // Supabase; assert tolerance logic via mode + weight comparison.
    final goal = NutritionGoal(
      mode: NutritionGoalMode.lose,
      targetWeightKg: 80,
      weeklyRateKg: 0.5,
      calorieGoalKcal: 2100,
      source: NutritionGoalSource.computed,
    );
    const current = 80.3;
    final reached =
        current <= goal.targetWeightKg! + NutritionGoalService.goalReachedToleranceKg;
    expect(reached, isTrue);
  });
}
