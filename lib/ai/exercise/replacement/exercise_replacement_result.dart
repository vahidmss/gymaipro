import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';

/// One ranked replacement candidate.
class ExerciseReplacementCandidate {
  const ExerciseReplacementCandidate({
    required this.exercise,
    required this.score,
    required this.reasons,
  });

  final ExerciseProfile exercise;
  final double score;
  final List<ExerciseIntelligenceReason> reasons;
}

/// Outcome of replacement search.
class ExerciseReplacementResult {
  const ExerciseReplacementResult({
    required this.original,
    required this.candidates,
    required this.reasons,
  });

  final ExerciseProfile original;
  final List<ExerciseReplacementCandidate> candidates;
  final List<ExerciseIntelligenceReason> reasons;

  ExerciseReplacementResult copyWith({
    ExerciseProfile? original,
    List<ExerciseReplacementCandidate>? candidates,
    List<ExerciseIntelligenceReason>? reasons,
  }) {
    return ExerciseReplacementResult(
      original: original ?? this.original,
      candidates: candidates ?? this.candidates,
      reasons: reasons ?? this.reasons,
    );
  }
}
