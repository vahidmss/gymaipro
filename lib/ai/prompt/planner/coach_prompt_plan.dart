import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/knowledge_node.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_budget.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_priority.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_section.dart';
import 'package:gymaipro/ai/prompt/planner/coach_prompt_trace.dart';
import 'package:gymaipro/ai/prompt/prompt_personality.dart';
import 'package:gymaipro/ai/prompt/prompt_version.dart';

/// Token-aware plan consumed by PromptBuilder.
class CoachPromptPlan {
  const CoachPromptPlan({
    required this.intent,
    required this.sections,
    required this.priority,
    required this.estimatedTokens,
    required this.removedSections,
    required this.compressedSections,
    required this.warnings,
    required this.trace,
    required this.budget,
    required this.contextKeys,
    required this.memoryKeys,
    this.knowledgeNode,
    this.personality = PromptPersonality.gymAiCoach,
    this.version = PromptVersion.v1,
    this.createdAt,
  });

  final AIIntent intent;
  final List<CoachPromptSection> sections;
  final CoachPromptPriority priority;
  final int estimatedTokens;
  final List<CoachPromptSection> removedSections;
  final List<CoachPromptSection> compressedSections;
  final List<String> warnings;
  final CoachPromptTrace trace;
  final CoachPromptBudget budget;
  final Set<AIContextProviderKey> contextKeys;
  final List<String> memoryKeys;
  final KnowledgeNode? knowledgeNode;
  final PromptPersonality personality;
  final PromptVersion version;
  final DateTime? createdAt;
}
