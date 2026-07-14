import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/exercise/compatibility/exercise_compatibility_engine.dart';
import 'package:gymaipro/ai/exercise/fatigue/exercise_fatigue_engine.dart';
import 'package:gymaipro/ai/exercise/intelligence/exercise_intelligence_evaluation.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_versions.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/replacement/exercise_replacement_engine.dart';
import 'package:gymaipro/ai/exercise/replacement/exercise_replacement_result.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_engine.dart';
import 'package:gymaipro/ai/exercise/scoring/exercise_scoring_engine.dart';

/// Orchestrates exercise intelligence engines without coupling to workout generation.
class ExerciseIntelligenceRuntime {
  const ExerciseIntelligenceRuntime({
    this.scoringEngine = const ExerciseScoringEngine(),
    this.compatibilityEngine = const ExerciseCompatibilityEngine(),
    this.safetyEngine = const ExerciseSafetyEngine(),
    this.fatigueEngine = const ExerciseFatigueEngine(),
    this.replacementEngine = const ExerciseReplacementEngine(),
    this.enforceCoachV2Gate = true,
  });

  final ExerciseScoringEngine scoringEngine;
  final ExerciseCompatibilityEngine compatibilityEngine;
  final ExerciseSafetyEngine safetyEngine;
  final ExerciseFatigueEngine fatigueEngine;
  final ExerciseReplacementEngine replacementEngine;
  final bool enforceCoachV2Gate;

  String get engineVersion => ExerciseIntelligenceVersions.engineVersion;

  ExerciseIntelligenceEvaluation evaluate({
    required ExerciseProfile exercise,
    required ExerciseIntelligenceQuery query,
  }) {
    if (enforceCoachV2Gate && !CoachV2Config.coachV2Enabled) {
      return ExerciseIntelligenceEvaluation.disabled(exercise: exercise);
    }

    final scoring = scoringEngine.score(exercise: exercise, query: query);
    final compatibility = compatibilityEngine.evaluate(
      exercise: exercise,
      query: query,
    );
    final safety = safetyEngine.evaluate(exercise: exercise, query: query);
    final fatigue = fatigueEngine.evaluate(exercise: exercise, query: query);

    final recommended = compatibility.isCompatible &&
        safety.isSafe &&
        fatigue.isAcceptable &&
        scoring.score >= 0.35;

    final reasons = <ExerciseIntelligenceReason>[
      ...scoring.reasons,
      ...compatibility.reasons,
      ...safety.reasons,
      ...fatigue.reasons,
    ];

    return ExerciseIntelligenceEvaluation(
      exercise: exercise,
      enabled: true,
      scoring: scoring,
      compatibility: compatibility,
      safety: safety,
      fatigue: fatigue,
      recommended: recommended,
      reasons: List<ExerciseIntelligenceReason>.unmodifiable(reasons),
    );
  }

  List<ExerciseIntelligenceEvaluation> rankCatalog({
    required List<ExerciseProfile> catalog,
    required ExerciseIntelligenceQuery query,
  }) {
    final evaluations = catalog
        .map((exercise) => evaluate(exercise: exercise, query: query))
        .where((result) => result.enabled && result.recommended)
        .toList()
      ..sort((a, b) => b.scoring.score.compareTo(a.scoring.score));
    return evaluations;
  }

  ExerciseReplacementResult findReplacement({
    required ExerciseProfile original,
    required List<ExerciseProfile> catalog,
    required ExerciseIntelligenceQuery query,
    int limit = 3,
  }) {
    if (enforceCoachV2Gate && !CoachV2Config.coachV2Enabled) {
      return ExerciseReplacementResult(
        original: original,
        candidates: const <ExerciseReplacementCandidate>[],
        reasons: const <ExerciseIntelligenceReason>[
          ExerciseIntelligenceReason(
            code: 'runtime.disabled',
            subject: 'ExerciseIntelligenceRuntime',
            because: <String>['CoachV2 is disabled'],
          ),
        ],
      );
    }

    return replacementEngine.findReplacements(
      original: original,
      catalog: catalog,
      query: query,
      limit: limit,
    );
  }
}
