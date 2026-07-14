import 'package:gymaipro/ai/exercise/compatibility/exercise_compatibility_result.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/scoring/exercise_scoring_engine.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';

/// Checks whether an exercise can be programmed for the given query.
class ExerciseCompatibilityEngine {
  const ExerciseCompatibilityEngine({
    this.scoringEngine = const ExerciseScoringEngine(),
  });

  final ExerciseScoringEngine scoringEngine;

  ExerciseCompatibilityResult evaluate({
    required ExerciseProfile exercise,
    required ExerciseIntelligenceQuery query,
  }) {
    final reasons = <ExerciseIntelligenceReason>[];
    var compatible = true;

    if (_isAvoided(exercise, query.avoidExerciseNames)) {
      compatible = false;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'compatibility.avoided',
          subject: exercise.canonicalName,
          because: <String>['Exercise is on user avoid list'],
        ),
      );
    }

    final scoring = scoringEngine.score(exercise: exercise, query: query);
    final equipmentMatch = scoring.reasons.any(
      (reason) => reason.code == 'equipment.match',
    );
    if (!equipmentMatch && query.availableEquipment.isNotEmpty) {
      compatible = false;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'compatibility.equipment',
          subject: exercise.canonicalName,
          because: <String>['Equipment not available for this session'],
        ),
      );
    }

    if (!_matchesExperience(exercise, query.experience)) {
      compatible = false;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'compatibility.experience',
          subject: exercise.canonicalName,
          because: <String>[
            'Experience mismatch',
            'Required=${exercise.experienceLevel.name}',
          ],
        ),
      );
    }

    if (query.targetMuscles.isNotEmpty && !_matchesMuscles(exercise, query)) {
      compatible = false;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'compatibility.muscle',
          subject: exercise.canonicalName,
          because: <String>[
            'Target muscles do not align',
            'Expected=${query.targetMuscles.join(',')}',
          ],
        ),
      );
    }

    if (compatible) {
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'compatibility.pass',
          subject: exercise.canonicalName,
          because: <String>['Exercise is compatible with session constraints'],
        ),
      );
    }

    return ExerciseCompatibilityResult(
      isCompatible: compatible,
      reasons: List<ExerciseIntelligenceReason>.unmodifiable(reasons),
    );
  }

  bool _isAvoided(ExerciseProfile exercise, List<String> avoidNames) {
    if (avoidNames.isEmpty) return false;
    for (final avoid in avoidNames) {
      final normalized = avoid.toLowerCase();
      for (final name in exercise.searchableNames) {
        if (name.toLowerCase().contains(normalized)) return true;
      }
    }
    return false;
  }

  bool _matchesExperience(ExerciseProfile exercise, String experience) {
    if (WorkoutScience.isBeginnerExperience(experience)) {
      return exercise.experienceLevel != ExerciseExperienceLevel.advanced;
    }
    return true;
  }

  bool _matchesMuscles(
    ExerciseProfile exercise,
    ExerciseIntelligenceQuery query,
  ) {
    final muscles = <String>{
      ...exercise.primaryMuscles,
      ...exercise.secondaryMuscles,
    };
    return query.targetMuscles.any(
      (target) => muscles.any((muscle) => muscle.contains(target)),
    );
  }
}
