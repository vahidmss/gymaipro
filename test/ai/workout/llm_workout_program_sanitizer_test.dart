import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_program_sanitizer.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_program_validator.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/models/exercise.dart';

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

Exercise _catalog({
  required int id,
  required String name,
  required String muscle,
}) {
  return Exercise(
    id: id,
    title: name,
    name: name,
    mainMuscle: muscle,
    secondaryMuscles: '',
    tips: const <String>[],
    videoUrl: '',
    imageUrl: '',
    otherNames: const <String>[],
    content: '',
    equipment: 'هالتر',
  );
}

void main() {
  test('sanitizer strips wrong-day muscles and caps push presses', () {
    final catalog = <Exercise>[
      _catalog(id: 1, name: 'پرس سینه', muscle: 'chest'),
      _catalog(id: 2, name: 'پرس شیب', muscle: 'chest'),
      _catalog(id: 3, name: 'پرس سوم', muscle: 'chest'),
      _catalog(id: 4, name: 'OHP', muscle: 'shoulder_anterior'),
      _catalog(id: 5, name: 'اسمیت', muscle: 'shoulder_anterior'),
      _catalog(id: 11, name: 'پشت بازو کابل', muscle: 'triceps'),
      _catalog(id: 12, name: 'فلای', muscle: 'chest'),
      _catalog(id: 6, name: 'گابلت', muscle: 'quads'),
      _catalog(id: 7, name: 'رویینگ', muscle: 'back_lat'),
      _catalog(id: 8, name: 'جلو بازو', muscle: 'biceps'),
      _catalog(id: 9, name: 'بلغاری', muscle: 'quads'),
      _catalog(id: 10, name: 'جلو بازو ۲', muscle: 'biceps'),
      _catalog(id: 13, name: 'لت پول', muscle: 'back_lat'),
      _catalog(id: 14, name: 'سیت‌آپ', muscle: 'abs'),
      _catalog(id: 15, name: 'فیس پول', muscle: 'back_upper'),
      _catalog(id: 16, name: 'اسکوات', muscle: 'quads'),
      _catalog(id: 17, name: 'لگ کرل', muscle: 'hamstrings'),
      _catalog(id: 18, name: 'هیپ تراست', muscle: 'glutes'),
      _catalog(id: 19, name: 'ساق', muscle: 'calves'),
      _catalog(id: 20, name: 'پلانک', muscle: 'abs'),
    ];

    final dirty = WorkoutProgram(
      id: 'p1',
      name: 'سفر چربی‌سوزی با حرکات آشنا',
      goal: TrainingGoal.fatLoss,
      experienceLevel: 'مبتدی',
      daysPerWeek: 3,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 0,
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
                _ex(id: 7, name: 'رویینگ', muscle: 'back_lat'),
              ],
            ),
            WorkoutDay(
              id: 'd2',
              dayIndex: 1,
              label: 'روز کشش',
              exercises: <WorkoutExercise>[
                _ex(id: 6, name: 'گابلت', muscle: 'quads'),
                _ex(id: 8, name: 'جلو بازو', muscle: 'biceps'),
                _ex(id: 9, name: 'بلغاری', muscle: 'quads'),
                _ex(id: 10, name: 'جلو بازو ۲', muscle: 'biceps'),
                _ex(id: 13, name: 'لت پول', muscle: 'back_lat'),
              ],
            ),
            WorkoutDay(
              id: 'd3',
              dayIndex: 2,
              label: 'روز پا',
              exercises: <WorkoutExercise>[
                _ex(id: 16, name: 'اسکوات', muscle: 'quads'),
                _ex(id: 17, name: 'لگ کرل', muscle: 'hamstrings'),
                _ex(id: 18, name: 'هیپ تراست', muscle: 'glutes'),
                _ex(id: 1, name: 'پرس سینه', muscle: 'chest'),
                _ex(id: 19, name: 'ساق', muscle: 'calves'),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    );

    final cleaned = LlmWorkoutProgramSanitizer.sanitize(
      dirty,
      curatedCatalog: catalog,
      usedAcrossProgram: <int>{},
    );

    expect(cleaned.name.contains('حرکات آشنا'), isFalse);

    final allowed = catalog.map((e) => e.id).toSet();
    final issues = LlmWorkoutProgramValidator.validate(
      cleaned,
      allowedExerciseIds: allowed,
      expectedDaysPerWeek: 3,
    );
    expect(issues, isEmpty, reason: issues.join(' | '));
  });

  test('sanitizer rebalances quad-heavy leg day', () {
    final catalog = <Exercise>[
      _catalog(id: 1, name: 'اسکوات', muscle: 'quads'),
      _catalog(id: 2, name: 'پرس پا', muscle: 'quads'),
      _catalog(id: 3, name: 'لانج', muscle: 'quads'),
      _catalog(id: 4, name: 'اکستنشن', muscle: 'quads'),
      _catalog(id: 5, name: 'هاک', muscle: 'quads'),
      _catalog(id: 6, name: 'لگ کرل', muscle: 'hamstrings'),
      _catalog(id: 7, name: 'هیپ تراست', muscle: 'glutes'),
      _catalog(id: 8, name: 'ساق', muscle: 'calves'),
      _catalog(id: 9, name: 'پلانک', muscle: 'abs'),
    ];

    final dirty = WorkoutProgram(
      id: 'p2',
      name: 'پا متعادل باشگاهی',
      goal: TrainingGoal.fatLoss,
      experienceLevel: 'مبتدی',
      daysPerWeek: 1,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 0,
          days: <WorkoutDay>[
            WorkoutDay(
              id: 'd1',
              dayIndex: 0,
              label: 'روز پا',
              exercises: <WorkoutExercise>[
                _ex(id: 1, name: 'اسکوات', muscle: 'quads'),
                _ex(id: 2, name: 'پرس پا', muscle: 'quads'),
                _ex(id: 3, name: 'لانج', muscle: 'quads'),
                _ex(id: 4, name: 'اکستنشن', muscle: 'quads'),
                _ex(id: 5, name: 'هاک', muscle: 'quads'),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    );

    final cleaned = LlmWorkoutProgramSanitizer.sanitize(
      dirty,
      curatedCatalog: catalog,
      usedAcrossProgram: <int>{},
    );

    final issues = LlmWorkoutProgramValidator.validate(
      cleaned,
      allowedExerciseIds: catalog.map((e) => e.id).toSet(),
      expectedDaysPerWeek: 1,
    );
    expect(issues, isEmpty, reason: issues.join(' | '));
    final quads = cleaned.allDays.first.exercises
        .where((e) => e.primaryMuscle.toLowerCase().contains('quad'))
        .length;
    expect(quads, lessThanOrEqualTo(3));
  });

  test('sanitizer groups muscles and puts core last', () {
    final catalog = <Exercise>[
      _catalog(id: 1, name: 'پرس سینه', muscle: 'chest'),
      _catalog(id: 2, name: 'پرس شیب', muscle: 'chest'),
      _catalog(id: 3, name: 'پرس سرشانه', muscle: 'shoulder_anterior'),
      _catalog(id: 4, name: 'پشت بازو', muscle: 'triceps'),
      _catalog(id: 5, name: 'پلانک', muscle: 'abs'),
      _catalog(id: 6, name: 'لت', muscle: 'back_lat'),
      _catalog(id: 7, name: 'رویینگ', muscle: 'back_lat'),
      _catalog(id: 8, name: 'جلو بازو', muscle: 'biceps'),
      _catalog(id: 9, name: 'اسکوات', muscle: 'quads'),
      _catalog(id: 10, name: 'لگ کرل', muscle: 'hamstrings'),
      _catalog(id: 11, name: 'هیپ', muscle: 'glutes'),
      _catalog(id: 12, name: 'ساق', muscle: 'calves'),
      _catalog(id: 13, name: 'پرس پا', muscle: 'quads'),
      _catalog(id: 50, name: 'کرانچ', muscle: 'abs'),
      _catalog(id: 51, name: 'زیرشکم', muscle: 'abs'),
      _catalog(id: 52, name: 'فیس پول', muscle: 'back_upper'),
    ];

    final program = WorkoutProgram(
      id: 'p3',
      name: 'ترتیب درست باشگاهی',
      goal: TrainingGoal.fatLoss,
      experienceLevel: 'مبتدی',
      daysPerWeek: 3,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 0,
          days: <WorkoutDay>[
            WorkoutDay(
              id: 'd1',
              dayIndex: 0,
              label: 'روز فشار',
              exercises: <WorkoutExercise>[
                _ex(id: 1, name: 'پرس سینه', muscle: 'chest'),
                _ex(id: 3, name: 'پرس سرشانه', muscle: 'shoulder_anterior'),
                _ex(id: 2, name: 'پرس شیب', muscle: 'chest'),
                _ex(id: 5, name: 'پلانک', muscle: 'abs'),
                _ex(id: 4, name: 'پشت بازو', muscle: 'triceps'),
              ],
            ),
            WorkoutDay(
              id: 'd2',
              dayIndex: 1,
              label: 'روز کشش',
              exercises: <WorkoutExercise>[
                _ex(id: 6, name: 'لت', muscle: 'back_lat'),
                _ex(id: 8, name: 'جلو بازو', muscle: 'biceps'),
                _ex(id: 7, name: 'رویینگ', muscle: 'back_lat'),
                _ex(id: 50, name: 'کرانچ', muscle: 'abs'),
                _ex(id: 52, name: 'فیس پول', muscle: 'back_upper'),
              ],
            ),
            WorkoutDay(
              id: 'd3',
              dayIndex: 2,
              label: 'روز پا',
              exercises: <WorkoutExercise>[
                _ex(id: 9, name: 'اسکوات', muscle: 'quads'),
                _ex(id: 51, name: 'زیرشکم', muscle: 'abs'),
                _ex(id: 11, name: 'هیپ', muscle: 'glutes'),
                _ex(id: 13, name: 'پرس پا', muscle: 'quads'),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    );

    final cleaned = LlmWorkoutProgramSanitizer.sanitize(
      program,
      curatedCatalog: catalog,
      usedAcrossProgram: <int>{},
    );

    final pushMuscles =
        cleaned.allDays[0].exercises.map((e) => e.primaryMuscle).toList();
    expect(pushMuscles.last.toLowerCase().contains('abs'), isTrue);
    expect(
      pushMuscles.where((m) => !m.toLowerCase().contains('abs')).toList(),
      equals(<String>['chest', 'chest', 'shoulder_anterior', 'triceps']),
    );

    final pullMuscles =
        cleaned.allDays[1].exercises.map((e) => e.primaryMuscle).toList();
    expect(pullMuscles.last.toLowerCase().contains('abs'), isTrue);
    final pullIdxBiceps =
        pullMuscles.indexWhere((m) => m.toLowerCase().contains('bicep'));
    final pullIdxBackLast =
        pullMuscles.lastIndexWhere((m) => m.toLowerCase().contains('back'));
    expect(pullIdxBiceps, greaterThan(-1));
    expect(pullIdxBackLast, greaterThan(-1));
    expect(pullIdxBackLast < pullIdxBiceps, isTrue);

    final legMuscles =
        cleaned.allDays[2].exercises.map((e) => e.primaryMuscle).toList();
    expect(legMuscles.last.toLowerCase().contains('abs'), isTrue);
    expect(
      legMuscles.indexWhere((m) => m.toLowerCase().contains('abs')),
      equals(legMuscles.length - 1),
    );
  });

  test('pull day never puts biceps between back moves', () {
    final catalog = <Exercise>[
      _catalog(id: 3939, name: 'لت', muscle: 'back_lat'),
      _catalog(id: 3931, name: 'شراگ', muscle: 'traps'),
      _catalog(id: 4069, name: 'جلو بازو', muscle: 'biceps'),
      _catalog(id: 3978, name: 'فیله', muscle: 'lower_back'),
      _catalog(id: 3948, name: 'قایقی', muscle: 'back_lat'),
      _catalog(id: 3958, name: 'پلانک', muscle: 'abs'),
    ];

    final dirty = WorkoutProgram(
      id: 'p4',
      name: 'چربی‌سوز ۳روزه باشگاهی',
      goal: TrainingGoal.fatLoss,
      experienceLevel: 'مبتدی',
      daysPerWeek: 1,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 0,
          days: <WorkoutDay>[
            WorkoutDay(
              id: 'd1',
              dayIndex: 0,
              label: 'روز کشش — پشت و بازو',
              exercises: <WorkoutExercise>[
                _ex(id: 3939, name: 'لت', muscle: 'back_lat'),
                _ex(id: 3931, name: 'شراگ', muscle: 'traps'),
                _ex(id: 4069, name: 'جلو بازو', muscle: 'biceps'),
                _ex(id: 3978, name: 'فیله', muscle: 'lower_back'),
                _ex(id: 3948, name: 'قایقی', muscle: 'back_lat'),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    );

    final cleaned = LlmWorkoutProgramSanitizer.sanitize(
      dirty,
      curatedCatalog: catalog,
      usedAcrossProgram: <int>{},
    );

    final muscles =
        cleaned.allDays.first.exercises.map((e) => e.primaryMuscle).toList();
    final bicepsIdx =
        muscles.indexWhere((m) => m.toLowerCase().contains('bicep'));
    final lastBackIdx = muscles.lastIndexWhere((m) {
      final lower = m.toLowerCase();
      return lower.contains('back') ||
          lower.contains('lat') ||
          lower.contains('trap');
    });
    expect(bicepsIdx, greaterThan(-1));
    expect(lastBackIdx, greaterThan(-1));
    expect(lastBackIdx < bicepsIdx, isTrue, reason: muscles.join(' → '));
  });

  test('shoulder_lateral is not treated as foreign on push day', () {
    final program = WorkoutProgram(
      id: 'p5',
      name: 'فشار تمیز باشگاهی',
      goal: TrainingGoal.fatLoss,
      experienceLevel: 'متوسط',
      daysPerWeek: 1,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 0,
          days: <WorkoutDay>[
            WorkoutDay(
              id: 'd1',
              dayIndex: 0,
              label: 'روز فشار — سینه و سرشانه',
              exercises: <WorkoutExercise>[
                _ex(id: 1, name: 'پرس سینه', muscle: 'chest'),
                _ex(id: 2, name: 'پرس سرشانه', muscle: 'shoulder_anterior'),
                _ex(id: 3, name: 'نشر جانب', muscle: 'shoulder_lateral'),
                _ex(id: 4, name: 'پشت بازو', muscle: 'triceps'),
                _ex(id: 5, name: 'کرانچ', muscle: 'abs'),
              ],
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026, 7, 17),
      updatedAt: DateTime(2026, 7, 17),
    );

    final issues = LlmWorkoutProgramValidator.validate(
      program,
      allowedExerciseIds: {1, 2, 3, 4, 5},
      expectedDaysPerWeek: 1,
    );
    expect(
      issues.any((i) => i.contains('نامرتبط')),
      isFalse,
      reason: issues.join(' | '),
    );
  });
}
