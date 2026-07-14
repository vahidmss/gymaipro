import 'package:gymaipro/ai/state/conversation_phase.dart';

/// A completed step in a multi-step coach conversation.
class ConversationCheckpoint {
  const ConversationCheckpoint({
    required this.id,
    required this.phase,
    required this.completedAt,
    this.collectedFieldKeys = const <String>[],
    this.notes = const <String>[],
    this.confidence = 1,
  });

  /// Stable checkpoint id.
  final String id;

  /// Phase that was completed.
  final ConversationPhase phase;

  /// Completion timestamp.
  final DateTime completedAt;

  /// Field keys captured while completing this checkpoint.
  final List<String> collectedFieldKeys;

  /// Diagnostic notes.
  final List<String> notes;

  /// Confidence in this checkpoint from 0 to 1.
  final double confidence;
}
