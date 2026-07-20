import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_program_validator.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';

WorkoutExercise _ex({
  required int id,
  required String name,
  required String muscle,
}) {
  return WorkoutExercise(
    id: 'e$id',
    catalogExerciseId: id,
    name: name,
    primaryMuscle: muscle,
    order: 0,
    sets: const <WorkoutSet>[
      WorkoutSet(id: 's1', order: 0, type: WorkoutSetType.reps, reps: 10),
      WorkoutSet(id: 's2', order: 1, type: WorkoutSetType.reps, reps: 10),
      WorkoutSet(id: 's3', order: 2, type: WorkoutSetType.reps, reps: 10),
    ],
  );
}

WorkoutProgram _program({
  required String name,
  required List<WorkoutDay> days,
}) {
  final now = DateTime(2026, 7, 17);
  return WorkoutProgram(
    id: 'p1',
    name: name,
    goal: TrainingGoal.fatLoss,
    experienceLevel: 'متوسط',
    daysPerWeek: days.length,
    weeks: <WorkoutWeek>[
      WorkoutWeek(id: 'w1', weekIndex: 0, days: days),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('rejects silly program names', () {
    final program = _program(
      name: 'سفر چربی‌سوزی با حرکات آشنا',
      days: <WorkoutDay>[
        WorkoutDay(
          id: 'd1',
          dayIndex: 0,
          label: 'روز فشار',
          exercises: <WorkoutExercise>[
            _ex(id: 1, name: 'پرس سینه', muscle: 'chest'),
            _ex(id: 2, name: 'پرس سرشانه', muscle: 'shoulder_anterior'),
            _ex(id: 3, name: 'پشت بازو', muscle: 'triceps'),
            _ex(id: 4, name: 'نشر جانب', muscle: 'shoulder_lateral'),
            _ex(id: 5, name: 'پلانک', muscle: 'abs'),
          ],
        ),
      ],
    );
    final issues = LlmWorkoutProgramValidator.validate(
      program,
      allowedExerciseIds: {1, 2, 3, 4, 5},
      expectedDaysPerWeek: 1,
    );
    expect(issues.any((i) => i.contains('حرکات آشنا') || i.contains('مصنوعی')), isTrue);
  });

  test('rejects legs on pull day and heavy push spam', () {
    final program = _program(
      name: 'چربی‌سوز ۳روزه باشگاهی',
      days: <WorkoutDay>[
        WorkoutDay(
          id: 'd1',
          dayIndex: 0,
          label: 'روز فشار',
          exercises: <WorkoutExercise>[
            _ex(id: 1, name: 'پرس سینه', muscle: 'chest'),
            _ex(id: 2, name: 'پرس شیب', muscle: 'chest'),
            _ex(id: 3, name: 'پرس سوم', muscle: 'chest'),
            _ex(id: 4, name: 'OHP', muscle: 'shoulder_anterior'),
            _ex(id: 5, name: 'اسمیت', muscle: 'shoulder_anterior'),
          ],
        ),
        WorkoutDay(
          id: 'd2',
          dayIndex: 1,
          label: 'روز کشش',
          exercises: <WorkoutExercise>[
            _ex(id: 6, name: 'گابلت', muscle: 'quads'),
            _ex(id: 7, name: 'رویینگ', muscle: 'back_lat'),
            _ex(id: 8, name: 'جلو بازو', muscle: 'biceps'),
            _ex(id: 9, name: 'بلغاری', muscle: 'quads'),
            _ex(id: 10, name: 'جلو بازو ۲', muscle: 'biceps'),
          ],
        ),
      ],
    );
    final issues = LlmWorkoutProgramValidator.validate(
      program,
      allowedExerciseIds: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
      expectedDaysPerWeek: 2,
    );
    expect(issues.any((i) => i.contains('سینه')), isTrue);
    expect(issues.any((i) => i.contains('کشش') && i.contains('نامرتبط')), isTrue);
  });
}
