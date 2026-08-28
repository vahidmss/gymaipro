import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

enum CoachChatMessageRole { user, coach }

enum CoachChatMessageType {
  normal,
  explanation,
  warning,
  workoutPreview,
  reviewResult,
  modificationPreview,
  memoryUpdate,
  knowledgeInsight,
  followUpQuestion,
  localSkillResponse,
  aiResponse,
}

enum CoachChatCardType {
  explanation,
  reason,
  coachNotes,
  warning,
  recommendation,
  nextAction,
  workoutPreview,
  reviewResult,
  modificationPreview,
  memoryUpdate,
  knowledgeInsight,
  followUpQuestion,
}

class CoachChatMessage {
  const CoachChatMessage({
    required this.id,
    required this.role,
    required this.type,
    required this.text,
    required this.createdAt,
    this.cards = const <CoachChatMessageCard>[],
    this.isStreaming = false,
  });

  final String id;
  final CoachChatMessageRole role;
  final CoachChatMessageType type;
  final String text;
  final DateTime createdAt;
  final List<CoachChatMessageCard> cards;
  final bool isStreaming;

  CoachChatMessage copyWith({
    String? id,
    CoachChatMessageRole? role,
    CoachChatMessageType? type,
    String? text,
    DateTime? createdAt,
    List<CoachChatMessageCard>? cards,
    bool? isStreaming,
  }) {
    return CoachChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      type: type ?? this.type,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      cards: cards ?? this.cards,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class CoachChatMessageCard {
  const CoachChatMessageCard({
    required this.type,
    required this.title,
    required this.items,
  });

  final CoachChatCardType type;
  final String title;
  final List<String> items;
}

class CoachChatSuggestedPrompt {
  const CoachChatSuggestedPrompt({
    required this.id,
    required this.label,
    required this.prompt,
  });

  final String id;
  final String label;
  final String prompt;
}

class CoachChatPreviewResponse {
  const CoachChatPreviewResponse({
    required this.message,
    this.thinkingSteps = CoachChatThinkingDefaults.steps,
  });

  final CoachChatMessage message;
  final List<String> thinkingSteps;
}
