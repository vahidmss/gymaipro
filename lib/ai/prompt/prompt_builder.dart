import 'package:gymaipro/ai/prompt/planner/coach_prompt_plan.dart';
import 'package:gymaipro/ai/prompt/prompt_budget.dart';
import 'package:gymaipro/ai/prompt/prompt_metadata.dart';
import 'package:gymaipro/ai/prompt/prompt_package.dart';
import 'package:gymaipro/ai/prompt/prompt_section.dart';

/// Renders optimized [CoachPromptPlan] packages for Coach v2 runtime.
///
/// Does not render text prompts and does not call OpenAI.
class PromptBuilder {
  const PromptBuilder();

  /// Renders an already optimized Coach prompt plan into a package.
  PromptPackage buildFromPlan(CoachPromptPlan plan) {
    final sections = plan.sections
        .where((section) => !section.removed)
        .map((section) => section.toPromptSection())
        .toList(growable: false);
    final budget = PromptBudget(
      maxTokens: plan.budget.maxTokens,
      reservedResponseTokens: plan.budget.reservedForResponse,
      maxEstimatedCost: 1,
    );
    final createdAt = plan.createdAt ?? DateTime.now();
    final metadata = PromptMetadata(
      intent: plan.intent,
      createdAt: createdAt,
      version: plan.version,
      sectionCount: sections.length,
      estimatedTokens: plan.estimatedTokens,
      estimatedCost: _estimatedCost(plan.estimatedTokens),
      requiresAI: plan.knowledgeNode?.requiresAI ?? true,
      knowledgeNodeId: plan.knowledgeNode?.id,
      notes: <String>[
        ...plan.warnings,
        if (plan.compressedSections.isNotEmpty)
          'Compressed sections: ${plan.compressedSections.map((s) => s.id).join(', ')}.',
        if (plan.removedSections.isNotEmpty)
          'Removed sections: ${plan.removedSections.map((s) => s.id).join(', ')}.',
      ],
    );

    return PromptPackage(
      id: '${plan.intent.name}_${plan.version.id}_package',
      intent: plan.intent,
      sections: List<PromptSection>.unmodifiable(sections),
      budget: budget,
      personality: plan.personality,
      version: plan.version,
      metadata: metadata,
      contextKeys: plan.contextKeys,
      memoryKeys: plan.memoryKeys,
    );
  }

  double _estimatedCost(int estimatedTokens) {
    return estimatedTokens / 4000;
  }
}
