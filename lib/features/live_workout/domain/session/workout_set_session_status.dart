/// Lifecycle state for a single logged set during live workout.
enum WorkoutSetSessionStatus {
  pending,
  current,
  completed,
  skipped,
  failed;

  bool get isTerminal =>
      this == WorkoutSetSessionStatus.completed ||
      this == WorkoutSetSessionStatus.skipped ||
      this == WorkoutSetSessionStatus.failed;

  String toJson() => name;

  static WorkoutSetSessionStatus fromJson(String? value) {
    return WorkoutSetSessionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => WorkoutSetSessionStatus.pending,
    );
  }
}
