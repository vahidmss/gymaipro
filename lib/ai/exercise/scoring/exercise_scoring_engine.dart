import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/scoring/exercise_scoring_result.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';

/// Scores how well an exercise fits a programming query.
class ExerciseScoringEngine {
  const ExerciseScoringEngine();

  ExerciseScoringResult score({
    required ExerciseProfile exercise,
    required ExerciseIntelligenceQuery query,
  }) {
    var score = 0.0;
    final reasons = <ExerciseIntelligenceReason>[];

    if (_matchesGoal(exercise, query.goal)) {
      score += 0.3;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'goal.match',
          subject: exercise.canonicalName,
          because: <String>[
            'Goal Match',
            'PreferredGoals=${exercise.preferredGoals.map((g) => g.name).join(',')}',
            'QueryGoal=${query.goal.name}',
          ],
        ),
      );
    }

    if (_matchesEquipment(exercise, query.availableEquipment)) {
      score += 0.25;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'equipment.match',
          subject: exercise.canonicalName,
          because: <String>[
            'Equipment Match',
            'Required=${exercise.equipment.map((e) => e.name).join(',')}',
            'Available=${query.availableEquipment.join(',')}',
          ],
        ),
      );
    } else {
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'equipment.mismatch',
          subject: exercise.canonicalName,
          because: <String>[
            'Equipment mismatch',
            'Required=${exercise.equipment.map((e) => e.name).join(',')}',
          ],
        ),
      );
    }

    if (_matchesMuscles(exercise, query.targetMuscles)) {
      score += 0.2;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'muscle.match',
          subject: exercise.canonicalName,
          because: <String>[
            'Target muscle alignment',
            'Primary=${exercise.primaryMuscles.join(',')}',
          ],
        ),
      );
    }

    if (query.preferCompound && exercise.compound) {
      score += 0.15;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'movement.compound_bonus',
          subject: exercise.canonicalName,
          because: <String>['Compound movement bonus'],
        ),
      );
    }

    if (_matchesExperience(exercise, query.experience)) {
      score += 0.1;
      reasons.add(
        ExerciseIntelligenceReason(
          code: 'experience.match',
          subject: exercise.canonicalName,
          because: <String>[
            'Experience fit',
            'Required=${exercise.experienceLevel.name}',
            'User=${query.experience}',
          ],
        ),
      );
    }

    score += exercise.stimulusScore * 0.1;

    return ExerciseScoringResult(
      score: score.clamp(0, 2),
      reasons: List<ExerciseIntelligenceReason>.unmodifiable(reasons),
    );
  }

  bool _matchesGoal(ExerciseProfile exercise, TrainingGoal goal) {
    if (exercise.preferredGoals.isEmpty) return true;
    return exercise.preferredGoals.contains(goal) ||
        exercise.preferredGoals.contains(TrainingGoal.general);
  }

  bool _matchesEquipment(
    ExerciseProfile exercise,
    List<String> availableEquipment,
  ) {
    if (availableEquipment.isEmpty) return true;
    final available = availableEquipment.join(' ').toLowerCase();
    final homeGym = available.contains('خانه') || available.contains('home');
    return exercise.equipment.any((type) {
      return switch (type) {
        ExerciseEquipmentType.barbell =>
          available.contains('هالتر') || available.contains('barbell'),
        ExerciseEquipmentType.dumbbell =>
          available.contains('دمبل') ||
              available.contains('dumbbell') ||
              homeGym,
        ExerciseEquipmentType.machine =>
          available.contains('دستگاه') || available.contains('machine'),
        ExerciseEquipmentType.cable =>
          available.contains('کابل') ||
              available.contains('cable') ||
              available.contains('پولی'),
        ExerciseEquipmentType.bodyweight =>
          available.contains('بدون') ||
              available.contains('bodyweight') ||
              homeGym,
        ExerciseEquipmentType.kettlebell =>
          available.contains('کتل') || available.contains('kettlebell'),
        ExerciseEquipmentType.band =>
          available.contains('کش') || available.contains('band') || homeGym,
        ExerciseEquipmentType.other => homeGym,
      };
    });
  }

  bool _matchesMuscles(
    ExerciseProfile exercise,
    List<String> targetMuscles,
  ) {
    if (targetMuscles.isEmpty) return true;
    final muscles = <String>{
      ...exercise.primaryMuscles,
      ...exercise.secondaryMuscles,
    };
    return targetMuscles.any(
      (target) => muscles.any(
        (muscle) =>
            muscle.contains(target) ||
            target.contains(muscle) ||
            muscle.toLowerCase().contains(target.toLowerCase()),
      ),
    );
  }

  bool _matchesExperience(ExerciseProfile exercise, String experience) {
    if (WorkoutScience.isBeginnerExperience(experience)) {
      return exercise.experienceLevel == ExerciseExperienceLevel.beginner ||
          exercise.experienceLevel == ExerciseExperienceLevel.intermediate;
    }
    if (WorkoutScience.isAdvancedExperience(experience)) {
      return true;
    }
    return exercise.experienceLevel != ExerciseExperienceLevel.advanced;
  }
}
