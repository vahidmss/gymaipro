import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/state/conversation_phase.dart';
import 'package:gymaipro/ai/state/pending_question.dart';
import 'package:gymaipro/ai/state/state_transition.dart';

/// Validation result for conversation state inputs or outputs.
class CoachStateValidationResult {
  const CoachStateValidationResult({
    required this.isValid,
    this.issues = const <String>[],
  });

  final bool isValid;
  final List<String> issues;
}

/// Validates conversation state packages and engine mutations.
///
/// The validator is deterministic and does not call services or APIs.
class CoachStateValidator {
  const CoachStateValidator();

  /// Validates a [CoachConversationState] snapshot.
  CoachStateValidationResult validateState(CoachConversationState state) {
    final issues = <String>[];

    if (state.id.trim().isEmpty) {
      issues.add('State id must not be empty.');
    }
    if (state.userId.trim().isEmpty) {
      issues.add('userId must not be empty.');
    }
    if (state.confidence < 0 || state.confidence > 1) {
      issues.add('confidence must be between 0 and 1.');
    }
    if (state.restartCount < 0) {
      issues.add('restartCount must not be negative.');
    }
    if (state.cancelled &&
        state.status != ConversationStateStatus.cancelled &&
        state.currentPhase != ConversationPhase.cancelled) {
      issues.add('cancelled states must use cancelled status or phase.');
    }
    if (state.status == ConversationStateStatus.expired &&
        state.currentPhase != ConversationPhase.expired) {
      issues.add('expired status must align with expired phase.');
    }
    if (state.status == ConversationStateStatus.completed &&
        state.currentPhase != ConversationPhase.completed) {
      issues.add('completed status must align with completed phase.');
    }

    final pendingIds = <String>{};
    for (final question in state.pendingQuestions) {
      if (!pendingIds.add(question.id)) {
        issues.add('Duplicate pending question id: ${question.id}.');
      }
      if (question.prompt.trim().isEmpty) {
        issues.add('Pending question ${question.id} must have a prompt.');
      }
      if (question.fieldKey.trim().isEmpty) {
        issues.add('Pending question ${question.id} must have a fieldKey.');
      }
    }

    final checkpointIds = <String>{};
    for (final checkpoint in state.completedCheckpoints) {
      if (!checkpointIds.add(checkpoint.id)) {
        issues.add('Duplicate checkpoint id: ${checkpoint.id}.');
      }
      if (checkpoint.confidence < 0 || checkpoint.confidence > 1) {
        issues.add('Checkpoint ${checkpoint.id} confidence must be 0..1.');
      }
    }

    final transitionIds = <String>{};
    for (final transition in state.transitionHistory) {
      if (!transitionIds.add(transition.id)) {
        issues.add('Duplicate transition id: ${transition.id}.');
      }
    }

    if (!state.resumable && state.canResume) {
      issues.add('State cannot be resumable when resumable is false.');
    }

    return CoachStateValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  /// Validates a proposed transition.
  CoachStateValidationResult validateTransition({
    required CoachConversationState state,
    required ConversationPhase toPhase,
    required StateTransitionReason reason,
  }) {
    final issues = <String>[];

    if (!state.isActive && reason != StateTransitionReason.resumed) {
      issues.add('Cannot transition an inactive conversation state.');
    }
    if (state.cancelled && reason != StateTransitionReason.restarted) {
      issues.add('Cannot transition a cancelled state.');
    }
    if (state.isExpired() && reason != StateTransitionReason.restarted) {
      issues.add('Cannot transition an expired state.');
    }
    if (toPhase == state.currentPhase &&
        reason != StateTransitionReason.confidenceAdjusted &&
        reason != StateTransitionReason.resumed &&
        reason != StateTransitionReason.questionAnswered) {
      issues.add('Transition target phase must differ from current phase.');
    }

    return CoachStateValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  /// Validates answering a pending question.
  CoachStateValidationResult validateAnswer({
    required CoachConversationState state,
    required String questionId,
    required Object? answer,
  }) {
    final issues = <String>[];

    if (!state.isActive) {
      issues.add('Cannot answer questions on an inactive state.');
    }

    final question = _findQuestion(state, questionId);
    if (question == null) {
      issues.add('Pending question $questionId was not found.');
    } else if (question.isExpired()) {
      issues.add('Pending question $questionId has expired.');
    }

    if (answer == null) {
      issues.add('Answer for $questionId must not be null.');
    } else if (answer is String && answer.trim().isEmpty) {
      issues.add('Answer for $questionId must not be empty.');
    }

    return CoachStateValidationResult(
      isValid: issues.isEmpty,
      issues: List<String>.unmodifiable(issues),
    );
  }

  PendingQuestion? _findQuestion(
    CoachConversationState state,
    String questionId,
  ) {
    for (final question in state.pendingQuestions) {
      if (question.id == questionId) return question;
    }
    return null;
  }
}
