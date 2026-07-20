import 'package:gymaipro/ai/context/coach_conversation_summary.dart';
import 'package:gymaipro/ai/persistence/conversation_summary_repository.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';

/// Rolling conversation summarizer for coach chat.
///
/// Uses a cheap local extractive summary by default. Optionally upgrades via
/// OpenAI when enough new messages accumulate.
class ConversationSummaryService {
  ConversationSummaryService({
    ConversationSummaryRepository? repository,
    OpenAIService? openAIService,
    this.messageThreshold = 10,
    this.recentMessageWindow = 24,
  }) : _repository = repository ?? ConversationSummaryRepository(),
       _openAIService = openAIService;

  final ConversationSummaryRepository _repository;
  final OpenAIService? _openAIService;

  /// Refresh after this many new messages since the last summary.
  final int messageThreshold;

  /// How many recent messages feed the summary prompt.
  final int recentMessageWindow;

  Future<CoachConversationSummary> load(String userId) {
    return _repository.loadSummary(userId);
  }

  /// Refreshes the summary when enough new messages arrived.
  Future<CoachConversationSummary> refreshIfNeeded({
    required String userId,
    required List<CoachChatMessage> messages,
    bool force = false,
    bool allowLlm = true,
  }) async {
    final current = await _repository.loadSummary(userId);
    final total = messages.length;
    if (total == 0) return current;

    final delta = total - current.messageCount;
    if (!force && delta < messageThreshold && !current.placeholder) {
      return current;
    }

    final window = messages.length <= recentMessageWindow
        ? messages
        : messages.sublist(messages.length - recentMessageWindow);

    var summaryText = _buildLocalSummary(window, previous: current.summary);
    if (allowLlm && _openAIService != null && window.length >= 6) {
      try {
        final upgraded = await _summarizeWithLlm(
          window: window,
          previous: current.summary,
        );
        if (upgraded != null && upgraded.trim().isNotEmpty) {
          summaryText = upgraded.trim();
        }
      } on Object {
        // Keep local summary on LLM failure.
      }
    }

    final next = CoachConversationSummary(
      summary: summaryText,
      messageCount: total,
      lastUpdatedAt: DateTime.now(),
      placeholder: summaryText.trim().isEmpty,
    );
    await _repository.saveSummary(userId, next);
    return next;
  }

  String _buildLocalSummary(
    List<CoachChatMessage> messages, {
    String? previous,
  }) {
    final bullets = <String>[];
    if (previous != null && previous.trim().isNotEmpty) {
      bullets.add(previous.trim());
    }

    for (final message in messages) {
      final text = message.text.trim();
      if (text.isEmpty) continue;
      if (message.role == CoachChatMessageRole.user) {
        final clipped = text.length > 90 ? '${text.substring(0, 90)}…' : text;
        bullets.add('کاربر: $clipped');
      } else if (_looksLikeDecision(text)) {
        final clipped = text.length > 90 ? '${text.substring(0, 90)}…' : text;
        bullets.add('مربی: $clipped');
      }
    }

    // Keep the rolling local summary bounded for token budget.
    final unique = <String>[];
    final seen = <String>{};
    for (final line in bullets.reversed) {
      final key = line.toLowerCase();
      if (!seen.add(key)) continue;
      unique.insert(0, line);
      if (unique.length >= 8) break;
    }

    return unique.join('\n');
  }

  bool _looksLikeDecision(String text) {
    final lower = text.toLowerCase();
    return lower.contains('برنامه') ||
        lower.contains('تمرین') ||
        lower.contains('ریکاوری') ||
        lower.contains('آسیب') ||
        lower.contains('زانو') ||
        lower.contains('هدف') ||
        lower.contains('پیشنهاد');
  }

  Future<String?> _summarizeWithLlm({
    required List<CoachChatMessage> window,
    String? previous,
  }) async {
    final openAI = _openAIService;
    if (openAI == null) return null;

    final transcript = window
        .map((message) {
          final role = message.role == CoachChatMessageRole.user
              ? 'User'
              : 'Coach';
          return '$role: ${message.text.trim()}';
        })
        .join('\n');

    final prompt = StringBuffer()
      ..writeln(
        'Summarize this GymAI coach chat in Persian for future context.',
      )
      ..writeln('Keep under 180 words. Focus on goals, injuries, preferences,')
      ..writeln('program decisions, and open questions. No fluff.')
      ..writeln()
      ..writeln('Previous summary:')
      ..writeln(previous?.trim().isNotEmpty == true ? previous : '(none)')
      ..writeln()
      ..writeln('Recent messages:')
      ..writeln(transcript);

    return openAI.sendCompletion(
      messages: <Map<String, String>>[
        <String, String>{'role': 'system', 'content': 'You write concise Persian coaching memory summaries.'},
        <String, String>{'role': 'user', 'content': prompt.toString()},
      ],
      maxTokens: 280,
      temperature: 0.2,
    );
  }
}
