import 'package:gymaipro/ai/state/conversation_phase.dart';

/// Reason for a conversation phase transition.
enum StateTransitionReason {
  flowStarted,
  questionAnswered,
  checkpointCompleted,
  confirmationGranted,
  confirmationRejected,
  executionReady,
  flowCompleted,
  userCancelled,
  systemCancelled,
  expired,
  restarted,
  resumed,
  confidenceAdjusted,
  validationBlocked,
  manualTransition,
}

/// Immutable record of one conversation phase transition.
class StateTransition {
  const StateTransition({
    required this.id,
    required this.fromPhase,
    required this.toPhase,
    required this.reason,
    required this.occurredAt,
    this.trigger,
    this.notes = const <String>[],
  });

  /// Stable transition id.
  final String id;

  /// Previous phase.
  final ConversationPhase fromPhase;

  /// New phase.
  final ConversationPhase toPhase;

  /// Why the transition happened.
  final StateTransitionReason reason;

  /// When the transition occurred.
  final DateTime occurredAt;

  /// Optional trigger label such as a question id or checkpoint id.
  final String? trigger;

  /// Diagnostic notes.
  final List<String> notes;
}
