/// High-level strategy families produced by the Coach Strategy Engine.
enum CoachStrategyType {
  conversational,
  followUpCollection,
  aiCoaching,
  localGuidance,
  programFocus,
  progressReview,
  recoveryFocus,
  safetyGate,
  errorFallback,
}

/// Product-facing recommendation style for a coach strategy.
enum CoachRecommendationType {
  answer,
  coach,
  navigate,
  collectData,
  explain,
  motivate,
  defer,
}

/// Tone guidance for future response rendering.
enum CoachStrategyTone {
  neutral,
  supportive,
  direct,
  educational,
  motivational,
  cautious,
}

/// Safety signals attached to a coach strategy.
enum CoachSafetyFlag {
  medicalRestrictionsPresent,
  missingRestrictionsData,
  workoutGenerationBlocked,
  lowContextConfidence,
  apiUsageLimited,
  providerGap,
}
