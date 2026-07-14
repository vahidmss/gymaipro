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
import 'package:gymaipro/features/coach_chat/application/coach_chat_facade.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_storage_service.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoachChatStorageService', () {
    test('round-trips messages for a user', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = CoachChatStorageService();
      const userId = 'user_123';
      final messages = <CoachChatMessage>[
        CoachChatMessage(
          id: 'user_1',
          role: CoachChatMessageRole.user,
          type: CoachChatMessageType.normal,
          text: 'سلام',
          createdAt: DateTime(2026, 7, 13, 12),
        ),
        CoachChatMessage(
          id: 'coach_1',
          role: CoachChatMessageRole.coach,
          type: CoachChatMessageType.aiResponse,
          text: 'سلام! چطور می‌تونم کمکت کنم؟',
          createdAt: DateTime(2026, 7, 13, 12, 1),
          cards: const <CoachChatMessageCard>[
            CoachChatMessageCard(
              type: CoachChatCardType.coachNotes,
              title: 'یادداشت مربی',
              items: <String>['ریکاوری مناسب است.'],
            ),
          ],
        ),
      ];

      await storage.saveMessages(userId, messages);
      final loaded = await storage.loadMessages(userId);

      expect(loaded.length, 2);
      expect(loaded.first.text, 'سلام');
      expect(loaded.last.cards.single.items, ['ریکاوری مناسب است.']);
    });
  });

  test('CoachChatFacade hides technical pipeline cards', () async {
    final facade = CoachChatFacade(
      coachLoader: ({
        required userMessage,
        userId = '',
        context,
        metadata = const <String, Object?>{},
      }) async {
        return _technicalIntegrationResult();
      },
      programResolver: CoachProgramResolver(programLoader: (_) async => null),
    );

    final response = await facade.map(
      _technicalIntegrationResult(),
      prompt: 'سلام',
      resolvedText: 'سلام! امروز چطور می‌تونم کمکت کنم؟',
    );

    expect(response.message.text, contains('سلام'));
    expect(
      response.message.cards.where(
        (card) => card.type == CoachChatCardType.knowledgeInsight,
      ),
      isEmpty,
    );
    expect(
      response.message.cards.where(
        (card) => card.type == CoachChatCardType.coachNotes,
      ),
      isEmpty,
    );
  });
}

CoachIntegrationResult _technicalIntegrationResult() {
  final decision = CoachDecision(
    shouldCallAI: true,
    missingData: const <String>[],
    requiredProviders: const <AIContextProviderKey>{},
    missingProviders: const <AIContextProviderKey>{},
    decisionReason: const <CoachReason>{CoachReason.openAIRequired},
    confidence: 0.5,
    notes: const <String>['intent matched generalChat'],
    knowledgeReasons: const <String>[
      'No knowledge node met the minimum ranking threshold.',
    ],
  );
  final responsePlan = CoachResponsePlan(
    id: 'test_plan',
    intent: AIIntent.generalChat,
    action: CoachAction.callOpenAI,
    requiresAI: true,
    requiredProviders: const <AIContextProviderKey>{},
    missingProviders: const <AIContextProviderKey>{},
    followUpQuestions: const <String>[],
    contextKeys: const <AIContextProviderKey>{},
    confidence: 0.5,
    estimatedTokens: 0,
    estimatedCost: 0,
    estimatedLatency: Duration.zero,
    notes: const <String>['pipeline started'],
    steps: const <ResponseStep>[
      ResponseStep(
        id: 'route',
        action: CoachAction.callOpenAI,
        priority: ResponsePriority.high,
        description: 'test',
      ),
    ],
  );
  return CoachIntegrationResult(
    intent: AIIntent.generalChat,
    coachContext: CoachContext(
      intent: AIIntent.generalChat,
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
  );
}
