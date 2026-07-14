/// Entity categories extracted from user messages before prompt construction.
enum EntityType {
  height,
  weight,
  age,
  gender,
  goal,
  equipment,
  experience,
  injury,
  medicalCondition,
  muscleGroup,
  exerciseName,
  workoutDay,
  timeExpression,
  supplement,
  food,
  sleepDuration,
  waterIntake,
}

/// Extraction strategy used by an entity rule.
enum EntityRuleType { keyword, regex }

/// Canonical value kind after normalization.
enum EntityValueKind { text, number, duration, volume, enumValue }
