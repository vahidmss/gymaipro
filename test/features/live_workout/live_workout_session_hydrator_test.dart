import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_hydrator.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  const hydrator = LiveWorkoutSessionHydrator();

  WorkoutSession freshSession() {
    return WorkoutSession(
      id: 'fresh-id',
      title: 'تست',
      focus: 'روز ۱',
      estimatedMinutes: 45,
      startedAt: DateTime(2026, 7, 20, 10),
      programId: 'p1',
      userId: 'u1',
      exercises: [
        WorkoutExerciseSession(
          id: 'ex1',
          name: 'اسکوات',
          primaryMuscle: 'پا',
          exerciseId: 10,
          sets: const [
            WorkoutSetSession(index: 1, targetReps: 8, targetWeightKg: 60),
            WorkoutSetSession(index: 2, targetReps: 8, targetWeightKg: 60),
          ],
        ),
      ],
    );
  }

  test('hydrates saved sets onto a fresh live session', () {
    final session = freshSession();
    final dailyLog = WorkoutDailyLog(
      userId: 'u1',
      logDate: DateTime(2026, 7, 20),
      sessions: [
        WorkoutSessionLog(
          id: 'log-session-1',
          day: 'روز ۱',
          programId: 'p1',
          notes: 'live_workout:old-id',
          exercises: [
            NormalExerciseLog(
              id: 'e1',
              exerciseId: 10,
              exerciseName: 'اسکوات',
              tag: 'پا',
              style: 'sets_reps',
              sets: [
                ExerciseSetLog(reps: 8, weight: 80),
                ExerciseSetLog(reps: 6, weight: 85),
              ],
            ),
          ],
        ),
      ],
    );

    final hydrated = hydrator.applyLog(session: session, dailyLog: dailyLog);

    expect(hydrated.id, 'log-session-1');
    expect(hydrated.exercises.first.sets[0].actualWeightKg, 80);
    expect(hydrated.exercises.first.sets[0].actualReps, 8);
    expect(
      hydrated.exercises.first.sets[0].status,
      WorkoutSetSessionStatus.completed,
    );
    expect(hydrated.exercises.first.sets[1].actualWeightKg, 85);
    expect(hydrated.exercises.first.sets[1].actualReps, 6);
  });

  test('leaves session unchanged when no matching log', () {
    final session = freshSession().copyWith(focus: 'روز ۲');
    final dailyLog = WorkoutDailyLog(
      userId: 'u1',
      logDate: DateTime(2026, 7, 20),
      sessions: [
        WorkoutSessionLog(
          id: 'other',
          day: 'روز ۱',
          exercises: const [],
        ),
      ],
    );

    final hydrated = hydrator.applyLog(session: session, dailyLog: dailyLog);
    expect(hydrated.id, session.id);
    expect(hydrated.exercises.first.sets.first.actualReps, isNull);
  });
}
