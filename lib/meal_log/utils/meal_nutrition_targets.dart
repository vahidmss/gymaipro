import 'package:gymaipro/meal_log/models/nutrition_goal.dart';
import 'package:gymaipro/services/fitness_calculator.dart';

/// Shared calorie/macro targets for meal log UI, insights, and coach.
///
/// [maintenanceKcal] is always TDEE (weight-balance reference).
/// [calorieTarget] is what the progress bar compares against:
/// - with an active goal → [goalKcal]
/// - without a goal → [maintenanceKcal] (labeled as reference, not "هدف")
class MealNutritionTargets {
  const MealNutritionTargets({
    required this.calorieTarget,
    required this.maintenanceKcal,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.isMale,
    this.goalKcal,
    this.goal,
    this.currentWeightKg,
  });

  /// Number used by progress UI / remaining calories.
  final double calorieTarget;

  /// Estimated maintenance (TDEE).
  final double maintenanceKcal;

  /// Persisted/active goal kcal when [hasActiveGoal], else null.
  final double? goalKcal;

  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final bool isMale;
  final NutritionGoal? goal;
  final double? currentWeightKg;

  bool get hasActiveGoal =>
      goal != null && goal!.isActive && goalKcal != null;

  /// Short title for the daily calorie ceiling in the summary bar.
  String get calorieReferenceTitle {
    if (hasActiveGoal) {
      return switch (goal!.mode) {
        NutritionGoalMode.maintain => 'سقف حفظ وزن',
        NutritionGoalMode.lose => 'سقف روزانه',
        NutritionGoalMode.gain => 'سقف روزانه',
        NutritionGoalMode.custom => 'سقف روزانه',
        NutritionGoalMode.none => 'نیاز روزانه',
      };
    }
    return 'نیاز روزانه';
  }

  /// Explains what the ceiling number represents (budget framing).
  String get calorieReferenceHint {
    final need = maintenanceKcal.round();
    if (hasActiveGoal) {
      return switch (goal!.mode) {
        NutritionGoalMode.maintain =>
          'بودجه برای ثابت ماندن وزن · نیاز تقریبی $need',
        NutritionGoalMode.lose =>
          'بودجه کاهش وزن · برای حفظ وزن فعلی حدود $need کالری لازم است',
        NutritionGoalMode.gain =>
          'بودجه افزایش وزن · برای حفظ وزن فعلی حدود $need کالری لازم است',
        NutritionGoalMode.custom =>
          'بودجه دستی · برای حفظ وزن فعلی حدود $need کالری لازم است',
        NutritionGoalMode.none =>
          'برآورد کالری برای حفظ وزن فعلی · هنوز بودجه جدا نگذاشتی',
      };
    }
    return 'برآورد کالری برای حفظ وزن فعلی · هنوز بودجه جدا نگذاشتی';
  }

  static int safetyFloorKcal({required bool isMale}) => isMale ? 1500 : 1200;

  static MealNutritionTargets fromProfile(Map<String, dynamic>? profileData) {
    if (profileData == null) {
      return const MealNutritionTargets(
        calorieTarget: 2000,
        maintenanceKcal: 2000,
        proteinTarget: 120,
        carbsTarget: 250,
        fatTarget: 65,
        isMale: true,
      );
    }

    final height = _readDouble(profileData, const <String>[
      'height',
      'height_cm',
      'bb_height_cm',
    ]);
    final weight = _readDouble(profileData, const <String>[
      'latest_weight',
      'weight',
      'weight_kg',
      'bb_weight_kg',
      'current_weight',
    ]);
    final birthDateStr = _readString(profileData['birth_date']);
    final gender = _readString(profileData['gender'])?.toLowerCase();
    final isMale = gender == null ||
        gender == 'male' ||
        gender == 'مرد' ||
        gender.isEmpty;

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
      } on Object {
        age = 25;
      }
    }

    final nutritionGoal = NutritionGoal.fromProfileMap(profileData);

    if (height <= 0 || weight <= 0 || age <= 0) {
      const maintenance = 2000.0;
      final goalKcal = _resolveGoalKcal(
        goal: nutritionGoal,
        maintenance: maintenance,
        isMale: isMale,
      );
      return MealNutritionTargets(
        calorieTarget: goalKcal ?? maintenance,
        maintenanceKcal: maintenance,
        goalKcal: goalKcal,
        proteinTarget: isMale ? 154 : 133,
        carbsTarget: 250,
        fatTarget: isMale ? 65 : 70,
        isMale: isMale,
        goal: nutritionGoal,
        currentWeightKg: weight > 0 ? weight : null,
      );
    }

    final bmr = FitnessCalculator.calculateBMR(weight, height, age, isMale);
    final activityLevelStr =
        _readString(profileData['activity_level']) ?? 'moderate';
    final tdee = FitnessCalculator.calculateTDEE(
      bmr,
      activityLevelStr.toActivityLevel(),
    );

    // Macros scale off the *progress* calorie number (goal or maintenance).
    final goalKcal = _resolveGoalKcal(
      goal: nutritionGoal,
      maintenance: tdee,
      isMale: isMale,
    );
    final progressCalories = goalKcal ?? tdee;

    final proteinTarget = isMale ? weight * 2.2 : weight * 1.9;
    final carbsPercentage = isMale ? 0.47 : 0.42;
    final fatPercentage = isMale ? 0.23 : 0.28;
    final carbsTarget = (progressCalories * carbsPercentage) / 4.0;
    final fatTarget = (progressCalories * fatPercentage) / 9.0;

    return MealNutritionTargets(
      calorieTarget: progressCalories,
      maintenanceKcal: tdee,
      goalKcal: goalKcal,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatTarget: fatTarget,
      isMale: isMale,
      goal: nutritionGoal,
      currentWeightKg: weight,
    );
  }

  /// Progress-bar calories (goal if set, else maintenance).
  static double dailyCalories(Map<String, dynamic>? profileData) =>
      fromProfile(profileData).calorieTarget;

  static double? _resolveGoalKcal({
    required NutritionGoal goal,
    required double maintenance,
    required bool isMale,
  }) {
    if (!goal.mode.isActive) return null;

    if (goal.mode == NutritionGoalMode.custom ||
        goal.mode == NutritionGoalMode.maintain) {
      final stored = goal.calorieGoalKcal?.toDouble();
      if (goal.mode == NutritionGoalMode.maintain) {
        return stored ?? maintenance;
      }
      if (stored != null && stored > 0) {
        return stored.clamp(
          safetyFloorKcal(isMale: isMale).toDouble(),
          maintenance + 1000,
        );
      }
      return null;
    }

    // Prefer persisted value; recompute if missing.
    if (goal.calorieGoalKcal != null && goal.calorieGoalKcal! > 0) {
      return goal.calorieGoalKcal!.toDouble().clamp(
        safetyFloorKcal(isMale: isMale).toDouble(),
        maintenance + 1000,
      );
    }

    final rate = (goal.weeklyRateKg ?? 0.5).abs().clamp(0.1, 1.0);
    final dailyDelta = (7700 * rate / 7);
    if (goal.mode == NutritionGoalMode.lose) {
      return (maintenance - dailyDelta).clamp(
        safetyFloorKcal(isMale: isMale).toDouble(),
        maintenance,
      );
    }
    if (goal.mode == NutritionGoalMode.gain) {
      return (maintenance + dailyDelta).clamp(maintenance, maintenance + 1000);
    }
    return null;
  }

  static double _readDouble(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final raw = source[key];
      if (raw == null) continue;
      if (raw is num) {
        final value = raw.toDouble();
        if (value > 0) return value;
      }
      final parsed = double.tryParse(
        raw.toString().trim().replaceAll(',', '.'),
      );
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }

  static String? _readString(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).join(',');
    }
    return raw.toString();
  }
}
