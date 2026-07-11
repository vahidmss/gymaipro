/// Reasons emitted while extracting memory from text.
enum MemoryExtractionReason {
  ruleMatched,
  explicitPreference,
  explicitGoal,
  restrictionMention,
  equipmentMention,
  nutritionMention,
  recoveryMention,
  appFeedback,
  duplicateDetected,
  conflictDetected,
  ignoredLowSignal,
  noRuleMatched,
}
