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
  test('recovery only trims volume and never swaps OHP into squat', () {
    final ohp = _profile(
      id: 1,
      name: 'پرس سرشانه با هالتر',
      pattern: ExerciseMovementPattern.verticalPush,
      muscles: const <String>['سرشانه'],
      fatigue: 0.75,
      recovery: 0.7,
      compound: true,
    );
    final squat = _profile(
      id: 2,
      name: 'اسکوات هالتر',
      pattern: ExerciseMovementPattern.squat,
      muscles: const <String>['پا'],
      fatigue: 0.4,
      recovery: 0.3,
      compound: true,
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
                  catalogExerciseId: 1,
                  name: 'پرس سرشانه با هالتر',
                  primaryMuscle: 'سرشانه',
                  order: 0,
                  sets: const <WorkoutSet>[
                    WorkoutSet(
                      id: 's1',
                      order: 1,
                      type: WorkoutSetType.reps,
                      reps: 8,
                    ),
                    WorkoutSet(
                      id: 's2',
                      order: 2,
                      type: WorkoutSetType.reps,
                      reps: 8,
                    ),
                    WorkoutSet(
                      id: 's3',
                      order: 3,
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
        WorkoutModificationType.recoveryAdaptation,
      ],
      catalogProfiles: <ExerciseProfile>[ohp, squat],
    );

    final replaces = result.modifications.where(
      (m) =>
          m.status == WorkoutModificationStatus.applied &&
          (m.beforeName ?? '').isNotEmpty &&
          (m.afterName ?? '').isNotEmpty,
    );
    expect(replaces, isEmpty);

    final keptName = result.modifiedProgram.allDays.first.exercises.first.name;
    expect(keptName, contains('سرشانه'));
    expect(keptName, isNot(contains('اسکوات')));

    final setsAfter =
        result.modifiedProgram.allDays.first.exercises.first.sets.length;
    expect(setsAfter, lessThan(3));
  });
}

ExerciseProfile _profile({
  required int id,
  required String name,
  required ExerciseMovementPattern pattern,
  required List<String> muscles,
  required double fatigue,
  required double recovery,
  required bool compound,
}) {
  return ExerciseProfile(
    id: id,
    slug: 'ex-$id',
    canonicalName: name,
    primaryMuscles: muscles,
    movementPattern: pattern,
    fatigueScore: fatigue,
    recoveryCost: recovery,
    stimulusScore: 0.5,
    compound: compound,
    isolation: !compound,
  );
}
