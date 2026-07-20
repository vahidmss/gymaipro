import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modification.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_result.dart';
import 'package:gymaipro/ai/workout_modify/runtime/workout_modify_runtime.dart';

void main() {
  group('workout modify goals behave correctly', () {
    test('home version never swaps dumbbell OHP into machine', () {
      final dumbbellOhp = _profile(
        id: 1,
        name: 'پرس سرشانه دمبل',
        pattern: ExerciseMovementPattern.verticalPush,
        muscles: const <String>['سرشانه'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.dumbbell],
      );
      final machineOhp = _profile(
        id: 2,
        name: 'پرس سرشانه دستگاه',
        pattern: ExerciseMovementPattern.verticalPush,
        muscles: const <String>['سرشانه'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.machine],
        injuryRisk: 0.2,
      );
      final bandRaise = _profile(
        id: 3,
        name: 'نشر جانب با کش',
        pattern: ExerciseMovementPattern.isolation,
        muscles: const <String>['سرشانه'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.band],
        injuryRisk: 0.25,
        compound: false,
      );

      final result = _run(
        exerciseName: 'پرس سرشانه دمبل',
        catalogId: 1,
        equipmentField: '',
        types: const <WorkoutModificationType>[
          WorkoutModificationType.homeVersion,
        ],
        catalog: <ExerciseProfile>[dumbbellOhp, machineOhp, bandRaise],
      );

      final after = result.modifiedProgram.allDays.first.exercises.first.name;
      expect(after, isNot(contains('دستگاه')));
      expect(after, anyOf(contains('دمبل'), contains('کش')));

      final badSwaps = result.modifications.where(
        (m) =>
            m.status == WorkoutModificationStatus.applied &&
            (m.afterName ?? '').contains('دستگاه'),
      );
      expect(badSwaps, isEmpty);
    });

    test('home version converts barbell OHP to dumbbell not machine', () {
      final barbellOhp = _profile(
        id: 1,
        name: 'پرس سرشانه با هالتر',
        pattern: ExerciseMovementPattern.verticalPush,
        muscles: const <String>['سرشانه'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.barbell],
        injuryRisk: 0.7,
      );
      final machineOhp = _profile(
        id: 2,
        name: 'پرس سرشانه دستگاه',
        pattern: ExerciseMovementPattern.verticalPush,
        muscles: const <String>['سرشانه'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.machine],
        injuryRisk: 0.2,
      );
      final dumbbellOhp = _profile(
        id: 3,
        name: 'پرس سرشانه دمبل',
        pattern: ExerciseMovementPattern.verticalPush,
        muscles: const <String>['سرشانه'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.dumbbell],
        injuryRisk: 0.4,
      );

      final result = _run(
        exerciseName: 'پرس سرشانه با هالتر',
        catalogId: 1,
        equipmentField: 'هالتر',
        types: const <WorkoutModificationType>[
          WorkoutModificationType.homeVersion,
        ],
        catalog: <ExerciseProfile>[barbellOhp, machineOhp, dumbbellOhp],
      );

      final applied = result.modifications.where(
        (m) =>
            m.status == WorkoutModificationStatus.applied &&
            (m.afterName ?? '').isNotEmpty,
      );
      expect(applied, isNotEmpty);
      expect(applied.first.afterName, contains('دمبل'));
      expect(applied.first.afterName, isNot(contains('دستگاه')));
    });

    test('recovery only trims sets and keeps OHP name', () {
      final ohp = _profile(
        id: 1,
        name: 'پرس سرشانه با هالتر',
        pattern: ExerciseMovementPattern.verticalPush,
        muscles: const <String>['سرشانه'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.barbell],
        fatigue: 0.8,
      );
      final squat = _profile(
        id: 2,
        name: 'اسکوات هالتر',
        pattern: ExerciseMovementPattern.squat,
        muscles: const <String>['پا'],
        equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.barbell],
        fatigue: 0.3,
      );

      final result = _run(
        exerciseName: 'پرس سرشانه با هالتر',
        catalogId: 1,
        equipmentField: 'هالتر',
        types: const <WorkoutModificationType>[
          WorkoutModificationType.recoveryAdaptation,
        ],
        catalog: <ExerciseProfile>[ohp, squat],
        setCount: 3,
      );

      expect(
        result.modifiedProgram.allDays.first.exercises.first.name,
        contains('سرشانه'),
      );
      expect(
        result.modifiedProgram.allDays.first.exercises.first.sets.length,
        lessThan(3),
      );
      final replaces = result.modifications.where(
        (m) =>
            (m.beforeName ?? '').isNotEmpty && (m.afterName ?? '').isNotEmpty,
      );
      expect(replaces, isEmpty);
    });

    test('reduce volume does not rename exercises', () {
      final result = _run(
        exerciseName: 'پرس سینه هالتر',
        catalogId: 1,
        equipmentField: 'هالتر',
        types: const <WorkoutModificationType>[
          WorkoutModificationType.reduceVolume,
        ],
        catalog: <ExerciseProfile>[
          _profile(
            id: 1,
            name: 'پرس سینه هالتر',
            pattern: ExerciseMovementPattern.horizontalPush,
            muscles: const <String>['سینه'],
            equipment: const <ExerciseEquipmentType>[
              ExerciseEquipmentType.barbell,
            ],
          ),
        ],
        setCount: 4,
      );
      expect(
        result.modifiedProgram.allDays.first.exercises.first.name,
        'پرس سینه هالتر',
      );
      expect(
        result.modifiedProgram.allDays.first.exercises.first.sets.length,
        lessThan(4),
      );
    });
  });
}

WorkoutModificationResult _run({
  required String exerciseName,
  required int catalogId,
  required String equipmentField,
  required List<WorkoutModificationType> types,
  required List<ExerciseProfile> catalog,
  int setCount = 3,
}) {
  final sets = List<WorkoutSet>.generate(
    setCount,
    (i) => WorkoutSet(
      id: 's$i',
      order: i + 1,
      type: WorkoutSetType.reps,
      reps: 10,
    ),
  );
  final program = WorkoutProgram(
    id: 'p1',
    userId: 'u1',
    name: 'test',
    goal: TrainingGoal.hypertrophy,
    experienceLevel: 'متوسط',
    daysPerWeek: 1,
    sessionDurationMinutes: 45,
    weeks: <WorkoutWeek>[
      WorkoutWeek(
        id: 'w1',
        weekIndex: 1,
        days: <WorkoutDay>[
          WorkoutDay(
            id: 'd1',
            dayIndex: 1,
            label: 'روز ۱',
            exercises: <WorkoutExercise>[
              WorkoutExercise(
                id: 'ex1',
                catalogExerciseId: catalogId,
                name: exerciseName,
                primaryMuscle: 'سرشانه',
                equipment: equipmentField,
                order: 0,
                sets: sets,
              ),
            ],
          ),
        ],
      ),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  return const WorkoutModifyRuntime(enforceCoachV2Gate: false).modify(
    program: program,
    context: CoachContext.empty(intent: AIIntent.workoutModification),
    modifications: types,
    catalogProfiles: catalog,
  );
}

ExerciseProfile _profile({
  required int id,
  required String name,
  required ExerciseMovementPattern pattern,
  required List<String> muscles,
  required List<ExerciseEquipmentType> equipment,
  double injuryRisk = 0.5,
  double fatigue = 0.5,
  bool compound = true,
}) {
  return ExerciseProfile(
    id: id,
    slug: 'ex-$id',
    canonicalName: name,
    primaryMuscles: muscles,
    movementPattern: pattern,
    equipment: equipment,
    injuryRisk: injuryRisk,
    fatigueScore: fatigue,
    recoveryCost: fatigue,
    stimulusScore: 0.5,
    compound: compound,
    isolation: !compound,
  );
}
