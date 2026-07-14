import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/intent/intent_intelligence_engine.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_result.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';
import 'package:gymaipro/features/coach/application/coach_preview_seed_loader.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_completion_service.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_facade_result.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/coach_chat/state/coach_chat_state.dart';
import 'package:gymaipro/features/product_experience/coach_experience_runtime_bridge.dart';
import 'package:gymaipro/features/product_experience/coach_feature_integration.dart';
import 'package:gymaipro/features/product_experience/coach_program_resolver.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_storage_service.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/utils/auth_helper.dart';

@Deprecated('Use CoachFeatureLoader')
typedef CoachChatPreviewLoader = CoachFeatureLoader;

class CoachChatFacade {
  CoachChatFacade({
    CoachFeatureLoader? coachLoader,
    @Deprecated('Use coachLoader') CoachFeatureLoader? previewLoader,
    CoachPreviewSeedProvider? seedLoader,
    IntentIntelligenceEngine? intentEngine,
    CoachProgramResolver? programResolver,
    CoachExperienceRuntimeBridge? runtimeBridge,
    CoachChatCompletionService? completionService,
    CoachChatStorageService? storageService,
  }) : _coachLoader =
           coachLoader ??
           previewLoader ??
           CoachFeatureIntegration.defaultLoader(),
       _seedLoader = seedLoader,
       _intentEngine = intentEngine ?? IntentIntelligenceEngine(),
       _programResolver = programResolver ?? CoachProgramResolver(),
       _runtimeBridge = runtimeBridge ?? const CoachExperienceRuntimeBridge(),
       _completionService =
           completionService ?? CoachChatCompletionService(),
       _storageService = storageService ?? CoachChatStorageService();

  final CoachFeatureLoader _coachLoader;
  final CoachPreviewSeedProvider? _seedLoader;
  final IntentIntelligenceEngine _intentEngine;
  final CoachProgramResolver _programResolver;
  final CoachExperienceRuntimeBridge _runtimeBridge;
  final CoachChatCompletionService _completionService;
  final CoachChatStorageService _storageService;

  Future<CoachChatFacadeResult> load() async {
    final userId = _safeUserId();
    if (userId == null) {
      return const CoachChatFacadeResult(
        state: CoachChatState.empty(),
      );
    }

    final messages = await _storageService.loadMessages(userId);
    if (messages.isEmpty) {
      return const CoachChatFacadeResult(
        state: CoachChatState.empty(),
      );
    }

    return CoachChatFacadeResult(
      state: CoachChatState(
        status: CoachChatStatus.loaded,
        messages: messages,
      ),
    );
  }

  Future<void> persistMessages(List<CoachChatMessage> messages) async {
    final userId = _safeUserId();
    if (userId == null) return;
    await _storageService.saveMessages(userId, messages);
  }

  Future<CoachChatPreviewResponse> send(
    String prompt, {
    List<ChatMessage> history = const <ChatMessage>[],
  }) async {
    final intent = _intentEngine
        .detect(IntentDetectionRequest(message: prompt))
        .primaryIntent;
    final seed = await (_seedLoader ?? CoachPreviewSeedLoader()).load(
      intent: intent,
      message: prompt,
    );
    final result = await _coachLoader(
      userMessage: prompt,
      userId: seed.userId,
      context: seed.context,
      metadata: const <String, Object?>{'feature': 'coach_chat'},
    );
    final text = await _completionService.resolveResponse(
      result: result,
      userMessage: prompt,
      history: history,
    );
    return map(
      result,
      prompt: prompt,
      intent: intent,
      resolvedText: text,
    );
  }

  Future<CoachChatPreviewResponse> map(
    CoachIntegrationResult result, {
    required String prompt,
    AIIntent? intent,
    String? resolvedText,
  }) async {
    final resolvedIntent = intent ?? result.intent;
    final response = result.skillExecutionResult?.response;
    final text = resolvedText ??
        response?.message ??
        result.responsePlan.localMessage ??
        result.decision.localResponse ??
        result.decision.followUpQuestion ??
        'پاسخی از موتور مربی دریافت نشد.';

    final resolved = await _programResolver.resolve(result: result);
    final review = resolvedIntent == AIIntent.progressAnalysis
        ? _runtimeBridge.reviewProgram(
            program: resolved?.aiProgram,
            context: result.coachContext,
          )
        : null;
    final modification = resolvedIntent == AIIntent.workoutModification
        ? _runtimeBridge.modifyProgram(
            program: resolved?.aiProgram,
            context: result.coachContext,
            modifications: prompt.contains('جایگزین')
                ? const <WorkoutModificationType>[
                    WorkoutModificationType.replaceExercise,
                  ]
                : const <WorkoutModificationType>[
                    WorkoutModificationType.recoveryAdaptation,
                  ],
          )
        : null;

    final cards = _buildCards(
      result: result,
      response: response,
      resolvedIntent: resolvedIntent,
      prompt: prompt,
      review: review,
      modification: modification,
    );

    return CoachChatPreviewResponse(
      message: CoachChatMessage(
        id: 'coach_${DateTime.now().microsecondsSinceEpoch}',
        role: CoachChatMessageRole.coach,
        type: result.isLocalResponse
            ? CoachChatMessageType.localSkillResponse
            : result.responsePlan.requiresAI
            ? CoachChatMessageType.aiResponse
            : CoachChatMessageType.normal,
        text: text.trim().isEmpty
            ? 'پاسخی از موتور مربی دریافت نشد.'
            : (resolvedText != null ? text : ProductExperienceFormatter.humanizeReason(text)),
        createdAt: DateTime.now(),
        cards: cards,
      ),
      thinkingSteps: ProductExperienceFormatter.thinkingSteps(result),
    );
  }

  List<CoachChatMessageCard> _buildCards({
    required CoachIntegrationResult result,
    required CoachSkillResponse? response,
    required AIIntent resolvedIntent,
    required String prompt,
    required WorkoutReviewResult? review,
    required WorkoutModificationResult? modification,
  }) {
    final coachNotes = ProductExperienceFormatter.coachNotes(result);
    final trainingInsights = ProductExperienceFormatter.insights(
      result.coachContext,
      result,
    );

    return <CoachChatMessageCard>[
      ...<CoachChatMessageCard?>[
        if (response?.explanation != null)
          _card(
            type: CoachChatCardType.explanation,
            title: ProductExperienceFormatter.localizeCardTitle(
              response!.explanation!.summary,
            ),
            items: response.explanation!.bullets,
          ),
        if ((response?.reasons ?? const []).isNotEmpty)
          _card(
            type: CoachChatCardType.reason,
            title: ProductExperienceFormatter.localizeCardTitle('Reasons'),
            items: response!.reasons.map((reason) => reason.message).toList(),
          ),
        if ((response?.warnings ?? const []).isNotEmpty)
          _card(
            type: CoachChatCardType.warning,
            title: ProductExperienceFormatter.localizeCardTitle('Warnings'),
            items: response!.warnings,
          ),
        if ((response?.recommendations ?? const []).isNotEmpty)
          _card(
            type: CoachChatCardType.recommendation,
            title: ProductExperienceFormatter.localizeCardTitle(
              'Recommendations',
            ),
            items: response!.recommendations
                .map((item) => '${item.title}: ${item.detail}')
                .toList(),
          ),
        if ((response?.nextActions ?? const []).isNotEmpty)
          _card(
            type: CoachChatCardType.nextAction,
            title: ProductExperienceFormatter.localizeCardTitle('Next Actions'),
            items: response!.nextActions,
          ),
        if (coachNotes.isNotEmpty)
          _card(
            type: CoachChatCardType.coachNotes,
            title: ProductExperienceFormatter.localizeCardTitle('Coach Notes'),
            items: coachNotes,
          ),
        if (trainingInsights.isNotEmpty)
          _card(
            type: CoachChatCardType.knowledgeInsight,
            title: ProductExperienceFormatter.localizeCardTitle(
              'Knowledge Insight',
            ),
            items: trainingInsights,
          ),
        if (result.responsePlan.followUpQuestions.isNotEmpty)
          _card(
            type: CoachChatCardType.followUpQuestion,
            title: ProductExperienceFormatter.localizeCardTitle(
              'Follow-up Question',
            ),
            items: result.responsePlan.followUpQuestions,
          ),
      ].whereType<CoachChatMessageCard>(),
      if (review != null && review.enabled)
        CoachChatMessageCard(
          type: CoachChatCardType.reviewResult,
          title: ProductCopy.whyThisSuggestion,
          items: ProductExperienceFormatter.reviewSummaryLines(review),
        ),
      if (modification != null && modification.enabled)
        CoachChatMessageCard(
          type: CoachChatCardType.modificationPreview,
          title: ProductCopy.coachOpinion,
          items: _runtimeBridge.formatModification(modification),
        ),
    ].where((card) => card.items.isNotEmpty).toList(growable: false);
  }

  CoachChatMessageCard? _card({
    required CoachChatCardType type,
    required String title,
    required List<String> items,
  }) {
    final visible = _displayItems(items);
    if (visible.isEmpty) return null;
    return CoachChatMessageCard(type: type, title: title, items: visible);
  }

  List<String> _displayItems(List<String> items) {
    return items
        .map(ProductExperienceFormatter.humanizeReason)
        .where((item) => item.trim().isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  String? _safeUserId() {
    try {
      final userId = AuthHelper.currentUserIdSync;
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } on Object {
      return null;
    }
  }
}
