import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/meal_log/models/nutrition_goal.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates / updates / clears the user's calorie goal.
///
/// Always persists locally (SharedPreferences) so the UI works even before
/// the profiles SQL migration is applied. Best-effort sync to Supabase.
class NutritionGoalService {
  NutritionGoalService();

  static const List<double> suggestedWeeklyRatesKg = <double>[0.25, 0.5, 0.75];
  static const double maxWeeklyRateKg = 1.0;
  static const double kcalPerKg = 7700;
  static const double goalReachedToleranceKg = 0.5;
  static const double maintainDriftFraction = 0.015;
  static const String _prefsPrefix = 'nutrition_goal_v1_';

  NutritionGoal readFromProfile(Map<String, dynamic>? profile) =>
      NutritionGoal.fromProfileMap(profile);

  /// Merge local prefs into a profile map (sync helper for meal log).
  static Future<Map<String, dynamic>> mergeLocalGoalIntoProfile(
    Map<String, dynamic> profile,
  ) async {
    final local = await loadLocalGoal();
    if (local == null || !local.mode.isActive) {
      // If remote already has a goal, keep it.
      return profile;
    }
    final remote = NutritionGoal.fromProfileMap(profile);
    // Prefer newer local stamp when remote is empty/none or older.
    if (!remote.isActive ||
        (local.updatedAt != null &&
            (remote.updatedAt == null ||
                local.updatedAt!.isAfter(remote.updatedAt!)))) {
      final updates = local.toProfileUpdates();
      profile.addAll(updates);
      SimpleProfileService.patchCachedProfileFields(updates);
    }
    return profile;
  }

  static Future<NutritionGoal?> loadLocalGoal() async {
    try {
      final userId = AuthHelper.currentUserIdSync;
      if (userId == null || userId.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsPrefix$userId');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return NutritionGoal.fromProfileMap(
        Map<String, dynamic>.from(decoded),
      );
    } on Object catch (error) {
      debugPrint('NutritionGoalService.loadLocalGoal: $error');
      return null;
    }
  }

  static Future<void> _saveLocalGoal(NutritionGoal goal) async {
    final userId = AuthHelper.currentUserIdSync;
    if (userId == null || userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefsPrefix$userId';
    if (goal.mode == NutritionGoalMode.none) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(goal.toProfileUpdates()));
  }

  NutritionGoalPreview preview({
    required Map<String, dynamic>? profile,
    required NutritionGoalMode mode,
    double? targetWeightKg,
    double? weeklyRateKg,
    int? manualCalorieKcal,
  }) {
    final targets = MealNutritionTargets.fromProfile(profile);
    final maintenance = targets.maintenanceKcal.round();
    final isMale = targets.isMale;

    if (mode == NutritionGoalMode.none) {
      return NutritionGoalPreview(
        mode: mode,
        maintenanceKcal: maintenance,
        goalKcal: null,
        dailyDeltaKcal: 0,
        estimatedWeeks: null,
        estimatedDate: null,
        clampedRateKg: null,
        usedSafetyFloor: false,
      );
    }

    if (mode == NutritionGoalMode.maintain) {
      return NutritionGoalPreview(
        mode: mode,
        maintenanceKcal: maintenance,
        goalKcal: maintenance,
        dailyDeltaKcal: 0,
        estimatedWeeks: null,
        estimatedDate: null,
        clampedRateKg: null,
        usedSafetyFloor: false,
      );
    }

    if (mode == NutritionGoalMode.custom) {
      final goal = (manualCalorieKcal ?? maintenance).clamp(
        MealNutritionTargets.safetyFloorKcal(isMale: isMale),
        maintenance + 1000,
      );
      return NutritionGoalPreview(
        mode: mode,
        maintenanceKcal: maintenance,
        goalKcal: goal,
        dailyDeltaKcal: goal - maintenance,
        estimatedWeeks: null,
        estimatedDate: null,
        clampedRateKg: null,
        usedSafetyFloor:
            goal == MealNutritionTargets.safetyFloorKcal(isMale: isMale),
      );
    }

    final currentWeight = targets.currentWeightKg;
    final rateRaw = (weeklyRateKg ?? 0.5).abs();
    final rate = rateRaw.clamp(0.1, maxWeeklyRateKg);
    final dailyDeltaAbs = (kcalPerKg * rate / 7).round();

    var goal = mode == NutritionGoalMode.lose
        ? maintenance - dailyDeltaAbs
        : maintenance + dailyDeltaAbs;
    final floor = MealNutritionTargets.safetyFloorKcal(isMale: isMale);
    var usedFloor = false;
    if (mode == NutritionGoalMode.lose && goal < floor) {
      goal = floor;
      usedFloor = true;
    }
    if (mode == NutritionGoalMode.gain && goal > maintenance + 1000) {
      goal = maintenance + 1000;
    }

    int? weeks;
    DateTime? eta;
    if (currentWeight != null &&
        targetWeightKg != null &&
        targetWeightKg > 0 &&
        rate > 0) {
      final delta = (targetWeightKg - currentWeight).abs();
      if (delta > 0.05) {
        weeks = (delta / rate).ceil();
        eta = DateTime.now().add(Duration(days: weeks * 7));
      }
    }

    return NutritionGoalPreview(
      mode: mode,
      maintenanceKcal: maintenance,
      goalKcal: goal,
      dailyDeltaKcal: goal - maintenance,
      estimatedWeeks: weeks,
      estimatedDate: eta,
      clampedRateKg: rate,
      usedSafetyFloor: usedFloor,
    );
  }

  Future<NutritionGoalSaveResult> save({
    required NutritionGoalMode mode,
    double? targetWeightKg,
    double? weeklyRateKg,
    int? manualCalorieKcal,
    Map<String, dynamic>? profileOverride,
  }) async {
    final profile =
        profileOverride ?? await SimpleProfileService.getCurrentProfile();
    final previewResult = preview(
      profile: profile,
      mode: mode,
      targetWeightKg: targetWeightKg,
      weeklyRateKg: weeklyRateKg,
      manualCalorieKcal: manualCalorieKcal,
    );

    if (mode == NutritionGoalMode.none) {
      return clear();
    }

    if (previewResult.goalKcal == null) {
      return const NutritionGoalSaveResult(
        ok: false,
        savedRemotely: false,
        message: 'نتونستیم کالری هدف را حساب کنیم',
      );
    }

    final goal = NutritionGoal(
      mode: mode,
      targetWeightKg:
          mode == NutritionGoalMode.custom ? null : targetWeightKg,
      weeklyRateKg:
          (mode == NutritionGoalMode.lose || mode == NutritionGoalMode.gain)
          ? previewResult.clampedRateKg
          : null,
      calorieGoalKcal: previewResult.goalKcal,
      source: mode == NutritionGoalMode.custom
          ? NutritionGoalSource.manual
          : NutritionGoalSource.computed,
      updatedAt: DateTime.now().toUtc(),
    );

    // 1) Always persist locally first — UI must never depend on migration.
    try {
      await _saveLocalGoal(goal);
      SimpleProfileService.patchCachedProfileFields(goal.toProfileUpdates());
    } on Object catch (error) {
      debugPrint('NutritionGoalService local save failed: $error');
      return NutritionGoalSaveResult(
        ok: false,
        savedRemotely: false,
        message: 'ذخیره نشد: $error',
      );
    }

    // 2) Best-effort remote sync (needs SQL migration on profiles).
    var remoteOk = false;
    String? remoteError;
    try {
      remoteOk = await SimpleProfileService.updateNutritionGoal(goal);
      if (!remoteOk) {
        remoteError =
            'روی سرور ذخیره نشد (ممکن است ستون‌های هدف کالری هنوز ساخته نشده باشد)';
      }
    } on Object catch (error) {
      remoteOk = false;
      remoteError = error.toString();
      debugPrint('NutritionGoalService remote save failed: $error');
    }

    return NutritionGoalSaveResult(
      ok: true,
      savedRemotely: remoteOk,
      message: remoteOk ? null : remoteError,
      goal: goal,
    );
  }

  Future<NutritionGoalSaveResult> clear() async {
    final cleared = NutritionGoal.none.copyWith(
      updatedAt: DateTime.now().toUtc(),
    );
    try {
      await _saveLocalGoal(cleared);
      SimpleProfileService.patchCachedProfileFields(
        cleared.toProfileUpdates(clearReachedAt: true),
      );
    } on Object catch (error) {
      return NutritionGoalSaveResult(
        ok: false,
        savedRemotely: false,
        message: 'حذف نشد: $error',
      );
    }

    var remoteOk = false;
    try {
      remoteOk = await SimpleProfileService.updateNutritionGoal(
        cleared,
        clearReachedAt: true,
      );
    } on Object catch (error) {
      debugPrint('NutritionGoalService remote clear failed: $error');
    }

    return NutritionGoalSaveResult(
      ok: true,
      savedRemotely: remoteOk,
      goal: cleared,
    );
  }

  Future<NutritionGoal?> recomputeIfNeeded({
    Map<String, dynamic>? profileOverride,
  }) async {
    final profile =
        profileOverride ?? await SimpleProfileService.getCurrentProfile();
    if (profile == null) return null;
    final existing = NutritionGoal.fromProfileMap(profile);
    if (!existing.mode.isActive) return existing;
    if (existing.mode == NutritionGoalMode.custom) return existing;

    final previewResult = preview(
      profile: profile,
      mode: existing.mode,
      targetWeightKg: existing.targetWeightKg,
      weeklyRateKg: existing.weeklyRateKg,
      manualCalorieKcal: existing.calorieGoalKcal,
    );
    if (previewResult.goalKcal == null) return existing;
    if (previewResult.goalKcal == existing.calorieGoalKcal) return existing;

    final updated = existing.copyWith(
      calorieGoalKcal: previewResult.goalKcal,
      weeklyRateKg: previewResult.clampedRateKg ?? existing.weeklyRateKg,
      source: NutritionGoalSource.computed,
      updatedAt: DateTime.now().toUtc(),
    );
    await save(
      mode: updated.mode,
      targetWeightKg: updated.targetWeightKg,
      weeklyRateKg: updated.weeklyRateKg,
      manualCalorieKcal: updated.calorieGoalKcal,
      profileOverride: profile,
    );
    return updated;
  }

  Future<NutritionGoalReachedResult?> checkGoalReached({
    Map<String, dynamic>? profileOverride,
  }) async {
    final profile =
        profileOverride ?? await SimpleProfileService.getCurrentProfile();
    if (profile == null) return null;
    final existing = NutritionGoal.fromProfileMap(profile);
    if (existing.mode != NutritionGoalMode.lose &&
        existing.mode != NutritionGoalMode.gain) {
      return null;
    }
    final target = existing.targetWeightKg;
    if (target == null) return null;

    final targets = MealNutritionTargets.fromProfile(profile);
    final current = targets.currentWeightKg;
    if (current == null) return null;

    final reached = existing.mode == NutritionGoalMode.lose
        ? current <= target + goalReachedToleranceKg
        : current >= target - goalReachedToleranceKg;
    if (!reached) return null;

    final maintenance = targets.maintenanceKcal.round();
    final updated = NutritionGoal(
      mode: NutritionGoalMode.maintain,
      targetWeightKg: target,
      weeklyRateKg: null,
      calorieGoalKcal: maintenance,
      source: NutritionGoalSource.computed,
      updatedAt: DateTime.now().toUtc(),
      reachedAt: DateTime.now().toUtc(),
    );
    final result = await save(
      mode: updated.mode,
      targetWeightKg: updated.targetWeightKg,
      weeklyRateKg: null,
      manualCalorieKcal: updated.calorieGoalKcal,
      profileOverride: profile,
    );
    if (!result.ok) return null;
    return NutritionGoalReachedResult(
      previous: existing,
      next: updated,
      currentWeightKg: current,
    );
  }

  bool shouldSuggestRestartGoal({
    required Map<String, dynamic>? profile,
  }) {
    final goal = NutritionGoal.fromProfileMap(profile);
    if (goal.mode != NutritionGoalMode.maintain) return false;
    final target = goal.targetWeightKg;
    if (target == null || target <= 0) return false;
    final current = MealNutritionTargets.fromProfile(profile).currentWeightKg;
    if (current == null) return false;
    final drift = (current - target).abs() / target;
    return drift >= maintainDriftFraction;
  }
}

class NutritionGoalPreview {
  const NutritionGoalPreview({
    required this.mode,
    required this.maintenanceKcal,
    required this.goalKcal,
    required this.dailyDeltaKcal,
    required this.estimatedWeeks,
    required this.estimatedDate,
    required this.clampedRateKg,
    required this.usedSafetyFloor,
  });

  final NutritionGoalMode mode;
  final int maintenanceKcal;
  final int? goalKcal;
  final int dailyDeltaKcal;
  final int? estimatedWeeks;
  final DateTime? estimatedDate;
  final double? clampedRateKg;
  final bool usedSafetyFloor;
}

class NutritionGoalReachedResult {
  const NutritionGoalReachedResult({
    required this.previous,
    required this.next,
    required this.currentWeightKg,
  });

  final NutritionGoal previous;
  final NutritionGoal next;
  final double currentWeightKg;
}

class NutritionGoalSaveResult {
  const NutritionGoalSaveResult({
    required this.ok,
    required this.savedRemotely,
    this.message,
    this.goal,
  });

  final bool ok;
  final bool savedRemotely;
  final String? message;
  final NutritionGoal? goal;
}
