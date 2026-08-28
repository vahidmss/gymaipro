import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_catalog_curator.dart';

import 'fixtures/workout_exercise_catalog_fixture.dart';

void main() {
  final catalog = WorkoutExerciseCatalogFixture.gymCatalog();

  test('curator keeps squat when there is no injury', () {
    final curated = LlmWorkoutCatalogCurator.curate(
      catalog,
      equipment: const <String>['باشگاه کامل', 'هالتر', 'دمبل'],
    );
    expect(curated.map((e) => e.name), contains('اسکوات هالتر'));
    expect(curated, isNotEmpty);
  });

  test('curator drops squat and lunge for a knee limitation', () {
    final curated = LlmWorkoutCatalogCurator.curate(
      catalog,
      equipment: const <String>['باشگاه کامل', 'هالتر', 'دمبل'],
      restrictions: const <String>['درد زانو'],
    );
    final names = curated.map((e) => e.name).toList();
    expect(names, isNot(contains('اسکوات هالتر')));
    expect(names, isNot(contains('لانج دمبل')));
    expect(names, contains('پرس سینه هالتر'));
    expect(curated, isNotEmpty);
  });

  test('curator ignores empty injury labels', () {
    final curated = LlmWorkoutCatalogCurator.curate(
      catalog,
      equipment: const <String>['باشگاه کامل'],
      restrictions: const <String>['ندارم'],
    );
    expect(curated.map((e) => e.name), contains('اسکوات هالتر'));
  });
}
