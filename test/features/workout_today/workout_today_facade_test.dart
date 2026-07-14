import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/features/workout_today/application/workout_today_facade.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';

void main() {
  test('WorkoutTodayFacade calls coach loader and maps activeProgram', () async {
    Map<String, Object?>? metadataSeen;
    final facade = WorkoutTodayFacade(
      seedLoader: _FakeSeedLoader(),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
      coachLoader: ({
        required userMessage,
        userId = 'preview_user',
        context,
        metadata = const <String, Object?>{},
      }) async {
        metadataSeen = metadata;
        expect(context, isNotNull);
        return _integrationResult(activeProgram: _activeProgram);
      },
    );

    final result = await facade.load();

    expect(metadataSeen?['feature'], 'workout_today');
    expect(result.state.isLoaded, true);
    expect(result.state.data!.workout.exercises.length, 2);
    expect(result.hasGaps, isFalse);
  });

  test('WorkoutTodayFacade returns empty when no workout data', () async {
    final facade = WorkoutTodayFacade(
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
      coachLoader: ({
        required userMessage,
        userId = 'preview_user',
        context,
        metadata = const <String, Object?>{},
      }) async {
        return _integrationResult(activeProgram: const <String, Object?>{});
      },
    );

    final mapped = await facade.map(
      _integrationResult(activeProgram: const <String, Object?>{}),
    );

    expect(mapped.state.isEmpty, true);
  });
}

const Map<String, Object?> _activeProgram = <String, Object?>{
  'headline': 'امروز روز تمرین بالاتنه است.',
  'durationMinutes': 65,
  'totalSets': 8,
  'intensity': 'متوسط',
  'exercises': <Object?>[
    <String, Object?>{
      'name': 'Bench Press',
      'sets': 4,
      'reps': 10,
      'primaryMuscle': 'سینه',
    },
    <String, Object?>{
      'name': 'Triceps Pushdown',
      'sets': 4,
      'reps': 12,
      'primaryMuscle': 'پشت بازو',
    },
  ],
};

CoachIntegrationResult _integrationResult({
  required Map<String, Object?> activeProgram,
}) {
  return CoachIntegrationResult.local(
    intent: AIIntent.workoutToday,
    coachContext: CoachContext(
      intent: AIIntent.workoutToday,
      profile: const <String, Object?>{'first_name': 'وحید', 'recovery': 82},
      activeProgram: activeProgram,
      metadata: CoachContextMetadata(
        buildTime: DateTime(2026, 7, 13),
        sourceCount: 1,
        missingProviders: const {},
        confidence: 0.9,
        contextVersion: CoachContext.contextVersion,
      ),
    ),
    skillExecution: CoachSkillExecutionResult(
      skillId: 'workout_today_skill',
      response: CoachSkillResponse(
        confidence: 0.9,
        requiresAI: false,
        message: 'preview',
        structuredData: <String, Object?>{'program': activeProgram},
      ),
      executionTime: const Duration(milliseconds: 1),
      success: true,
    ),
    processingTime: const Duration(milliseconds: 1),
    logs: const [],
    pipelineMode: CoachPipelineMode.runtime,
  );
}

class _FakeSeedLoader implements CoachPreviewSeedProvider {
  @override
  Future<CoachPreviewSeed> load({
    required AIIntent intent,
    required String message,
  }) async {
    return CoachPreviewSeed(
      userId: 'user_1',
      intent: intent,
      message: message,
      context: CoachContext(
        intent: intent,
        profile: const <String, Object?>{'first_name': 'وحید'},
        metadata: CoachContextMetadata(
          buildTime: DateTime(2026, 7, 13),
          sourceCount: 1,
          missingProviders: const {},
          confidence: 0.9,
          contextVersion: CoachContext.contextVersion,
        ),
      ),
    );
  }
}
