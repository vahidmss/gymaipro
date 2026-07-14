import 'dart:math';

import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_fidelity_validator.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_reason.dart';
import 'package:gymaipro/ai/workout/exercise_selector/workout_exercise_selector.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_selection_trace.dart';
import 'package:gymaipro/ai/workout/models/workout_note.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/ai/workout/planner/workout_split_planner.dart';
import 'package:gymaipro/ai/workout/progression/workout_progression_engine.dart';
import 'package:gymaipro/ai/workout/validator/workout_program_validator.dart';
import 'package:uuid/uuid.dart';

/// Rule-based offline workout program generator.
///
/// Executes a pre-planned [WorkoutBlueprint]. Does not make planning decisions.
class CoachWorkoutGenerator {
  const CoachWorkoutGenerator({
    WorkoutSplitPlanner splitPlanner = const WorkoutSplitPlanner(),
    WorkoutExerciseSelector exerciseSelector = const WorkoutExerciseSelector(),
    WorkoutProgressionEngine progressionEngine = const WorkoutProgressionEngine(),
    WorkoutProgramValidator validator = const WorkoutProgramValidator(),
    WorkoutBlueprintFidelityValidator fidelityValidator =
        const WorkoutBlueprintFidelityValidator(),
  }) : _splitPlanner = splitPlanner,
       _exerciseSelector = exerciseSelector,
       _progressionEngine = progressionEngine,
       _validator = validator,
       _fidelityValidator = fidelityValidator;

  final WorkoutSplitPlanner _splitPlanner;
  final WorkoutExerciseSelector _exerciseSelector;
  final WorkoutProgressionEngine _progressionEngine;
  final WorkoutProgramValidator _validator;
  final WorkoutBlueprintFidelityValidator _fidelityValidator;
  static const Uuid _uuid = Uuid();

  WorkoutGeneratorResult generate({
    required WorkoutBlueprint blueprint,
    required ExerciseCatalogAdapter catalog,
  }) {
    final fidelity = _fidelityValidator.validate(blueprint);
    if (!fidelity.isValid) {
      return WorkoutGeneratorResult(
        status: WorkoutGeneratorStatus.blueprintInvalid,
        validationIssues: fidelity.issues,
        message: 'Blueprint cannot be executed faithfully.',
      );
    }

    if (catalog.isEmpty) {
      return const WorkoutGeneratorResult(
        status: WorkoutGeneratorStatus.insufficientExercises,
        message: 'Exercise catalog is empty.',
      );
    }

    final rng = Random(
      blueprint.varietySeed ?? DateTime.now().microsecondsSinceEpoch,
    );
    final dayPlans = _splitPlanner.planFromBlueprint(blueprint);
    final usedInProgram = <int>{};
    final days = <WorkoutDay>[];
    final allReasons = _blueprintReasonsToGenerator(blueprint.reasons);
    var selectionTrace = WorkoutGeneratorSelectionTrace.empty();

    for (final dayPlan in dayPlans) {
      final dayResult = _exerciseSelector.selectForDay(
        dayPlan: dayPlan,
        blueprint: blueprint,
        catalog: catalog,
        usedInProgram: usedInProgram,
      );
      selectionTrace = selectionTrace.merge(dayResult.trace);
      if (dayResult.selected.isEmpty) continue;

      final exercises = <WorkoutExercise>[];
      for (var i = 0; i < dayResult.selected.length; i++) {
        final selection = dayResult.selected[i];
        usedInProgram.add(selection.exercise.id);
        final sets = _progressionEngine.buildSets(
          exercise: selection.exercise,
          blueprint: blueprint,
          exerciseOrder: i + 1,
        );
        exercises.add(
          WorkoutExercise(
            id: _uuid.v4(),
            catalogExerciseId: selection.exercise.id,
            name: selection.exercise.name,
            primaryMuscle: selection.exercise.mainMuscle,
            secondaryMuscles: selection.exercise.secondaryMuscles
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList(),
            equipment: selection.exercise.equipment,
            difficulty: selection.exercise.difficulty,
            isCompound: selection.evaluation.exercise.compound,
            order: i + 1,
            sets: sets,
            selectionReasons: selection.reasons,
          ),
        );
        allReasons.addAll(selection.reasons);
      }

      days.add(
        WorkoutDay(
          id: _uuid.v4(),
          dayIndex: dayPlan.dayIndex,
          label: dayPlan.label,
          exercises: exercises,
          notes: <WorkoutNote>[
            WorkoutNote(
              id: _uuid.v4(),
              text: WorkoutScience.restGuidance(blueprint.goal),
              scope: WorkoutNoteScope.day,
            ),
          ],
        ),
      );
      allReasons.addAll(dayPlan.reasons);
    }

    if (days.isEmpty) {
      return WorkoutGeneratorResult(
        status: WorkoutGeneratorStatus.insufficientExercises,
        selectionTrace: selectionTrace,
        message: 'Could not select exercises for any training day.',
      );
    }

    final now = DateTime.now();
    final program = WorkoutProgram(
      id: _uuid.v4(),
      userId: blueprint.userId,
      name: _programName(blueprint, rng),
      goal: blueprint.goal,
      experienceLevel: blueprint.experience,
      daysPerWeek: blueprint.daysPerWeek,
      sessionDurationMinutes: blueprint.maxSessionMinutes,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: _uuid.v4(),
          weekIndex: 1,
          days: days,
        ),
      ],
      programReasons: allReasons,
      createdAt: now,
      updatedAt: now,
    );

    final validation = _validator.validate(program: program, blueprint: blueprint);
    if (!validation.isValid) {
      return WorkoutGeneratorResult(
        status: WorkoutGeneratorStatus.validationFailed,
        validationIssues: validation.issues,
        reasons: allReasons,
        selectionTrace: selectionTrace,
        message: 'Generated program failed validation.',
      );
    }

    return WorkoutGeneratorResult(
      status: WorkoutGeneratorStatus.success,
      program: program,
      reasons: allReasons,
      selectionTrace: selectionTrace,
      message: 'Workout program generated offline.',
    );
  }

  List<WorkoutGeneratorReason> _blueprintReasonsToGenerator(
    List<WorkoutBlueprintReason> reasons,
  ) {
    return reasons
        .map(
          (reason) => WorkoutGeneratorReason(
            code: reason.code,
            subject: reason.subject,
            because: reason.because,
          ),
        )
        .toList();
  }

  String _programName(WorkoutBlueprint blueprint, Random rng) {
    final goalLabel = switch (blueprint.goal) {
      TrainingGoal.hypertrophy => 'عضله‌سازی',
      TrainingGoal.strength => 'قدرت',
      TrainingGoal.fatLoss => 'چربی‌سوزی',
      TrainingGoal.endurance => 'استقامت',
      TrainingGoal.general => 'تناسب‌اندام',
    };
    return 'برنامه $goalLabel — ${blueprint.daysPerWeek} روزه';
  }
}
