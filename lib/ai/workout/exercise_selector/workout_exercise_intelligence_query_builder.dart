import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/planner/workout_split_planner.dart';

/// Maps workout planning artifacts to exercise intelligence queries.
class WorkoutExerciseIntelligenceQueryBuilder {
  const WorkoutExerciseIntelligenceQueryBuilder();

  ExerciseIntelligenceQuery build({
    required WorkoutBlueprint blueprint,
    required WorkoutDayPlan dayPlan,
    double sessionFatigueAccumulated = 0,
  }) {
    return ExerciseIntelligenceQuery(
      goal: blueprint.goal,
      experience: blueprint.experience,
      availableEquipment: _equipmentWithGymDefaults(blueprint.equipment),
      limitations: blueprint.limitations,
      recoveryScore: blueprint.trace.recoveryScore,
      avoidExerciseNames: blueprint.avoidExercises,
      maxFatigueBudget: _maxFatigueBudget(blueprint),
      sessionFatigueAccumulated: sessionFatigueAccumulated,
    );
  }

  List<String> _equipmentWithGymDefaults(List<String> equipment) {
    final normalized = List<String>.from(equipment);
    final impliesGym = normalized.any(
      (item) =>
          item.contains('هالتر') ||
          item.contains('barbell') ||
          item.contains('باشگاه') ||
          item.contains('gym'),
    );
    if (impliesGym && !normalized.any((item) => item.contains('دستگاه'))) {
      normalized.add('دستگاه');
    }
    return normalized;
  }

  // Day muscle targeting is enforced by selector bucket gate before evaluate().

  double _maxFatigueBudget(WorkoutBlueprint blueprint) {
    final base = switch (blueprint.recoveryStrategy) {
      WorkoutRecoveryStrategy.conservative => 0.6,
      WorkoutRecoveryStrategy.normal => 0.9,
      WorkoutRecoveryStrategy.aggressive => 1,
    };
    return (base * blueprint.trace.recoveryScore.clamp(0.4, 1.0)).clamp(0.35, 1.0);
  }
}
