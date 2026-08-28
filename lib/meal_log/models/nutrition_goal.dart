/// How the user wants daily calories managed relative to maintenance.
enum NutritionGoalMode {
  /// No calorie goal — UI shows maintenance (TDEE) as reference only.
  none,

  /// Explicitly maintain weight; goal kcal == maintenance.
  maintain,

  /// Lose weight at [weeklyRateKg].
  lose,

  /// Gain weight at [weeklyRateKg].
  gain,

  /// User typed a calorie number directly.
  custom,
}

extension NutritionGoalModeX on NutritionGoalMode {
  String get storageValue => name;

  static NutritionGoalMode fromStorage(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    return switch (value) {
      'maintain' => NutritionGoalMode.maintain,
      'lose' => NutritionGoalMode.lose,
      'gain' => NutritionGoalMode.gain,
      'custom' => NutritionGoalMode.custom,
      _ => NutritionGoalMode.none,
    };
  }

  bool get isActive => this != NutritionGoalMode.none;

  String get titleFa => switch (this) {
    NutritionGoalMode.none => 'بدون هدف',
    NutritionGoalMode.maintain => 'حفظ وزن',
    NutritionGoalMode.lose => 'کاهش وزن',
    NutritionGoalMode.gain => 'افزایش وزن',
    NutritionGoalMode.custom => 'کالری دستی',
  };
}

/// Whether [calorieGoalKcal] was derived from rate math or typed manually.
enum NutritionGoalSource {
  computed,
  manual,
}

extension NutritionGoalSourceX on NutritionGoalSource {
  String get storageValue => name;

  static NutritionGoalSource? fromStorage(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    return switch (value) {
      'computed' => NutritionGoalSource.computed,
      'manual' => NutritionGoalSource.manual,
      _ => null,
    };
  }
}

/// Persisted nutrition goal snapshot (profiles columns).
class NutritionGoal {
  const NutritionGoal({
    required this.mode,
    this.targetWeightKg,
    this.weeklyRateKg,
    this.calorieGoalKcal,
    this.source,
    this.updatedAt,
    this.reachedAt,
  });

  final NutritionGoalMode mode;
  final double? targetWeightKg;
  final double? weeklyRateKg;
  final int? calorieGoalKcal;
  final NutritionGoalSource? source;
  final DateTime? updatedAt;
  final DateTime? reachedAt;

  static const NutritionGoal none = NutritionGoal(mode: NutritionGoalMode.none);

  bool get isActive => mode.isActive && calorieGoalKcal != null;

  factory NutritionGoal.fromProfileMap(Map<String, dynamic>? profile) {
    if (profile == null) return NutritionGoal.none;
    final mode = NutritionGoalModeX.fromStorage(profile['nutrition_goal_mode']);
    return NutritionGoal(
      mode: mode,
      targetWeightKg: _asDouble(profile['target_weight_kg']),
      weeklyRateKg: _asDouble(profile['weekly_rate_kg']),
      calorieGoalKcal: _asInt(profile['calorie_goal_kcal']),
      source: NutritionGoalSourceX.fromStorage(profile['calorie_goal_source']),
      updatedAt: _asDate(profile['calorie_goal_updated_at']),
      reachedAt: _asDate(profile['goal_reached_at']),
    );
  }

  Map<String, dynamic> toProfileUpdates({bool clearReachedAt = false}) {
    final map = <String, dynamic>{
      'nutrition_goal_mode': mode.storageValue,
      'calorie_goal_kcal': calorieGoalKcal,
      'calorie_goal_source': source?.storageValue,
      'calorie_goal_updated_at': (updatedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
    };
    // Only send weight/rate when relevant; null clears on purpose for none/custom.
    if (mode == NutritionGoalMode.lose ||
        mode == NutritionGoalMode.gain ||
        mode == NutritionGoalMode.maintain) {
      map['target_weight_kg'] = targetWeightKg;
    } else {
      map['target_weight_kg'] = null;
    }
    if (mode == NutritionGoalMode.lose || mode == NutritionGoalMode.gain) {
      map['weekly_rate_kg'] = weeklyRateKg;
    } else {
      map['weekly_rate_kg'] = null;
    }
    if (clearReachedAt) {
      map['goal_reached_at'] = null;
    } else if (reachedAt != null) {
      map['goal_reached_at'] = reachedAt!.toUtc().toIso8601String();
    }
    return map;
  }

  NutritionGoal copyWith({
    NutritionGoalMode? mode,
    double? targetWeightKg,
    double? weeklyRateKg,
    int? calorieGoalKcal,
    NutritionGoalSource? source,
    DateTime? updatedAt,
    DateTime? reachedAt,
    bool clearReachedAt = false,
  }) {
    return NutritionGoal(
      mode: mode ?? this.mode,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      weeklyRateKg: weeklyRateKg ?? this.weeklyRateKg,
      calorieGoalKcal: calorieGoalKcal ?? this.calorieGoalKcal,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      reachedAt: clearReachedAt ? null : (reachedAt ?? this.reachedAt),
    );
  }

  static double? _asDouble(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim().replaceAll(',', '.'));
  }

  static int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw.toString().trim());
  }

  static DateTime? _asDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
