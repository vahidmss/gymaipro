import 'package:gymaipro/ai/state/conversation_phase.dart';

/// Priority for pending coach questions.
enum PendingQuestionPriority { required, recommended, optional }

/// A question waiting for a user answer in a multi-step coach flow.
class PendingQuestion {
  const PendingQuestion({
    required this.id,
    required this.prompt,
    required this.fieldKey,
    required this.phase,
    this.priority = PendingQuestionPriority.required,
    this.askedAt,
    this.expiresAt,
    this.metadata = const <String, Object?>{},
  });

  /// Stable question id.
  final String id;

  /// User-facing prompt text.
  final String prompt;

  /// Field key that the answer should populate in collected fields.
  final String fieldKey;

  /// Phase where this question was issued.
  final ConversationPhase phase;

  /// Relative importance of the question.
  final PendingQuestionPriority priority;

  /// When the question was asked.
  final DateTime? askedAt;

  /// Optional expiration for stale pending questions.
  final DateTime? expiresAt;

  /// Optional diagnostic metadata.
  final Map<String, Object?> metadata;

  /// Whether this question has passed its expiration time.
  bool isExpired({DateTime? now}) {
    final expiresAt = this.expiresAt;
    if (expiresAt == null) return false;
    return (now ?? DateTime.now()).isAfter(expiresAt);
  }

  /// Returns a copy with updated timestamps.
  PendingQuestion copyWith({
    DateTime? askedAt,
    DateTime? expiresAt,
    Map<String, Object?>? metadata,
  }) {
    return PendingQuestion(
      id: id,
      prompt: prompt,
      fieldKey: fieldKey,
      phase: phase,
      priority: priority,
      askedAt: askedAt ?? this.askedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
