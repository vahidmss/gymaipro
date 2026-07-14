import 'package:gymaipro/ai/exercise/compatibility/exercise_compatibility_result.dart';
import 'package:gymaipro/ai/exercise/fatigue/exercise_fatigue_result.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_result.dart';
import 'package:gymaipro/ai/exercise/scoring/exercise_scoring_result.dart';

/// Combined evaluation from all exercise intelligence engines.
class ExerciseIntelligenceEvaluation {
  const ExerciseIntelligenceEvaluation({
    required this.exercise,
    required this.enabled,
    required this.scoring,
    required this.compatibility,
    required this.safety,
    required this.fatigue,
    required this.recommended,
    required this.reasons,
  });

  factory ExerciseIntelligenceEvaluation.disabled({
    required ExerciseProfile exercise,
  }) {
    return ExerciseIntelligenceEvaluation(
      exercise: exercise,
      enabled: false,
      scoring: const ExerciseScoringResult(score: 0, reasons: <ExerciseIntelligenceReason>[]),
      compatibility: const ExerciseCompatibilityResult(
        isCompatible: false,
        reasons: <ExerciseIntelligenceReason>[],
      ),
      safety: const ExerciseSafetyResult(
        isSafe: false,
        reasons: <ExerciseIntelligenceReason>[],
      ),
      fatigue: const ExerciseFatigueResult(
        isAcceptable: false,
        projectedFatigue: 0,
        reasons: <ExerciseIntelligenceReason>[],
      ),
      recommended: false,
      reasons: const <ExerciseIntelligenceReason>[
        ExerciseIntelligenceReason(
          code: 'runtime.disabled',
          subject: 'ExerciseIntelligenceRuntime',
          because: <String>['CoachV2 is disabled'],
        ),
      ],
    );
  }

  final ExerciseProfile exercise;
  final bool enabled;
  final ExerciseScoringResult scoring;
  final ExerciseCompatibilityResult compatibility;
  final ExerciseSafetyResult safety;
  final ExerciseFatigueResult fatigue;
  final bool recommended;
  final List<ExerciseIntelligenceReason> reasons;

  ExerciseIntelligenceEvaluation copyWith({
    ExerciseProfile? exercise,
    bool? enabled,
    ExerciseScoringResult? scoring,
    ExerciseCompatibilityResult? compatibility,
    ExerciseSafetyResult? safety,
    ExerciseFatigueResult? fatigue,
    bool? recommended,
    List<ExerciseIntelligenceReason>? reasons,
  }) {
    return ExerciseIntelligenceEvaluation(
      exercise: exercise ?? this.exercise,
      enabled: enabled ?? this.enabled,
      scoring: scoring ?? this.scoring,
      compatibility: compatibility ?? this.compatibility,
      safety: safety ?? this.safety,
      fatigue: fatigue ?? this.fatigue,
      recommended: recommended ?? this.recommended,
      reasons: reasons ?? this.reasons,
    );
  }
}
