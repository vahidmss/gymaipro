import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';

/// Outcome of exercise fatigue assessment.
class ExerciseFatigueResult {
  const ExerciseFatigueResult({
    required this.isAcceptable,
    required this.projectedFatigue,
    required this.reasons,
  });

  final bool isAcceptable;
  final double projectedFatigue;
  final List<ExerciseIntelligenceReason> reasons;

  ExerciseFatigueResult copyWith({
    bool? isAcceptable,
    double? projectedFatigue,
    List<ExerciseIntelligenceReason>? reasons,
  }) {
    return ExerciseFatigueResult(
      isAcceptable: isAcceptable ?? this.isAcceptable,
      projectedFatigue: projectedFatigue ?? this.projectedFatigue,
      reasons: reasons ?? this.reasons,
    );
  }
}
