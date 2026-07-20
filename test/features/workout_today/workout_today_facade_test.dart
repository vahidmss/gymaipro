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
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';

void main() {
  test('WorkoutTodayFacade maps coach result with selected session', () async {
    final facade = WorkoutTodayFacade(
      seedLoader: _FakeSeedLoader(),
      programCatalog: _StubProgramCatalog(_testProgram),
      sessionGateway: const _FakeSessionGateway(selectedDay: 'Upper'),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
    );

    final result = await facade.map(
      _integrationResult(activeProgram: _activeProgram),
    );

    expect(result.state.isLoaded, true);
    expect(result.state.data!.workout.exercises.length, 2);
    expect(result.hasGaps, isFalse);
  });

  test('WorkoutTodayFacade returns awaitingSession when day not selected', () async {
    final facade = WorkoutTodayFacade(
      programCatalog: _StubProgramCatalog(_testProgram),
      sessionGateway: const _FakeSessionGateway(selectedDay: null),
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
    );

    final mapped = await facade.map(
      _integrationResult(activeProgram: _activeProgram),
    );

    expect(mapped.state.isAwaitingSession, true);
  });

  test('WorkoutTodayFacade returns empty when no workout data', () async {
    final facade = WorkoutTodayFacade(
      programCatalog: _StubProgramCatalog(_testProgram),
      sessionGateway: const _FakeSessionGateway(selectedDay: 'Upper'),
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

const _testProgram = ActiveProgramOption(
  id: 'program_1',
  title: 'برنامه تست',
  creatorLabel: 'GymAI',
  isActive: true,
  isAiSupervised: true,
);

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

class _StubProgramCatalog extends ActiveProgramCatalogService {
  _StubProgramCatalog(this._active) : super();

  final ActiveProgramOption _active;

  @override
  Future<ActiveProgramOption?> getActiveProgramOption() async => _active;

  @override
  Future<List<ActiveProgramOption>> listWorkoutPrograms() async => [_active];
}

class _FakeSessionGateway implements WorkoutSessionSelectionGateway {
  const _FakeSessionGateway({required this.selectedDay});

  final String? selectedDay;

  @override
  Future<void> applySessionChangeCleanup({
    required String sessionDayToDelete,
    String? userId,
  }) async {}

  @override
  Future<void> clearSelection({String? userId}) async {}

  @override
  SessionChangeEvaluation evaluateSessionChange({
    required ActiveWorkoutSessionContext context,
    required String newSessionDay,
    String? currentSessionDay,
  }) {
    return const SessionChangeEvaluation.none();
  }

  @override
  SessionChangeEvaluation evaluateProgramChange({
    required ActiveWorkoutSessionContext context,
  }) {
    return const SessionChangeEvaluation.none();
  }

  @override
  Future<ActiveWorkoutSessionContext> loadContext({
    required String programId,
    String? userId,
  }) async {
    return ActiveWorkoutSessionContext(
      programId: programId,
      programName: 'برنامه تست',
      sessions: const [],
      selectedSessionDay: selectedDay,
      loggedSessionDay: null,
      hasSavedLog: false,
      hasLiveDraft: false,
    );
  }

  @override
  Future<void> saveSelection({
    required String programId,
    required String sessionDay,
    String? userId,
  }) async {}
}
