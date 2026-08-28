import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_program_validator.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_science_brief.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';

WorkoutExercise _ex({
  required int id,
  required String name,
  required String muscle,
  int sets = 3,
}) {
  return WorkoutExercise(
    id: 'e$id',
    catalogExerciseId: id,
    name: name,
    primaryMuscle: muscle,
    order: 0,
    sets: List<WorkoutSet>.generate(
      sets,
      (i) => WorkoutSet(
        id: 's$id$i',
        order: i,
        type: WorkoutSetType.reps,
        reps: 10,
      ),
    ),
  );
}

void main() {
  test('hypertrophy volume bands match Schoenfeld/Helms practice range', () {
    final beginner = WorkoutScience.weeklySetBand(
      goal: TrainingGoal.hypertrophy,
      experience: 'مبتدی',
      bucket: MuscleBucket.chest,
    );
    final intermediate = WorkoutScience.weeklySetBand(
      goal: TrainingGoal.hypertrophy,
      experience: 'متوسط',
      bucket: MuscleBucket.chest,
    );
    expect(beginner.min, 8);
    expect(beginner.target, 10);
    expect(intermediate.min, 10);
    expect(intermediate.target, 14);
    expect(intermediate.max, lessThanOrEqualTo(20));
    expect(WorkoutScience.muscleFrequencyForDays(4), 2);
    expect(WorkoutScience.muscleFrequencyForDays(6), 2);
  });

  test('science brief injects weekly set targets for the user', () {
    final seed = CoachContext.empty();
    final brief = LlmWorkoutScienceBrief.build(
      context: CoachContext(
        intent: seed.intent,
        metadata: seed.metadata,
        goals: const <String>['عضله‌سازی'],
      ),
      daysPerWeek: 4,
      experience: 'متوسط',
    );
    expect(brief, contains('ست سخت هفتگی سینه'));
    expect(brief, contains('حداقل 10'));
    expect(brief, contains('بالاتنه / پایین‌تنه'));
    expect(brief, contains('RIR'));
  });

  test('validator flags below-MEV chest volume on a 3-day program', () {
    final program = WorkoutProgram(
      id: 'p',
      name: 'حجم متوسط باشگاهی',
      goal: TrainingGoal.hypertrophy,
      experienceLevel: 'متوسط',
      daysPerWeek: 3,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 0,
          days: <WorkoutDay>[
            WorkoutDay(
              id: 'd1',
              dayIndex: 0,
              label: 'روز ۱ — فشار',
              exercises: <WorkoutExercise>[
                _ex(id: 1, name: 'پرس سینه', muscle: 'chest'),
                _ex(id: 2, name: 'پرس شیب', muscle: 'chest'),
                _ex(id: 3, name: 'نشر جانب', muscle: 'shoulder_lateral'),
                _ex(id: 4, name: 'پشت بازو', muscle: 'triceps'),
                _ex(id: 5, name: 'پلانک', muscle: 'abs'),
              ],
            ),
            WorkoutDay(
              id: 'd2',
              dayIndex: 1,
              label: 'روز ۲ — کشش',
              exercises: <WorkoutExercise>[
                _ex(id: 6, name: 'لت', muscle: 'back_lat'),
                _ex(id: 7, name: 'قایقی', muscle: 'back_lat'),
                _ex(id: 8, name: 'فیس پول', muscle: 'back_upper'),
                _ex(id: 9, name: 'جلو بازو', muscle: 'biceps'),
                _ex(id: 10, name: 'کرانچ', muscle: 'abs'),
              ],
            ),
            WorkoutDay(
              id: 'd3',
              dayIndex: 2,
              label: 'روز ۳ — پا',
              exercises: <WorkoutExercise>[
                _ex(id: 11, name: 'اسکوات', muscle: 'quads'),
                _ex(id: 12, name: 'پرس پا', muscle: 'quads'),
                _ex(id: 13, name: 'لگ کرل', muscle: 'hamstrings'),
                _ex(id: 14, name: 'هیپ', muscle: 'glutes'),
                _ex(id: 15, name: 'ساق', muscle: 'calves'),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026, 8, 13),
      updatedAt: DateTime(2026, 8, 13),
    );

    final issues = LlmWorkoutProgramValidator.validate(
      program,
      allowedExerciseIds: {for (var i = 1; i <= 15; i++) i},
      expectedDaysPerWeek: 3,
      goal: TrainingGoal.hypertrophy,
      experience: 'متوسط',
    );
    expect(issues.join(' | '), contains('سینه'));
    expect(issues.join(' | '), contains('خیلی کم'));
  });

  test('science brief asks for 4 compound sets on advanced fat-loss 3-day', () {
    final seed = CoachContext.empty();
    final brief = LlmWorkoutScienceBrief.build(
      context: CoachContext(
        intent: seed.intent,
        metadata: seed.metadata,
        goals: const <String>['چربی‌سوزی'],
        profile: const <String, Object?>{'experience_level': 'پیشرفته'},
      ),
      daysPerWeek: 3,
      experience: 'پیشرفته',
    );
    expect(brief, contains('ست هر حرکت مرکب: 4'));
    expect(brief, contains('حداقل 12'));
  });
}
