import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:gymaipro/services/muscle_heatmap_insights.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

Exercise _ex({
  required int id,
  required Map<String, int> muscles,
}) {
  return Exercise(
    id: id,
    title: 'ex$id',
    name: 'ex$id',
    mainMuscle: 'test',
    secondaryMuscles: '',
    tips: const [],
    videoUrl: '',
    imageUrl: '',
    otherNames: const [],
    content: '',
    muscleTargets: muscles,
  );
}

NormalExerciseLog _log({
  required int exerciseId,
  required List<ExerciseSetLog> sets,
}) {
  return NormalExerciseLog(
    id: 'log-$exerciseId',
    exerciseId: exerciseId,
    exerciseName: 'e$exerciseId',
    tag: 'normal',
    style: 'sets_reps',
    sets: sets,
  );
}

void main() {
  group('MuscleHeatmapAggregate scientific stimulus', () {
    test('30% then 50% biceps accumulates proportionally before display norm', () {
      final byId = {
        1: _ex(id: 1, muscles: const {'biceps': 30}),
        2: _ex(id: 2, muscles: const {'biceps': 50}),
      };

      // Day A: 3 bodyweight-like sets @ 30% → 0.3*1*3 = 0.9
      final dayA = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 1,
            sets: List.generate(3, (_) => ExerciseSetLog(reps: 10)),
          ),
        ],
        byId,
      );
      expect(dayA.stimulus['biceps'], closeTo(0.9, 1e-9));
      expect(dayA.targets['biceps'], 100); // only muscle that day

      // Day B: 3 sets @ 50% → 1.5
      final dayB = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 2,
            sets: List.generate(3, (_) => ExerciseSetLog(reps: 10)),
          ),
        ],
        byId,
      );
      expect(dayB.stimulus['biceps'], closeTo(1.5, 1e-9));

      // Week merge (no per-session normalize into sum)
      final week = MuscleHeatmapAggregate.mergeStimulus([
        dayA.stimulus,
        dayB.stimulus,
      ]);
      expect(week['biceps'], closeTo(2.4, 1e-9));

      final display = MuscleHeatmapAggregate.normalizeForDisplay(week);
      expect(display['biceps'], 100);
    });

    test('heavier weight increases stimulus for same muscle %', () {
      final byId = {
        1: _ex(id: 1, muscles: const {'biceps': 50}),
      };

      final light = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 1,
            sets: [ExerciseSetLog(reps: 10, weight: 10)],
          ),
        ],
        byId,
      );
      final heavy = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 1,
            sets: [ExerciseSetLog(reps: 10, weight: 20)],
          ),
        ],
        byId,
      );

      expect(light.stimulus['biceps'], closeTo(5.0, 1e-9)); // 0.5 * 10
      expect(heavy.stimulus['biceps'], closeTo(10.0, 1e-9)); // 0.5 * 20
      expect(heavy.stimulus['biceps']!, greaterThan(light.stimulus['biceps']!));
    });

    test('relative display preserves 30 vs 50 against hotter muscle', () {
      final byId = {
        1: _ex(id: 1, muscles: const {'biceps': 30}),
        2: _ex(id: 2, muscles: const {'biceps': 50}),
        3: _ex(id: 3, muscles: const {'chest_middle': 80}),
      };

      final dayA = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 1,
            sets: List.generate(3, (_) => ExerciseSetLog(reps: 10)),
          ),
        ],
        byId,
      ); // biceps 0.9

      final dayB = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 2,
            sets: List.generate(3, (_) => ExerciseSetLog(reps: 10)),
          ),
        ],
        byId,
      ); // biceps 1.5 → week biceps 2.4

      final chestDay = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 3,
            sets: List.generate(3, (_) => ExerciseSetLog(reps: 10)),
          ),
        ],
        byId,
      ); // chest 0.8*3 = 2.4

      final week = MuscleHeatmapAggregate.mergeStimulus([
        dayA.stimulus,
        dayB.stimulus,
        chestDay.stimulus,
      ]);
      final display = MuscleHeatmapAggregate.normalizeForDisplay(week);

      expect(week['biceps'], closeTo(2.4, 1e-9));
      expect(week['chest_middle'], closeTo(2.4, 1e-9));
      expect(display['biceps'], 100);
      expect(display['chest_middle'], 100);
    });

    test('double session-normalize bug is avoided when merging stimulus', () {
      // Old bug: each isolation session becomes 100, so 2 light days = 200
      // vs one compound day with legs 100 + arms 40 → arms look huge after sum.
      final byId = {
        1: _ex(id: 1, muscles: const {'biceps': 100}),
        2: _ex(
          id: 2,
          muscles: const {'quads': 80, 'biceps': 10},
        ),
      };

      final isolation = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 1,
            sets: [ExerciseSetLog(reps: 12)],
          ),
        ],
        byId,
      ); // biceps stimulus 1.0

      final compound = MuscleHeatmapAggregate.fromExerciseLogs(
        [
          _log(
            exerciseId: 2,
            sets: List.generate(5, (_) => ExerciseSetLog(reps: 8, weight: 100)),
          ),
        ],
        byId,
      );
      // quads: 0.8*100*5 = 400; biceps: 0.1*100*5 = 50

      final week = MuscleHeatmapAggregate.mergeStimulus([
        isolation.stimulus,
        compound.stimulus,
      ]);
      final display = MuscleHeatmapAggregate.normalizeForDisplay(week);

      expect(week['quads']!, greaterThan(week['biceps']!));
      expect(display['quads'], 100);
      expect(display['biceps']!, lessThan(30));
    });
  });

  group('MuscleHeatmapInsights.weekTrendLine', () {
    test('compares raw stimulus totals not relative percents', () {
      final line = MuscleHeatmapInsights.weekTrendLine(
        currentStimulusTotal: 120,
        previousStimulusTotal: 100,
        currentSessions: 3,
        previousSessions: 3,
      );
      expect(line, 'فعال‌تر از هفته قبل');
    });
  });
}
