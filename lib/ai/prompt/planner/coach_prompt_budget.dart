/// Token budget calculated by the Coach prompt planner.
class CoachPromptBudget {
  const CoachPromptBudget({
    required this.maxTokens,
    required this.reservedForResponse,
    required this.estimatedPromptTokens,
  });

  /// Maximum total prompt + response tokens.
  final int maxTokens;

  /// Tokens reserved for model response.
  final int reservedForResponse;

  /// Tokens estimated for selected prompt sections.
  final int estimatedPromptTokens;

  /// Tokens available for prompt sections.
  int get availablePromptTokens {
    final available = maxTokens - reservedForResponse;
    return available < 0 ? 0 : available;
  }

  /// Prompt token budget remaining after selected sections.
  int get remainingTokens => availablePromptTokens - estimatedPromptTokens;

  CoachPromptBudget copyWith({
    int? maxTokens,
    int? reservedForResponse,
    int? estimatedPromptTokens,
  }) {
    return CoachPromptBudget(
      maxTokens: maxTokens ?? this.maxTokens,
      reservedForResponse: reservedForResponse ?? this.reservedForResponse,
      estimatedPromptTokens:
          estimatedPromptTokens ?? this.estimatedPromptTokens,
    );
  }
}
