import 'package:gymaipro/ai/integration/coach_integration_result.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/prompt/prompt_package_renderer.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
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
  }) async {
    final skillMessage = result.skillExecutionResult?.response.message?.trim();
    if (result.isLocalResponse &&
        skillMessage != null &&
        skillMessage.isNotEmpty) {
      final localized = ProductExperienceFormatter.humanizeReason(skillMessage);
      if (localized.isNotEmpty) return localized;
    }

    final localText = _pickLocalText(result);
    if (result.decision.shouldCallAI) {
      final promptPackage = result.promptPackage;
      if (promptPackage == null) {
        return localText ?? _genericFallback(result, userMessage);
      }

      try {
        final systemPrompt = PromptPackageRenderer.render(promptPackage);
        final recentHistory = history
            .where((message) => !message.isTyping && message.content.trim().isNotEmpty)
            .toList(growable: false);
        final trimmedHistory = recentHistory.length <= 4
            ? recentHistory
            : recentHistory.sublist(recentHistory.length - 4);

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

  String _genericFallback(CoachIntegrationResult result, String userMessage) {
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
      return 'سلام! من مربی GymAI هستم. درباره تمرین، برنامه یا ریکاوری بپرس.';
    }

    return 'برای ادامه، لطفاً سوالت را دقیق‌تر بپرس — مثلاً درباره تمرین امروز، ساخت برنامه یا اصلاح حرکت.';
  }
}
