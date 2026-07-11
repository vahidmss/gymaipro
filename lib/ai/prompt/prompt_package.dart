import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/prompt/prompt_budget.dart';
import 'package:gymaipro/ai/prompt/prompt_metadata.dart';
import 'package:gymaipro/ai/prompt/prompt_personality.dart';
import 'package:gymaipro/ai/prompt/prompt_section.dart';
import 'package:gymaipro/ai/prompt/prompt_version.dart';

/// Standard package produced by PromptBuilder.
///
/// This is a data model only and is not connected to existing prompts or OpenAI.
class PromptPackage {
  const PromptPackage({
    required this.id,
    required this.intent,
    required this.sections,
    required this.budget,
    required this.personality,
    required this.version,
    required this.metadata,
    required this.contextKeys,
    required this.memoryKeys,
  });

  /// Stable package id.
  final String id;

  /// Intent represented by the package.
  final AIIntent intent;

  /// Structured sections selected for this intent.
  final List<PromptSection> sections;

  /// Budget used during package construction.
  final PromptBudget budget;

  /// Personality selected for future rendering.
  final PromptPersonality personality;

  /// Prompt architecture version.
  final PromptVersion version;

  /// Package metadata.
  final PromptMetadata metadata;

  /// Context keys represented by package sections.
  final Set<AIContextProviderKey> contextKeys;

  /// Memory keys included in package sections.
  final List<String> memoryKeys;
}
