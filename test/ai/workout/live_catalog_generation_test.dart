import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_builder.dart';
import 'package:gymaipro/ai/workout/equipment/workout_equipment_tokens.dart';
import 'package:gymaipro/ai/workout/generator/coach_workout_generator.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/models/exercise.dart';

void main() {
  test('live AI catalog can generate a gym program', () {
    final file = File('test/ai/workout/fixtures/ai_exercises_live_sample.json');
    expect(file.existsSync(), isTrue, reason: 'sample fixture missing');

    final rows = jsonDecode(file.readAsStringSync()) as List<dynamic>;
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

    expect(exercises.length, greaterThan(100));

    final mapper = const ExerciseProfileMapper();
    final profiles = mapper.fromExercises(exercises);
    final equipmentCounts = <String, int>{};
    final bucketCounts = <String, int>{};
    var otherEquipment = 0;
    for (final profile in profiles) {
      for (final eq in profile.equipment) {
        equipmentCounts[eq.name] = (equipmentCounts[eq.name] ?? 0) + 1;
      }
      if (profile.equipment.length == 1 &&
          profile.equipment.first == ExerciseEquipmentType.other) {
        otherEquipment++;
      }
      final bucket = WorkoutScience.muscleBucket(
        exercises.firstWhere((e) => e.id == profile.id).mainMuscle,
      );
      bucketCounts[bucket.name] = (bucketCounts[bucket.name] ?? 0) + 1;
    }

    // ignore: avoid_print
    print('equipmentCounts=$equipmentCounts otherOnly=$otherEquipment');
    // ignore: avoid_print
    print('bucketCounts=$bucketCounts');

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
        'bb_session_minutes': 60,
      },
      goals: const <String>['چربی‌سوزی'],
      equipment: WorkoutEquipmentTokens.expand(const <String>['باشگاه کامل']),
    );

    final blueprint = const WorkoutBlueprintBuilder().build(
      context: context,
      userId: 'user',
    );
    expect(blueprint.blueprint, isNotNull, reason: blueprint.message);

    final result = const CoachWorkoutGenerator().generate(
      blueprint: blueprint.blueprint!,
      catalog: ListExerciseCatalogAdapter(exercises),
    );

    // ignore: avoid_print
    print('status=${result.status} msg=${result.message} '
        'trace=${result.selectionTrace?.steps}');

    expect(result.status, WorkoutGeneratorStatus.success);
    expect(result.program, isNotNull);
    expect(result.program!.allDays, isNotEmpty);
  });
}
