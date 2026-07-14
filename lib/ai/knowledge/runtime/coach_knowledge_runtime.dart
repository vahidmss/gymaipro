import 'package:gymaipro/ai/pipeline/coach_pipeline_mode.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/knowledge/knowledge_graph.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_ranker.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_selector.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_validator.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';

/// Orchestrates knowledge node ranking and selection for Coach v2.
///
/// Stages must consume this runtime instead of reading KnowledgeRegistry
/// directly.
class CoachKnowledgeRuntime {
  const CoachKnowledgeRuntime({
    KnowledgeGraph? graph,
    CoachKnowledgeRanker? ranker,
    CoachKnowledgeSelector? selector,
    CoachKnowledgeValidator? validator,
  }) : _graph = graph ?? const KnowledgeGraph(),
       _ranker = ranker ?? const CoachKnowledgeRanker(),
       _selector = selector ?? const CoachKnowledgeSelector(),
       _validator = validator ?? const CoachKnowledgeValidator();

  final KnowledgeGraph _graph;
  final CoachKnowledgeRanker _ranker;
  final CoachKnowledgeSelector _selector;
  final CoachKnowledgeValidator _validator;

  /// Resolves the best knowledge node for the current pipeline snapshot.
  CoachKnowledgeResult? resolve({
    required AIIntent intent,
    required CoachContext coachContext,
    List<NormalizedEntity> entities = const <NormalizedEntity>[],
    List<CoachMemory> memories = const <CoachMemory>[],
    CoachConversationState? conversationState,
    CoachPipelineMode pipelineMode = CoachPipelineMode.runtime,
  }) {
    if (!coachPipelineV2Active(pipelineMode)) return null;

    final stopwatch = Stopwatch()..start();
    final input = CoachKnowledgeRankingInput(
      intent: intent,
      coachContext: coachContext,
      entities: entities,
      memories: memories.isNotEmpty
          ? memories
          : coachContext.memories,
      conversationState: conversationState,
    );

    final ranked = _ranker.rank(
      input: input,
      nodes: _graph.allNodes,
    );
    final selected = _selector.selectBest(ranked);
    stopwatch.stop();

    return _validator.validate(
      graph: _graph,
      selected: selected,
      ranked: ranked,
      executionTime: stopwatch.elapsed,
    );
  }
}
