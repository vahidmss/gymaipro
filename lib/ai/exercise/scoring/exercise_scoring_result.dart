import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';

/// Outcome of exercise scoring.
class ExerciseScoringResult {
  const ExerciseScoringResult({
    required this.score,
    required this.reasons,
  });

  final double score;
  final List<ExerciseIntelligenceReason> reasons;

  ExerciseScoringResult copyWith({
    double? score,
    List<ExerciseIntelligenceReason>? reasons,
  }) {
    return ExerciseScoringResult(
      score: score ?? this.score,
      reasons: reasons ?? this.reasons,
    );
  }
}
