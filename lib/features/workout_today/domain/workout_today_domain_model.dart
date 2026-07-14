/// Domain-shaped model for the Workout Today experience.
class WorkoutTodayDomainModel {
  const WorkoutTodayDomainModel({
    required this.userName,
    required this.headline,
    required this.recoveryPercent,
    required this.durationMinutes,
    required this.exercises,
    required this.totalSets,
    required this.muscleGroups,
    required this.intensity,
    required this.coachNotes,
    required this.reasons,
  });

  final String userName;
  final String headline;
  final int recoveryPercent;
  final int durationMinutes;
  final List<WorkoutTodayExercise> exercises;
  final int totalSets;
  final List<String> muscleGroups;
  final String intensity;
  final List<String> coachNotes;
  final List<String> reasons;
}

class WorkoutTodayExercise {
  const WorkoutTodayExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.primaryMuscle,
    this.restSeconds,
    this.tempo,
    this.notes,
    this.weightKg,
  });

  final String name;
  final int sets;
  final int reps;
  final String primaryMuscle;
  final int? restSeconds;
  final String? tempo;
  final String? notes;
  final double? weightKg;
}
