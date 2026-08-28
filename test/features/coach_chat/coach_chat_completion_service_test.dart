import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/coach/coach_reason.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/planner/coach_executor.dart';
import 'package:gymaipro/ai/planner/coach_response_plan.dart';
import 'package:gymaipro/ai/planner/response_priority.dart';
import 'package:gymaipro/ai/planner/response_step.dart';
import 'package:gymaipro/ai/prompt/prompt_budget.dart';
import 'package:gymaipro/ai/prompt/prompt_metadata.dart';
import 'package:gymaipro/ai/prompt/prompt_package.dart';
import 'package:gymaipro/ai/prompt/prompt_personality.dart';
import 'package:gymaipro/ai/prompt/prompt_section.dart';
import 'package:gymaipro/ai/prompt/prompt_version.dart';
import 'package:gymaipro/ai/services/openai_coach_turn.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_execution_result.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/ai/tools/coach_chat_tool_definitions.dart';
import 'package:gymaipro/ai/tools/coach_chat_tool_executor.dart';
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

  test('CoachChatCompletionService localizes entitlement upgrade message', () async {
    final service = CoachChatCompletionService();
    final result = _integrationResult(
      shouldCallAI: false,
      status: CoachDecisionStatus.upgradeRequired,
      localResponse: 'Upgrade to coach_pro to use this coach capability.',
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'تحلیل کامل پیشرفتم رو بگو',
    );

    expect(text, contains('قابلیت‌های پیشرفتهٔ مربی'));
    expect(text, isNot(contains('coach_pro')));
  });

  test('blocked entitlement never calls OpenAI', () async {
    var called = false;
    final service = CoachChatCompletionService(
      coachTurn: _SpyCoachTurn(() => called = true),
    );
    final result = _integrationResult(
      shouldCallAI: false,
      status: CoachDecisionStatus.upgradeRequired,
      localResponse: 'Upgrade to coach_pro to use this coach capability.',
      withPromptPackage: true,
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'پیشرفتم رو تحلیل کن',
      intent: AIIntent.progressAnalysis,
    );

    expect(called, isFalse);
    expect(text, contains('قابلیت‌های پیشرفتهٔ مربی'));
  });

  test('weight-trend questions are not BMI short-circuited', () async {
    final service = CoachChatCompletionService(
      coachTurn: _SpyCoachTurn(() {}),
    );
    final result = _integrationResult(
      shouldCallAI: true,
      withPromptPackage: true,
      intent: AIIntent.progressAnalysis,
      profile: const <String, Object?>{
        'height_cm': 181,
        'weight_kg': 90,
        'bmi': 27.5,
      },
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'روند وزنم چطوره؟',
      intent: AIIntent.progressAnalysis,
    );

    expect(text.contains('اضافه وزن'), isFalse);
    expect(text.toLowerCase().contains('bmi'), isFalse);
  });

  test('CoachChatCompletionService blocks explicit program requests', () async {
    final service = CoachChatCompletionService();
    final result = _integrationResult(shouldCallAI: false);

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'برای من یک برنامه تمرینی بساز',
    );

    expect(text, contains('مربیان'));
  });

  test('CoachChatCompletionService returns follow-up when data is missing', () async {
    final service = CoachChatCompletionService();
    final result = _integrationResult(
      shouldCallAI: true,
      followUpQuestion: 'برای ساخت برنامه دقیق، سنت چند سال است؟',
      missingData: const <String>['age', 'height'],
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'شونه‌هام ضعیفه، چی کار کنم؟',
    );

    expect(text, contains('سنت چند سال'));
  });

  test('nutrition-today answers from engine, never invents fetch failure', () async {
    var openAiCalled = false;
    final service = CoachChatCompletionService(
      coachTurn: _SpyCoachTurn(() => openAiCalled = true),
      toolExecutor: _FakeNutritionToolExecutor(),
    );
    final result = _integrationResult(
      shouldCallAI: true,
      withPromptPackage: true,
      intent: AIIntent.nutrition,
      isLocalResponse: true,
      skillMessage: 'متاسفانه نتونستم اطلاعات تغذیه رو بگیرم',
      nutrition: const <String, Object?>{
        'summary_fa':
            'هدف کالری روزانه‌ات 2200 است (برای حفظ وزن فعلی حدود 2500 لازم داری)؛ پروتئین هدف حدود 160 گرم.',
        'daily_targets': <String, Object?>{
          'calories_kcal': 2200,
          'protein_g': 160,
          'maintenance_kcal': 2500,
          'has_active_goal': true,
        },
      },
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'امروز از نظر کالری و پروتئین کجام؟',
      intent: AIIntent.nutrition,
    );

    expect(openAiCalled, isFalse);
    expect(text, isNot(contains('نتونستم')));
    expect(text, contains('2200'));
    expect(text, contains('هدف کالری'));
    expect(text, contains('تا هدف'));
  });

  test('nutrition-today without goal does not invent هدف for TDEE', () async {
    var openAiCalled = false;
    final service = CoachChatCompletionService(
      coachTurn: _SpyCoachTurn(() => openAiCalled = true),
      toolExecutor: _FakeNutritionToolExecutor(hasActiveGoal: false),
    );
    final result = _integrationResult(
      shouldCallAI: true,
      withPromptPackage: true,
      intent: AIIntent.nutrition,
      nutrition: const <String, Object?>{},
    );

    final text = await service.resolveResponse(
      result: result,
      userMessage: 'امروز از نظر کالری و پروتئین کجام؟',
      intent: AIIntent.nutrition,
    );

    expect(openAiCalled, isFalse);
    expect(text, contains('نیاز'));
    expect(text, contains('حفظ وزن'));
    expect(text.contains('هدف کالری روزانه‌ات'), isFalse);
    expect(text, contains('هنوز هدف کالری'));
    expect(text.contains('نگهداری'), isFalse);
  });
}

CoachIntegrationResult _integrationResult({
  required bool shouldCallAI,
  Map<String, Object?> profile = const <String, Object?>{},
  Map<String, Object?> nutrition = const <String, Object?>{},
  List<String> knowledgeReasons = const <String>[],
  bool isLocalResponse = false,
  String? skillMessage,
  CoachDecisionStatus status = CoachDecisionStatus.allowed,
  String? localResponse,
  String? followUpQuestion,
  List<String> missingData = const <String>[],
  bool withPromptPackage = false,
  AIIntent intent = AIIntent.generalChat,
}) {
  final decision = CoachDecision(
    shouldCallAI: shouldCallAI,
    localResponse: localResponse,
    followUpQuestion: followUpQuestion,
    missingData: missingData,
    requiredProviders: const <AIContextProviderKey>{},
    missingProviders: const <AIContextProviderKey>{},
    decisionReason: const <CoachReason>{CoachReason.localAnswer},
    confidence: 0.5,
    notes: const <String>[],
    knowledgeReasons: knowledgeReasons,
    status: status,
  );
  final responsePlan = CoachResponsePlan(
    id: 'test_plan',
    intent: intent,
    action: shouldCallAI ? CoachAction.callOpenAI : CoachAction.localResponse,
    requiresAI: shouldCallAI,
    requiredProviders: const <AIContextProviderKey>{},
    missingProviders: const <AIContextProviderKey>{},
    followUpQuestions: <String>[
      if (followUpQuestion != null) followUpQuestion,
    ],
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
    intent: intent,
    coachContext: CoachContext(
      intent: intent,
      profile: profile,
      nutrition: nutrition,
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
    missingData: missingData,
    confidence: 0.5,
    estimatedCost: 0,
    estimatedTokens: 0,
    estimatedLatency: Duration.zero,
    logs: const [],
    isLocalResponse: isLocalResponse,
    promptPackage: withPromptPackage
        ? PromptPackage(
            id: 'test_pkg',
            intent: intent,
            sections: const <PromptSection>[],
            budget: PromptBudget.standard,
            personality: PromptPersonality.gymAiCoach,
            version: PromptVersion.v1,
            metadata: PromptMetadata(
              intent: intent,
              createdAt: DateTime(2026, 7, 13),
              version: PromptVersion.v1,
              sectionCount: 0,
              estimatedTokens: 10,
              estimatedCost: 0,
              requiresAI: true,
              knowledgeNodeId: 'test',
            ),
            contextKeys: const <AIContextProviderKey>{},
            memoryKeys: const <String>[],
          )
        : null,
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

class _SpyCoachTurn extends OpenAiCoachTurn {
  _SpyCoachTurn(this.onRun);

  final void Function() onRun;

  @override
  Stream<String> run({
    required String userId,
    required List<ChatMessage> messages,
    required String systemPrompt,
    bool enableTools = true,
  }) async* {
    onRun();
    yield 'should_not_appear';
  }
}

class _FakeNutritionToolExecutor extends CoachChatToolExecutor {
  _FakeNutritionToolExecutor({this.hasActiveGoal = true});

  final bool hasActiveGoal;

  @override
  Future<String> execute({
    required String name,
    required String userId,
    Map<String, Object?> arguments = const <String, Object?>{},
  }) async {
    if (name != 'get_nutrition_today') {
      return CoachChatToolDefinitions.encodeToolResult(<String, Object?>{
        'ok': false,
        'error': 'unexpected_tool',
      });
    }
    if (!hasActiveGoal) {
      return CoachChatToolDefinitions.encodeToolResult(<String, Object?>{
        'ok': true,
        'daily_targets': <String, Object?>{
          'calories_kcal': 2500,
          'protein_g': 180,
          'maintenance_kcal': 2500,
          'has_active_goal': false,
        },
        'today': <String, Object?>{'logged': false},
        'summary_fa':
            'نیاز تقریبی روزانه‌ات برای حفظ وزن حدود 2500 کالری است '
            'و هنوز هدف کالری جدا نگذاشتی؛ پروتئین پیشنهادی حدود 180 گرم؛ '
            'امروز هنوز غذایی ثبت نشده.',
      });
    }
    return CoachChatToolDefinitions.encodeToolResult(<String, Object?>{
      'ok': true,
      'daily_targets': <String, Object?>{
        'calories_kcal': 2200,
        'protein_g': 165,
        'maintenance_kcal': 2500,
        'has_active_goal': true,
        'goal_kcal': 2200,
      },
      'today': <String, Object?>{
        'logged': true,
        'consumed': <String, Object?>{
          'calories_kcal': 1400,
          'protein_g': 95,
        },
      },
      'remaining': <String, Object?>{
        'calories_kcal': 800,
        'protein_g': 70,
      },
      'summary_fa':
          'هدف کالری روزانه‌ات 2200 است (برای حفظ وزن فعلی حدود 2500 لازم داری)؛ '
          'امروز تا الان 1400 کالری و 95 گرم پروتئین ثبت شده؛ '
          'حدود 800 کالری و 70 گرم پروتئین تا هدف مانده.',
    });
  }
}
