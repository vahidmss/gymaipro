import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/coach/coach_brain.dart';
import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_entitlement.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_registry.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_trace.dart';

void main() {
  final metadata = CoachContextMetadata(
    buildTime: DateTime(2026, 7, 12),
    sourceCount: 1,
    missingProviders: const {},
    confidence: 0.8,
    contextVersion: CoachContext.contextVersion,
  );

  CoachContext context({AIIntent intent = AIIntent.generalChat}) {
    return CoachContext(
      intent: intent,
      metadata: metadata,
      currentQuestion: 'Can you help me train today?',
    );
  }

  CoachKnowledgeResult knowledge(String nodeId) {
    final node = KnowledgeRegistry.nodes[nodeId]!;
    return CoachKnowledgeResult(
      selectedNode: node,
      candidateNodes: <KnowledgeNode>[node],
      confidence: 0.82,
      reasons: <String>['Selected $nodeId for test.'],
      trace: CoachKnowledgeTrace(
        nodeTraces: const <CoachKnowledgeNodeTrace>[],
        executionTime: const Duration(milliseconds: 1),
        selectedNodeId: node.id,
        usedFallback: false,
      ),
    );
  }

  CoachEntitlement entitlement({
    CoachSubscriptionPlan plan = CoachSubscriptionPlan.free,
    Set<CoachCapability> disabled = const <CoachCapability>{},
    EntitlementUsageSnapshot usage = const EntitlementUsageSnapshot(),
  }) {
    return CoachEntitlement(
      userId: 'user_1',
      plan: plan,
      disabledCapabilities: disabled,
      usage: usage,
    );
  }

  group('CoachBrain knowledge decisions', () {
    test('knowledge drives selected decision metadata', () {
      final knowledgeResult = knowledge('general_chat');
      final decision = const CoachBrain().decide(
        context: context(),
        knowledgeResult: knowledgeResult,
      );

      expect(decision.status, CoachDecisionStatus.allowed);
      expect(decision.selectedKnowledgeId, 'general_chat');
      expect(decision.knowledgeConfidence, 0.82);
      expect(decision.knowledgeReasons, isNotEmpty);
      expect(decision.shouldCallAI, isTrue);
    });
  });

  group('CoachEntitlementRuntime', () {
    const runtime = CoachEntitlementRuntime();

    test('returns null when Coach v2 flag is disabled', () async {
      if (CoachV2Config.coachV2Enabled) return;

      final result = await runtime.resolve(
        userId: 'user_1',
        coachContext: context(),
        knowledgeResult: knowledge('general_chat'),
      );

      expect(result, isNull);
    });

    test('allows granted capabilities', () async {
      if (!CoachV2Config.coachV2Enabled) return;

      final result = await runtime.resolve(
        userId: 'user_1',
        coachContext: context(),
        knowledgeResult: knowledge('general_chat'),
        metadata: <String, Object?>{
          'coachEntitlement': entitlement(),
        },
      );

      expect(result, isNotNull);
      expect(result!.allowed, isTrue);
      expect(result.status, CoachDecisionStatus.allowed);
      expect(
        result.checkedCapabilities,
        contains(CoachCapability.coachConversation),
      );
    });

    test('blocks premium workout generation for free plan', () async {
      if (!CoachV2Config.coachV2Enabled) return;

      final result = await runtime.resolve(
        userId: 'user_1',
        coachContext: context(intent: AIIntent.workoutGeneration),
        knowledgeResult: knowledge('workout_generation'),
        metadata: <String, Object?>{
          'coachEntitlement': entitlement(),
        },
      );

      expect(result, isNotNull);
      expect(result!.allowed, isFalse);
      expect(result.status, CoachDecisionStatus.upgradeRequired);
      expect(result.missingCapabilities, contains(CoachCapability.generateWorkout));
      expect(result.upgradeSuggestion, contains('Upgrade'));
    });

    test('blocks when usage is exhausted', () async {
      if (!CoachV2Config.coachV2Enabled) return;

      final result = await runtime.resolve(
        userId: 'user_1',
        coachContext: context(),
        knowledgeResult: knowledge('general_chat'),
        metadata: <String, Object?>{
          'coachEntitlement': entitlement(
            usage: const EntitlementUsageSnapshot(
              dailyUsage: <CoachCapability, int>{
                CoachCapability.coachConversation: 10,
              },
            ),
          ),
        },
      );

      expect(result, isNotNull);
      expect(result!.allowed, isFalse);
      expect(result.status, CoachDecisionStatus.usageExceeded);
      expect(result.remainingUsage['coachConversation.daily'], 0);
    });

    test('blocks disabled capabilities', () async {
      if (!CoachV2Config.coachV2Enabled) return;

      final result = await runtime.resolve(
        userId: 'user_1',
        coachContext: context(),
        knowledgeResult: knowledge('general_chat'),
        metadata: <String, Object?>{
          'coachEntitlement': entitlement(
            disabled: const <CoachCapability>{
              CoachCapability.coachConversation,
            },
          ),
        },
      );

      expect(result, isNotNull);
      expect(result!.allowed, isFalse);
      expect(result.status, CoachDecisionStatus.featureDisabled);
    });

    test('generates entitlement trace', () async {
      if (!CoachV2Config.coachV2Enabled) return;

      final result = await runtime.resolve(
        userId: 'user_1',
        coachContext: context(),
        knowledgeResult: knowledge('general_chat'),
        metadata: <String, Object?>{
          'coachEntitlement': entitlement(),
        },
      );

      expect(result, isNotNull);
      expect(result!.trace.checkedCapabilities, isNotEmpty);
      expect(result.trace.remainingUsage, contains('coachConversation.daily'));
      expect(result.trace.executionTime, isNot(Duration.zero));
    });
  });
}
