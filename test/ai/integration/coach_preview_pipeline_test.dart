import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_provider.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/ai/integration/coach_integration_service.dart';
import 'package:gymaipro/ai/integration/coach_pipeline_dependencies_factory.dart';
import 'package:gymaipro/ai/integration/coach_state_integration.dart';
import 'package:gymaipro/ai/integration/entity_memory_integration.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_manager.dart';
import 'package:gymaipro/ai/memory/memory_repository.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/pipeline/coach_pipeline_stage.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/state/coach_state_repository.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  final metadata = CoachContextMetadata(
    buildTime: DateTime(2026, 7, 12),
    sourceCount: 1,
    missingProviders: const {},
    confidence: 0.85,
    contextVersion: CoachContext.contextVersion,
  );

  CoachContext baseContext({
    AIIntent intent = AIIntent.generalChat,
    String question = 'سلام',
    Map<String, Object?>? activeProgram,
    WeeklyMuscleHeatmapResult? weeklyHeatmap,
    List<String> equipment = const <String>[],
  }) {
    return CoachContext(
      intent: intent,
      metadata: metadata,
      currentQuestion: question,
      activeProgram: activeProgram,
      goals: const <String>['عضله‌سازی'],
      equipment: equipment,
      weeklyHeatmap: weeklyHeatmap,
    );
  }

  CoachIntegrationService buildService({
    required RecordingCoachStateRepository stateRepository,
    required RecordingMemoryRepository memoryRepository,
    CoachEntitlementProvider? entitlementProvider,
  }) {
    return CoachIntegrationService(
      pipelineDependencies: CoachPipelineDependenciesFactory.standard(
        stateIntegration: CoachStateIntegration(
          stateRepository: stateRepository,
        ),
        entityMemoryIntegration: EntityMemoryIntegration(
          memoryManager: MemoryManager(repository: memoryRepository),
        ),
        coachEntitlementRuntime: CoachEntitlementRuntime(
          provider: entitlementProvider ?? const CurrentSubscriptionAdapter(),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Coach preview pipeline migration', () {
    test('Preview uses CoachPipeline', () async {
      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: RecordingMemoryRepository(),
      );

      final result = await service.previewMessage(
        userMessage: 'سلام، درباره تمرین توضیح بده',
        context: baseContext(question: 'سلام، درباره تمرین توضیح بده'),
      );

      expect(result.pipelineMode, CoachPipelineMode.preview);
      expect(result.pipelineTrace, isNotNull);
      expect(result.pipelineTrace!.mode, CoachPipelineMode.preview);
      expect(result.pipelineTrace!.stages, isNotEmpty);
      expect(
        result.pipelineTrace!.traceFor(CoachPipelineStage.intent),
        isNotNull,
      );
    });

    test('Preview does not persist State', () async {
      final stateRepository = RecordingCoachStateRepository();
      final service = buildService(
        stateRepository: stateRepository,
        memoryRepository: RecordingMemoryRepository(),
      );

      await service.previewMessage(
        userMessage: 'یک برنامه تمرین جدید بساز',
        context: baseContext(
          intent: AIIntent.workoutGeneration,
          question: 'یک برنامه تمرین جدید بساز',
        ),
      );

      expect(stateRepository.saveCount, 0);
    });

    test('Preview does not write Memory', () async {
      final memoryRepository = RecordingMemoryRepository();
      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: memoryRepository,
      );

      final result = await service.previewMessage(
        userMessage: 'سن من ۲۵ ساله است',
        context: baseContext(question: 'سن من ۲۵ ساله است'),
      );

      expect(memoryRepository.saveCount, 0);
      final memoryTrace = result.pipelineTrace?.traceFor(CoachPipelineStage.memory);
      expect(memoryTrace, isNotNull);
      expect(memoryTrace!.reason, contains('without persisting'));
    });

    test('Preview does not consume Usage', () async {
      final provider = RecordingEntitlementProvider(
        snapshot: CoachEntitlementSnapshot(
          entitlement: CoachEntitlement(
            userId: 'preview_user',
            plan: CoachSubscriptionPlan.free,
            usage: const EntitlementUsageSnapshot(
              dailyUsage: <CoachCapability, int>{
                CoachCapability.coachConversation: 2,
              },
            ),
          ),
          source: 'test_snapshot',
          capturedAt: DateTime(2026, 7, 12),
        ),
      );
      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: RecordingMemoryRepository(),
        entitlementProvider: provider,
      );

      final result = await service.previewMessage(
        userMessage: 'سلام',
        context: baseContext(),
        metadata: <String, Object?>{
          'coachEntitlementSnapshot': provider.snapshot,
        },
      );

      expect(provider.snapshotCallCount, greaterThan(0));
      expect(provider.usageMutated, isFalse);
      final entitlementTrace =
          result.pipelineTrace?.traceFor(CoachPipelineStage.entitlement);
      expect(entitlementTrace, isNotNull);
      expect(entitlementTrace!.success, isTrue);
    });

    test('Preview executes Local Skill', () async {
      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: RecordingMemoryRepository(),
      );

      final result = await service.previewMessage(
        userMessage: 'تمرین امروز چیه؟',
        context: baseContext(
          intent: AIIntent.workoutToday,
          question: 'تمرین امروز چیه؟',
          activeProgram: const <String, Object?>{
            'programId': 'program_1',
            'name': 'Hypertrophy Block',
            'todaySession': 'Upper Body',
          },
          equipment: const <String>['دمبل', 'هالتر'],
          weeklyHeatmap: const WeeklyMuscleHeatmapResult(
            targets: <String, int>{'chest': 4},
            previousWeekTargets: <String, int>{},
            workoutDays: 3,
            sessionCount: 3,
            previousSessionCount: 2,
            hasHeatmapData: true,
            hasPreviousWeekData: false,
          ),
        ),
      );

      expect(result.isLocalResponse, isTrue);
      expect(result.skillExecutionResult, isNotNull);
      expect(result.skillExecutionResult!.handledLocally, isTrue);
      expect(result.skillExecutionResult!.skillId, 'workout_today_skill');
    });

    test('Preview builds PromptPlan', () async {
      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: RecordingMemoryRepository(),
      );

      final result = await service.previewMessage(
        userMessage: 'درباره اصول تمرین توضیح بده',
        context: baseContext(question: 'درباره اصول تمرین توضیح بده'),
      );

      expect(result.isLocalResponse, isFalse);
      expect(result.responsePlan.requiresAI, isTrue);
      final planningTrace =
          result.pipelineTrace?.traceFor(CoachPipelineStage.promptPlanning);
      expect(planningTrace, isNotNull);
      expect(planningTrace!.skipped, isFalse);
      expect(planningTrace.success, isTrue);
    });

    test('Preview generates PipelineTrace', () async {
      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: RecordingMemoryRepository(),
      );

      final result = await service.previewMessage(
        userMessage: 'سلام',
        context: baseContext(),
      );

      final trace = result.pipelineTrace!;
      expect(trace.mode, CoachPipelineMode.preview);
      expect(trace.totalDuration, greaterThan(Duration.zero));
      expect(trace.stages.any((stage) => stage.reason != null), isTrue);
      expect(
        trace.stages.any((stage) => stage.confidence != null),
        isTrue,
      );
    });

    test('Runtime unchanged', () async {
      if (!CoachV2Config.coachV2Enabled) {
        return;
      }

      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: RecordingMemoryRepository(),
      );

      final result = await service.processMessage(
        userId: 'runtime_user',
        userMessage: 'سلام',
        metadata: const <String, Object?>{},
      );

      expect(result.pipelineMode, CoachPipelineMode.runtime);
      expect(result.pipelineTrace, isNotNull);
      expect(result.pipelineTrace!.mode, CoachPipelineMode.runtime);
    });

    test('Flag OFF rejects processMessage', () async {
      if (CoachV2Config.coachV2Enabled) {
        return;
      }

      final service = buildService(
        stateRepository: RecordingCoachStateRepository(),
        memoryRepository: RecordingMemoryRepository(),
      );

      expect(
        () => service.processMessage(
          userId: 'legacy_user',
          userMessage: 'سلام',
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

class RecordingCoachStateRepository extends CoachStateRepository {
  int saveCount = 0;

  @override
  Future<void> saveState(CoachConversationState state) async {
    saveCount++;
    await super.saveState(state);
  }
}

class RecordingMemoryRepository extends MemoryRepository {
  int saveCount = 0;

  @override
  Future<void> saveMemories(
    String userId,
    List<CoachMemory> memories,
  ) async {
    saveCount++;
    await super.saveMemories(userId, memories);
  }
}

class RecordingEntitlementProvider extends CoachEntitlementProvider {
  RecordingEntitlementProvider({required this.snapshot});

  final CoachEntitlementSnapshot snapshot;
  int snapshotCallCount = 0;
  bool usageMutated = false;

  @override
  Future<CoachEntitlementSnapshot> snapshotFor({
    required String userId,
    required CoachContext context,
    required Map<String, Object?> metadata,
  }) async {
    snapshotCallCount++;
    return snapshot;
  }
}
