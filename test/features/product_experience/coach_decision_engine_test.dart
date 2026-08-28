import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/product_experience/domain/coach_decision_lock.dart';
import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  group('ExerciseDecision structured output', () {
    test('stable ready exposes increase action and next weight', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 35,
            rpe: 7,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 35,
            rpe: 7,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 35,
            rpe: 7,
          ),
        ],
        isTimedStyle: false,
        previousSets: const <PreviousExerciseSet>[
          PreviousExerciseSet(reps: 12, weight: 35),
          PreviousExerciseSet(reps: 12, weight: 35),
          PreviousExerciseSet(reps: 12, weight: 35),
        ],
      );

      expect(feedback, isNotNull);
      expect(feedback!.decision, isNotNull);
      expect(feedback.decision!.action, ExerciseCoachAction.increase);
      expect(feedback.decision!.nextWeightKg, 40);
      expect(feedback.decision!.toLockJson()['next_weight_kg'], 40);
    });

    test('previous comparison is attached when history exists', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 20,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 20,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 11,
            actualWeightKg: 20,
          ),
        ],
        isTimedStyle: false,
        previousSets: const <PreviousExerciseSet>[
          PreviousExerciseSet(reps: 8, weight: 20),
          PreviousExerciseSet(reps: 8, weight: 20),
          PreviousExerciseSet(reps: 8, weight: 20),
        ],
      );

      expect(feedback!.decision!.previousComparison, contains('تکرار بیشتر'));
    });

    test('assisted reps note appears and does not invent higher load', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 17.5,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 17.5,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 8,
            actualWeightKg: 20,
            assisted: true,
          ),
        ],
        isTimedStyle: false,
      );

      expect(feedback!.decision!.action, isNot(ExerciseCoachAction.increase));
      expect(
        feedback.decision!.previousComparison ?? feedback.analysis,
        anyOf(contains('کمکی'), contains('17.5'), contains('نگه')),
      );
    });

    test('leg press 50x3 then 55/55/60 is a probe, not another increase', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 55,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 55,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 60,
          ),
        ],
        isTimedStyle: false,
        previousSets: const <PreviousExerciseSet>[
          PreviousExerciseSet(reps: 12, weight: 50),
          PreviousExerciseSet(reps: 12, weight: 50),
          PreviousExerciseSet(reps: 12, weight: 50),
        ],
      );

      expect(feedback, isNotNull);
      expect(feedback!.decision, isNotNull);
      expect(feedback.decision!.action, isNot(ExerciseCoachAction.increase));
      expect(feedback.decision!.action, ExerciseCoachAction.bridge);
      expect(feedback.decision!.workingWeightKg, 55);
      expect(feedback.decision!.probeWeightKg, 60);
      expect(feedback.decision!.bridgeWeightKg, 55);
      expect(feedback.decision!.previousComparison, contains('ست‌های اول'));
      expect(feedback.decision!.previousComparison, contains('ست آخر'));
      expect(feedback.decision!.previousComparison, contains('رکورد'));
      expect(feedback.decision!.previousComparison, contains('60'));
      expect(feedback.decision!.previousComparison, contains('10'));
      expect(feedback.decision!.targetLine, contains('55'));
      expect(feedback.decision!.targetLine, contains('60'));
      expect(feedback.decision!.targetLine, isNot(contains('→')));
      expect(feedback.nextSession, contains('60'));
      expect(feedback.nextSession, isNot(contains('65')));
    });

    test('same load as last time and all reps hit → then increase', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 50,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 50,
          ),
          LoggedSetPerformance(
            targetReps: 12,
            actualReps: 12,
            actualWeightKg: 50,
          ),
        ],
        isTimedStyle: false,
        previousSets: const <PreviousExerciseSet>[
          PreviousExerciseSet(reps: 12, weight: 50),
          PreviousExerciseSet(reps: 12, weight: 50),
          PreviousExerciseSet(reps: 12, weight: 50),
        ],
      );

      expect(feedback!.decision!.action, ExerciseCoachAction.increase);
      expect(feedback.decision!.nextWeightKg, 55);
    });

    test(
      'already jumped all working sets this session → consolidate, do not jump again',
      () {
        final feedback = WorkoutExerciseCoachFeedbackEngine.build(
          sets: const <LoggedSetPerformance>[
            LoggedSetPerformance(
              targetReps: 12,
              actualReps: 12,
              actualWeightKg: 55,
            ),
            LoggedSetPerformance(
              targetReps: 12,
              actualReps: 12,
              actualWeightKg: 55,
            ),
            LoggedSetPerformance(
              targetReps: 12,
              actualReps: 12,
              actualWeightKg: 55,
            ),
          ],
          isTimedStyle: false,
          previousSets: const <PreviousExerciseSet>[
            PreviousExerciseSet(reps: 12, weight: 50),
            PreviousExerciseSet(reps: 12, weight: 50),
            PreviousExerciseSet(reps: 12, weight: 50),
          ],
        );

        expect(feedback!.decision!.action, ExerciseCoachAction.hold);
        expect(feedback.decision!.nextWeightKg, 55);
        expect(feedback.decision!.actionLabel, contains('تثبیت'));
        expect(feedback.analysis, contains('تثبیت'));
      },
    );

    test(
      'repeated heavy last set raises working by one step, not halfway to the probe',
      () {
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
              actualWeightKg: 55,
            ),
          ],
          isTimedStyle: false,
          previousSets: const <PreviousExerciseSet>[
            PreviousExerciseSet(reps: 12, weight: 40),
            PreviousExerciseSet(reps: 12, weight: 40),
            PreviousExerciseSet(reps: 12, weight: 55),
          ],
        );

        expect(feedback!.decision!.action, ExerciseCoachAction.bridge);
        expect(feedback.decision!.workingWeightKg, 40);
        expect(feedback.decision!.bridgeWeightKg, 45);
        expect(feedback.decision!.probeWeightKg, 55);
        expect(feedback.decision!.previousComparison, contains('مثل جلسه قبل'));
        expect(feedback.decision!.targetLine, contains('45'));
        expect(feedback.decision!.targetLine, isNot(contains('50 → 55')));
      },
    );
  });

  group('SessionDebriefEngine', () {
    test('flags skipped core/cardio and volume too high', () {
      final session = WorkoutSession(
        id: 's1',
        title: 'Day 1',
        focus: 'سینه',
        estimatedMinutes: 60,
        startedAt: DateTime(2026, 8, 9),
        exercises: <WorkoutExerciseSession>[
          _ex('press', 'پرس سینه', 'chest', done: true),
          _ex('fly', 'فلای', 'chest', done: true),
          _ex('cable', 'کراس', 'chest', done: true),
          _ex('tri1', 'پشت بازو', 'triceps', done: true),
          _ex('tri2', 'دیپ', 'triceps', done: true),
          _ex('core', 'کرانچ', 'abs', done: false),
          _ex('cardio', 'تردمیل', 'cardio', done: false),
        ],
      );

      final debrief = SessionDebriefEngine.build(session: session);
      expect(debrief.volumeTooHigh, isTrue);
      expect(debrief.coreDone, isFalse);
      expect(debrief.cardioDone, isFalse);
      expect(debrief.skippedExerciseNames, contains('کرانچ'));
      expect(debrief.nextFocus, contains('شکم'));
    });

    test('incomplete logged sets never recommend adding kg', () {
      final feedback = WorkoutExerciseCoachFeedbackEngine.build(
        sets: const <LoggedSetPerformance>[
          LoggedSetPerformance(
            targetReps: 10,
            actualReps: 10,
            actualWeightKg: 40,
          ),
          LoggedSetPerformance(
            targetReps: 10,
            actualReps: 10,
            actualWeightKg: 40,
          ),
        ],
        prescribedSetCount: 3,
        isTimedStyle: false,
      );
      expect(feedback, isNotNull);

      final debrief = SessionDebriefEngine.build(
        session: WorkoutSession(
          id: 's1',
          title: 'Day 1',
          focus: 'سینه',
          estimatedMinutes: 40,
          startedAt: DateTime(2026, 8, 13),
          exercises: <WorkoutExerciseSession>[
            _ex('press', 'پرس سینه', 'chest', done: true),
          ],
        ),
        feedbackByExerciseKey: <String, WorkoutExerciseCoachFeedback>{
          'press': feedback!,
        },
      );

      final text = '${debrief.bullets.join(' ')} ${debrief.nextFocus}';
      expect(text, contains('زیاد نمی‌کنیم'));
      expect(text, isNot(contains('آمادهٔ یک پله وزنه')));
      expect(debrief.nextFocus, contains('همه ست'));
    });
  });

  group('CoachObservationDetector', () {
    test('detects repeated cardio skips across logs', () {
      final logs = List<WorkoutDailyLog>.generate(3, (i) {
        return WorkoutDailyLog(
          userId: 'u1',
          logDate: DateTime(2026, 8, 1 + i),
          sessions: <WorkoutSessionLog>[
            WorkoutSessionLog(
              id: 'sess$i',
              day: 'A',
              exercises: <WorkoutExerciseLog>[
                NormalExerciseLog(
                  id: 'n$i',
                  exerciseId: 1,
                  exerciseName: 'پرس',
                  tag: '',
                  style: 'sets_reps',
                  sets: <ExerciseSetLog>[ExerciseSetLog(reps: 10, weight: 40)],
                ),
                NormalExerciseLog(
                  id: 'c$i',
                  exerciseId: 2,
                  exerciseName: 'تردمیل',
                  tag: 'cardio',
                  style: 'sets_time',
                  sets: <ExerciseSetLog>[ExerciseSetLog()],
                ),
              ],
            ),
          ],
        );
      });

      final observations = CoachObservationDetector.fromRecentLogs(logs);
      expect(
        observations.map((o) => o.code),
        contains(CoachObservationCode.cardioSkipped3x),
      );
    });
  });

  group('CoachDecisionLock', () {
    test('system rule mentions decisions.lock and numeric ban', () {
      expect(
        CoachDecisionLock.systemMentionsNumericLock(
          'You are GymAI Coach. ${CoachDecisionLock.systemRule}',
        ),
        isTrue,
      );
      expect(
        CoachDecisionLock.systemMentionsNumericLock('Be nice and invent loads'),
        isFalse,
      );
    });
  });
}

WorkoutExerciseSession _ex(
  String id,
  String name,
  String muscle, {
  required bool done,
}) {
  return WorkoutExerciseSession(
    id: id,
    name: name,
    primaryMuscle: muscle,
    sets: <WorkoutSetSession>[
      WorkoutSetSession(
        index: 1,
        targetReps: 12,
        targetWeightKg: 20,
        actualReps: done ? 12 : null,
        actualWeightKg: done ? 20 : null,
        status: done
            ? WorkoutSetSessionStatus.completed
            : WorkoutSetSessionStatus.pending,
      ),
    ],
  );
}
