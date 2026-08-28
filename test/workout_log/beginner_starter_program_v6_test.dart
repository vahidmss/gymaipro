import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_rich_meta.dart';
import 'package:gymaipro/workout_log/services/beginner_starter_program_service.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

Exercise _ex({
  required int id,
  required String name,
  required String muscle,
  String equipment = 'دستگاه',
  String type = 'قدرتی',
  String difficulty = 'مبتدی',
  String slug = '',
  String movement = '',
  List<String> otherNames = const [],
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
    otherNames: otherNames,
    content: '',
    difficulty: difficulty,
    equipment: equipment,
    exerciseType: type,
    movementPattern: movement,
    richMeta: ExerciseRichMeta(
      webSlug: slug.isEmpty
          ? name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-')
          : slug,
    ),
  );
}

List<Exercise> _wallCatalog({bool includeTreadmill = true}) {
  return <Exercise>[
    if (includeTreadmill)
      _ex(
        id: 9001,
        name: 'تردمیل',
        muscle: 'full_body',
        type: 'cardio',
        slug: 'تردمیل',
        movement: 'gait',
        otherNames: const ['Treadmill Walk', 'پیاده‌روی تردمیل'],
      ),
    _ex(
      id: 9002,
      name: 'تردمیل دویدن',
      muscle: 'full_body',
      type: 'cardio',
      slug: 'تردمیل-دویدن',
      movement: 'cardio',
      otherNames: const ['Treadmill Run', 'Jogging'],
    ),
    _ex(
      id: 4008,
      name: 'لگ پرس',
      muscle: 'quads',
      slug: 'لگ-پرس',
      movement: 'knee_dominant_press',
    ),
    _ex(
      id: 3949,
      name: 'اکستنشن پا',
      muscle: 'quads',
      slug: 'اکستنشن-پا',
      movement: 'knee_extension',
      otherNames: const ['جلو پا', 'Leg Extension'],
    ),
    _ex(
      id: 3842,
      name: 'پشت پا دستگاه',
      muscle: 'hamstrings',
      slug: 'پشت-پا-دستگاه',
      movement: 'knee_flexion',
    ),
    _ex(
      id: 4114,
      name: 'پشت پا نشسته دستگاه',
      muscle: 'hamstrings',
      slug: 'پشت-پا-نشسته-دستگاه',
      movement: 'knee_flexion',
    ),
    _ex(
      id: 4113,
      name: 'پشت پا خوابیده',
      muscle: 'hamstrings',
      slug: 'پشت-پا-خوابیده',
      movement: 'knee_flexion',
    ),
    _ex(
      id: 4007,
      name: 'پرس سینه اسمیت',
      muscle: 'chest',
      slug: 'پرس-سینه-اسمیت',
      movement: 'horizontal_push',
    ),
    _ex(
      id: 3832,
      name: 'پرس سینه دستگاه',
      muscle: 'chest',
      slug: 'پرس-سینه-دستگاه',
      movement: 'horizontal_push',
    ),
    _ex(
      id: 4014,
      name: 'فلای پک دستگاه',
      muscle: 'chest',
      slug: 'فلای-پک-دستگاه',
      movement: 'horizontal_adduction',
    ),
    _ex(
      id: 4021,
      name: 'زیربغل نشسته سیمکش',
      muscle: 'back_lat',
      slug: 'زیربغل-نشسته-سیمکش',
      movement: 'horizontal_pull',
    ),
    _ex(
      id: 3969,
      name: 'زیربغل دست جمع',
      muscle: 'back_lat',
      slug: 'زیربغل-دست-جمع',
      movement: 'vertical_pull',
    ),
    _ex(
      id: 3844,
      name: 'زیربغل سیمکش دست باز',
      muscle: 'back_lat',
      slug: 'زیربغل-سیمکش-دست-باز',
      movement: 'vertical_pull',
    ),
    _ex(
      id: 3853,
      name: 'پشت بازو سیم کش',
      muscle: 'triceps',
      slug: 'پشت-بازو-سیمکش',
      movement: 'elbow_extension',
    ),
    _ex(
      id: 3962,
      name: 'جلو بازو سیمکش',
      muscle: 'biceps',
      slug: 'جلو-بازو-سیمکش',
      movement: 'elbow_flexion',
    ),
    _ex(
      id: 3831,
      name: 'پرس سرشانه دستگاه',
      muscle: 'shoulder_anterior',
      slug: 'پرس-سرشانه-دستگاه',
      movement: 'vertical_push',
      otherNames: const ['Overhead Press Machine'],
    ),
    _ex(
      id: 4012,
      name: 'کرانچ سیمکش',
      muscle: 'abs',
      slug: 'کرانچ-سیمکش',
      movement: 'spinal_flexion',
    ),
    _ex(
      id: 3906,
      name: 'پلانک',
      muscle: 'abs',
      equipment: 'وزن بدن',
      slug: 'پلانک',
      movement: 'isometric_hold',
    ),
  ];
}

NormalExercise _asNormal(WorkoutExercise ex) => ex as NormalExercise;

void main() {
  test('v7 version and enrollment copy', () {
    expect(BeginnerStarterProgramService.programVersion, 7);
    final msg = BeginnerStarterProgramService.enrollmentDialogMessage(
      trainerName: 'جیم اِی آی',
      isNewAiStudent: true,
    );
    expect(msg, contains('ست سوم را رد کن'));
    expect(msg, isNot(contains('۲ ست برای هر حرکت')));
  });

  test('wall catalog builds 3 full-body sessions', () {
    final program = BeginnerStarterProgramService.buildFromCatalog(
      _wallCatalog(),
    );
    expect(program.sessions, hasLength(3));
    expect(
      program.sessions.every(
        (s) =>
            s.exercises.length >=
            BeginnerStarterProgramService.minRequiredExercisesPerSession,
      ),
      isTrue,
    );

    final s1 = program.sessions[0];
    expect(s1.exercises.map(_asNormal).map((e) => e.tag).toList(), [
      'گرم‌کردن',
      'پا',
      'پشت پا',
      'سینه',
      'پشت',
      'پشت بازو',
      'شکم',
    ]);

    final warmup = _asNormal(s1.exercises.first);
    expect(warmup.style, ExerciseStyle.setsTime);
    expect(warmup.sets, hasLength(1));
    expect(warmup.sets.first.timeSeconds, 300);
    expect(warmup.exerciseId, 9001);

    final press = _asNormal(s1.exercises[3]);
    expect(press.sets, hasLength(3));
    expect(press.sets.every((s) => s.reps == 12), isTrue);
    expect(press.exerciseId, 4007);
    expect(_asNormal(s1.exercises[1]).exerciseId, 4008);
    expect(_asNormal(s1.exercises[2]).exerciseId, 3842);
    expect(_asNormal(s1.exercises[4]).exerciseId, 4021);
  });

  test('days are A/B/C not copy-paste', () {
    final program = BeginnerStarterProgramService.buildFromCatalog(
      _wallCatalog(),
    );
    final s1 = program.sessions[0].exercises
        .whereType<NormalExercise>()
        .toList();
    final s2 = program.sessions[1].exercises
        .whereType<NormalExercise>()
        .toList();
    final s3 = program.sessions[2].exercises
        .whereType<NormalExercise>()
        .toList();

    expect(s2.map((e) => e.tag).toList(), [
      'گرم‌کردن',
      'پا',
      'پشت پا',
      'سینه',
      'پشت',
      'جلو بازو',
      'شکم',
    ]);

    expect(s2[1].exerciseId, 3949);
    expect(s2[1].exerciseId, isNot(s1[1].exerciseId));
    expect(s2[2].exerciseId, 4114);
    expect(s2[2].exerciseId, isNot(s1[2].exerciseId));
    expect(s2[3].exerciseId, 3832);
    expect(s2[4].exerciseId, 3969);
    expect(s2[4].exerciseId, isNot(s1[4].exerciseId));

    expect(s3[1].exerciseId, 4008);
    expect(s3[2].exerciseId, 4113);
    expect(s3[4].exerciseId, 3969);
    expect(s3[4].exerciseId, isNot(s1[4].exerciseId));
    expect(s3.any((e) => e.tag == 'سرشانه'), isTrue);
    expect(s2.any((e) => e.tag == 'سرشانه'), isFalse);

    final strengthIds = (NormalExercise e) =>
        e.tag != 'گرم‌کردن' && e.tag != 'پایان';
    expect(
      s1.where(strengthIds).map((e) => e.exerciseId).toList(),
      isNot(s2.where(strengthIds).map((e) => e.exerciseId).toList()),
    );
  });

  test('does not replace chest press with pec deck', () {
    final program = BeginnerStarterProgramService.buildFromCatalog(
      _wallCatalog(),
    );
    for (final session in program.sessions) {
      final chest = session.exercises
          .whereType<NormalExercise>()
          .where((e) => e.tag == 'سینه')
          .single;
      expect(chest.exerciseId, isIn(<int>[4007, 3832]));
      expect(chest.exerciseId, isNot(4014));
    }
  });

  test('every session has hamstring and a back pull', () {
    final program = BeginnerStarterProgramService.buildFromCatalog(
      _wallCatalog(),
    );
    for (final session in program.sessions) {
      final tags = session.exercises
          .whereType<NormalExercise>()
          .map((e) => e.tag)
          .toSet();
      expect(tags, contains('پشت پا'));
      expect(tags, contains('پشت'));
    }
  });

  test('session 3 keeps a pull and a timed finisher', () {
    final program = BeginnerStarterProgramService.buildFromCatalog(
      _wallCatalog(),
    );
    final s3 = program.sessions[2].exercises
        .whereType<NormalExercise>()
        .toList();
    expect(s3.map((e) => e.tag).toList(), [
      'گرم‌کردن',
      'پا',
      'پشت پا',
      'سینه',
      'پشت',
      'سرشانه',
      'پایان',
    ]);
    expect(s3.first.exerciseId, s3.last.exerciseId);
    expect(s3.last.sets.first.timeSeconds, 480);
    expect(s3.where((e) => e.tag == 'سرشانه').single.exerciseId, 3831);
    expect(s3.where((e) => e.tag == 'پشت').single.exerciseId, 3969);
  });

  test('warmup treadmill is walk, not jog', () {
    final program = BeginnerStarterProgramService.buildFromCatalog(
      _wallCatalog(),
    );
    final warmupIds = program.sessions
        .expand((s) => s.exercises.whereType<NormalExercise>())
        .where((e) => e.tag == 'گرم‌کردن' || e.tag == 'پایان')
        .map((e) => e.exerciseId)
        .toSet();
    expect(warmupIds, {9001});
    expect(warmupIds, isNot(contains(9002)));
  });

  test('still builds if treadmill is not in catalog yet', () {
    final program = BeginnerStarterProgramService.buildFromCatalog(
      _wallCatalog(includeTreadmill: false),
    );
    expect(program.sessions, hasLength(3));
    for (final session in program.sessions) {
      final tags = session.exercises.whereType<NormalExercise>().map(
        (e) => e.tag,
      );
      expect(tags, isNot(contains('گرم‌کردن')));
      expect(tags, isNot(contains('پایان')));
      expect(tags, containsAll(<String>['پا', 'پشت پا', 'سینه', 'پشت']));
    }
  });

  test('missing hamstring is a required gap', () {
    final catalog = _wallCatalog()
        .where((e) => e.id != 3842 && e.id != 4114 && e.id != 4113)
        .toList();
    final missing = BeginnerStarterProgramService.missingRequiredSlots(catalog);
    expect(missing.any((s) => s.contains('پشت پا')), isTrue);
  });

  test('leg extension preferred id wins even if muscle tag is wrong', () {
    final catalog = _wallCatalog()
        .map(
          (e) => e.id == 3949
              ? _ex(
                  id: 3949,
                  name: 'اکستنشن پا',
                  muscle: 'hamstrings',
                  slug: 'اکستنشن-پا',
                  movement: 'knee_extension',
                  otherNames: const ['جلو پا', 'Leg Extension'],
                )
              : e,
        )
        .toList();
    final program = BeginnerStarterProgramService.buildFromCatalog(catalog);
    final day2Leg = program.sessions[1].exercises
        .whereType<NormalExercise>()
        .where((e) => e.tag == 'پا')
        .single;
    expect(day2Leg.exerciseId, 3949);
  });
}
