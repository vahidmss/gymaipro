/// Summary shown after a live workout session completes.
class LiveWorkoutCompletionSummary {
  const LiveWorkoutCompletionSummary({
    required this.title,
    required this.focus,
    required this.durationMinutes,
    required this.completedExercises,
    required this.totalExercises,
    required this.completedSets,
    required this.totalSets,
    required this.totalVolumeKg,
    required this.coachMessage,
    required this.highlights,
    required this.synced,
  });

  final String title;
  final String focus;
  final int durationMinutes;
  final int completedExercises;
  final int totalExercises;
  final int completedSets;
  final int totalSets;
  final double totalVolumeKg;
  final String coachMessage;
  final List<String> highlights;
  final bool synced;
}
