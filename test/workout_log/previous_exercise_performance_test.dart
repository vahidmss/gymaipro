import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  group('PreviousExercisePerformance', () {
    WorkoutDailyLog day({
      required DateTime date,
      required List<WorkoutSessionLog> sessions,
    }) {
      return WorkoutDailyLog(
        userId: 'u1',
        logDate: date,
        sessions: sessions,
      );
    }

    NormalExerciseLog normal({
      required int id,
      required List<ExerciseSetLog> sets,
    }) {
      return NormalExerciseLog(
        id: 'n-$id',
        exerciseId: id,
        exerciseName: 'ex-$id',
        tag: '',
        style: 'sets_reps',
        sets: sets,
      );
    }

    test('picks newest prior day with meaningful sets', () {
      final logs = [
        day(
          date: DateTime(2026, 8, 5),
          sessions: [
            WorkoutSessionLog(
              id: 's1',
              day: 'روز ۱',
              exercises: [
                normal(
                  id: 10,
                  sets: [
                    ExerciseSetLog(reps: 12, weight: 20),
                    ExerciseSetLog(reps: 10, weight: 22.5),
                  ],
                ),
              ],
            ),
          ],
        ),
        day(
          date: DateTime(2026, 8, 1),
          sessions: [
            WorkoutSessionLog(
              id: 's0',
              day: 'روز ۱',
              exercises: [
                normal(
                  id: 10,
                  sets: [ExerciseSetLog(reps: 8, weight: 15)],
                ),
              ],
            ),
          ],
        ),
      ];

      final result = PreviousExercisePerformance.fromLogs(
        logs: logs,
        exerciseIds: {10},
      );

      expect(result[10], isNotNull);
      expect(result[10]!.length, 2);
      expect(result[10]![0].reps, 12);
      expect(result[10]![0].weight, 20);
      expect(result[10]![1].weight, 22.5);
    });

    test('skips empty shells and reads from supersets', () {
      final logs = [
        day(
          date: DateTime(2026, 8, 6),
          sessions: [
            WorkoutSessionLog(
              id: 's1',
              day: 'روز ۱',
              exercises: [
                normal(id: 7, sets: [ExerciseSetLog()]),
                SupersetExerciseLog(
                  id: 'ss',
                  tag: '',
                  style: 'sets_reps',
                  exercises: [
                    SupersetItemLog(
                      exerciseId: 7,
                      exerciseName: 'ex-7',
                      sets: [
                        ExerciseSetLog(reps: 15, weight: 10),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];

      final result = PreviousExercisePerformance.fromLogs(
        logs: logs,
        exerciseIds: {7},
      );

      expect(result[7]!.single.reps, 15);
      expect(result[7]!.single.weight, 10);
    });

    test('summaryLabel formats reps×weight', () {
      expect(
        const PreviousExerciseSet(reps: 12, weight: 20).summaryLabel,
        '\u200E12\u00D720',
      );
      expect(
        const PreviousExerciseSet(reps: 8, weight: 22.5).summaryLabel,
        '\u200E8\u00D722.5',
      );
    });
  });
}
