/// Capability-first feature surface for GymAI Coach.
///
/// Future skills, strategies, prompts, and services should declare required
/// capabilities from this enum instead of checking subscription plans directly.
enum CoachCapability {
  generateWorkout,
  modifyWorkout,
  analyzeProgress,
  explainHeatmap,
  recoveryAnalysis,
  nutritionPlanning,
  supplementAdvice,
  advancedMemory,
  unlimitedMessages,
  coachConversation,
  aiWorkoutReview,
  aiProgramReview,
  aiNutritionReview,
  premiumReasoning,
}

/// Metadata for one coach capability.
class CoachCapabilityDefinition {
  const CoachCapabilityDefinition({
    required this.capability,
    required this.id,
    required this.title,
    required this.description,
    this.requiresOnlineAI = false,
    this.defaultDailyLimit,
    this.defaultMonthlyLimit,
    this.defaultTokenLimit,
    this.tags = const <String>[],
  });

  /// Capability enum value.
  final CoachCapability capability;

  /// Stable machine id.
  final String id;

  /// Human-readable capability title.
  final String title;

  /// Product description.
  final String description;

  /// Whether this capability normally requires a remote AI model.
  final bool requiresOnlineAI;

  /// Optional default daily allowance.
  final int? defaultDailyLimit;

  /// Optional default monthly allowance.
  final int? defaultMonthlyLimit;

  /// Optional token allowance.
  final int? defaultTokenLimit;

  /// Optional future grouping tags.
  final List<String> tags;
}
