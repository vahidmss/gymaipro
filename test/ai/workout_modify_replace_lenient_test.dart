import 'package:flutter_test/flutter_test.dart';
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
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';

void main() {
  test('explicit replace finds candidate when equipment is only باشگاه', () {
    final original = _profile(
      id: 1,
      name: 'پرس سرشانه دمبل',
      pattern: ExerciseMovementPattern.verticalPush,
      muscles: const <String>['سرشانه'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.dumbbell],
      shoulderLoad: 0.7,
    );
    final alt = _profile(
      id: 2,
      name: 'نشر جانب دمبل',
      pattern: ExerciseMovementPattern.isolation,
      muscles: const <String>['سرشانه'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.dumbbell],
      shoulderLoad: 0.35,
    );
    final machine = _profile(
      id: 3,
      name: 'پرس سرشانه دستگاه',
      pattern: ExerciseMovementPattern.verticalPush,
      muscles: const <String>['سرشانه'],
      equipment: const <ExerciseEquipmentType>[ExerciseEquipmentType.machine],
      shoulderLoad: 0.45,
    );

    final program = WorkoutProgram(
      id: 'p1',
      userId: 'u1',
      name: 'test',
      goal: TrainingGoal.fatLoss,
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
                  name: 'پرس سرشانه دمبل',
                  primaryMuscle: 'سرشانه',
                  order: 0,
                  sets: const <WorkoutSet>[
                    WorkoutSet(
                      id: 's1',
                      order: 1,
                      type: WorkoutSetType.reps,
                      reps: 10,
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
      context: CoachContext.empty(intent: AIIntent.workoutModification).copyWith(
        equipment: const <String>['باشگاه'],
      ),
      modifications: const <WorkoutModificationType>[
        WorkoutModificationType.replaceExercise,
      ],
      catalogProfiles: <ExerciseProfile>[original, alt, machine],
      options: const <String, Object?>{
        'exerciseId': 'ex1',
        'preferLowerJoint': 'shoulder',
        'avoidExerciseName': 'پرس سرشانه دمبل',
      },
    );

    final applied = result.modifications
        .where((m) => m.status == WorkoutModificationStatus.applied)
        .toList();
    expect(applied, isNotEmpty);
    expect(applied.first.afterName, isNotNull);
    expect(applied.first.afterName, isNot(equals('پرس سرشانه دمبل')));
  });
}

ExerciseProfile _profile({
  required int id,
  required String name,
  required ExerciseMovementPattern pattern,
  required List<String> muscles,
  required List<ExerciseEquipmentType> equipment,
  required double shoulderLoad,
}) {
  return ExerciseProfile(
    id: id,
    slug: 'ex-$id',
    canonicalName: name,
    primaryMuscles: muscles,
    movementPattern: pattern,
    equipment: equipment,
    shoulderLoad: shoulderLoad,
    injuryRisk: shoulderLoad * 0.8,
    fatigueScore: 0.4,
    stimulusScore: 0.5,
    recoveryCost: 0.4,
  );
}

extension on CoachContext {
  CoachContext copyWith({List<String>? equipment}) {
    return CoachContext(
      intent: intent,
      metadata: metadata,
      profile: profile,
      goals: goals,
      restrictions: restrictions,
      equipment: equipment ?? this.equipment,
      preferences: preferences,
      activeProgram: activeProgram,
      workoutHistory: workoutHistory,
      weeklyHeatmap: weeklyHeatmap,
      memories: memories,
      apiUsage: apiUsage,
      currentQuestion: currentQuestion,
      conversationSummary: conversationSummary,
    );
  }
}
