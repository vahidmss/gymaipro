/// Canonical movement pattern for exercise intelligence.
enum ExerciseMovementPattern {
  horizontalPush,
  horizontalPull,
  verticalPush,
  verticalPull,
  squat,
  hinge,
  lunge,
  carry,
  rotation,
  isolation,
  cardio,
  other,
}

/// How force is applied during the movement.
enum ExerciseMovementType {
  compound,
  isolation,
  plyometric,
  isometric,
  cardio,
  mobility,
}

/// Equipment required to perform the exercise.
enum ExerciseEquipmentType {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  band,
  other,
}

/// Difficulty tier for programming filters.
enum ExerciseDifficultyLevel {
  beginner,
  intermediate,
  advanced,
}

/// Minimum experience required to perform safely.
enum ExerciseExperienceLevel {
  beginner,
  intermediate,
  advanced,
}

/// Grip orientation used during execution.
enum ExerciseGripType {
  pronated,
  supinated,
  neutral,
  mixed,
  none,
}

/// Relative joint stress level.
enum ExerciseJointStressLevel {
  none,
  low,
  moderate,
  high,
}
