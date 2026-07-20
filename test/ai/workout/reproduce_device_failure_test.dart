import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_builder.dart';
import 'package:gymaipro/ai/workout/equipment/workout_equipment_tokens.dart';
import 'package:gymaipro/ai/workout/generator/coach_workout_generator.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';

void main() {
  test('reproduce device failure conditions', () {
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
        'height': 182.0,
        'weight': 3.0,
        'experience_level': 'متوسط',
        'bb_days_per_week': 3,
        'bb_session_minutes': 60,
      },
      goals: const <String>['چربی‌سوزی'],
      equipment: WorkoutEquipmentTokens.expand(const <String>['باشگاه کامل']),
      restrictions: const <String>['هیچکدام'],
      weeklyHeatmap: const WeeklyMuscleHeatmapResult(
        targets: <String, int>{
          'chest': 6,
          'back': 6,
          'quads': 6,
          'shoulders': 6,
          'hamstrings': 6,
          'glutes': 6,
        },
        previousWeekTargets: <String, int>{},
        workoutDays: 4,
        sessionCount: 4,
        previousSessionCount: 0,
        hasHeatmapData: true,
        hasPreviousWeekData: false,
      ),
    );

    final blueprint = const WorkoutBlueprintBuilder().build(
      context: context,
      userId: 'user',
    );
    // ignore: avoid_print
    print('bp ok=${blueprint.blueprint != null} msg=${blueprint.message}');
    final result = const CoachWorkoutGenerator().generate(
      blueprint: blueprint.blueprint!,
      catalog: ListExerciseCatalogAdapter(exercises),
    );
    // ignore: avoid_print
    print(
      'status=${result.status} msg=${result.message} '
      'steps=${result.selectionTrace?.steps}',
    );
    expect(result.status, WorkoutGeneratorStatus.success);
  });
}
