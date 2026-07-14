import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_decision_step.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_fidelity_validator.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_reason.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_trace.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_versions.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_complexity.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_exercise_replacement_policy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_frequency_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_intensity_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_periodization_type.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_training_style.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_volume_strategy.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/workout/generator/coach_workout_generator.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/ai/workout/models/workout_progression.dart';
import '../fixtures/workout_exercise_catalog_fixture.dart';

WorkoutBlueprint _validBlueprint({
  WorkoutSplitStrategy split = WorkoutSplitStrategy.pushPullLegs,
  WorkoutFrequencyStrategy frequency = WorkoutFrequencyStrategy.three,
  WorkoutRecoveryStrategy recovery = WorkoutRecoveryStrategy.normal,
  WorkoutVolumeStrategy volume = WorkoutVolumeStrategy.medium,
}) {
  return WorkoutBlueprint(
    goal: TrainingGoal.hypertrophy,
    experience: 'متوسط',
    daysPerWeek: frequency.daysPerWeek,
    splitStrategy: split,
    frequency: frequency,
    volume: volume,
    intensity: WorkoutIntensityStrategy.moderate,
    periodization: WorkoutPeriodizationType.linear,
    recoveryStrategy: recovery,
    equipment: const <String>['هالتر', 'دمبل'],
    limitations: const <String>[],
    preferredMuscles: const <String>[],
    avoidExercises: const <String>[],
    preferredExercises: const <String>[],
    weeklySetsTarget: 14,
    maxSessionMinutes: 60,
    minRecoveryHours: 24,
    preferredExerciseComplexity: WorkoutExerciseComplexity.moderate,
    exerciseReplacementPolicy: WorkoutExerciseReplacementPolicy.substitute,
    deloadFrequencyWeeks: 4,
    progressionStrategy: WorkoutProgressionStrategy.increaseReps,
    trainingStyle: WorkoutTrainingStyle.hypertrophy,
    exercisesPerSession: 4,
    confidence: 0.9,
    reasons: const <WorkoutBlueprintReason>[
      WorkoutBlueprintReason(
        code: 'test',
        subject: 'Test',
        because: <String>['fixture'],
      ),
    ],
    trace: const WorkoutBlueprintTrace(
      steps: <String>['test'],
      recoveryScore: 0.85,
      decisions: <WorkoutBlueprintDecisionStep>[
        WorkoutBlueprintDecisionStep(
          decision: 'splitStrategy',
          outcome: 'pushPullLegs',
          factors: <String>['Goal=hypertrophy'],
        ),
      ],
    ),
    userId: 'test_user',
    varietySeed: 42,
  );
}

void main() {
  const generator = CoachWorkoutGenerator();
  const fidelityValidator = WorkoutBlueprintFidelityValidator();
  final catalog = ListExerciseCatalogAdapter(
    WorkoutExerciseCatalogFixture.gymCatalog(),
  );

  group('EPIC 20.5 blueprint finalization', () {
    test('blueprint versioning fields are populated', () {
      final blueprint = _validBlueprint();
      expect(blueprint.schemaVersion, WorkoutBlueprintVersions.schemaVersion);
      expect(blueprint.builderVersion, WorkoutBlueprintVersions.builderVersion);
      expect(blueprint.createdBy, WorkoutBlueprintVersions.createdBy);
      expect(
        blueprint.planningEngineVersion,
        WorkoutBlueprintVersions.planningEngineVersion,
      );
    });

    test('blueprint models are immutable via copyWith', () {
      final original = _validBlueprint();
      final updated = original.copyWith(volume: WorkoutVolumeStrategy.high);
      expect(updated.volume, WorkoutVolumeStrategy.high);
      expect(original.volume, WorkoutVolumeStrategy.medium);

      final trace = original.trace;
      final updatedTrace = trace.copyWith(recoveryScore: 0.2);
      expect(updatedTrace.recoveryScore, 0.2);
      expect(trace.recoveryScore, 0.85);
    });

    test('trace records decision chain not only outcomes', () {
      final blueprint = _validBlueprint();
      final splitDecision = blueprint.trace.decisions.firstWhere(
        (step) => step.decision == 'splitStrategy',
      );
      expect(splitDecision.factors, contains('Goal=hypertrophy'));
    });

    test('generator cannot override invalid blueprint', () {
      final invalid = _validBlueprint().copyWith(
        daysPerWeek: 2,
        frequency: WorkoutFrequencyStrategy.four,
        splitStrategy: WorkoutSplitStrategy.phat,
      );
      final result = generator.generate(
        blueprint: invalid,
        catalog: catalog,
      );
      expect(result.status, WorkoutGeneratorStatus.blueprintInvalid);
      expect(result.program, isNull);
      expect(result.validationIssues, isNotEmpty);
    });

    test('missing blueprint fields fail fidelity validation', () {
      final invalid = _validBlueprint().copyWith(
        weeklySetsTarget: 0,
        exercisesPerSession: 1,
      );
      final validation = fidelityValidator.validate(invalid);
      expect(validation.isValid, isFalse);
    });

    test('recovery conflict is rejected', () {
      final invalid = _validBlueprint(
        recovery: WorkoutRecoveryStrategy.conservative,
        volume: WorkoutVolumeStrategy.veryHigh,
      );
      final validation = fidelityValidator.validate(invalid);
      expect(validation.isValid, isFalse);
      expect(
        validation.issues.any((issue) => issue.contains('Recovery conflict')),
        isTrue,
      );
    });

    test('frequency conflict is rejected', () {
      final invalid = _validBlueprint().copyWith(
        daysPerWeek: 3,
        frequency: WorkoutFrequencyStrategy.five,
      );
      final validation = fidelityValidator.validate(invalid);
      expect(validation.isValid, isFalse);
      expect(
        validation.issues.any((issue) => issue.contains('Frequency conflict')),
        isTrue,
      );
    });

    test('split conflict is rejected', () {
      final invalid = _validBlueprint(
        split: WorkoutSplitStrategy.phat,
        frequency: WorkoutFrequencyStrategy.two,
      );
      final validation = fidelityValidator.validate(invalid);
      expect(validation.isValid, isFalse);
      expect(
        validation.issues.any((issue) => issue.contains('Split conflict')),
        isTrue,
      );
    });

    test('valid blueprint executes without overriding planning fields', () {
      final blueprint = _validBlueprint();
      final result = generator.generate(
        blueprint: blueprint,
        catalog: catalog,
      );
      expect(result.isSuccess, isTrue);
      expect(result.program!.goal, blueprint.goal);
      expect(result.program!.daysPerWeek, blueprint.daysPerWeek);
    });
  });
}
