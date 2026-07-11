/// Token and cost budget for building a future prompt package.
class PromptBudget {
  const PromptBudget({
    required this.maxTokens,
    required this.reservedResponseTokens,
    required this.maxEstimatedCost,
    this.maxSectionTokens,
  });

  /// Conservative default for dry-run planning.
  static const standard = PromptBudget(
    maxTokens: 4000,
    reservedResponseTokens: 1200,
    maxEstimatedCost: 1,
    maxSectionTokens: 900,
  );

  /// Maximum total prompt+response tokens.
  final int maxTokens;

  /// Tokens reserved for the model response.
  final int reservedResponseTokens;

  /// Optional max tokens per section.
  final int? maxSectionTokens;

  /// Relative max cost budget.
  final double maxEstimatedCost;

  /// Estimated input tokens available for prompt sections.
  int get availableInputTokens {
    final available = maxTokens - reservedResponseTokens;
    if (available < 0) return 0;
    return available;
  }

  /// Whether a section with [estimatedTokens] can fit after [usedTokens].
  bool canInclude({required int usedTokens, required int estimatedTokens}) {
    final sectionLimit = maxSectionTokens;
    if (sectionLimit != null && estimatedTokens > sectionLimit) return false;
    return usedTokens + estimatedTokens <= availableInputTokens;
  }
}
