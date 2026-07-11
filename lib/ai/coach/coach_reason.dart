/// Reasons explaining why the coach brain made a decision.
enum CoachReason {
  needMoreProfile,
  needWorkoutProgram,
  needWorkoutLogs,
  enoughContext,
  localAnswer,
  openAIRequired,
  validationFailed,
  missingProvider,
  lowConfidence,
  needCurrentQuestion,
  needGoals,
  needRestrictions,
  unsupportedLocalResponse,
}
