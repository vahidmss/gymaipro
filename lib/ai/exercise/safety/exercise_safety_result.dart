import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';

/// Outcome of exercise safety screening.
class ExerciseSafetyResult {
  const ExerciseSafetyResult({
    required this.isSafe,
    required this.reasons,
  });

  final bool isSafe;
  final List<ExerciseIntelligenceReason> reasons;

  ExerciseSafetyResult copyWith({
    bool? isSafe,
    List<ExerciseIntelligenceReason>? reasons,
  }) {
    return ExerciseSafetyResult(
      isSafe: isSafe ?? this.isSafe,
      reasons: reasons ?? this.reasons,
    );
  }
}
