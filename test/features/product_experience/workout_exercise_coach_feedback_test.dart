import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

List<PreviousExerciseSet> _prev(double kg, {int reps = 12, int n = 3}) {
  return List<PreviousExerciseSet>.generate(
    n,
    (_) => PreviousExerciseSet(reps: reps, weight: kg),
  );
}

void main() {
  group('WorkoutExerciseCoachFeedbackEngine', () {
    test('returns null until all sets are saved', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.fromControllers(
        prescription: <ExerciseSet>[
          ExerciseSet(reps: 12, weight: 35),
          ExerciseSet(reps: 12, weight: 35),
        ],
        setValues: <Map<String, String>>[
          <String, String>{'weight': '35', 'reps': '12'},
          <String, String>{'weight': '35', 'reps': '12'},
        ],
        savedStatus: <bool>[true, false],
        style: ExerciseStyle.setsReps,
      );
      expect(feedback, isNull);
    });

    test('first complete log consolidates load instead of bumping', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.fromControllers(
        prescription: <ExerciseSet>[
          ExerciseSet(reps: 15, weight: 35),
          ExerciseSet(reps: 15, weight: 35),
          ExerciseSet(reps: 15, weight: 35),
        ],
        setValues: <Map<String, String>>[
          <String, String>{'weight': '35', 'reps': '15'},
          <String, String>{'weight': '35', 'reps': '15'},
          <String, String>{'weight': '35', 'reps': '15'},
        ],
        savedStatus: <bool>[true, true, true],
        style: ExerciseStyle.setsReps,
        formTipSource: 'لگنت را از روی دستگاه بلند نکن.',
      );

      expect(feedback, isNotNull);
      expect(feedback!.decision!.action, ExerciseCoachAction.hold);
      expect(
        feedback.decision!.pattern,
        ExerciseCoachPattern.stableHoldFirstSession,
      );
      expect(feedback.decision!.toLockJson()['first_session'], isTrue);
      expect(feedback.decision!.toLockJson()['chase_load'], isFalse);
      expect(feedback.nextSession, contains('35'));
      expect(feedback.nextSession, isNot(contains('40')));
      expect(feedback.formTip, contains('لگنت'));
    });

    test(
      'failed heavy probe 12x30 / 12x30 / 8x40 does NOT start next at 40',
      () {
        final feedback = WorkoutExerciseCoachFeedbackEngine.build(
          sets: const <LoggedSetPerformance>[
            LoggedSetPerformance(
              targetReps: 12,
              actualReps: 12,
              actualWeightKg: 30,
            ),
            LoggedSetPerformance(
              targetReps: 12,
              actualReps: 12,
              actualWeightKg: 30,
            ),
            LoggedSetPerformance(
              targetReps: 12,
              actualReps: 8,
              actualWeightKg: 40,
            ),
          ],
          isTimedStyle: false,
        );

        expect(feedback, isNotNull);
        expect(feedback!.analysis, contains('30'));
        expect(feedback.analysis, contains('40'));
        expect(feedback.analysis, contains('8'));
        expect(feedback.analysis, contains('سنگینه'));
        expect(feedback.nextSession, contains('30'));
        expect(feedback.nextSession, contains('از 40 شروع نکن'));
        expect(feedback.nextSession, isNot(contains('از 40 برای همه')));
        expect(feedback.nextSession, isNot(contains('45')));
      },
    );

    test('successful heavy probe earns a bridge, not a full jump to peak', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
        ],
        isTimedStyle: false,
      );

      expect(feedback!.analysis, contains('پایه'));
      expect(feedback.analysis, contains('هر سه ست نیست'));
      expect(feedback.nextSession, contains('شروع نکن'));
      expect(feedback.nextSession, contains('35'));
      expect(feedback.nextSession, contains('40'));
    });

    test('detects drop-off 20/20/10 and refuses progression', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 8,
            actualReps: 8,
            actualWeightKg: 20,
          ),
          LoggedSetPerformance(
            targetReps: 8,
            actualReps: 8,
            actualWeightKg: 20,
          ),
          LoggedSetPerformance(
            targetReps: 8,
            actualReps: 8,
            actualWeightKg: 10,
          ),
        ],
        isTimedStyle: false,
      );

      expect(feedback!.analysis, contains('سبک‌تر'));
      expect(feedback.nextSession, contains('20'));
      expect(feedback.nextSession, contains('زیاد نکن'));
      expect(feedback.nextSession, isNot(contains('25')));
    });

    test('stable same weight still progresses when reps hit', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 8,
            actualReps: 8,
            actualWeightKg: 20,
          ),
          LoggedSetPerformance(
            targetReps: 8,
            actualReps: 8,
            actualWeightKg: 20,
          ),
          LoggedSetPerformance(
            targetReps: 8,
            actualReps: 8,
            actualWeightKg: 20,
          ),
        ],
        isTimedStyle: false,
        previousSets: _prev(20, reps: 8),
      );

      expect(feedback!.nextSession, contains('25'));
      expect(feedback.analysis, contains('تکرار کامل'));
    });

    test(
      'clean ascending pyramid with full reps does not jump every set to the peak',
      () {
        final feedback = WorkoutExerciseCoachFeedbackEngine.build(
          sets: const <LoggedSetPerformance>[
            LoggedSetPerformance(
              targetReps: 10,
              actualReps: 10,
              actualWeightKg: 20,
            ),
            LoggedSetPerformance(
              targetReps: 10,
              actualReps: 10,
              actualWeightKg: 25,
            ),
            LoggedSetPerformance(
              targetReps: 10,
              actualReps: 10,
              actualWeightKg: 30,
            ),
          ],
          isTimedStyle: false,
        );

        expect(feedback!.decision!.action, isNot(ExerciseCoachAction.increase));
        expect(feedback.nextSession, contains('30'));
        expect(feedback.nextSession, isNot(contains('35')));
        expect(
          feedback.nextSession,
          anyOf(contains('25'), contains('شروع نکن')),
        );
      },
    );

    test('RPE 8 with full reps holds load without claiming missed reps', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
            rpe: 8,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
            rpe: 8,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
            rpe: 8,
          ),
        ],
        isTimedStyle: false,
      );

      expect(feedback!.analysis, contains('کامل'));
      expect(feedback.analysis, contains('شدت'));
      expect(feedback.analysis, contains('8'));
      expect(feedback.analysis, isNot(contains('کمتر از هدف')));
      expect(feedback.nextSession, contains('همین'));
      expect(feedback.nextSession, contains('۶–۷'));
      expect(feedback.nextSession, isNot(contains('35')));
    });

    test('RPE 6–7 with full reps still progresses', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
            rpe: 6,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
            rpe: 7,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 30,
            rpe: 7,
          ),
        ],
        isTimedStyle: false,
        previousSets: _prev(30),
      );

      expect(feedback!.analysis, contains('جا افتاده'));
      expect(feedback.nextSession, contains('35'));
    });

    test('suggests hold when reps fall short', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            targetWeightKg: 40,
            actualReps: 9,
            actualWeightKg: 40,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            targetWeightKg: 40,
            actualReps: 8,
            actualWeightKg: 40,
          ),
        ],
        isTimedStyle: false,
      );

      expect(feedback!.analysis, contains('تکرار'));
      expect(feedback.analysis, contains('وزنه بیشتر'));
      expect(feedback.nextSession, contains('همین'));
      expect(feedback.nextSession, contains('12'));
    });

    test('holds when reps fade across stable weight', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 10,
            actualWeightKg: 40,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 8,
            actualWeightKg: 40,
          ),
        ],
        isTimedStyle: false,
      );

      expect(feedback!.analysis, contains('افت'));
      expect(feedback.nextSession, contains('40'));
      expect(feedback.nextSession, isNot(contains('45')));
    });

    test('2 of 3 sets at 40kg does NOT bump all 3 to 45', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
        ],
        isTimedStyle: false,
        prescribedSetCount: 3,
      );

      expect(feedback, isNotNull);
      expect(feedback!.decision!.action, ExerciseCoachAction.hold);
      expect(feedback.decision!.pattern, ExerciseCoachPattern.incompleteVolume);
      expect(feedback.decision!.workingWeightKg, 40);
      expect(feedback.decision!.nextWeightKg, 40);
      expect(feedback.decision!.prescribedSetCount, 3);
      expect(feedback.decision!.setCount, 2);
      expect(feedback.decision!.isIncompleteVolume, isTrue);
      expect(feedback.decision!.toLockJson()['incomplete_volume'], isTrue);
      expect(feedback.analysis, contains('3'));
      expect(feedback.analysis, contains('2'));
      expect(feedback.analysis, contains('40'));
      expect(feedback.nextSession, contains('40'));
      expect(feedback.nextSession, isNot(contains('45')));
      expect(feedback.decision!.targetLine, contains('40'));
      expect(feedback.decision!.targetLine, isNot(contains('45')));
    });

    test('all 3 prescribed sets at 40kg still earns 45', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
        ],
        isTimedStyle: false,
        prescribedSetCount: 3,
        previousSets: _prev(40),
      );

      expect(feedback!.decision!.action, ExerciseCoachAction.increase);
      expect(feedback.decision!.nextWeightKg, 45);
      expect(feedback.decision!.targetLine, contains('45'));
      expect(feedback.nextSession, contains('45'));
    });

    test('single-set prescription can still progress', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 40,
          ),
        ],
        isTimedStyle: false,
        prescribedSetCount: 1,
        previousSets: _prev(40, n: 1),
      );

      expect(feedback!.decision!.action, ExerciseCoachAction.increase);
      expect(feedback.decision!.nextWeightKg, 45);
    });
  });
}
