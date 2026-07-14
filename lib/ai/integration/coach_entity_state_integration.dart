import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';
import 'package:gymaipro/ai/integration/entity_integration_registry.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/state/coach_state_engine.dart';
import 'package:gymaipro/ai/state/pending_question.dart';

/// Result of applying extracted entities to conversation state.
class EntityStateApplicationResult {
  const EntityStateApplicationResult({
    required this.state,
    required this.applied,
    this.resolvedFieldKey,
    this.resolvedValue,
  });

  final CoachConversationState state;
  final bool applied;
  final String? resolvedFieldKey;
  final Object? resolvedValue;
}

/// Maps [NormalizedEntity] values to pending conversation-state fields.
///
/// This layer only consumes entity-engine output. Extraction, normalization,
/// and entity validation stay in the entity module. Answer validation is
/// delegated to the state engine.
class CoachEntityStateIntegration {
  CoachEntityStateIntegration({
    CoachStateEngine? stateEngine,
    this.minConfidence = 0.35,
  }) : _stateEngine = stateEngine ?? CoachStateEngine();

  final CoachStateEngine _stateEngine;
  final double minConfidence;

  /// Attempts to resolve the next pending question using [entities].
  /// Returns unchanged state when no matching entity exists.
  EntityStateApplicationResult applyToPendingQuestion({
    required CoachConversationState state,
    required List<NormalizedEntity> entities,
  }) {
    if (state.pendingQuestions.isEmpty || !state.isActive) {
      return EntityStateApplicationResult(state: state, applied: false);
    }

    final question = _nextPendingQuestion(state);
    final bestEntity = _selectBestEntity(question.fieldKey, entities);
    if (bestEntity == null) {
      return EntityStateApplicationResult(state: state, applied: false);
    }

    final answered = _stateEngine.answerQuestion(
      state: state,
      questionId: question.id,
      answer: bestEntity.value,
      answerConfidence: bestEntity.confidence,
    );

    if (!answered.applied) {
      return EntityStateApplicationResult(state: state, applied: false);
    }

    return EntityStateApplicationResult(
      state: answered.state,
      applied: true,
      resolvedFieldKey: question.fieldKey,
      resolvedValue: bestEntity.value,
    );
  }

  NormalizedEntity? _selectBestEntity(
    String fieldKey,
    List<NormalizedEntity> entities,
  ) {
    final allowedTypes = EntityIntegrationRegistry.entityTypesForFieldKey(
      fieldKey,
    );
    if (allowedTypes.isEmpty) return null;

    NormalizedEntity? best;
    for (final entity in entities) {
      final candidates = <_EntityCandidate>[
        _EntityCandidate(
          type: entity.type,
          value: entity.value,
          confidence: entity.confidence,
        ),
        for (final alternative in entity.alternatives)
          _EntityCandidate(
            type: alternative.type,
            value: alternative.value,
            confidence: alternative.confidence,
          ),
      ];

      for (final candidate in candidates) {
        if (!allowedTypes.contains(candidate.type)) continue;
        if (candidate.confidence < minConfidence) continue;

        if (best == null || candidate.confidence > best.confidence) {
          best = NormalizedEntity(
            type: candidate.type,
            value: candidate.value,
            confidence: candidate.confidence,
            source: entity.source,
          );
        }
      }
    }

    return best;
  }

  PendingQuestion _nextPendingQuestion(CoachConversationState state) {
    final requiredQuestions = state.pendingQuestions.where(
      (question) => question.priority == PendingQuestionPriority.required,
    );
    if (requiredQuestions.isNotEmpty) return requiredQuestions.first;
    return state.pendingQuestions.first;
  }
}

class _EntityCandidate {
  const _EntityCandidate({
    required this.type,
    required this.value,
    required this.confidence,
  });

  final EntityType type;
  final Object value;
  final double confidence;
}
