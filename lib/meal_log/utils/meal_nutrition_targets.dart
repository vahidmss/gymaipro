import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/services/fitness_calculator.dart';

/// Shared calorie/macro targets for meal log UI and insight engine.
class MealNutritionTargets {
  const MealNutritionTargets({
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    this.goalAdjustmentLabel,
  });

  final double calorieTarget;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final String? goalAdjustmentLabel;

  /// Short title for the calorie reference line (not a user-set goal).
  String get calorieReferenceTitle =>
      goalAdjustmentLabel != null ? 'برآورد روزانه' : 'نیاز روزانه';

  /// Explains what the reference number represents.
  String get calorieReferenceHint {
    if (goalAdjustmentLabel != null) {
      return 'بر اساس پروفایل ($goalAdjustmentLabel) — مرجع، نه هدف دستی';
    }
    return 'مرجع تعادل وزن (TDEE) — نه هدف کاهش/افزایش دستی';
  }

  static MealNutritionTargets fromProfile(Map<String, dynamic>? profileData) {
    if (profileData == null) {
      return const MealNutritionTargets(
        calorieTarget: 2000,
        proteinTarget: 120,
        carbsTarget: 250,
        fatTarget: 65,
      );
    }

    final height =
        double.tryParse((profileData['height'] as String?) ?? '') ?? 0;
    final latestWeight = profileData['latest_weight'] as double?;
    final weight =
        latestWeight ??
        double.tryParse((profileData['weight'] as String?) ?? '') ??
        0;
    final birthDateStr = profileData['birth_date'] as String?;
    final isMale = (profileData['gender'] as String?) == 'male';

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

    if (height <= 0 || weight <= 0 || age <= 0) {
      return MealNutritionTargets(
        calorieTarget: 2000,
        proteinTarget: isMale ? 154 : 133,
        carbsTarget: 250,
        fatTarget: isMale ? 65 : 70,
      );
    }

    final bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);
    final activityLevelStr =
        (profileData['activity_level'] as String?) ?? 'moderate';
    final tdee = FitnessCalculator.calculateTDEE(
      bmr,
      activityLevelStr.toActivityLevel(),
    );

    final goalsRaw = (profileData['fitness_goals'] as String?) ?? '';
    final adjusted = _adjustCaloriesForGoals(tdee, goalsRaw, isMale);

    final proteinTarget = isMale ? weight * 2.2 : weight * 1.9;
    final carbsPercentage = isMale ? 0.47 : 0.42;
    final fatPercentage = isMale ? 0.23 : 0.28;
    final carbsTarget = (adjusted.calories * carbsPercentage) / 4.0;
    final fatTarget = (adjusted.calories * fatPercentage) / 9.0;

    return MealNutritionTargets(
      calorieTarget: adjusted.calories,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatTarget: fatTarget,
      goalAdjustmentLabel: adjusted.label,
    );
  }

  static double dailyCalories(Map<String, dynamic>? profileData) =>
      fromProfile(profileData).calorieTarget;

  static _GoalAdjustment _adjustCaloriesForGoals(
    double tdee,
    String goalsRaw,
    bool isMale,
  ) {
    final normalized = goalsRaw.toLowerCase();
    final minCalories = isMale ? 1500.0 : 1200.0;

    if (_containsGoal(normalized, 'weight_loss', ['کاهش وزن'])) {
      return _GoalAdjustment(
        calories: (tdee - 400).clamp(minCalories, tdee),
        label: AppConfig.fitnessGoals['weight_loss'],
      );
    }
    if (_containsGoal(normalized, 'muscle_gain', [
      'افزایش حجم',
      'افزایش عضله',
    ])) {
      return _GoalAdjustment(
        calories: tdee + 300,
        label: AppConfig.fitnessGoals['muscle_gain'],
      );
    }
    if (_containsGoal(normalized, 'strength', ['قدرت'])) {
      return _GoalAdjustment(
        calories: tdee + 200,
        label: AppConfig.fitnessGoals['strength'],
      );
    }
    if (_containsGoal(normalized, 'endurance', ['استقامت'])) {
      return _GoalAdjustment(
        calories: tdee + 150,
        label: AppConfig.fitnessGoals['endurance'],
      );
    }

    return _GoalAdjustment(calories: tdee);
  }

  static bool _containsGoal(
    String haystack,
    String key, [
    List<String> faLabels = const [],
  ]) {
    if (haystack.contains(key)) return true;
    for (final label in faLabels) {
      if (haystack.contains(label)) return true;
    }
    return false;
  }
}

class _GoalAdjustment {
  const _GoalAdjustment({required this.calories, this.label});

  final double calories;
  final String? label;
}
