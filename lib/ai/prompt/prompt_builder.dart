import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/prompt_context.dart';
import 'package:gymaipro/ai/knowledge/knowledge_category.dart';
import 'package:gymaipro/ai/knowledge/knowledge_graph.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/knowledge/knowledge_requirement.dart';
import 'package:gymaipro/ai/memory/coach_memory.dart';
import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/planner/coach_action.dart';
import 'package:gymaipro/ai/prompt/prompt_budget.dart';
import 'package:gymaipro/ai/prompt/prompt_compressor.dart';
import 'package:gymaipro/ai/prompt/prompt_metadata.dart';
import 'package:gymaipro/ai/prompt/prompt_package.dart';
import 'package:gymaipro/ai/prompt/prompt_personality.dart';
import 'package:gymaipro/ai/prompt/prompt_section.dart';
import 'package:gymaipro/ai/prompt/prompt_version.dart';

/// Input for building a prompt package.
class PromptBuildRequest {
  const PromptBuildRequest({
    required this.intent,
    required this.context,
    this.memories = const <CoachMemory>[],
    this.knowledgeNode,
    this.budget = PromptBudget.standard,
    this.personality = PromptPersonality.gymAiCoach,
    this.version = PromptVersion.v1,
    this.createdAt,
  });

  /// Intent to build for.
  final AIIntent intent;

  /// Context selected by future context providers.
  final PromptContext context;

  /// Candidate coach memories.
  final List<CoachMemory> memories;

  /// Optional preselected knowledge node.
  final KnowledgeNode? knowledgeNode;

  /// API/token budget.
  final PromptBudget budget;

  /// Prompt personality metadata.
  final PromptPersonality personality;

  /// Prompt version metadata.
  final PromptVersion version;

  /// Optional deterministic creation time for tests.
  final DateTime? createdAt;
}

/// Future-facing prompt build request that consumes [CoachContext] only.
class CoachPromptBuildRequest {
  const CoachPromptBuildRequest({
    required this.coachContext,
    this.knowledgeNode,
    this.budget = PromptBudget.standard,
    this.personality = PromptPersonality.gymAiCoach,
    this.version = PromptVersion.v1,
    this.createdAt,
  });

  /// Unified coach context package.
  final CoachContext coachContext;

  /// Optional preselected knowledge node.
  final KnowledgeNode? knowledgeNode;

  /// API/token budget.
  final PromptBudget budget;

  /// Prompt personality metadata.
  final PromptPersonality personality;

  /// Prompt version metadata.
  final PromptVersion version;

  /// Optional deterministic creation time for tests.
  final DateTime? createdAt;
}

/// Builds structured prompt packages for future AI integrations.
///
/// The builder does not render text prompts and does not call OpenAI. Existing
/// prompts and services remain unchanged.
class PromptBuilder {
  const PromptBuilder({
    this.knowledgeGraph = const KnowledgeGraph(),
    this.compressor = const PromptCompressor(),
  });

  /// Knowledge graph used to determine relevant sections.
  final KnowledgeGraph knowledgeGraph;

  /// Compressor contract. Currently structural only.
  final PromptCompressor compressor;

  /// Builds a standardized package from a unified [CoachContext].
  ///
  /// This is the future-facing entry point. Existing runtime paths are not
  /// connected to it yet.
  PromptPackage buildFromCoachContext(CoachPromptBuildRequest request) {
    final coachContext = request.coachContext;
    return build(
      PromptBuildRequest(
        intent: coachContext.intent,
        context: coachContext.toPromptContext(),
        memories: coachContext.memories,
        knowledgeNode: request.knowledgeNode,
        budget: request.budget,
        personality: request.personality,
        version: request.version,
        createdAt: request.createdAt ?? coachContext.metadata.buildTime,
      ),
    );
  }

  /// Builds a standardized package for [request].
  PromptPackage build(PromptBuildRequest request) {
    final node =
        request.knowledgeNode ?? knowledgeGraph.nodeForIntent(request.intent);
    final keys = _relevantKeys(node);
    final sections = _sectionsFor(request: request, node: node, keys: keys);
    final compression = compressor.compress(
      sections: sections,
      budget: request.budget,
    );
    final selectedSections = _fitBudget(compression.sections, request.budget);
    final estimatedTokens = _estimatedTokens(selectedSections);
    final estimatedCost = _estimatedCost(estimatedTokens);
    final memoryKeys = _memoryKeys(selectedSections);
    final createdAt = request.createdAt ?? DateTime.now();
    final metadata = PromptMetadata(
      intent: request.intent,
      createdAt: createdAt,
      version: request.version,
      sectionCount: selectedSections.length,
      estimatedTokens: estimatedTokens,
      estimatedCost: estimatedCost,
      requiresAI: node?.requiresAI ?? true,
      knowledgeNodeId: node?.id,
      notes: compression.notes,
    );

    return PromptPackage(
      id: '${request.intent.name}_${request.version.id}_package',
      intent: request.intent,
      sections: selectedSections,
      budget: request.budget,
      personality: request.personality,
      version: request.version,
      metadata: metadata,
      contextKeys: keys,
      memoryKeys: memoryKeys,
    );
  }

  Set<AIContextProviderKey> _relevantKeys(KnowledgeNode? node) {
    if (node == null) {
      return const <AIContextProviderKey>{AIContextProviderKey.currentQuestion};
    }

    return <AIContextProviderKey>{
      for (final item in node.requiredKnowledge) item.providerKey,
      for (final item in node.optionalKnowledge) item.providerKey,
    };
  }

  List<PromptSection> _sectionsFor({
    required PromptBuildRequest request,
    required KnowledgeNode? node,
    required Set<AIContextProviderKey> keys,
  }) {
    final sections = <PromptSection>[];
    if (node != null) {
      sections.add(
        PromptSection(
          id: 'knowledge.${node.id}',
          title: node.title,
          type: PromptSectionType.knowledge,
          content: <String, Object?>{
            'description': node.description,
            'missingBehaviour': node.missingBehaviour.name,
            'recommendedFollowUp': node.recommendedFollowUp,
            'defaultAction': node.defaultAction.wireName,
          },
          providerKey: null,
          required: true,
          priority: ContextPriority.required,
          estimatedTokens: 120,
        ),
      );
    }

    _addContextSections(sections, request.context, keys);
    _addMemorySections(sections, request.memories, node);
    return List<PromptSection>.unmodifiable(sections);
  }

  void _addContextSections(
    List<PromptSection> sections,
    PromptContext context,
    Set<AIContextProviderKey> keys,
  ) {
    if (keys.contains(AIContextProviderKey.currentQuestion) &&
        context.currentQuestion?.text != null) {
      sections.add(
        _section(
          id: 'context.current_question',
          title: 'Current Question',
          type: PromptSectionType.currentQuestion,
          content: context.currentQuestion!.text!,
          providerKey: AIContextProviderKey.currentQuestion,
          required: true,
          estimatedTokens: 80,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.profile) &&
        context.userProfile != null) {
      sections.add(
        _section(
          id: 'context.profile',
          title: 'User Profile',
          type: PromptSectionType.profile,
          content: context.userProfile!.data,
          providerKey: AIContextProviderKey.profile,
          required: true,
          estimatedTokens: 220,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.goals) && context.goal != null) {
      sections.add(
        _section(
          id: 'context.goals',
          title: 'Goals',
          type: PromptSectionType.goals,
          content: context.goal!.goals,
          providerKey: AIContextProviderKey.goals,
          required: true,
          estimatedTokens: 90,
        ),
      );
    }
    if ((keys.contains(AIContextProviderKey.activeProgram) ||
            keys.contains(AIContextProviderKey.workoutHistory)) &&
        context.workout != null) {
      sections.add(
        _section(
          id: 'context.workout',
          title: 'Workout Context',
          type: PromptSectionType.workout,
          content: <String, Object?>{
            'activeProgram': context.workout!.activeProgram,
            'historyCount': context.workout!.history.length,
          },
          providerKey: AIContextProviderKey.workoutHistory,
          required: keys.contains(AIContextProviderKey.workoutHistory),
          estimatedTokens: 260,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.heatmap) &&
        context.heatmap?.weekly != null) {
      sections.add(
        _section(
          id: 'context.heatmap',
          title: 'Heatmap',
          type: PromptSectionType.heatmap,
          content: context.heatmap!.weekly!.targets,
          providerKey: AIContextProviderKey.heatmap,
          required: true,
          estimatedTokens: 180,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.equipment) &&
        context.equipment != null) {
      sections.add(
        _section(
          id: 'context.equipment',
          title: 'Equipment',
          type: PromptSectionType.equipment,
          content: context.equipment!.items,
          providerKey: AIContextProviderKey.equipment,
          required: true,
          estimatedTokens: 90,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.restrictions) &&
        context.restrictions != null) {
      sections.add(
        _section(
          id: 'context.restrictions',
          title: 'Restrictions',
          type: PromptSectionType.restrictions,
          content: context.restrictions!.items,
          providerKey: AIContextProviderKey.restrictions,
          required: true,
          estimatedTokens: 120,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.preferences) &&
        context.preferences != null) {
      sections.add(
        _section(
          id: 'context.preferences',
          title: 'Preferences',
          type: PromptSectionType.preferences,
          content: context.preferences!.items,
          providerKey: AIContextProviderKey.preferences,
          required: false,
          estimatedTokens: 120,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.apiUsage) &&
        context.apiUsage != null) {
      sections.add(
        _section(
          id: 'context.api_usage',
          title: 'API Usage',
          type: PromptSectionType.apiUsage,
          content: context.apiUsage!.data,
          providerKey: AIContextProviderKey.apiUsage,
          required: false,
          estimatedTokens: 80,
        ),
      );
    }
    if (keys.contains(AIContextProviderKey.recovery) &&
        context.recovery != null) {
      sections.add(
        _section(
          id: 'context.recovery',
          title: 'Recovery',
          type: PromptSectionType.recovery,
          content: context.recovery!.data,
          providerKey: AIContextProviderKey.recovery,
          required: false,
          estimatedTokens: 120,
        ),
      );
    }
  }

  void _addMemorySections(
    List<PromptSection> sections,
    List<CoachMemory> memories,
    KnowledgeNode? node,
  ) {
    if (memories.isEmpty) return;
    final categories = _memoryCategoriesFor(node);
    final selected = memories
        .where(
          (memory) =>
              categories.isEmpty || categories.contains(memory.category),
        )
        .where((memory) => !memory.isExpired())
        .toList(growable: false);
    if (selected.isEmpty) return;

    sections.add(
      _section(
        id: 'memory.selected',
        title: 'Coach Memory',
        type: PromptSectionType.memory,
        content: selected
            .map((memory) => memory.toJson())
            .toList(growable: false),
        providerKey: AIContextProviderKey.memory,
        required: false,
        estimatedTokens: 240,
      ),
    );
  }

  Set<MemoryCategory> _memoryCategoriesFor(KnowledgeNode? node) {
    if (node == null) return const <MemoryCategory>{};
    final categories = <MemoryCategory>{};
    for (final requirement in <KnowledgeRequirement>[
      ...node.requiredKnowledge,
      ...node.optionalKnowledge,
    ]) {
      final mapped = _mapKnowledgeCategory(requirement.category);
      if (mapped != null) categories.add(mapped);
    }
    return categories;
  }

  MemoryCategory? _mapKnowledgeCategory(KnowledgeCategory category) {
    switch (category) {
      case KnowledgeCategory.profile:
        return MemoryCategory.profile;
      case KnowledgeCategory.goals:
        return MemoryCategory.goal;
      case KnowledgeCategory.workout:
        return MemoryCategory.workout;
      case KnowledgeCategory.recovery:
        return MemoryCategory.recovery;
      case KnowledgeCategory.nutrition:
        return MemoryCategory.nutrition;
      case KnowledgeCategory.medical:
        return MemoryCategory.medical;
      case KnowledgeCategory.equipment:
        return MemoryCategory.equipment;
      case KnowledgeCategory.memory:
        return MemoryCategory.preference;
      case KnowledgeCategory.app:
        return MemoryCategory.app;
      case KnowledgeCategory.progress:
      case KnowledgeCategory.heatmap:
      case KnowledgeCategory.subscription:
      case KnowledgeCategory.usage:
        return null;
    }
  }

  PromptSection _section({
    required String id,
    required String title,
    required PromptSectionType type,
    required Object content,
    required AIContextProviderKey providerKey,
    required bool required,
    required int estimatedTokens,
  }) {
    return PromptSection(
      id: id,
      title: title,
      type: type,
      content: content,
      providerKey: providerKey,
      required: required,
      priority: required ? ContextPriority.required : ContextPriority.medium,
      estimatedTokens: estimatedTokens,
    );
  }

  List<PromptSection> _fitBudget(
    List<PromptSection> sections,
    PromptBudget budget,
  ) {
    var usedTokens = 0;
    final selected = <PromptSection>[];
    for (final section in sections) {
      if (!budget.canInclude(
        usedTokens: usedTokens,
        estimatedTokens: section.estimatedTokens,
      )) {
        if (section.required) selected.add(section);
        continue;
      }
      selected.add(section);
      usedTokens += section.estimatedTokens;
    }
    return List<PromptSection>.unmodifiable(selected);
  }

  int _estimatedTokens(List<PromptSection> sections) {
    return sections.fold<int>(
      0,
      (total, section) => total + section.estimatedTokens,
    );
  }

  double _estimatedCost(int estimatedTokens) {
    return estimatedTokens / 4000;
  }

  List<String> _memoryKeys(List<PromptSection> sections) {
    final keys = <String>[];
    for (final section in sections) {
      if (section.type != PromptSectionType.memory) continue;
      final content = section.content;
      if (content is! Iterable<Object?>) continue;
      for (final item in content) {
        if (item is Map<String, Object?>) {
          final key = item['key'];
          if (key is String) keys.add(key);
        }
      }
    }
    return List<String>.unmodifiable(keys);
  }
}
