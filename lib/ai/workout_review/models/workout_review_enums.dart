/// Severity for a detected program issue.
enum WorkoutReviewIssueSeverity { low, medium, high, critical }

/// Known issue codes emitted by the review engine.
enum WorkoutReviewIssueCode {
  chestOverloaded,
  noPosteriorChain,
  tooMuchKneeStress,
  recoveryTooLow,
  tooManyCompoundExercises,
  missingDeload,
  weakShoulderBalance,
  noPullingVolume,
  excessiveIsolation,
  equipmentConflict,
  beginnerVolumeTooHigh,
  advancedVolumeTooLow,
  goalMismatch,
  emptyProgram,
}

/// Known recommendation codes emitted by the review engine.
enum WorkoutReviewRecommendationCode {
  reduceLegDayVolume,
  replaceSquatWithHackSquat,
  addFacePull,
  addHamstringExercise,
  increaseRest,
  reduceChestVolume,
  addBackExercise,
  addDeloadWeek,
  swapToHomeEquipment,
  reduceCompoundCount,
  addIsolationBalance,
  lowerSessionIntensity,
}
