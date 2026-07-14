import 'package:gymaipro/ai/exercise/fatigue/exercise_fatigue_result.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';

/// Assesses systemic and session fatigue impact of an exercise.
class ExerciseFatigueEngine {
  const ExerciseFatigueEngine();

  ExerciseFatigueResult evaluate({
    required ExerciseProfile exercise,
    required ExerciseIntelligenceQuery query,
  }) {
    final recoveryMultiplier = query.recoveryScore.clamp(0.2, 1);
    final budget =
        (query.maxFatigueBudget * recoveryMultiplier) - query.sessionFatigueAccumulated;
    final projected =
        exercise.fatigueScore * 0.6 + exercise.recoveryCost * 0.4;
    final acceptable = projected <= budget;
    final reasons = <ExerciseIntelligenceReason>[];

    if (!acceptable) {
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'fatigue.too_high',
          subject: exercise.canonicalName,
          because: <String>[
            'Fatigue Too High',
            'Projected=${projected.toStringAsFixed(2)}',
            'Budget=${budget.toStringAsFixed(2)}',
            'RecoveryScore=${query.recoveryScore}',
          ],
        ),
      );
    } else {
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'fatigue.recovery_friendly',
          subject: exercise.canonicalName,
          because: <String>[
            'Recovery Friendly',
            'Projected=${projected.toStringAsFixed(2)}',
            'RecoveryScore=${query.recoveryScore}',
          ],
        ),
      );
    }

    return ExerciseFatigueResult(
      isAcceptable: acceptable,
      projectedFatigue: projected,
      reasons: List<ExerciseIntelligenceReason>.unmodifiable(reasons),
    );
  }
}
