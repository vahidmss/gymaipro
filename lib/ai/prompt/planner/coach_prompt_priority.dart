/// Priority used by the Coach prompt planning engine.
enum CoachPromptPriority {
  critical,
  high,
  medium,
  low,
}

extension CoachPromptPriorityRank on CoachPromptPriority {
  /// Higher values are kept earlier when the optimizer sorts sections.
  int get rank {
    switch (this) {
      case CoachPromptPriority.critical:
        return 4;
      case CoachPromptPriority.high:
        return 3;
      case CoachPromptPriority.medium:
        return 2;
      case CoachPromptPriority.low:
        return 1;
    }
  }
}
