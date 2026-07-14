import 'package:gymaipro/ai/exercise/compatibility/exercise_compatibility_engine.dart';
import 'package:gymaipro/ai/exercise/fatigue/exercise_fatigue_engine.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/replacement/exercise_replacement_result.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_engine.dart';
import 'package:gymaipro/ai/exercise/scoring/exercise_scoring_engine.dart';

/// Finds safer or better-fitting alternatives for a given exercise.
class ExerciseReplacementEngine {
  const ExerciseReplacementEngine({
    this.scoringEngine = const ExerciseScoringEngine(),
    this.compatibilityEngine = const ExerciseCompatibilityEngine(),
    this.safetyEngine = const ExerciseSafetyEngine(),
    this.fatigueEngine = const ExerciseFatigueEngine(),
  });

  final ExerciseScoringEngine scoringEngine;
  final ExerciseCompatibilityEngine compatibilityEngine;
  final ExerciseSafetyEngine safetyEngine;
  final ExerciseFatigueEngine fatigueEngine;

  ExerciseReplacementResult findReplacements({
    required ExerciseProfile original,
    required List<ExerciseProfile> catalog,
    required ExerciseIntelligenceQuery query,
    int limit = 3,
  }) {
    final reasons = <ExerciseIntelligenceReason>[];
    final candidates = <ExerciseReplacementCandidate>[];

    for (final candidate in catalog) {
      if (candidate.id == original.id) continue;

      final samePattern = candidate.movementPattern == original.movementPattern;
      final sameMuscle = _sharesPrimaryMuscle(candidate, original);
      if (!samePattern && !sameMuscle) continue;

      final compatibility = compatibilityEngine.evaluate(
        exercise: candidate,
        query: query,
      );
      if (!compatibility.isCompatible) continue;

      final safety = safetyEngine.evaluate(exercise: candidate, query: query);
      if (!safety.isSafe) continue;

      final fatigue = fatigueEngine.evaluate(exercise: candidate, query: query);
      if (!fatigue.isAcceptable) continue;

      final scoring = scoringEngine.score(exercise: candidate, query: query);
      var score = scoring.score;
      if (candidate.injuryRisk < original.injuryRisk) score += 0.2;
      if (candidate.fatigueScore < original.fatigueScore) score += 0.15;

      final candidateReasons = <ExerciseIntelligenceReason>[
        ...scoring.reasons,
        ExerciseIntelligenceReason(
          code: 'replacement.better',
          subject: candidate.canonicalName,
          because: <String>[
            'Better Replacement',
            'Replaces=${original.canonicalName}',
            if (candidate.injuryRisk < original.injuryRisk)
              'Lower injury risk',
            if (candidate.fatigueScore < original.fatigueScore)
              'Lower fatigue cost',
          ],
        ),
      ];

      candidates.add(
        ExerciseReplacementCandidate(
          exercise: candidate,
          score: score,
          reasons: List<ExerciseIntelligenceReason>.unmodifiable(
            candidateReasons,
          ),
        ),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final top = candidates.take(limit).toList();

    if (top.isEmpty) {
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'replacement.none',
          subject: original.canonicalName,
          because: <String>['No suitable replacement found in catalog'],
        ),
      );
    }

    return ExerciseReplacementResult(
      original: original,
      candidates: List<ExerciseReplacementCandidate>.unmodifiable(top),
      reasons: List<ExerciseIntelligenceReason>.unmodifiable(reasons),
    );
  }

  bool _sharesPrimaryMuscle(
    ExerciseProfile candidate,
    ExerciseProfile original,
  ) {
    return candidate.primaryMuscles.any(
      (muscle) => original.primaryMuscles.any(
        (originalMuscle) =>
            muscle.contains(originalMuscle) ||
            originalMuscle.contains(muscle),
      ),
    );
  }
}
