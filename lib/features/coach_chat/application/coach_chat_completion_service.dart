import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/prompt/prompt_package_renderer.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/features/coach_chat/application/coach_chat_program_policy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Resolves the final coach chat text — local skill, local decision, or OpenAI.
class CoachChatCompletionService {
  CoachChatCompletionService({OpenAIService? openAIService})
    : _openAIService = openAIService ?? OpenAIService();

  final OpenAIService _openAIService;

  Future<String> resolveResponse({
    required CoachIntegrationResult result,
    required String userMessage,
    List<ChatMessage> history = const <ChatMessage>[],
    AIIntent? intent,
  }) async {
    if (CoachChatProgramPolicy.shouldBlockChatProgramDelivery(
      intent: intent ?? result.intent,
      knowledgeId: result.decision.selectedKnowledgeId,
      userMessage: userMessage,
    )) {
      return CoachChatProgramPolicy.redirectMessage;
    }

    final skillMessage = result.skillExecutionResult?.response.message?.trim();
    if (result.isLocalResponse &&
        skillMessage != null &&
        skillMessage.isNotEmpty) {
      final localized = ProductExperienceFormatter.humanizeReason(skillMessage);
      if (localized.isNotEmpty) return localized;
    }

    final localText = _pickLocalText(result);

    final needsGuidedFollowUp = result.decision.requiresFollowUp ||
        result.decision.missingData.isNotEmpty ||
        (result.conversationState?.pendingQuestions.isNotEmpty ?? false);
    if (needsGuidedFollowUp &&
        localText != null &&
        localText.trim().isNotEmpty) {
      return localText;
    }

    if (result.decision.shouldCallAI) {
      final promptPackage = result.promptPackage;
      if (promptPackage == null) {
        return localText ?? _genericFallback(result, userMessage);
      }

      try {
        final systemPrompt = PromptPackageRenderer.render(promptPackage);
        final recentHistory = history
            .where(
              (message) =>
                  !message.isTyping && message.content.trim().isNotEmpty,
            )
            .toList(growable: false);
        final trimmedHistory = recentHistory.length <= 8
            ? recentHistory
            : recentHistory.sublist(recentHistory.length - 8);

        final aiResponse = await _openAIService.sendMessage(
          messages: <ChatMessage>[
            ...trimmedHistory,
            ChatMessage.user(content: userMessage),
          ],
          systemPrompt: systemPrompt,
        );
        final content = aiResponse.content.trim();
        if (content.isNotEmpty) return content;
      } on Object {
        if (localText != null) return localText;
        return 'الان نتوانستم به سرور هوش مصنوعی وصل شوم. لطفاً دوباره امتحان کن.';
      }
    }

    final resolved = localText ?? _genericFallback(result, userMessage);
    return resolved.trim().isEmpty
        ? _genericFallback(result, userMessage)
        : resolved;
  }

  String? _pickLocalText(CoachIntegrationResult result) {
    final entitlement = _entitlementMessage(result);
    if (entitlement != null) return entitlement;

    final pending = result.conversationState?.pendingQuestions;
    if (pending != null && pending.isNotEmpty) {
      final prompt = pending.last.prompt.trim();
      if (prompt.isNotEmpty) {
        return ProductExperienceFormatter.humanizeReason(prompt);
      }
    }

    for (final candidate in <String?>[
      result.decision.followUpQuestion,
      result.responsePlan.localMessage,
      result.decision.localResponse,
    ]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      final localized = ProductExperienceFormatter.humanizeReason(candidate);
      if (localized.isNotEmpty) return localized;
    }

    return null;
  }

  String? _entitlementMessage(CoachIntegrationResult result) {
    final status = result.decision.status;
    if (status == CoachDecisionStatus.allowed) return null;

    final localized =
        ProductExperienceFormatter.localizeEntitlementStatus(status);
    if (localized.isNotEmpty) return localized;

    final localResponse = result.decision.localResponse;
    if (localResponse == null || localResponse.trim().isEmpty) return null;
    final humanized = ProductExperienceFormatter.humanizeReason(localResponse);
    return humanized.isNotEmpty ? humanized : null;
  }

  String _genericFallback(CoachIntegrationResult result, String userMessage) {
    if (CoachChatProgramPolicy.looksLikeProgramRequest(userMessage)) {
      return CoachChatProgramPolicy.redirectMessage;
    }

    final trimmed = userMessage.trim();
    final normalized = trimmed.toLowerCase();
    if (trimmed == 'سلام' ||
        normalized == 'hello' ||
        normalized == 'hi' ||
        trimmed == 'درود') {
      final firstName =
          result.coachContext.profile['first_name']?.toString().trim();
      if (firstName != null && firstName.isNotEmpty) {
        return 'سلام $firstName! امروز چطور می‌تونم کمکت کنم؟';
      }
      return 'سلام! من مربی GymAI هستم. درباره تمرین امروز، ریکاوری یا تکنیک بپرس.';
    }

    return 'سؤالت را کمی دقیق‌تر بپرس؛ مثلاً درباره تمرین امروز، ریکاوری یا اصلاح حرکت. '
        'برای ساخت برنامه کامل از بخش مربیان یا درخواست برنامه مربی هوشمند استفاده کن.';
  }
}
