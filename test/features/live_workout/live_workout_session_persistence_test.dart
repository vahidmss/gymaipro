import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_persistence.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  group('LiveWorkoutSessionPersistence.mergeSessionIntoDailyLog', () {
    final logDate = DateTime(2026, 7, 19);

    test('creates daily log when none exists', () {
      final session = WorkoutSessionLog(
        id: 'live-1',
        day: 'Push',
        notes: LiveWorkoutSessionPersistence.liveSessionNote('live-1'),
        exercises: const <WorkoutExerciseLog>[],
      );

      final merged = LiveWorkoutSessionPersistence.mergeSessionIntoDailyLog(
        existing: null,
        sessionLog: session,
        userId: 'user_1',
        logDate: logDate,
      );

      expect(merged.sessions, hasLength(1));
      expect(merged.sessions.single.id, 'live-1');
    });

    test('upserts same live session instead of appending', () {
      final first = WorkoutSessionLog(
        id: 'live-1',
        day: 'Push',
        notes: LiveWorkoutSessionPersistence.liveSessionNote('live-1'),
        exercises: <WorkoutExerciseLog>[
          NormalExerciseLog(
            id: 'ex1',
            exerciseId: 1,
            exerciseName: 'Bench',
            tag: 'chest',
            style: 'sets_reps',
            sets: <ExerciseSetLog>[ExerciseSetLog(reps: 10, weight: 20)],
          ),
        ],
      );
      final existing = WorkoutDailyLog(
        id: 'daily-1',
        userId: 'user_1',
        logDate: logDate,
        sessions: <WorkoutSessionLog>[first],
      );

      final updated = WorkoutSessionLog(
        id: 'live-1',
        day: 'Push',
        notes: LiveWorkoutSessionPersistence.liveSessionNote('live-1'),
        exercises: <WorkoutExerciseLog>[
          NormalExerciseLog(
            id: 'ex1',
            exerciseId: 1,
            exerciseName: 'Bench',
            tag: 'chest',
            style: 'sets_reps',
            sets: <ExerciseSetLog>[
              ExerciseSetLog(reps: 10, weight: 20),
              ExerciseSetLog(reps: 10, weight: 20),
            ],
          ),
        ],
      );

      final merged = LiveWorkoutSessionPersistence.mergeSessionIntoDailyLog(
        existing: existing,
        sessionLog: updated,
        userId: 'user_1',
        logDate: logDate,
      );

      expect(merged.sessions, hasLength(1));
      final exercise = merged.sessions.single.exercises.single as NormalExerciseLog;
      expect(exercise.sets, hasLength(2));
    });

    test('keeps other sessions and appends a different live session', () {
      final other = WorkoutSessionLog(
        id: 'manual-1',
        day: 'Pull',
        exercises: const <WorkoutExerciseLog>[],
      );
      final existing = WorkoutDailyLog(
        id: 'daily-1',
        userId: 'user_1',
        logDate: logDate,
        sessions: <WorkoutSessionLog>[other],
      );
      final live = WorkoutSessionLog(
        id: 'live-2',
        day: 'Push',
        notes: LiveWorkoutSessionPersistence.liveSessionNote('live-2'),
        exercises: const <WorkoutExerciseLog>[],
      );

      final merged = LiveWorkoutSessionPersistence.mergeSessionIntoDailyLog(
        existing: existing,
        sessionLog: live,
        userId: 'user_1',
        logDate: logDate,
      );

      expect(merged.sessions, hasLength(2));
      expect(merged.sessions.map((s) => s.id), containsAll(<String>['manual-1', 'live-2']));
    });
  });
}
