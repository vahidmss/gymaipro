import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  group('WorkoutDailyLog.hasMeaningfulLoggedSets', () {
    test('false for empty sessions', () {
      final log = WorkoutDailyLog(
        userId: 'u1',
        logDate: DateTime(2026, 7, 20),
        sessions: const [],
      );
      expect(log.hasMeaningfulLoggedSets, isFalse);
    });

    test('false for exercise shell with empty sets', () {
      final log = WorkoutDailyLog(
        userId: 'u1',
        logDate: DateTime(2026, 7, 20),
        sessions: [
          WorkoutSessionLog(
            id: 's1',
            day: 'روز ۱',
            exercises: [
              NormalExerciseLog(
                id: 'e1',
                exerciseId: 1,
                exerciseName: 'Squat',
                tag: 'legs',
                style: 'sets_reps',
                sets: const [],
              ),
            ],
          ),
        ],
      );
      expect(log.hasMeaningfulLoggedSets, isFalse);
    });

    test('false for zeroed placeholder sets', () {
      final log = WorkoutDailyLog(
        userId: 'u1',
        logDate: DateTime(2026, 7, 20),
        sessions: [
          WorkoutSessionLog(
            id: 's1',
            day: 'روز ۱',
            exercises: [
              NormalExerciseLog(
                id: 'e1',
                exerciseId: 1,
                exerciseName: 'Squat',
                tag: 'legs',
                style: 'sets_reps',
                sets: [ExerciseSetLog(reps: 0, weight: 0)],
              ),
            ],
          ),
        ],
      );
      expect(log.hasMeaningfulLoggedSets, isFalse);
    });

    test('true when a set has real reps/weight', () {
      final log = WorkoutDailyLog(
        userId: 'u1',
        logDate: DateTime(2026, 7, 20),
        sessions: [
          WorkoutSessionLog(
            id: 's1',
            day: 'روز ۱',
            exercises: [
              NormalExerciseLog(
                id: 'e1',
                exerciseId: 1,
                exerciseName: 'Squat',
                tag: 'legs',
                style: 'sets_reps',
                sets: [ExerciseSetLog(reps: 8, weight: 60)],
              ),
            ],
          ),
        ],
      );
      expect(log.hasMeaningfulLoggedSets, isTrue);
    });
  });
}
