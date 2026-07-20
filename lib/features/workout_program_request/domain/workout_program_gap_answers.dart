/// Answers collected on the program-request gap-fill screen.
class WorkoutProgramGapAnswers {
  const WorkoutProgramGapAnswers({
    this.age,
    this.height,
    this.weight,
    this.goal,
    this.equipment,
    this.experience,
    this.daysPerWeek,
    this.sessionMinutes,
    this.injuries = const <String>[],
    this.priorityMuscles = const <String>[],
  });

  final int? age;
  final double? height;
  final double? weight;
  final String? goal;
  final String? equipment;
  final String? experience;
  final int? daysPerWeek;
  final int? sessionMinutes;
  final List<String> injuries;
  final List<String> priorityMuscles;

  WorkoutProgramGapAnswers copyWith({
    int? age,
    double? height,
    double? weight,
    String? goal,
    String? equipment,
    String? experience,
    int? daysPerWeek,
    int? sessionMinutes,
    List<String>? injuries,
    List<String>? priorityMuscles,
  }) {
    return WorkoutProgramGapAnswers(
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      goal: goal ?? this.goal,
      equipment: equipment ?? this.equipment,
      experience: experience ?? this.experience,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      injuries: injuries ?? this.injuries,
      priorityMuscles: priorityMuscles ?? this.priorityMuscles,
    );
  }
}
