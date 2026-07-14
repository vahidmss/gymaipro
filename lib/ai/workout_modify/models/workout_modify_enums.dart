/// Requested modification kinds supported by the modify engine.
enum WorkoutModificationType {
  replaceExercise,
  removeExercise,
  addExercise,
  reduceVolume,
  increaseVolume,
  reduceIntensity,
  increaseIntensity,
  shortenSession,
  homeVersion,
  gymVersion,
  injuryAdaptation,
  equipmentAdaptation,
  recoveryAdaptation,
}

/// Outcome status for a single modification attempt.
enum WorkoutModificationStatus { applied, skipped, rejected }
