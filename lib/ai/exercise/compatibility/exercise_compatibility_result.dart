import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';

/// Outcome of exercise compatibility checks.
class ExerciseCompatibilityResult {
  const ExerciseCompatibilityResult({
    required this.isCompatible,
    required this.reasons,
  });

  final bool isCompatible;
  final List<ExerciseIntelligenceReason> reasons;

  ExerciseCompatibilityResult copyWith({
    bool? isCompatible,
    List<ExerciseIntelligenceReason>? reasons,
  }) {
    return ExerciseCompatibilityResult(
      isCompatible: isCompatible ?? this.isCompatible,
      reasons: reasons ?? this.reasons,
    );
  }
}
