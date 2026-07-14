import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/state/coach_state_repository.dart';
import 'package:gymaipro/ai/state/coach_state_validator.dart';
import 'package:gymaipro/ai/state/conversation_checkpoint.dart';
import 'package:gymaipro/ai/state/conversation_phase.dart';
import 'package:gymaipro/ai/state/pending_question.dart';
import 'package:gymaipro/ai/state/state_transition.dart';

/// Result returned by [CoachStateEngine] operations.
class CoachStateResult {
  const CoachStateResult({
    required this.state,
    required this.validation,
    this.applied = true,
  });

  final CoachConversationState state;
  final CoachStateValidationResult validation;
  final bool applied;

  bool get isValid => validation.isValid && applied;
}

/// Request to start a new multi-step coach conversation.
class StartConversationRequest {
  const StartConversationRequest({
    required this.userId,
    required this.flowType,
    this.sessionId,
    this.initialFields = const <String, Object?>{},
    this.pendingQuestions = const <PendingQuestion>[],
    this.expiresAt,
    this.confidence = 0.5,
    this.resumable = true,
    this.notes = const <String>[],
  });

  final String userId;
  final ConversationFlowType flowType;
  final String? sessionId;
  final Map<String, Object?> initialFields;
  final List<PendingQuestion> pendingQuestions;
  final DateTime? expiresAt;
  final double confidence;
  final bool resumable;
  final List<String> notes;
}

/// Infrastructure engine for multi-step coach conversation state.
///
/// Models workout generation, progress analysis, onboarding, and other
/// resumable flows without changing runtime, prompts, OpenAI, UI, or navigation.
class CoachStateEngine {
  CoachStateEngine({
    CoachStateValidator validator = const CoachStateValidator(),
    CoachStateRepository? repository,
  }) : _validator = validator,
       _repository = repository;

  final CoachStateValidator _validator;
  final CoachStateRepository? _repository;
  int _sequence = 0;

  /// Starts a new conversation state.
  CoachStateResult startConversation(StartConversationRequest request) {
    final now = DateTime.now();
    final initialPhase = request.flowType.initialPhase;
    final state = CoachConversationState(
      id: _nextId('state', request.userId),
      userId: request.userId,
      sessionId: request.sessionId,
      flowType: request.flowType,
      currentPhase: initialPhase,
      status: ConversationStateStatus.active,
      pendingQuestions: List<PendingQuestion>.unmodifiable(
        request.pendingQuestions,
      ),
      collectedFields: Map<String, Object?>.unmodifiable(request.initialFields),
      transitionHistory: List<StateTransition>.unmodifiable(<StateTransition>[
        StateTransition(
          id: _nextId('transition', request.userId),
          fromPhase: ConversationPhase.notStarted,
          toPhase: initialPhase,
          reason: StateTransitionReason.flowStarted,
          occurredAt: now,
          notes: <String>['Started ${request.flowType.name} flow.'],
        ),
      ]),
      resumable: request.resumable,
      expiresAt: request.expiresAt,
      confidence: request.confidence.clamp(0, 1),
      createdAt: now,
      updatedAt: now,
      notes: List<String>.unmodifiable(request.notes),
    );

    return _finalize(state);
  }

  /// Resumes a paused or active conversation.
  CoachStateResult resumeConversation(CoachConversationState state) {
    if (!state.canResume) {
      return CoachStateResult(
        state: state,
        validation: const CoachStateValidationResult(
          isValid: false,
          issues: <String>['Conversation state is not resumable.'],
        ),
        applied: false,
      );
    }

    final now = DateTime.now();
    final resumed = _appendTransition(
      state: state,
      toPhase: state.currentPhase,
      reason: StateTransitionReason.resumed,
      occurredAt: now,
      notes: const <String>['Conversation resumed.'],
    ).copyWith(status: ConversationStateStatus.active, updatedAt: now);

    return _finalize(resumed);
  }

  /// Adds or replaces a pending question.
  CoachStateResult enqueueQuestion({
    required CoachConversationState state,
    required PendingQuestion question,
    DateTime? now,
  }) {
    if (!state.isActive) {
      return _inactiveResult(state);
    }

    final effectiveNow = now ?? DateTime.now();
    final stamped = question.askedAt == null
        ? question.copyWith(askedAt: effectiveNow)
        : question;
    final pending = <PendingQuestion>[
      for (final item in state.pendingQuestions)
        if (item.id != stamped.id) item,
      stamped,
    ];

    final updated = state.copyWith(
      pendingQuestions: List<PendingQuestion>.unmodifiable(pending),
      updatedAt: effectiveNow,
      notes: <String>[...state.notes, 'Queued pending question ${stamped.id}.'],
    );

    return _finalize(updated);
  }

  /// Records an answer, stores the field, and removes the pending question.
  CoachStateResult answerQuestion({
    required CoachConversationState state,
    required String questionId,
    required Object? answer,
    double? answerConfidence,
    DateTime? now,
  }) {
    final validation = _validator.validateAnswer(
      state: state,
      questionId: questionId,
      answer: answer,
    );
    if (!validation.isValid) {
      return CoachStateResult(
        state: state,
        validation: validation,
        applied: false,
      );
    }

    final question = state.pendingQuestions.firstWhere(
      (item) => item.id == questionId,
    );
    final effectiveNow = now ?? DateTime.now();
    final fields = Map<String, Object?>.from(state.collectedFields)
      ..[question.fieldKey] = answer;

    final pending = state.pendingQuestions
        .where((item) => item.id != questionId)
        .toList(growable: false);

    final transitioned =
        _appendTransition(
          state: state.copyWith(
            collectedFields: Map<String, Object?>.unmodifiable(fields),
            pendingQuestions: List<PendingQuestion>.unmodifiable(pending),
          ),
          toPhase: state.currentPhase,
          reason: StateTransitionReason.questionAnswered,
          occurredAt: effectiveNow,
          trigger: questionId,
          notes: <String>['Answered question for ${question.fieldKey}.'],
        ).copyWith(
          confidence: _blendConfidence(
            state.confidence,
            answerConfidence ?? 0.85,
          ),
          updatedAt: effectiveNow,
        );

    return _finalize(transitioned);
  }

  /// Completes a checkpoint for the current or supplied phase.
  CoachStateResult completeCheckpoint({
    required CoachConversationState state,
    required ConversationPhase phase,
    List<String> collectedFieldKeys = const <String>[],
    double checkpointConfidence = 1,
    DateTime? now,
  }) {
    if (!state.isActive) {
      return _inactiveResult(state);
    }

    final effectiveNow = now ?? DateTime.now();
    final checkpoint = ConversationCheckpoint(
      id: _nextId('checkpoint', state.userId),
      phase: phase,
      completedAt: effectiveNow,
      collectedFieldKeys: List<String>.unmodifiable(collectedFieldKeys),
      notes: const <String>['Checkpoint completed.'],
      confidence: checkpointConfidence.clamp(0, 1),
    );

    final checkpoints = <ConversationCheckpoint>[
      ...state.completedCheckpoints,
      checkpoint,
    ];

    final nextPhase = _nextFlowPhase(state: state, completedPhase: phase);
    final transitioned =
        _appendTransition(
          state: state.copyWith(
            completedCheckpoints: List<ConversationCheckpoint>.unmodifiable(
              checkpoints,
            ),
          ),
          toPhase: nextPhase ?? state.currentPhase,
          reason: StateTransitionReason.checkpointCompleted,
          occurredAt: effectiveNow,
          trigger: checkpoint.id,
          notes: <String>[
            'Completed checkpoint for ${phase.name}.',
            if (nextPhase != null) 'Advanced to ${nextPhase.name}.',
          ],
        ).copyWith(
          currentPhase: nextPhase ?? state.currentPhase,
          confidence: _blendConfidence(state.confidence, checkpointConfidence),
          updatedAt: effectiveNow,
        );

    return _finalize(transitioned);
  }

  /// Transitions the conversation to a new phase.
  CoachStateResult transitionToPhase({
    required CoachConversationState state,
    required ConversationPhase toPhase,
    required StateTransitionReason reason,
    String? trigger,
    List<String> notes = const <String>[],
    DateTime? now,
  }) {
    final validation = _validator.validateTransition(
      state: state,
      toPhase: toPhase,
      reason: reason,
    );
    if (!validation.isValid) {
      return CoachStateResult(
        state: state,
        validation: validation,
        applied: false,
      );
    }

    final effectiveNow = now ?? DateTime.now();
    final transitioned =
        _appendTransition(
          state: state,
          toPhase: toPhase,
          reason: reason,
          occurredAt: effectiveNow,
          trigger: trigger,
          notes: notes,
        ).copyWith(
          currentPhase: toPhase,
          status: _statusForPhase(toPhase, state.status),
          updatedAt: effectiveNow,
        );

    return _finalize(transitioned);
  }

  /// Marks the conversation as ready to execute the downstream action.
  CoachStateResult markReadyToExecute({
    required CoachConversationState state,
    DateTime? now,
  }) {
    return transitionToPhase(
      state: state,
      toPhase: ConversationPhase.readyToExecute,
      reason: StateTransitionReason.executionReady,
      notes: const <String>['Conversation is ready for execution.'],
      now: now,
    );
  }

  /// Completes the conversation flow.
  CoachStateResult completeConversation({
    required CoachConversationState state,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final completed =
        _appendTransition(
          state: state,
          toPhase: ConversationPhase.completed,
          reason: StateTransitionReason.flowCompleted,
          occurredAt: effectiveNow,
          notes: const <String>['Conversation flow completed.'],
        ).copyWith(
          currentPhase: ConversationPhase.completed,
          status: ConversationStateStatus.completed,
          pendingQuestions: const <PendingQuestion>[],
          resumable: false,
          confidence: _blendConfidence(state.confidence, 1),
          updatedAt: effectiveNow,
        );

    return _finalize(completed);
  }

  /// Cancels the conversation flow.
  CoachStateResult cancelConversation({
    required CoachConversationState state,
    StateTransitionReason reason = StateTransitionReason.userCancelled,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final cancelled =
        _appendTransition(
          state: state,
          toPhase: ConversationPhase.cancelled,
          reason: reason,
          occurredAt: effectiveNow,
          notes: <String>[
            if (reason == StateTransitionReason.userCancelled)
              'Conversation cancelled by user.'
            else
              'Conversation cancelled by system.',
          ],
        ).copyWith(
          currentPhase: ConversationPhase.cancelled,
          status: ConversationStateStatus.cancelled,
          cancelled: true,
          resumable: false,
          pendingQuestions: const <PendingQuestion>[],
          updatedAt: effectiveNow,
        );

    return _finalize(cancelled);
  }

  /// Restarts the flow while preserving restart metadata.
  CoachStateResult restartConversation({
    required CoachConversationState state,
    Map<String, Object?>? seedFields,
    List<PendingQuestion> pendingQuestions = const <PendingQuestion>[],
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final initialPhase = state.flowType.initialPhase;
    final restarted = CoachConversationState(
      id: state.id,
      userId: state.userId,
      sessionId: state.sessionId,
      flowType: state.flowType,
      currentPhase: initialPhase,
      status: ConversationStateStatus.active,
      pendingQuestions: List<PendingQuestion>.unmodifiable(pendingQuestions),
      collectedFields: Map<String, Object?>.unmodifiable(
        seedFields ?? const <String, Object?>{},
      ),
      transitionHistory: List<StateTransition>.unmodifiable(<StateTransition>[
        ...state.transitionHistory,
        StateTransition(
          id: _nextId('transition', state.userId),
          fromPhase: state.currentPhase,
          toPhase: initialPhase,
          reason: StateTransitionReason.restarted,
          occurredAt: effectiveNow,
          notes: <String>[
            'Conversation restarted. Count=${state.restartCount + 1}.',
          ],
        ),
      ]),
      expiresAt: state.expiresAt,
      confidence: 0.5,
      restartCount: state.restartCount + 1,
      createdAt: state.createdAt,
      updatedAt: effectiveNow,
      notes: <String>[
        ...state.notes,
        'Flow restarted at ${effectiveNow.toIso8601String()}.',
      ],
    );

    return _finalize(restarted);
  }

  /// Expires the conversation when past [CoachConversationState.expiresAt].
  CoachStateResult expireIfNeeded({
    required CoachConversationState state,
    DateTime? now,
  }) {
    if (!state.isExpired(now: now)) {
      return CoachStateResult(
        state: state,
        validation: const CoachStateValidationResult(isValid: true),
        applied: false,
      );
    }

    final effectiveNow = now ?? DateTime.now();
    final expired =
        _appendTransition(
          state: state,
          toPhase: ConversationPhase.expired,
          reason: StateTransitionReason.expired,
          occurredAt: effectiveNow,
          notes: const <String>['Conversation state expired.'],
        ).copyWith(
          currentPhase: ConversationPhase.expired,
          status: ConversationStateStatus.expired,
          resumable: false,
          pendingQuestions: const <PendingQuestion>[],
          updatedAt: effectiveNow,
        );

    return _finalize(expired);
  }

  /// Updates conversation confidence without changing phase.
  CoachStateResult updateConfidence({
    required CoachConversationState state,
    required double confidence,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final updated = _appendTransition(
      state: state,
      toPhase: state.currentPhase,
      reason: StateTransitionReason.confidenceAdjusted,
      occurredAt: effectiveNow,
      notes: <String>[
        'Confidence updated to ${confidence.toStringAsFixed(2)}.',
      ],
    ).copyWith(confidence: confidence.clamp(0, 1), updatedAt: effectiveNow);

    return _finalize(updated);
  }

  /// Persists the result state when a repository is configured.
  Future<CoachStateResult> persist(CoachStateResult result) async {
    final repository = _repository;
    if (repository == null || !result.isValid) return result;
    await repository.saveState(result.state);
    return result;
  }

  /// Loads a resumable state for a user and flow type.
  Future<CoachConversationState?> loadResumable({
    required String userId,
    ConversationFlowType? flowType,
  }) async {
    final repository = _repository;
    if (repository == null) return null;

    final states = await repository.loadResumableStates(userId);
    for (final state in states) {
      if (flowType == null || state.flowType == flowType) {
        return state;
      }
    }
    return null;
  }

  CoachStateResult _finalize(CoachConversationState state) {
    final validation = _validator.validateState(state);
    return CoachStateResult(
      state: state,
      validation: validation,
      applied: validation.isValid,
    );
  }

  CoachStateResult _inactiveResult(CoachConversationState state) {
    return CoachStateResult(
      state: state,
      validation: const CoachStateValidationResult(
        isValid: false,
        issues: <String>['Conversation state is not active.'],
      ),
      applied: false,
    );
  }

  CoachConversationState _appendTransition({
    required CoachConversationState state,
    required ConversationPhase toPhase,
    required StateTransitionReason reason,
    required DateTime occurredAt,
    String? trigger,
    List<String> notes = const <String>[],
  }) {
    final transition = StateTransition(
      id: _nextId('transition', state.userId),
      fromPhase: state.currentPhase,
      toPhase: toPhase,
      reason: reason,
      occurredAt: occurredAt,
      trigger: trigger,
      notes: List<String>.unmodifiable(notes),
    );

    return state.copyWith(
      transitionHistory: List<StateTransition>.unmodifiable(<StateTransition>[
        ...state.transitionHistory,
        transition,
      ]),
    );
  }

  ConversationPhase? _nextFlowPhase({
    required CoachConversationState state,
    required ConversationPhase completedPhase,
  }) {
    final order = state.flowType.phaseOrder;
    final index = order.indexOf(completedPhase);
    if (index < 0 || index >= order.length - 1) return null;
    return order[index + 1];
  }

  ConversationStateStatus _statusForPhase(
    ConversationPhase phase,
    ConversationStateStatus current,
  ) {
    switch (phase) {
      case ConversationPhase.completed:
        return ConversationStateStatus.completed;
      case ConversationPhase.cancelled:
        return ConversationStateStatus.cancelled;
      case ConversationPhase.expired:
        return ConversationStateStatus.expired;
      case ConversationPhase.awaitingConfirmation:
        return ConversationStateStatus.paused;
      case ConversationPhase.notStarted:
      case ConversationPhase.greeting:
      case ConversationPhase.collectingProfile:
      case ConversationPhase.collectingGoals:
      case ConversationPhase.collectingRestrictions:
      case ConversationPhase.collectingEquipment:
      case ConversationPhase.collectingProgressData:
      case ConversationPhase.reviewingCollectedData:
      case ConversationPhase.readyToExecute:
        return current == ConversationStateStatus.paused
            ? ConversationStateStatus.active
            : current;
    }
  }

  double _blendConfidence(double current, double incoming) {
    if (current <= 0) return incoming.clamp(0, 1);
    return ((current + incoming) / 2).clamp(0, 1);
  }

  String _nextId(String prefix, String userId) {
    _sequence += 1;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_${userId}_$timestamp$_sequence';
  }
}
