import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';
import 'package:gymaipro/features/session_analysis/application/session_analysis_assembler.dart';
import 'package:gymaipro/features/session_analysis/application/session_analysis_store.dart';
import 'package:gymaipro/features/session_analysis/application/workout_log_session_bridge.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_eligibility.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:gymaipro/features/session_analysis/domain/workout_calorie_estimator.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  group('SessionAnalysisEligibility', () {
    test('shows CTA for AI and starter only', () {
      expect(
        SessionAnalysisEligibility.canShowFinishCta(
          SessionAnalysisProgramKind.aiSupervised,
        ),
        isTrue,
      );
      expect(
        SessionAnalysisEligibility.canShowFinishCta(
          SessionAnalysisProgramKind.starter,
        ),
        isTrue,
      );
      expect(
        SessionAnalysisEligibility.canShowFinishCta(
          SessionAnalysisProgramKind.unsupported,
        ),
        isFalse,
      );
    });

    test('modify unlocked only for AI supervised', () {
      expect(
        SessionAnalysisEligibility.canModifyProgram(
          SessionAnalysisProgramKind.aiSupervised,
        ),
        isTrue,
      );
      expect(
        SessionAnalysisEligibility.canModifyProgram(
          SessionAnalysisProgramKind.starter,
        ),
        isFalse,
      );
      expect(
        SessionAnalysisEligibility.canModifyProgram(
          SessionAnalysisProgramKind.unsupported,
        ),
        isFalse,
      );
    });

    test('classify prefers AI over starter flags', () {
      expect(
        SessionAnalysisEligibility.classify(
          isAiSupervised: true,
          isStarter: false,
        ),
        SessionAnalysisProgramKind.aiSupervised,
      );
      expect(
        SessionAnalysisEligibility.classify(
          isAiSupervised: false,
          isStarter: true,
        ),
        SessionAnalysisProgramKind.starter,
      );
      expect(
        SessionAnalysisEligibility.classify(
          isAiSupervised: false,
          isStarter: false,
        ),
        SessionAnalysisProgramKind.unsupported,
      );
    });
  });

  group('WorkoutCalorieEstimator', () {
    test('returns null without weight and volume', () {
      expect(
        WorkoutCalorieEstimator.estimateKcal(
          bodyWeightKg: null,
          totalVolumeKg: 0,
          workingSeconds: 0,
          wallClockSeconds: 0,
          exercises: const <ExerciseCalorieInput>[],
        ),
        isNull,
      );
    });

    test('estimates from volume when weight missing', () {
      final kcal = WorkoutCalorieEstimator.estimateKcal(
        bodyWeightKg: null,
        totalVolumeKg: 1000,
        workingSeconds: 0,
        wallClockSeconds: 0,
        exercises: const <ExerciseCalorieInput>[
          ExerciseCalorieInput(caloriesPer1000kg: 40, volumeKg: 1000),
        ],
      );
      expect(kcal, 40);
    });

    test('estimates from MET × weight × time', () {
      final kcal = WorkoutCalorieEstimator.estimateKcal(
        bodyWeightKg: 80,
        totalVolumeKg: 0,
        workingSeconds: 1800,
        wallClockSeconds: 3600,
        exercises: const <ExerciseCalorieInput>[
          ExerciseCalorieInput(met: 8, workingSeconds: 1800),
        ],
      );
      // 8 * 80 * 0.5h = 320
      expect(kcal, 320);
    });
  });

  group('SessionAnalysisAssembler incomplete session', () {
    test('marks skipped exercises and incomplete ratio', () {
      final session = WorkoutSession(
        id: 's1',
        title: 'روز ۱',
        focus: 'سینه',
        estimatedMinutes: 60,
        startedAt: DateTime(2026, 8, 11, 18),
        exercises: <WorkoutExerciseSession>[
          _ex(
            id: '1',
            name: 'پرس سینه',
            sets: <WorkoutSetSession>[
              const WorkoutSetSession(
                index: 1,
                targetReps: 10,
                targetWeightKg: 40,
                actualReps: 10,
                actualWeightKg: 40,
                status: WorkoutSetSessionStatus.completed,
              ),
            ],
            exerciseId: 101,
          ),
          _ex(
            id: '2',
            name: 'پرس بالا سینه',
            sets: <WorkoutSetSession>[
              const WorkoutSetSession(
                index: 1,
                targetReps: 10,
                targetWeightKg: 30,
                actualReps: 10,
                actualWeightKg: 30,
                status: WorkoutSetSessionStatus.completed,
              ),
            ],
            exerciseId: 102,
          ),
          _ex(
            id: '3',
            name: 'فلای',
            sets: <WorkoutSetSession>[
              const WorkoutSetSession(
                index: 1,
                targetReps: 12,
                targetWeightKg: 15,
                actualReps: 12,
                actualWeightKg: 15,
                status: WorkoutSetSessionStatus.completed,
              ),
            ],
            exerciseId: 103,
          ),
          _ex(
            id: '4',
            name: 'پشت بازو',
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(index: 1, targetReps: 12, targetWeightKg: 20),
            ],
            exerciseId: 104,
          ),
          _ex(
            id: '5',
            name: 'جلو بازو',
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(index: 1, targetReps: 12, targetWeightKg: 15),
            ],
            exerciseId: 105,
          ),
          _ex(
            id: '6',
            name: 'کرانچ',
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(index: 1, targetReps: 15, targetWeightKg: 0),
            ],
            exerciseId: 106,
          ),
          _ex(
            id: '7',
            name: 'تردمیل',
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(index: 1, targetReps: 0, targetWeightKg: 0),
            ],
            exerciseId: 107,
          ),
          _ex(
            id: '8',
            name: 'کول',
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(index: 1, targetReps: 12, targetWeightKg: 20),
            ],
            exerciseId: 108,
          ),
        ],
      );

      final debrief = SessionDebriefEngine.build(session: session);
      expect(debrief.completedExercises, 3);
      expect(debrief.plannedExercises, 8);
      expect(
        debrief.skippedExerciseNames,
        containsAll(<String>['پشت بازو', 'جلو بازو', 'کرانچ', 'تردمیل', 'کول']),
      );
      expect(debrief.volumeTooHigh, isTrue);

      final snapshot = SessionAnalysisAssembler.assemble(
        session: session,
        programKind: SessionAnalysisProgramKind.starter,
        debrief: debrief,
        bodyWeightKg: 90,
        exerciseById: <int, Exercise>{
          101: Exercise(
            id: 101,
            title: 'پرس',
            name: 'پرس سینه',
            mainMuscle: 'سینه',
            secondaryMuscles: '',
            tips: const <String>[],
            videoUrl: '',
            imageUrl: '',
            otherNames: const <String>[],
            content: '',
            caloriesPer1000kg: 35,
            met: 5,
          ),
        },
      );

      expect(snapshot.isIncomplete, isTrue);
      expect(snapshot.canModifyProgram, isFalse);
      expect(snapshot.isStarter, isTrue);
      expect(snapshot.skippedExerciseNames.length, greaterThanOrEqualTo(5));
      expect(snapshot.completedExercises, 3);
      expect(snapshot.estimatedCaloriesKcal, isNotNull);
      expect(snapshot.decisionLock.containsKey('debrief'), isTrue);
      expect(snapshot.comparisons.every((c) => c.isFirstLogged), isTrue);
      expect(snapshot.comparisons.every((c) => c.badge == 'اولین ثبت'), isTrue);
      expect(debrief.headline.contains('بهتر از قبل'), isFalse);
    });

    test('volume ignores prescribed weight when actual was not logged', () {
      final session = WorkoutSession(
        id: 's-vol',
        title: 'روز ۱',
        focus: 'سینه',
        estimatedMinutes: 40,
        startedAt: DateTime(2026, 8, 13, 18),
        exercises: <WorkoutExerciseSession>[
          _ex(
            id: '1',
            name: 'پرس سینه',
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(
                index: 1,
                targetReps: 10,
                targetWeightKg: 40,
                actualReps: 10,
                status: WorkoutSetSessionStatus.completed,
              ),
            ],
            exerciseId: 101,
          ),
        ],
      );
      final snapshot = SessionAnalysisAssembler.assemble(
        session: session,
        programKind: SessionAnalysisProgramKind.starter,
        debrief: SessionDebriefEngine.build(session: session),
      );
      expect(snapshot.totalVolumeKg, 0);
    });

    test('with previous history keeps prior date and does not first-log', () {
      final session = WorkoutSession(
        id: 's2',
        title: 'روز ۲',
        focus: 'سینه',
        estimatedMinutes: 45,
        startedAt: DateTime(2026, 8, 11, 18),
        exercises: <WorkoutExerciseSession>[
          _ex(
            id: '1',
            name: 'پرس سینه',
            sets: <WorkoutSetSession>[
              const WorkoutSetSession(
                index: 1,
                targetReps: 10,
                targetWeightKg: 40,
                actualReps: 10,
                actualWeightKg: 45,
                status: WorkoutSetSessionStatus.completed,
              ),
            ],
            exerciseId: 101,
          ),
        ],
      );
      final debrief = SessionDebriefEngine.build(session: session);
      final snapshot = SessionAnalysisAssembler.assemble(
        session: session,
        programKind: SessionAnalysisProgramKind.aiSupervised,
        debrief: debrief,
        previousByExerciseId: <int, List<PreviousExerciseSet>>{
          101: const <PreviousExerciseSet>[
            PreviousExerciseSet(reps: 10, weight: 40),
          ],
        },
        previousLogDateByExerciseId: <int, DateTime>{101: DateTime(2026, 8, 4)},
      );
      expect(snapshot.comparisons.single.isFirstLogged, isFalse);
      expect(snapshot.comparisons.single.previousLogDate, DateTime(2026, 8, 4));
      expect(snapshot.comparisons.single.badge, isNot(equals('اولین ثبت')));
    });
  });

  group('SessionAnalysisSnapshot persistence', () {
    test('roundtrips json including narrative and logged sets', () {
      final session = WorkoutSession(
        id: 's3',
        title: 'روز ۳',
        focus: 'سینه',
        estimatedMinutes: 40,
        startedAt: DateTime(2026, 8, 12, 18),
        exercises: <WorkoutExerciseSession>[
          _ex(
            id: '1',
            name: 'پرس سینه',
            sets: <WorkoutSetSession>[
              const WorkoutSetSession(
                index: 1,
                targetReps: 10,
                targetWeightKg: 40,
                actualReps: 10,
                actualWeightKg: 40,
                status: WorkoutSetSessionStatus.completed,
              ),
            ],
            exerciseId: 101,
          ),
        ],
      );
      final debrief = SessionDebriefEngine.build(session: session);
      final original = SessionAnalysisAssembler.assemble(
        session: session,
        programKind: SessionAnalysisProgramKind.starter,
        debrief: debrief,
        programTitle: 'شروع باشگاه',
        sessionDay: 'روز ۱',
      ).copyWith(coachNarrative: 'امروز پرس رو تمیز زدی.');

      final restored = SessionAnalysisSnapshot.tryParse(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.programKind, SessionAnalysisProgramKind.starter);
      expect(restored.coachNarrative, 'امروز پرس رو تمیز زدی.');
      expect(restored.comparisons.single.exerciseName, 'پرس سینه');
      expect(restored.comparisons.single.todaySets.single.weight, 40);
      expect(restored.debrief.headline.contains('بهتر از قبل'), isFalse);
    });

    test('session log keeps analysis until it is cleared', () {
      final snapshot = SessionAnalysisAssembler.assemble(
        session: WorkoutSession(
          id: 's4',
          title: 'روز ۱',
          focus: 'سینه',
          estimatedMinutes: 30,
          startedAt: DateTime(2026, 8, 12, 18),
          exercises: <WorkoutExerciseSession>[
            _ex(
              id: '1',
              name: 'پرس سینه',
              sets: <WorkoutSetSession>[
                const WorkoutSetSession(
                  index: 1,
                  targetReps: 8,
                  targetWeightKg: 50,
                  actualReps: 8,
                  actualWeightKg: 50,
                  status: WorkoutSetSessionStatus.completed,
                ),
              ],
              exerciseId: 101,
            ),
          ],
        ),
        programKind: SessionAnalysisProgramKind.aiSupervised,
        debrief: SessionDebriefEngine.build(
          session: WorkoutSession(
            id: 's4',
            title: 'روز ۱',
            focus: 'سینه',
            estimatedMinutes: 30,
            startedAt: DateTime(2026, 8, 12, 18),
            exercises: <WorkoutExerciseSession>[
              _ex(
                id: '1',
                name: 'پرس سینه',
                sets: <WorkoutSetSession>[
                  const WorkoutSetSession(
                    index: 1,
                    targetReps: 8,
                    targetWeightKg: 50,
                    actualReps: 8,
                    actualWeightKg: 50,
                    status: WorkoutSetSessionStatus.completed,
                  ),
                ],
                exerciseId: 101,
              ),
            ],
          ),
        ),
      );

      final log = WorkoutSessionLog(
        id: 'log1',
        day: 'روز ۱',
        programId: 'p1',
        exercises: const <WorkoutExerciseLog>[],
        sessionAnalysis: Map<String, dynamic>.from(snapshot.toJson()),
      );
      final encoded = log.toJson();
      final decoded = WorkoutSessionLog.fromJson(encoded);
      expect(
        SessionAnalysisSnapshot.tryParse(decoded.sessionAnalysis)?.focus,
        'سینه',
      );

      final cleared = decoded.copyWith(clearSessionAnalysis: true);
      expect(cleared.sessionAnalysis, isNull);
      expect(cleared.toJson().containsKey('session_analysis'), isFalse);
    });

    test('store loads embedded json without prefs', () async {
      final snapshot = SessionAnalysisAssembler.assemble(
        session: WorkoutSession(
          id: 's5',
          title: 'روز ۱',
          focus: 'پا',
          estimatedMinutes: 30,
          startedAt: DateTime(2026, 8, 12, 18),
          exercises: <WorkoutExerciseSession>[
            _ex(
              id: '1',
              name: 'اسکوات',
              sets: <WorkoutSetSession>[
                const WorkoutSetSession(
                  index: 1,
                  targetReps: 8,
                  targetWeightKg: 60,
                  actualReps: 8,
                  actualWeightKg: 60,
                  status: WorkoutSetSessionStatus.completed,
                ),
              ],
              exerciseId: 201,
            ),
          ],
        ),
        programKind: SessionAnalysisProgramKind.starter,
        debrief: SessionDebriefEngine.build(
          session: WorkoutSession(
            id: 's5',
            title: 'روز ۱',
            focus: 'پا',
            estimatedMinutes: 30,
            startedAt: DateTime(2026, 8, 12, 18),
            exercises: <WorkoutExerciseSession>[
              _ex(
                id: '1',
                name: 'اسکوات',
                sets: <WorkoutSetSession>[
                  const WorkoutSetSession(
                    index: 1,
                    targetReps: 8,
                    targetWeightKg: 60,
                    actualReps: 8,
                    actualWeightKg: 60,
                    status: WorkoutSetSessionStatus.completed,
                  ),
                ],
                exerciseId: 201,
              ),
            ],
          ),
        ),
        sessionDay: 'روز ۱',
        programTitle: 'شروع باشگاه',
      );

      final restored = await SessionAnalysisStore.load(
        userId: '',
        date: DateTime(2026, 8, 12),
        programId: snapshot.programId,
        sessionDay: 'روز ۱',
        embeddedJson: snapshot.toJson(),
      );
      expect(restored, isNotNull);
      expect(restored!.focus, 'پا');
      expect(
        SessionAnalysisStore.dateKey(DateTime(2026, 8, 12, 19, 30)),
        '2026-08-12',
      );
    });
  });

  group('WorkoutLogSessionBridge partial sets', () {
    test('2 of 3 logged sets hold load instead of inventing a bump', () {
      final session = WorkoutSession(
        id: 's-partial',
        title: 'روز ۱',
        focus: 'پا',
        estimatedMinutes: 45,
        startedAt: DateTime(2026, 8, 13, 18),
        exercises: <WorkoutExerciseSession>[
          _ex(
            id: 'lp',
            name: 'لگ پرس',
            exerciseId: 4008,
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(
                index: 1,
                targetReps: 12,
                targetWeightKg: 40,
                actualReps: 12,
                actualWeightKg: 40,
                status: WorkoutSetSessionStatus.completed,
              ),
              WorkoutSetSession(
                index: 2,
                targetReps: 12,
                targetWeightKg: 40,
                actualReps: 12,
                actualWeightKg: 40,
                status: WorkoutSetSessionStatus.completed,
              ),
              WorkoutSetSession(
                index: 3,
                targetReps: 12,
                targetWeightKg: 40,
                status: WorkoutSetSessionStatus.pending,
              ),
            ],
          ),
        ],
      );

      final feedback = WorkoutLogSessionBridge.buildFeedbackMap(
        session: session,
      );
      expect(feedback.containsKey('lp'), isTrue);
      final decision = feedback['lp']!.decision!;
      expect(decision.action, ExerciseCoachAction.hold);
      expect(decision.isIncompleteVolume, isTrue);
      expect(decision.nextWeightKg, 40);
      expect(decision.targetLine, isNot(contains('45')));
      expect(feedback['lp']!.nextSession, isNot(contains('45')));
    });

    test('does not treat empty saved fields as a hit of the target', () {
      final session = WorkoutSession(
        id: 's-empty',
        title: 'روز ۱',
        focus: 'پا',
        estimatedMinutes: 45,
        startedAt: DateTime(2026, 8, 13, 18),
        exercises: <WorkoutExerciseSession>[
          _ex(
            id: 'lp',
            name: 'لگ پرس',
            exerciseId: 4008,
            sets: const <WorkoutSetSession>[
              WorkoutSetSession(
                index: 1,
                targetReps: 12,
                targetWeightKg: 40,
                status: WorkoutSetSessionStatus.completed,
              ),
              WorkoutSetSession(
                index: 2,
                targetReps: 12,
                targetWeightKg: 40,
                actualReps: 12,
                actualWeightKg: 40,
                status: WorkoutSetSessionStatus.completed,
              ),
              WorkoutSetSession(
                index: 3,
                targetReps: 12,
                targetWeightKg: 40,
                actualReps: 12,
                actualWeightKg: 40,
                status: WorkoutSetSessionStatus.completed,
              ),
            ],
          ),
        ],
      );

      final feedback = WorkoutLogSessionBridge.buildFeedbackMap(
        session: session,
      );
      final decision = feedback['lp']!.decision!;
      expect(decision.setCount, 2);
      expect(decision.prescribedSetCount, 3);
      expect(decision.action, ExerciseCoachAction.hold);
      expect(decision.nextWeightKg, 40);
    });
  });
}

WorkoutExerciseSession _ex({
  required String id,
  required String name,
  required List<WorkoutSetSession> sets,
  int? exerciseId,
}) {
  return WorkoutExerciseSession(
    id: id,
    name: name,
    primaryMuscle: name,
    exerciseId: exerciseId,
    sets: sets,
  );
}
