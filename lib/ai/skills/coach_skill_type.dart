/// Stable skill families supported by the Coach Skill Engine.
enum CoachSkillType {
  workoutToday,
  workoutGeneration,
  heatmap,
  recovery,
  progressSummary,
  motivation,
  appHelp,
}

/// Outcome category for a skill evaluation.
enum SkillOutcome {
  handledLocally,
  partialLocal,
  requiresAI,
  insufficientContext,
}
