import 'package:gymaipro/models/exercise.dart';

/// Approximate session calorie burn from catalog metrics + logged work.
///
/// Not medical-grade. Prefer UI label «تقریبی».
abstract final class WorkoutCalorieEstimator {
  static const double defaultMet = 4.5;
  static const int defaultCaloriesPer1000kg = 30;

  /// Hybrid estimate:
  /// - strength tonnage: `volumeKg * kcalPer1000kg / 1000`
  /// - timed / cardio work: `MET * bodyKg * hours`
  /// Falls back to MET × weight × wall-clock hours when set work is thin.
  static int? estimateKcal({
    required double? bodyWeightKg,
    required double totalVolumeKg,
    required int workingSeconds,
    required int wallClockSeconds,
    required List<ExerciseCalorieInput> exercises,
  }) {
    final weight = bodyWeightKg;
    if (weight == null || weight <= 0) {
      // Volume-only path still useful without body weight.
      final fromVolume = _fromVolume(totalVolumeKg, exercises);
      return fromVolume > 0 ? fromVolume.round() : null;
    }

    var kcal = 0.0;
    var usedVolume = false;
    var usedTimed = false;

    for (final item in exercises) {
      if (item.volumeKg > 0 && (item.caloriesPer1000kg ?? 0) > 0) {
        kcal += item.volumeKg * item.caloriesPer1000kg! / 1000.0;
        usedVolume = true;
      }
      if (item.workingSeconds > 0) {
        final met = item.met ?? defaultMet;
        kcal += met * weight * (item.workingSeconds / 3600.0);
        usedTimed = true;
      }
    }

    if (!usedVolume && totalVolumeKg > 0) {
      kcal += _fromVolume(totalVolumeKg, exercises);
      usedVolume = true;
    }

    if (!usedVolume && !usedTimed) {
      final seconds = workingSeconds > 0
          ? workingSeconds
          : wallClockSeconds.clamp(0, 3 * 3600);
      if (seconds <= 0) return null;
      final avgMet = _averageMet(exercises);
      kcal = avgMet * weight * (seconds / 3600.0);
    }

    if (kcal <= 0) return null;
    return kcal.round().clamp(1, 5000);
  }

  static double _fromVolume(
    double totalVolumeKg,
    List<ExerciseCalorieInput> exercises,
  ) {
    if (totalVolumeKg <= 0) return 0;
    final rates = exercises
        .map((e) => e.caloriesPer1000kg)
        .whereType<int>()
        .where((v) => v > 0)
        .toList(growable: false);
    final rate = rates.isEmpty
        ? defaultCaloriesPer1000kg
        : (rates.reduce((a, b) => a + b) / rates.length).round();
    return totalVolumeKg * rate / 1000.0;
  }

  static double _averageMet(List<ExerciseCalorieInput> exercises) {
    final mets = exercises
        .map((e) => e.met)
        .whereType<double>()
        .where((v) => v > 0)
        .toList(growable: false);
    if (mets.isEmpty) return defaultMet;
    return mets.reduce((a, b) => a + b) / mets.length;
  }
}

class ExerciseCalorieInput {
  const ExerciseCalorieInput({
    this.met,
    this.caloriesPer1000kg,
    this.volumeKg = 0,
    this.workingSeconds = 0,
  });

  factory ExerciseCalorieInput.fromCatalog({
    Exercise? exercise,
    double volumeKg = 0,
    int workingSeconds = 0,
  }) {
    return ExerciseCalorieInput(
      met: exercise?.met,
      caloriesPer1000kg: exercise?.caloriesPer1000kg,
      volumeKg: volumeKg,
      workingSeconds: workingSeconds,
    );
  }

  final double? met;
  final int? caloriesPer1000kg;
  final double volumeKg;
  final int workingSeconds;
}
