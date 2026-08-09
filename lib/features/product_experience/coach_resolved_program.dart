import 'package:gymaipro/ai/workout/models/workout_program.dart' as ai;

/// Exercise row resolved from a real stored or generated workout program.
class CoachResolvedExercise {
  const CoachResolvedExercise({
    required this.name,
    required this.primaryMuscle,
    required this.sets,
    required this.reps,
    this.exerciseId,
    this.restSeconds,
    this.tempo,
    this.notes,
    this.weightKg,
    this.repsPerSet,
  });

  final String name;
  final int? exerciseId;
  final String primaryMuscle;
  final int sets;
  final int reps;
  final int? restSeconds;
  final String? tempo;
  final String? notes;
  final double? weightKg;
  /// When non-null and length matches [sets], per-set targets (e.g. 12-10-8).
  final List<int>? repsPerSet;

  /// Display scheme: `۳ × ۱۰` or `۱۲ - ۱۰ - ۸`.
  String get repsScheme {
    final perSet = repsPerSet;
    if (perSet != null &&
        perSet.length == sets &&
        perSet.isNotEmpty &&
        !perSet.every((v) => v == perSet.first)) {
      return perSet.join(' - ');
    }
    return '$sets × $reps';
  }
}

/// Today's workout resolved from CoachContext + integration payloads.
class CoachResolvedTodayWorkout {
  const CoachResolvedTodayWorkout({
    required this.title,
    required this.focus,
    required this.sessionLabel,
    required this.durationMinutes,
    required this.exercises,
    required this.muscleGroups,
    required this.intensity,
    this.aiProgram,
  });

  final String title;
  final String focus;
  final String sessionLabel;
  final int durationMinutes;
  final List<CoachResolvedExercise> exercises;
  final List<String> muscleGroups;
  final String intensity;
  final ai.WorkoutProgram? aiProgram;

  int get exerciseCount => exercises.length;

  int get totalSets =>
      exercises.fold<int>(0, (sum, exercise) => sum + exercise.sets);
}
