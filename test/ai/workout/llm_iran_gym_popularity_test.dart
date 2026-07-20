import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/workout/generator/llm_iran_gym_style.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_catalog_curator.dart';
import 'package:gymaipro/models/exercise.dart';

Exercise _ex({
  required int id,
  required String name,
  String muscle = 'chest',
  String equipment = 'هالتر',
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
    equipment: equipment,
  );
}

void main() {
  test('familiar chest presses score higher than niche variants', () {
    final bench = _ex(id: 1, name: 'پرس سینه هالتر');
    final weird = _ex(id: 2, name: 'پرس سوندر');
    expect(
      LlmIranGymPopularity.score(bench),
      greaterThan(LlmIranGymPopularity.score(weird)),
    );
  });

  test('curator puts familiar staples early in the list', () {
    final catalog = <Exercise>[
      _ex(id: 1, name: 'پرس سوندر', muscle: 'chest'),
      _ex(id: 2, name: 'پرس سینه دمبل', muscle: 'chest'),
      _ex(id: 3, name: 'اسکوات هالتر', muscle: 'quads'),
      _ex(id: 4, name: 'اسکات کوزاک', muscle: 'quads'),
      _ex(id: 5, name: 'زیربغل سیمکش دست باز', muscle: 'back_lat'),
      _ex(id: 6, name: 'بارفیکس آرچر', muscle: 'back_lat'),
    ];

    final curated = LlmWorkoutCatalogCurator.curate(
      catalog,
      equipment: const <String>['باشگاه کامل'],
      maxExercises: 6,
    );

    final names = curated.take(3).map((e) => e.name).toList();
    expect(names, contains('پرس سینه دمبل'));
    expect(names, contains('اسکوات هالتر'));
    expect(names, contains('زیربغل سیمکش دست باز'));
  });
}
