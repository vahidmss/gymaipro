import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/models/muscle_targets.dart';

/// منبع دادهٔ هستهٔ تمرینی.
enum MuscleProfileSource {
  /// از کاتالوگ seeded علمی اپ
  catalog,
  /// تخمین مدل زبانی (fallback)
  ai,
}

/// یکی از سه تفسیر احتمالی تمرین — برای تأیید شناسایی توسط مربی.
class ExerciseIdentityOption {
  const ExerciseIdentityOption({
    required this.id,
    required this.standardNameFa,
    required this.standardNameEn,
    required this.summary,
    required this.mainMuscleGroup,
    required this.equipmentHint,
  });

  factory ExerciseIdentityOption.fromJson(Map<String, dynamic> json) {
    return ExerciseIdentityOption(
      id: (json['id'] ?? '').toString(),
      standardNameFa: (json['standard_name_fa'] ?? '').toString(),
      standardNameEn: (json['standard_name_en'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      mainMuscleGroup: (json['main_muscle_group'] ?? '').toString(),
      equipmentHint: (json['equipment_hint'] ?? '').toString(),
    );
  }

  final String id;
  final String standardNameFa;
  final String standardNameEn;
  final String summary;
  final String mainMuscleGroup;
  final String equipmentHint;
}

/// هستهٔ کاربردی تمرین + نقشه عضلانی (بدون توضیحات/نکات).
class GeneratedMuscleProfile {
  const GeneratedMuscleProfile({
    required this.mainMuscle,
    required this.secondaryMuscles,
    required this.muscleTargets,
    this.met,
    this.typicalRpe,
    this.movementPattern = '',
    this.bodyEngagement = '',
    this.mechanicsType = '',
    this.forceType = '',
    this.caloriesPer1000kg,
    this.source = MuscleProfileSource.ai,
    this.catalogExerciseId,
    this.catalogExerciseName,
  });

  factory GeneratedMuscleProfile.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString().replaceAll(',', '.'));
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.round();
      return int.tryParse(v.toString());
    }

    return GeneratedMuscleProfile(
      mainMuscle: (json['main_muscle'] ?? 'سینه').toString(),
      secondaryMuscles: (json['secondary_muscles'] ?? '').toString(),
      muscleTargets: MuscleTargets.parse(json['muscle_targets']),
      met: asDouble(json['met']),
      typicalRpe: asDouble(json['typical_rpe']),
      movementPattern: (json['movement_pattern'] ?? '').toString().trim(),
      bodyEngagement: (json['body_engagement'] ?? '').toString().trim(),
      mechanicsType: (json['mechanics_type'] ?? '').toString().trim(),
      forceType: (json['force_type'] ?? '').toString().trim(),
      caloriesPer1000kg: asInt(json['calories_per_1000kg']),
    );
  }

  final String mainMuscle;
  final String secondaryMuscles;
  final Map<String, int> muscleTargets;
  final double? met;
  final double? typicalRpe;
  final String movementPattern;
  final String bodyEngagement;
  final String mechanicsType;
  final String forceType;
  final int? caloriesPer1000kg;
  final MuscleProfileSource source;
  final int? catalogExerciseId;
  final String? catalogExerciseName;

  bool get isFromCatalog => source == MuscleProfileSource.catalog;

  bool get hasCoreMetrics =>
      met != null &&
      typicalRpe != null &&
      movementPattern.isNotEmpty &&
      bodyEngagement.isNotEmpty &&
      mechanicsType.isNotEmpty &&
      forceType.isNotEmpty &&
      caloriesPer1000kg != null;

  String get movementPatternLabel =>
      ExerciseDisplayLabels.movement(movementPattern);

  String get bodyEngagementLabel =>
      ExerciseDisplayLabels.engagement(bodyEngagement);
}
