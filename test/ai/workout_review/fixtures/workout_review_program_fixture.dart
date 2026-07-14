import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/models/exercise.dart';

import '../../workout/fixtures/workout_exercise_catalog_fixture.dart';

/// Builds synthetic workout programs for review engine tests.
class WorkoutReviewProgramFixture {
  const WorkoutReviewProgramFixture._();

  static const mapper = ExerciseProfileMapper();
  static final DateTime _now = DateTime(2026, 7, 12);

  static List<ExerciseProfile> gymProfiles() =>
      WorkoutExerciseCatalogFixture.gymCatalog()
          .map(mapper.fromExercise)
          .toList(growable: false);

  static Exercise _byId(int id) =>
      WorkoutExerciseCatalogFixture.gymCatalog().firstWhere((e) => e.id == id);

  static WorkoutProgram balancedProgram() {
    return _program(
      name: 'Balanced PPL',
      experience: 'متوسط',
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          _plan(1, sets: 4, reps: 10, compound: true),
          _plan(6, sets: 3, reps: 10, compound: true),
          _plan(13, sets: 3, reps: 12),
        ],
        <_ExercisePlan>[
          _plan(4, sets: 4, reps: 10, compound: true),
          _plan(5, sets: 3, reps: 10, compound: true),
          _plan(12, sets: 3, reps: 12),
        ],
        <_ExercisePlan>[
          _plan(8, sets: 4, reps: 8, compound: true),
          _plan(10, sets: 3, reps: 10, compound: true),
          _plan(11, sets: 3, reps: 12),
        ],
      ],
    );
  }

  static WorkoutProgram badProgram() {
    return _program(
      name: 'Bad Program',
      experience: 'متوسط',
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 2,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          _plan(1, sets: 6, reps: 6, compound: true),
          _plan(2, sets: 5, reps: 10),
          _plan(3, sets: 5, reps: 12),
          _plan(6, sets: 5, reps: 8, compound: true),
        ],
        <_ExercisePlan>[
          _plan(8, sets: 6, reps: 5, compound: true),
          _plan(9, sets: 5, reps: 10, compound: true),
          _plan(16, sets: 5, reps: 12, compound: true),
        ],
      ],
    );
  }

  static WorkoutProgram highKneeStressProgram() {
    return _program(
      name: 'Knee Stress',
      experience: 'متوسط',
      goal: TrainingGoal.strength,
      daysPerWeek: 3,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          _plan(8, sets: 5, reps: 5, compound: true),
          _plan(9, sets: 5, reps: 8, compound: true),
          _plan(16, sets: 4, reps: 10, compound: true),
        ],
        <_ExercisePlan>[
          _plan(8, sets: 5, reps: 5, compound: true),
          _plan(9, sets: 4, reps: 8, compound: true),
        ],
        <_ExercisePlan>[
          _plan(16, sets: 5, reps: 8, compound: true),
          _plan(8, sets: 4, reps: 6, compound: true),
        ],
      ],
    );
  }

  static WorkoutProgram chestDominantProgram() {
    return _program(
      name: 'Chest Dominant',
      experience: 'متوسط',
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          _plan(1, sets: 5, reps: 10, compound: true),
          _plan(2, sets: 5, reps: 10),
          _plan(3, sets: 5, reps: 12),
        ],
        <_ExercisePlan>[
          _plan(1, sets: 5, reps: 8, compound: true),
          _plan(2, sets: 4, reps: 10),
          _plan(6, sets: 4, reps: 10, compound: true),
        ],
        <_ExercisePlan>[
          _plan(8, sets: 3, reps: 10, compound: true),
          _plan(10, sets: 3, reps: 10, compound: true),
        ],
      ],
    );
  }

  static WorkoutProgram missingBackProgram() {
    return _program(
      name: 'Missing Back',
      experience: 'متوسط',
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 3,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          _plan(1, sets: 4, reps: 10, compound: true),
          _plan(6, sets: 3, reps: 10, compound: true),
          _plan(13, sets: 3, reps: 12),
        ],
        <_ExercisePlan>[
          _plan(2, sets: 4, reps: 10),
          _plan(7, sets: 3, reps: 12),
          _plan(12, sets: 3, reps: 12),
        ],
        <_ExercisePlan>[
          _plan(8, sets: 4, reps: 8, compound: true),
          _plan(11, sets: 3, reps: 12),
        ],
      ],
    );
  }

  static WorkoutProgram equipmentConflictProgram() {
    return _program(
      name: 'Equipment Conflict',
      experience: 'متوسط',
      goal: TrainingGoal.hypertrophy,
      daysPerWeek: 2,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          _plan(1, sets: 4, reps: 10, compound: true, equipment: 'هالتر'),
          _plan(5, sets: 3, reps: 10, compound: true, equipment: 'دستگاه'),
        ],
        <_ExercisePlan>[
          _plan(16, sets: 4, reps: 10, compound: true, equipment: 'دستگاه'),
          _plan(13, sets: 3, reps: 12, equipment: 'دستگاه'),
        ],
      ],
    );
  }

  static WorkoutProgram beginnerHighVolumeProgram() {
    const ids = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    return _program(
      name: 'Beginner High Volume',
      experience: 'مبتدی',
      goal: TrainingGoal.general,
      daysPerWeek: 3,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          for (var i = 0; i < 7; i++)
            _plan(ids[i % ids.length], sets: 3, reps: 12),
        ],
        <_ExercisePlan>[
          for (var i = 0; i < 7; i++)
            _plan(ids[(i + 4) % ids.length], sets: 3, reps: 12),
        ],
        <_ExercisePlan>[
          for (var i = 0; i < 7; i++)
            _plan(ids[(i + 8) % ids.length], sets: 3, reps: 12),
        ],
      ],
    );
  }

  static WorkoutProgram advancedLowVolumeProgram() {
    return _program(
      name: 'Advanced Low Volume',
      experience: 'پیشرفته',
      goal: TrainingGoal.strength,
      daysPerWeek: 4,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[_plan(1, sets: 3, reps: 5, compound: true)],
        <_ExercisePlan>[_plan(4, sets: 3, reps: 5, compound: true)],
        <_ExercisePlan>[_plan(8, sets: 3, reps: 5, compound: true)],
        <_ExercisePlan>[_plan(6, sets: 3, reps: 8, compound: true)],
      ],
    );
  }

  static WorkoutProgram goalMismatchProgram() {
    return _program(
      name: 'Goal Mismatch',
      experience: 'متوسط',
      goal: TrainingGoal.strength,
      daysPerWeek: 2,
      dayPlans: <List<_ExercisePlan>>[
        <_ExercisePlan>[
          _plan(1, sets: 4, reps: 20, compound: true),
          _plan(3, sets: 4, reps: 25),
        ],
        <_ExercisePlan>[
          _plan(2, sets: 4, reps: 20),
          _plan(7, sets: 3, reps: 25),
        ],
      ],
    );
  }

  static WorkoutProgram _program({
    required String name,
    required String experience,
    required TrainingGoal goal,
    required int daysPerWeek,
    required List<List<_ExercisePlan>> dayPlans,
    int weekCount = 1,
  }) {
    final labels = WorkoutScience.dayLabels(daysPerWeek);
    final weeks = <WorkoutWeek>[];
    for (var w = 0; w < weekCount; w++) {
      final days = <WorkoutDay>[];
      for (var d = 0; d < dayPlans.length; d++) {
        final plans = dayPlans[d];
        final exercises = <WorkoutExercise>[];
        for (var i = 0; i < plans.length; i++) {
          final plan = plans[i];
          final catalog = _byId(plan.catalogId);
          exercises.add(
            WorkoutExercise(
              id: 'ex-$w-$d-$i',
              catalogExerciseId: plan.catalogId,
              name: catalog.name,
              primaryMuscle: catalog.mainMuscle,
              equipment: plan.equipment ?? catalog.equipment,
              order: i,
              isCompound: plan.compound,
              sets: List<WorkoutSet>.generate(
                plan.sets,
                (index) => WorkoutSet(
                  id: 'set-$w-$d-$i-$index',
                  order: index,
                  type: WorkoutSetType.reps,
                  reps: plan.reps,
                ),
              ),
            ),
          );
        }
        days.add(
          WorkoutDay(
            id: 'day-$w-$d',
            dayIndex: d,
            label: labels[d],
            exercises: exercises,
          ),
        );
      }
      weeks.add(WorkoutWeek(id: 'week-$w', weekIndex: w + 1, days: days));
    }

    return WorkoutProgram(
      id: 'program-$name',
      name: name,
      goal: goal,
      experienceLevel: experience,
      daysPerWeek: daysPerWeek,
      weeks: weeks,
      createdAt: _now,
      updatedAt: _now,
    );
  }

  static _ExercisePlan _plan(
    int catalogId, {
    required int sets,
    required int reps,
    bool compound = false,
    String? equipment,
  }) {
    return _ExercisePlan(
      catalogId: catalogId,
      sets: sets,
      reps: reps,
      compound: compound,
      equipment: equipment,
    );
  }
}

class _ExercisePlan {
  const _ExercisePlan({
    required this.catalogId,
    required this.sets,
    required this.reps,
    this.compound = false,
    this.equipment,
  });

  final int catalogId;
  final int sets;
  final int reps;
  final bool compound;
  final String? equipment;
}
