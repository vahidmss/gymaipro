import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/entity/entity_match.dart';
import 'package:gymaipro/ai/entity/entity_type.dart';
import 'package:gymaipro/ai/knowledge/knowledge_category.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_requirement.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_trace.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/context/context_models.dart';

/// Input snapshot for knowledge ranking.
class CoachKnowledgeRankingInput {
  const CoachKnowledgeRankingInput({
    required this.intent,
    required this.coachContext,
    this.entities = const <NormalizedEntity>[],
    this.memories = const <CoachMemory>[],
    this.conversationState,
  });

  final AIIntent intent;
  final CoachContext coachContext;
  final List<NormalizedEntity> entities;
  final List<CoachMemory> memories;
  final CoachConversationState? conversationState;
}

/// Ranked node with score and explainability trace.
class CoachKnowledgeRankedNode {
  const CoachKnowledgeRankedNode({
    required this.node,
    required this.score,
    required this.trace,
  });

  final KnowledgeNode node;
  final double score;
  final CoachKnowledgeNodeTrace trace;
}

/// Ranks knowledge nodes using weighted context signals.
class CoachKnowledgeRanker {
  const CoachKnowledgeRanker({
    this.weights = const CoachKnowledgeRankingWeights(),
  });

  final CoachKnowledgeRankingWeights weights;

  /// Ranks [nodes] for [input] and returns sorted highest-first results.
  List<CoachKnowledgeRankedNode> rank({
    required CoachKnowledgeRankingInput input,
    required Iterable<KnowledgeNode> nodes,
  }) {
    final ranked =
        <CoachKnowledgeRankedNode>[
          for (final node in nodes)
            () {
              final scored = _scoreNode(input: input, node: node);
              return CoachKnowledgeRankedNode(
                node: node,
                score: scored.score,
                trace: scored.trace,
              );
            }(),
        ]..sort((a, b) => b.score.compareTo(a.score));

    return List<CoachKnowledgeRankedNode>.unmodifiable(ranked);
  }

  _ScoredNode _scoreNode({
    required CoachKnowledgeRankingInput input,
    required KnowledgeNode node,
  }) {
    final reasons = <String>[];
    var score = 0.0;

    final intentMatched = node.intent == input.intent;
    if (intentMatched) {
      score += weights.intentMatch;
      reasons.add('intent matched ${input.intent.name}');
    }

    final matchedEntities = _matchedEntities(input.entities, node);
    if (matchedEntities.isNotEmpty) {
      score += weights.entityOverlap;
      reasons.add('entity overlap: ${matchedEntities.join(', ')}');
    }

    final matchedGoals = _matchedGoals(input.coachContext, node);
    if (matchedGoals.isNotEmpty) {
      score += weights.goalOverlap;
      reasons.add('goal overlap: ${matchedGoals.join(', ')}');
    }

    final matchedRestrictions = _matchedRestrictions(input.coachContext, node);
    if (matchedRestrictions.isNotEmpty) {
      score += weights.restrictionOverlap;
      reasons.add('restriction overlap: ${matchedRestrictions.join(', ')}');
    }

    final matchedEquipment = _matchedEquipment(input.coachContext, node);
    if (matchedEquipment.isNotEmpty) {
      score += weights.equipmentOverlap;
      reasons.add('equipment overlap: ${matchedEquipment.join(', ')}');
    }

    if (_hasActiveProgram(input.coachContext) &&
        _nodeRequiresProvider(node, AIContextProviderKey.activeProgram)) {
      score += weights.activeProgram;
      reasons.add('active program available');
    }

    if (_hasConversationState(input.conversationState) &&
        _nodeRequiresProvider(node, AIContextProviderKey.currentQuestion)) {
      score += weights.currentState;
      reasons.add('conversation state available');
    }

    final matchedMemory = _matchedMemory(input.memories, node);
    if (matchedMemory.isNotEmpty) {
      score += weights.memoryRelevance;
      reasons.add('memory relevance: ${matchedMemory.join(', ')}');
    }

    final priorityBoost = _priorityBoost(node);
    if (priorityBoost > 0) {
      score += weights.knowledgePriority * priorityBoost;
      reasons.add('knowledge priority boost');
    }

    return _ScoredNode(
      score: score.clamp(0.0, 1.0),
      trace: CoachKnowledgeNodeTrace(
        nodeId: node.id,
        score: score.clamp(0.0, 1.0),
        matchedEntities: matchedEntities,
        matchedGoals: matchedGoals,
        matchedRestrictions: matchedRestrictions,
        matchedEquipment: matchedEquipment,
        matchedMemory: matchedMemory,
        matchedIntent: intentMatched,
        reasons: List<String>.unmodifiable(reasons),
      ),
    );
  }

  List<String> _matchedEntities(
    List<NormalizedEntity> entities,
    KnowledgeNode node,
  ) {
    final categories = _nodeCategories(node);
    final matches = <String>[];
    for (final entity in entities) {
      final category = _categoryForEntity(entity.type);
      if (category != null && categories.contains(category)) {
        matches.add(entity.type.name);
      }
    }
    return matches;
  }

  List<String> _matchedGoals(CoachContext context, KnowledgeNode node) {
    if (!_nodeRequiresCategory(node, KnowledgeCategory.goals)) {
      return const <String>[];
    }
    if (context.goals.isEmpty) return const <String>[];
    return context.goals.take(3).toList(growable: false);
  }

  List<String> _matchedRestrictions(CoachContext context, KnowledgeNode node) {
    if (!_nodeRequiresCategory(node, KnowledgeCategory.medical) &&
        !_nodeRequiresProvider(node, AIContextProviderKey.restrictions)) {
      return const <String>[];
    }
    if (context.restrictions.isEmpty) return const <String>[];
    return context.restrictions.take(2).toList(growable: false);
  }

  List<String> _matchedEquipment(CoachContext context, KnowledgeNode node) {
    if (!_nodeRequiresProvider(node, AIContextProviderKey.equipment)) {
      return const <String>[];
    }
    if (context.equipment.isEmpty) return const <String>[];
    return context.equipment.take(3).toList(growable: false);
  }

  List<String> _matchedMemory(List<CoachMemory> memories, KnowledgeNode node) {
    final categories = _nodeCategories(node);
    final matches = <String>[];
    for (final memory in memories) {
      if (_memoryCategoryMatches(memory.category, categories)) {
        matches.add(memory.key);
      }
      if (matches.length >= 3) break;
    }
    return matches;
  }

  bool _hasActiveProgram(CoachContext context) {
    final program = context.activeProgram;
    return program != null && program.isNotEmpty;
  }

  bool _hasConversationState(CoachConversationState? state) {
    return state != null &&
        (state.pendingQuestions.isNotEmpty ||
            state.collectedFields.isNotEmpty);
  }

  double _priorityBoost(KnowledgeNode node) {
    final requirements = <KnowledgeRequirement>[
      ...node.requiredKnowledge,
      ...node.optionalKnowledge,
    ];
    if (requirements.isEmpty) return 0;
    final requiredCount = requirements.where((req) => req.required).length;
    return (requiredCount / requirements.length).clamp(0.0, 1.0);
  }

  Set<KnowledgeCategory> _nodeCategories(KnowledgeNode node) {
    return <KnowledgeCategory>{
      for (final req in <KnowledgeRequirement>[
        ...node.requiredKnowledge,
        ...node.optionalKnowledge,
      ])
        req.category,
    };
  }

  bool _nodeRequiresCategory(KnowledgeNode node, KnowledgeCategory category) {
    return _nodeCategories(node).contains(category);
  }

  bool _nodeRequiresProvider(
    KnowledgeNode node,
    AIContextProviderKey provider,
  ) {
    for (final req in <KnowledgeRequirement>[
      ...node.requiredKnowledge,
      ...node.optionalKnowledge,
    ]) {
      if (req.providerKey == provider) return true;
    }
    return false;
  }

  KnowledgeCategory? _categoryForEntity(EntityType type) {
    switch (type) {
      case EntityType.height:
      case EntityType.weight:
      case EntityType.age:
      case EntityType.gender:
      case EntityType.experience:
        return KnowledgeCategory.profile;
      case EntityType.goal:
        return KnowledgeCategory.goals;
      case EntityType.equipment:
        return KnowledgeCategory.equipment;
      case EntityType.injury:
      case EntityType.medicalCondition:
        return KnowledgeCategory.medical;
      case EntityType.muscleGroup:
      case EntityType.exerciseName:
      case EntityType.workoutDay:
        return KnowledgeCategory.workout;
      case EntityType.supplement:
        return KnowledgeCategory.nutrition;
      case EntityType.food:
        return KnowledgeCategory.nutrition;
      case EntityType.sleepDuration:
        return KnowledgeCategory.recovery;
      case EntityType.timeExpression:
      case EntityType.waterIntake:
        return KnowledgeCategory.profile;
    }
  }

  bool _memoryCategoryMatches(
    MemoryCategory memoryCategory,
    Set<KnowledgeCategory> categories,
  ) {
    switch (memoryCategory) {
      case MemoryCategory.profile:
        return categories.contains(KnowledgeCategory.profile);
      case MemoryCategory.goal:
        return categories.contains(KnowledgeCategory.goals);
      case MemoryCategory.restriction:
      case MemoryCategory.medical:
        return categories.contains(KnowledgeCategory.medical);
      case MemoryCategory.equipment:
        return categories.contains(KnowledgeCategory.equipment);
      case MemoryCategory.workout:
        return categories.contains(KnowledgeCategory.workout);
      case MemoryCategory.nutrition:
        return categories.contains(KnowledgeCategory.nutrition);
      case MemoryCategory.recovery:
        return categories.contains(KnowledgeCategory.recovery);
      case MemoryCategory.preference:
      case MemoryCategory.behavior:
      case MemoryCategory.app:
      case MemoryCategory.relationship:
      case MemoryCategory.temporary:
      case MemoryCategory.other:
        return false;
    }
  }
}

class _ScoredNode {
  const _ScoredNode({required this.score, required this.trace});

  final double score;
  final CoachKnowledgeNodeTrace trace;
}

/// Independent weights for each ranking signal.
class CoachKnowledgeRankingWeights {
  const CoachKnowledgeRankingWeights({
    this.intentMatch = 0.30,
    this.entityOverlap = 0.12,
    this.goalOverlap = 0.12,
    this.restrictionOverlap = 0.08,
    this.equipmentOverlap = 0.08,
    this.activeProgram = 0.08,
    this.currentState = 0.07,
    this.memoryRelevance = 0.10,
    this.knowledgePriority = 0.05,
  });

  final double intentMatch;
  final double entityOverlap;
  final double goalOverlap;
  final double restrictionOverlap;
  final double equipmentOverlap;
  final double activeProgram;
  final double currentState;
  final double memoryRelevance;
  final double knowledgePriority;
}
