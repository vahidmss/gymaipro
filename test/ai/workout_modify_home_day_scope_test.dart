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
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/runtime/workout_modify_runtime.dart';

void main() {
  test('home version only touches selected day and never suggests cable', () {
    final day1BarbellPress = _profile(
      id: 1,
      name: 'پرس سرشانه با هالتر',
      pattern: ExerciseMovementPattern.verticalPush,
      muscles: const <String>['سرشانه'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.barbell],
    );
    final day2Squat = _profile(
      id: 2,
      name: 'اسکوات هالتر',
      pattern: ExerciseMovementPattern.squat,
      muscles: const <String>['پا'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.barbell],
    );
    final cableRow = _profile(
      id: 3,
      name: 'زیربغل سیم کش',
      pattern: ExerciseMovementPattern.horizontalPull,
      muscles: const <String>['زیربغل'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.cable],
      injuryRisk: 0.15,
    );
    final dumbbellPress = _profile(
      id: 4,
      name: 'پرس سرشانه دمبل',
      pattern: ExerciseMovementPattern.verticalPush,
      muscles: const <String>['سرشانه'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.dumbbell],
      injuryRisk: 0.35,
    );
    final bandPull = _profile(
      id: 5,
      name: 'زیربغل با کش',
      pattern: ExerciseMovementPattern.horizontalPull,
      muscles: const <String>['زیربغل'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.band],
      injuryRisk: 0.25,
    );

    final program = WorkoutProgram(
      id: 'p1',
      userId: 'u1',
      name: 'test',
      goal: TrainingGoal.hypertrophy,
      experienceLevel: 'متوسط',
      daysPerWeek: 2,
      sessionDurationMinutes: 45,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 1,
          days: <WorkoutDay>[
            WorkoutDay(
              id: 'd1',
              dayIndex: 1,
              label: 'روز ۱ — بالاتنه ۱',
              exercises: <WorkoutExercise>[
                WorkoutExercise(
                  id: 'ex-day1',
                  catalogExerciseId: 1,
                  name: 'پرس سرشانه با هالتر',
                  primaryMuscle: 'سرشانه',
                  equipment: 'هالتر',
                  order: 0,
                  sets: const <WorkoutSet>[
                    WorkoutSet(
                      id: 's1',
                      order: 1,
                      type: WorkoutSetType.reps,
                      reps: 8,
                    ),
                  ],
                ),
              ],
            ),
            WorkoutDay(
              id: 'd2',
              dayIndex: 2,
              label: 'روز ۲ — پایین‌تنه ۱',
              exercises: <WorkoutExercise>[
                WorkoutExercise(
                  id: 'ex-day2',
                  catalogExerciseId: 2,
                  name: 'اسکوات هالتر',
                  primaryMuscle: 'پا',
                  equipment: 'هالتر',
                  order: 0,
                  sets: const <WorkoutSet>[
                    WorkoutSet(
                      id: 's2',
                      order: 1,
                      type: WorkoutSetType.reps,
                      reps: 8,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final result = const WorkoutModifyRuntime(enforceCoachV2Gate: false).modify(
      program: program,
      context: CoachContext.empty(intent: AIIntent.workoutModification),
      modifications: const <WorkoutModificationType>[
        WorkoutModificationType.homeVersion,
      ],
      catalogProfiles: <ExerciseProfile>[
        day1BarbellPress,
        day2Squat,
        cableRow,
        dumbbellPress,
        bandPull,
      ],
      options: const <String, Object?>{
        'dayLabel': 'روز ۱ — بالاتنه ۱',
      },
    );

    final day1Name =
        result.modifiedProgram.allDays.first.exercises.first.name;
    final day2Name =
        result.modifiedProgram.allDays[1].exercises.first.name;

    expect(day1Name, isNot(contains('هالتر')));
    expect(day1Name, anyOf(contains('دمبل'), contains('کش')));
    expect(day1Name.toLowerCase(), isNot(contains('سیم')));
    expect(day1Name, isNot(contains('دستگاه')));

    // Day 2 must stay untouched — squat was never on day 1.
    expect(day2Name, 'اسکوات هالتر');

    final appliedNames = result.modifications
        .where((m) => m.status == WorkoutModificationStatus.applied)
        .expand((m) => <String?>[m.beforeName, m.afterName])
        .whereType<String>()
        .join(' ');
    expect(appliedNames, isNot(contains('اسکوات')));
    expect(appliedNames, isNot(contains('سیم')));
  });
}

ExerciseProfile _profile({
  required int id,
  required String name,
  required ExerciseMovementPattern pattern,
  required List<String> muscles,
  required List<ExerciseEquipmentType> equipment,
  double injuryRisk = 0.5,
}) {
  return ExerciseProfile(
    id: id,
    slug: 'ex-$id',
    canonicalName: name,
    primaryMuscles: muscles,
    movementPattern: pattern,
    equipment: equipment,
    injuryRisk: injuryRisk,
    fatigueScore: 0.5,
    recoveryCost: 0.5,
    stimulusScore: 0.5,
    compound: true,
    isolation: false,
  );
}
