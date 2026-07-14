import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/coach/coach_reason.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/planner/coach_response_plan.dart';
import 'package:gymaipro/ai/planner/response_priority.dart';
import 'package:gymaipro/ai/planner/response_step.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_completion_service.dart';

void main() {
  test('CoachChatCompletionService greets locally for سلام', () async {
    final service = CoachChatCompletionService();
    final result = _integrationResult(
      shouldCallAI: false,
      profile: const <String, Object?>{'first_name': 'وحید'},
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'سلام',
    );

    expect(text, contains('سلام وحید'));
  });

  test('CoachChatCompletionService filters technical knowledge notes', () async {
    final service = CoachChatCompletionService();
    final result = _integrationResult(
      shouldCallAI: false,
      knowledgeReasons: const <String>[
        'No knowledge node met the minimum ranking threshold',
      ],
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'چطوری؟',
    );

    expect(text, isNot(contains('knowledge node')));
  });

  test('CoachChatCompletionService falls back when skill message is technical', () async {
    final service = CoachChatCompletionService();
    final result = _integrationResult(
      shouldCallAI: false,
      isLocalResponse: true,
      skillMessage: 'No knowledge node met the minimum ranking threshold',
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'سلام',
    );

    expect(text, contains('سلام'));
    expect(text, isNot(contains('knowledge node')));
  });
}

CoachIntegrationResult _integrationResult({
  required bool shouldCallAI,
  Map<String, Object?> profile = const <String, Object?>{},
  List<String> knowledgeReasons = const <String>[],
  bool isLocalResponse = false,
  String? skillMessage,
}) {
  final decision = CoachDecision(
    shouldCallAI: shouldCallAI,
    localResponse: shouldCallAI ? null : null,
    missingData: const <String>[],
    requiredProviders: const <AIContextProviderKey>{},
    missingProviders: const <AIContextProviderKey>{},
    decisionReason: const <CoachReason>{CoachReason.localAnswer},
    confidence: 0.5,
    notes: const <String>[],
    knowledgeReasons: knowledgeReasons,
  );
  final responsePlan = CoachResponsePlan(
    id: 'test_plan',
    intent: AIIntent.generalChat,
    action: shouldCallAI ? CoachAction.callOpenAI : CoachAction.localResponse,
    requiresAI: shouldCallAI,
    requiredProviders: const <AIContextProviderKey>{},
    missingProviders: const <AIContextProviderKey>{},
    followUpQuestions: const <String>[],
    contextKeys: const <AIContextProviderKey>{},
    confidence: 0.5,
    estimatedTokens: 0,
    estimatedCost: 0,
    estimatedLatency: Duration.zero,
    notes: const <String>[],
    steps: const <ResponseStep>[
      ResponseStep(
        id: 'route',
        action: CoachAction.localResponse,
        priority: ResponsePriority.high,
        description: 'test',
      ),
    ],
  );
  return CoachIntegrationResult(
    intent: AIIntent.generalChat,
    coachContext: CoachContext(
      intent: AIIntent.generalChat,
      profile: profile,
      metadata: CoachContextMetadata(
        buildTime: DateTime(2026, 7, 13),
        sourceCount: 1,
        missingProviders: const {},
        confidence: 0.9,
        contextVersion: CoachContext.contextVersion,
      ),
    ),
    decision: decision,
    responsePlan: responsePlan,
    executorPreview: CoachExecutionPreview(
      plan: responsePlan,
      target: CoachExecutionTarget.local,
      wouldExecute: false,
      description: 'test',
    ),
    processingTime: Duration.zero,
    missingProviders: const <AIContextProviderKey>{},
    missingData: const <String>[],
    confidence: 0.5,
    estimatedCost: 0,
    estimatedTokens: 0,
    estimatedLatency: Duration.zero,
    logs: const [],
    isLocalResponse: isLocalResponse,
    skillExecutionResult: skillMessage == null
        ? null
        : CoachSkillExecutionResult(
            skillId: 'test_skill',
            response: CoachSkillResponse(
              confidence: 0.9,
              requiresAI: false,
              message: skillMessage,
            ),
            executionTime: Duration.zero,
            success: true,
          ),
  );
}
