import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_builder.dart';
import 'package:gymaipro/ai/workout/equipment/workout_equipment_tokens.dart';
import 'package:gymaipro/ai/workout/generator/coach_workout_generator.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/models/exercise.dart';

void main() {
  test('PPL days only include on-focus muscle buckets', () {
    final rows = jsonDecode(
          File(
            'test/ai/workout/fixtures/ai_exercises_live_sample.json',
          ).readAsStringSync(),
        )
        as List<dynamic>;
    final exercises = rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return Exercise(
        id: (map['id'] as num?)?.toInt() ?? 0,
        title: (map['name'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        mainMuscle: (map['main_muscle'] as String?) ?? '',
        secondaryMuscles: '',
        tips: const <String>[],
        videoUrl: '',
        imageUrl: '',
        otherNames: const <String>[],
        content: '',
        difficulty: (map['difficulty'] as String?) ?? 'متوسط',
        equipment: (map['equipment'] as String?) ?? 'بدون تجهیزات',
        exerciseType: (map['exercise_type'] as String?) ?? 'قدرتی',
      );
    }).toList();

    final context = CoachContext(
      intent: AIIntent.workoutGeneration,
      metadata: CoachContextMetadata(
        buildTime: DateTime.now(),
        sourceCount: 1,
        missingProviders: const {},
        confidence: 1,
        contextVersion: CoachContext.contextVersion,
      ),
      profile: const <String, Object?>{
        'age': 31,
        'height': 182,
        'weight': 80,
        'experience_level': 'متوسط',
        'bb_days_per_week': 3,
        'bb_session_minutes': 75,
      },
      goals: const <String>['چربی‌سوزی'],
      equipment: WorkoutEquipmentTokens.expand(const <String>['باشگاه کامل']),
    );

    final blueprint = const WorkoutBlueprintBuilder().build(
      context: context,
      userId: 'user',
    );
    expect(blueprint.blueprint, isNotNull);

    final result = const CoachWorkoutGenerator().generate(
      blueprint: blueprint.blueprint!,
      catalog: ListExerciseCatalogAdapter(exercises),
    );
    expect(result.status, WorkoutGeneratorStatus.success);
    expect(result.program, isNotNull);

    final days = result.program!.allDays;
    expect(days, hasLength(3));

    final expected = WorkoutScience.bucketsPerDay(3);
    for (var i = 0; i < days.length; i++) {
      final allowed = expected[i];
      for (final exercise in days[i].exercises) {
        final bucket = WorkoutScience.muscleBucket(exercise.primaryMuscle);
        expect(
          allowed.contains(bucket),
          isTrue,
          reason:
              'Day ${i + 1} (${days[i].label}) got off-focus '
              '${exercise.name} [${exercise.primaryMuscle} → ${bucket.name}]. '
              'Allowed=${allowed.map((b) => b.name).join(",")}',
        );
      }
      expect(days[i].exercises.length, greaterThanOrEqualTo(3));
      expect(
        days[i].exercises.first.sets.length,
        greaterThanOrEqualTo(3),
      );
    }
  });
}
