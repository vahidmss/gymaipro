import 'package:gymaipro/models/muscle_targets.dart';

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

/// فقط نقشه عضلانی و گروه‌های عضلانی — بدون توضیحات و نکات.
class GeneratedMuscleProfile {
  const GeneratedMuscleProfile({
    required this.mainMuscle,
    required this.secondaryMuscles,
    required this.muscleTargets,
  });

  factory GeneratedMuscleProfile.fromJson(Map<String, dynamic> json) {
    return GeneratedMuscleProfile(
      mainMuscle: (json['main_muscle'] ?? 'سینه').toString(),
      secondaryMuscles: (json['secondary_muscles'] ?? '').toString(),
      muscleTargets: MuscleTargets.parse(json['muscle_targets']),
    );
  }

  final String mainMuscle;
  final String secondaryMuscles;
  final Map<String, int> muscleTargets;
}
