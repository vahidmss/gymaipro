import 'package:gymaipro/ai/workout/equipment/workout_equipment_tokens.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/planner/workout_split_planner.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';

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
      availableEquipment: WorkoutEquipmentTokens.expand(blueprint.equipment),
      limitations: blueprint.limitations,
      // Program generation is multi-day planning, not an acute live session.
      // Floor recovery so a heavy heatmap week cannot empty the catalog.
      recoveryScore: blueprint.trace.recoveryScore.clamp(0.7, 1.0),
      avoidExerciseNames: blueprint.avoidExercises,
      maxFatigueBudget: _maxFatigueBudget(blueprint),
      sessionFatigueAccumulated: sessionFatigueAccumulated,
    );
  }

  // Day muscle targeting is enforced by selector bucket gate before evaluate().

  double _maxFatigueBudget(WorkoutBlueprint blueprint) {
    // FatigueEngine multiplies this by recoveryScore — keep base generous.
    return switch (blueprint.recoveryStrategy) {
      WorkoutRecoveryStrategy.conservative => 0.85,
      WorkoutRecoveryStrategy.normal => 0.95,
      WorkoutRecoveryStrategy.aggressive => 1,
    };
  }
}