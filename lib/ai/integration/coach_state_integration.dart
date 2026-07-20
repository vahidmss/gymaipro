import 'package:gymaipro/ai/coach/coach_decision.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/integration/coach_entity_state_integration.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/state/coach_state_engine.dart';
import 'package:gymaipro/ai/state/coach_state_repository.dart';
import 'package:gymaipro/ai/state/coach_state_validator.dart';
import 'package:gymaipro/ai/state/conversation_phase.dart';
import 'package:gymaipro/ai/state/pending_question.dart';
import 'package:gymaipro/ai/state/state_transition.dart';

/// Metadata keys used by the Coach v2 state integration path.
abstract final class CoachStateMetadataKeys {
  static const sessionId = 'sessionId';
  static const coachStateAction = 'coach_state_action';
}

/// Supported state actions passed through integration metadata.
abstract final class CoachStateActions {
  static const cancel = 'cancel';
  static const restart = 'restart';
}

/// Wires the conversation state engine into the Coach v2 integration pipeline.
///
/// This helper is only used when `CoachV2Config.coachV2Enabled` is true.
class CoachStateIntegration {
  CoachStateIntegration({
    CoachStateEngine? stateEngine,
    CoachStateRepository? stateRepository,
    CoachEntityStateIntegration? entityStateIntegration,
    Duration stateTtl = const Duration(days: 7),
  }) : _stateRepository = stateRepository ?? CoachStateRepository(),
       _stateTtl = stateTtl {
    _stateEngine =
        stateEngine ?? CoachStateEngine(repository: _stateRepository);
    _entityStateIntegration =
        entityStateIntegration ??
        CoachEntityStateIntegration(stateEngine: _stateEngine);
  }

  final CoachStateRepository _stateRepository;
  late final CoachStateEngine _stateEngine;
  late final CoachEntityStateIntegration _entityStateIntegration;
  final Duration _stateTtl;

  /// Loads, resumes, creates, or mutates conversation state before processing.
  ///
  /// When [dryRun] is true (preview mode), state transitions run in memory only
  /// and no sessions are created or persisted.
  Future<CoachStatePrepareResult> prepareForMessage({
    required String userId,
    required AIIntent intent,
    required String userMessage,
    List<NormalizedEntity> normalizedEntities = const <NormalizedEntity>[],
    Map<String, Object?> metadata = const <String, Object?>{},
    bool dryRun = false,
  }) async {
    final sessionId = _readSessionId(metadata);
    final action = _readAction(metadata);

    await _stateRepository.pruneExpired(userId);
    var state = await _loadMatchingState(
      userId: userId,
      intent: intent,
      sessionId: sessionId,
    );

    if (state != null && action == CoachStateActions.cancel) {
      final cancelled = _stateEngine.cancelConversation(state: state);
      state = cancelled.state;
      await _persistIfNeeded(cancelled, dryRun: dryRun);
      return CoachStatePrepareResult(state: state);
    }

    if (state != null && action == CoachStateActions.restart) {
      final restarted = _stateEngine.restartConversation(state: state);
      state = restarted.state;
      await _persistIfNeeded(restarted, dryRun: dryRun);
      return CoachStatePrepareResult(state: state);
    }

    if (state == null && _shouldStartFlow(intent)) {
      if (dryRun) {
        return const CoachStatePrepareResult();
      }
      final started = _stateEngine.startConversation(
        StartConversationRequest(
          userId: userId,
          flowType: _flowTypeForIntent(intent),
          sessionId: sessionId,
          expiresAt: DateTime.now().add(_stateTtl),
          notes: const <String>['State created for multi-step coach flow.'],
        ),
      );
      state = started.state;
      await _persistIfNeeded(started, dryRun: dryRun);
    }

    if (state == null) return const CoachStatePrepareResult();

    final expired = _stateEngine.expireIfNeeded(state: state);
    if (expired.applied) {
      state = expired.state;
      await _persistIfNeeded(expired, dryRun: dryRun);
      return CoachStatePrepareResult(state: state);
    }

    if (state.canResume && state.pendingQuestions.isEmpty) {
      final resumed = _stateEngine.resumeConversation(state);
      if (resumed.applied) {
        state = resumed.state;
        await _persistIfNeeded(resumed, dryRun: dryRun);
      }
    }

    EntityStateApplicationResult? entityApplication;
    if (state.pendingQuestions.isNotEmpty &&
        state.isActive &&
        normalizedEntities.isNotEmpty) {
      entityApplication = _entityStateIntegration.applyToPendingQuestion(
        state: state,
        entities: normalizedEntities,
      );
      if (entityApplication.applied) {
        state = entityApplication.state;
        await _persistIfNeeded(
          CoachStateResult(
            state: state,
            validation: const CoachStateValidationResult(isValid: true),
          ),
          dryRun: dryRun,
        );
      }
    }

    if (state.pendingQuestions.isNotEmpty &&
        state.isActive &&
        !(entityApplication?.applied ?? false)) {
      final question = _nextPendingQuestion(state);
      final answered = _stateEngine.answerQuestion(
        state: state,
        questionId: question.id,
        answer: userMessage,
      );
      if (answered.applied) {
        state = answered.state;
        await _persistIfNeeded(answered, dryRun: dryRun);
      }
    }

    return CoachStatePrepareResult(
      state: state,
      entityApplication: entityApplication,
    );
  }

  /// Applies decision side-effects and persists the latest state snapshot.
  ///
  /// When [dryRun] is true (preview mode), transitions run in memory only.
  Future<CoachConversationState?> finalizeAfterDecision({
    required String userId,
    required AIIntent intent,
    required CoachDecision decision,
    CoachConversationState? state,
    Map<String, Object?> metadata = const <String, Object?>{},
    bool dryRun = false,
  }) async {
    final sessionId = _readSessionId(metadata);
    var currentState = state;

    if (currentState == null && decision.requiresFollowUp) {
      if (dryRun) {
        return null;
      }
      final started = _stateEngine.startConversation(
        StartConversationRequest(
          userId: userId,
          flowType: _flowTypeForIntent(intent),
          sessionId: sessionId,
          expiresAt: DateTime.now().add(_stateTtl),
          notes: const <String>['State created after follow-up decision.'],
        ),
      );
      currentState = started.state;
      await _persistIfNeeded(started, dryRun: dryRun);
    }

    if (currentState == null) return null;

    CoachStateResult latest = CoachStateResult(
      state: currentState,
      validation: const CoachStateValidationResult(isValid: true),
    );

    if (decision.requiresFollowUp && decision.followUpQuestion != null) {
      final alreadyPending = latest.state.pendingQuestions.any(
        (question) => question.prompt == decision.followUpQuestion,
      );
      if (!alreadyPending) {
        final question = _pendingQuestionFromDecision(
          state: latest.state,
          decision: decision,
        );
        latest = _stateEngine.enqueueQuestion(
          state: latest.state,
          question: question,
        );
      }
      latest = _stateEngine.transitionToPhase(
        state: latest.state,
        toPhase: ConversationPhase.awaitingConfirmation,
        reason: StateTransitionReason.manualTransition,
        notes: const <String>['Awaiting follow-up response.'],
      );
      await _persistIfNeeded(latest, dryRun: dryRun);
      return latest.state;
    }

    if (decision.shouldCallAI && latest.state.pendingQuestions.isEmpty) {
      latest = _stateEngine.markReadyToExecute(state: latest.state);
      await _persistIfNeeded(latest, dryRun: dryRun);
      return latest.state;
    }

    latest = CoachStateResult(
      state: latest.state.copyWith(updatedAt: DateTime.now()),
      validation: const CoachStateValidationResult(isValid: true),
    );
    await _persistIfNeeded(latest, dryRun: dryRun);
    return latest.state;
  }

  Future<void> persistState(CoachConversationState state) async {
    await _stateRepository.saveState(state);
  }

  ConversationFlowType _flowTypeForIntent(AIIntent intent) {
    switch (intent) {
      case AIIntent.workoutGeneration:
        // Programs are not authored in chat; keep flow generic.
        return ConversationFlowType.general;
      case AIIntent.progressAnalysis:
        return ConversationFlowType.progressAnalysis;
      case AIIntent.workoutToday:
      case AIIntent.workoutModification:
      case AIIntent.exerciseQuestion:
      case AIIntent.workoutQuestion:
      case AIIntent.recovery:
      case AIIntent.nutrition:
      case AIIntent.supplement:
      case AIIntent.motivation:
      case AIIntent.generalFitness:
      case AIIntent.generalChat:
      case AIIntent.appHelp:
      case AIIntent.bugReport:
      case AIIntent.feedback:
        return ConversationFlowType.general;
    }
  }

  bool _shouldStartFlow(AIIntent intent) {
    return intent == AIIntent.workoutGeneration ||
        intent == AIIntent.progressAnalysis;
  }

  Future<CoachConversationState?> _loadMatchingState({
    required String userId,
    required AIIntent intent,
    String? sessionId,
  }) async {
    final resumable = await _stateRepository.loadResumableStates(userId);
    if (resumable.isEmpty) return null;

    if (sessionId != null) {
      for (final state in resumable) {
        if (state.sessionId == sessionId) return state;
      }
    }

    final flowType = _flowTypeForIntent(intent);
    for (final state in resumable) {
      if (state.flowType == flowType) return state;
    }

    return resumable.first;
  }

  PendingQuestion _nextPendingQuestion(CoachConversationState state) {
    final requiredQuestions = state.pendingQuestions.where(
      (question) => question.priority == PendingQuestionPriority.required,
    );
    if (requiredQuestions.isNotEmpty) return requiredQuestions.first;
    return state.pendingQuestions.first;
  }

  PendingQuestion _pendingQuestionFromDecision({
    required CoachConversationState state,
    required CoachDecision decision,
  }) {
    final fieldKey = decision.missingData.isNotEmpty
        ? decision.missingData.first
        : 'followup_response';
    final questionId = 'followup_$fieldKey';

    return PendingQuestion(
      id: questionId,
      prompt: decision.followUpQuestion!,
      fieldKey: fieldKey,
      phase: state.currentPhase,
    );
  }

  String? _readSessionId(Map<String, Object?> metadata) {
    final value = metadata[CoachStateMetadataKeys.sessionId];
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  String? _readAction(Map<String, Object?> metadata) {
    final value = metadata[CoachStateMetadataKeys.coachStateAction];
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim().toLowerCase();
  }

  Future<void> _persistIfNeeded(
    CoachStateResult result, {
    required bool dryRun,
  }) async {
    if (dryRun) return;
    await _persist(result);
  }

  Future<void> _persist(CoachStateResult result) async {
    if (!result.isValid) return;
    await _stateRepository.saveState(result.state);
  }
}

/// Result of preparing conversation state before Coach v2 processing.
class CoachStatePrepareResult {
  const CoachStatePrepareResult({
    this.state,
    this.entityApplication,
  });

  final CoachConversationState? state;
  final EntityStateApplicationResult? entityApplication;
}
