import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_result.dart';

/// Screens exercises against injury limitations and joint load profiles.
class ExerciseSafetyEngine {
  const ExerciseSafetyEngine();

  ExerciseSafetyResult evaluate({
    required ExerciseProfile exercise,
    required ExerciseIntelligenceQuery query,
  }) {
    final reasons = <ExerciseIntelligenceReason>[];
    var safe = true;

    for (final limitation in query.limitations) {
      final normalized = limitation.toLowerCase();
      if (_kneeLimitation(normalized) && exercise.kneeLoad >= 0.45) {
        safe = false;
        reasons.add(
          ExerciseIntelligenceReason(
            code: 'safety.knee_risk',
            subject: exercise.canonicalName,
            because: <String>[
              'Knee load too high for limitation: $limitation',
              'KneeLoad=${exercise.kneeLoad}',
            ],
          ),
        );
      }
      if (_shoulderLimitation(normalized) && exercise.shoulderLoad >= 0.45) {
        safe = false;
        reasons.add(
          ExerciseIntelligenceReason(
            code: 'safety.shoulder_risk',
            subject: exercise.canonicalName,
            because: <String>[
              'Shoulder load too high for limitation: $limitation',
              'ShoulderLoad=${exercise.shoulderLoad}',
            ],
          ),
        );
      }
      if (_backLimitation(normalized) && exercise.spineLoad >= 0.45) {
        safe = false;
        reasons.add(
          ExerciseIntelligenceReason(
            code: 'safety.spine_risk',
            subject: exercise.canonicalName,
            because: <String>[
              'Spine load too high for limitation: $limitation',
              'SpineLoad=${exercise.spineLoad}',
            ],
          ),
        );
      }
    }

    if (exercise.injuryRisk >= 0.75 && query.limitations.isNotEmpty) {
      safe = false;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'safety.high_injury_risk',
          subject: exercise.canonicalName,
          because: <String>[
            'High injury risk profile',
            'InjuryRisk=${exercise.injuryRisk}',
          ],
        ),
      );
    }

    if (safe) {
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'safety.injury_safe',
          subject: exercise.canonicalName,
          because: <String>['Injury Safe', 'Joint loads within tolerance'],
        ),
      );
    }

    return ExerciseSafetyResult(
      isSafe: safe,
      reasons: List<ExerciseIntelligenceReason>.unmodifiable(reasons),
    );
  }

  bool _kneeLimitation(String limitation) {
    return limitation.contains('زانو') || limitation.contains('knee');
  }

  bool _shoulderLimitation(String limitation) {
    return limitation.contains('شانه') || limitation.contains('shoulder');
  }

  bool _backLimitation(String limitation) {
    return limitation.contains('کمر') ||
        limitation.contains('پشت') ||
        limitation.contains('back') ||
        limitation.contains('دیسک');
  }
}
