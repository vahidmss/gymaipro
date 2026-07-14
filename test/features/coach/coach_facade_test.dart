import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/features/coach/application/coach_facade.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';

void main() {
  test('CoachFacade calls coach loader and maps CoachHomeState', () async {
    Map<String, Object?>? metadataSeen;
    String? userIdSeen;
    final facade = CoachFacade(
      seedLoader: _FakeSeedLoader(),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
      coachLoader: ({
        required userMessage,
        userId = 'preview_user',
        context,
        metadata = const <String, Object?>{},
      }) async {
        metadataSeen = metadata;
        userIdSeen = userId;
        expect(context, isNotNull);
        return _integrationResult();
      },
    );

    final result = await facade.load();

    expect(metadataSeen?['feature'], 'coach_home');
    expect(userIdSeen, 'user_1');
    expect(result.state.isLoaded, true);
    expect(result.state.todayWorkout, isNotNull);
    expect(result.state.greeting, contains('وحید'));
  });
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

CoachIntegrationResult _integrationResult() {
  return CoachIntegrationResult.local(
    intent: AIIntent.workoutToday,
    coachContext: CoachContext(
      intent: AIIntent.workoutToday,
      profile: const <String, Object?>{
        'first_name': 'وحید',
        'recovery': 82,
        'fatigue': 25,
        'sleep': 80,
        'readiness': 75,
      },
      activeProgram: const <String, Object?>{
        'name': 'تمرین امروز',
        'focus': 'سینه + پشت بازو',
        'exerciseCount': 7,
        'durationMinutes': 65,
        'exercises': <Object?>[
          <String, Object?>{
            'name': 'Bench Press',
            'sets': 4,
            'reps': 10,
            'primaryMuscle': 'سینه',
          },
        ],
      },
      metadata: CoachContextMetadata(
        buildTime: DateTime(2026, 7, 13),
        sourceCount: 1,
        missingProviders: const {},
        confidence: 0.9,
        contextVersion: CoachContext.contextVersion,
      ),
    ),
    skillExecution: const CoachSkillExecutionResult(
      skillId: 'workout_today_skill',
      response: CoachSkillResponse(
        confidence: 0.9,
        requiresAI: false,
        message: 'preview',
      ),
      executionTime: Duration(milliseconds: 1),
      success: true,
    ),
    processingTime: const Duration(milliseconds: 1),
    logs: const [],
    pipelineMode: CoachPipelineMode.runtime,
  );
}
