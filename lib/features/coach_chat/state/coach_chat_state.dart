import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

enum CoachChatStatus { empty, loading, loaded, error }

class CoachChatState {
  const CoachChatState({
    required this.status,
    this.messages = const <CoachChatMessage>[],
    this.suggestedPrompts = CoachChatState.defaultSuggestedPrompts,
    this.isThinking = false,
    this.errorMessage,
    this.thinkingSteps = CoachChatState.defaultThinkingSteps,
  });

  const CoachChatState.empty()
    : status = CoachChatStatus.empty,
      messages = const <CoachChatMessage>[],
      suggestedPrompts = CoachChatState.defaultSuggestedPrompts,
      isThinking = false,
      errorMessage = null,
      thinkingSteps = CoachChatState.defaultThinkingSteps;

  const CoachChatState.loading()
    : status = CoachChatStatus.loading,
      messages = const <CoachChatMessage>[],
      suggestedPrompts = CoachChatState.defaultSuggestedPrompts,
      isThinking = true,
      errorMessage = null,
      thinkingSteps = CoachChatState.defaultThinkingSteps;

  const CoachChatState.error(String message)
    : status = CoachChatStatus.error,
      messages = const <CoachChatMessage>[],
      suggestedPrompts = CoachChatState.defaultSuggestedPrompts,
      isThinking = false,
      errorMessage = message,
      thinkingSteps = CoachChatState.defaultThinkingSteps;

  final CoachChatStatus status;
  final List<CoachChatMessage> messages;
  final List<CoachChatSuggestedPrompt> suggestedPrompts;
  final bool isThinking;
  final String? errorMessage;
  final List<String> thinkingSteps;

  bool get isEmpty => status == CoachChatStatus.empty;
  bool get isLoading => status == CoachChatStatus.loading;
  bool get isLoaded => status == CoachChatStatus.loaded;
  bool get hasError => status == CoachChatStatus.error;
  bool get hasConversation => messages.isNotEmpty;

  CoachChatState copyWith({
    CoachChatStatus? status,
    List<CoachChatMessage>? messages,
    List<CoachChatSuggestedPrompt>? suggestedPrompts,
    bool? isThinking,
    String? errorMessage,
    List<String>? thinkingSteps,
  }) {
    return CoachChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      isThinking: isThinking ?? this.isThinking,
      errorMessage: errorMessage ?? this.errorMessage,
      thinkingSteps: thinkingSteps ?? this.thinkingSteps,
    );
  }

  static const List<String> defaultThinkingSteps =
      CoachChatThinkingDefaults.steps;

  static const List<CoachChatSuggestedPrompt> defaultSuggestedPrompts =
      <CoachChatSuggestedPrompt>[
        CoachChatSuggestedPrompt(
          id: 'today_workout',
          label: 'تمرین امروز',
          prompt: 'تمرین امروز من چیه؟',
        ),
        CoachChatSuggestedPrompt(
          id: 'review_program',
          label: 'تحلیل برنامه',
          prompt: 'برنامه تمرینی من را تحلیل کن',
        ),
        CoachChatSuggestedPrompt(
          id: 'modify_workout',
          label: 'اصلاح برنامه',
          prompt: 'تمرین امروز من را اصلاح کن',
        ),
        CoachChatSuggestedPrompt(
          id: 'recovery',
          label: 'ریکاوری',
          prompt: 'ریکاوری من برای تمرین امروز چطوره؟',
        ),
        CoachChatSuggestedPrompt(
          id: 'nutrition',
          label: 'تغذیه',
          prompt: 'برای تمرین امروز چی بخورم؟',
        ),
        CoachChatSuggestedPrompt(
          id: 'supplements',
          label: 'مکمل‌ها',
          prompt: 'مکمل‌های امروز من چی باشه؟',
        ),
        CoachChatSuggestedPrompt(
          id: 'progress',
          label: 'پیشرفت',
          prompt: 'پیشرفت تمرینی من را بررسی کن',
        ),
      ];
}
