class LiveWorkoutSession {
  const LiveWorkoutSession({
    required this.title,
    required this.focus,
    required this.estimatedMinutes,
    required this.exercises,
    required this.coachTips,
    required this.explainability,
  });

  final String title;
  final String focus;
  final int estimatedMinutes;
  final List<LiveWorkoutExercise> exercises;
  final List<String> coachTips;
  final List<String> explainability;

  int get totalExercises => exercises.length;

  int get totalSets =>
      exercises.fold<int>(0, (sum, exercise) => sum + exercise.sets.length);
}

class LiveWorkoutExercise {
  const LiveWorkoutExercise({
    required this.name,
    required this.primaryMuscle,
    required this.sets,
  });

  final String name;
  final String primaryMuscle;
  final List<LiveWorkoutSet> sets;
}

class LiveWorkoutSet {
  const LiveWorkoutSet({
    required this.index,
    required this.reps,
    required this.weightKg,
  });

  final int index;
  final int reps;
  final double weightKg;
}
