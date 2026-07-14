import 'package:gymaipro/ai/knowledge/workout_science.dart';

/// Query context for exercise intelligence engines.
///
/// Standalone from workout generator and blueprint models.
class ExerciseIntelligenceQuery {
  const ExerciseIntelligenceQuery({
    this.goal = TrainingGoal.general,
    this.experience = 'متوسط',
    this.availableEquipment = const <String>[],
    this.limitations = const <String>[],
    this.recoveryScore = 1,
    this.targetMuscles = const <String>[],
    this.avoidExerciseNames = const <String>[],
    this.maxFatigueBudget = 0.75,
    this.preferCompound = true,
    this.sessionFatigueAccumulated = 0,
  });

  final TrainingGoal goal;
  final String experience;
  final List<String> availableEquipment;
  final List<String> limitations;
  final double recoveryScore;
  final List<String> targetMuscles;
  final List<String> avoidExerciseNames;
  final double maxFatigueBudget;
  final bool preferCompound;
  final double sessionFatigueAccumulated;

  ExerciseIntelligenceQuery copyWith({
    TrainingGoal? goal,
    String? experience,
    List<String>? availableEquipment,
    List<String>? limitations,
    double? recoveryScore,
    List<String>? targetMuscles,
    List<String>? avoidExerciseNames,
    double? maxFatigueBudget,
    bool? preferCompound,
    double? sessionFatigueAccumulated,
  }) {
    return ExerciseIntelligenceQuery(
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      limitations: limitations ?? this.limitations,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      avoidExerciseNames: avoidExerciseNames ?? this.avoidExerciseNames,
      maxFatigueBudget: maxFatigueBudget ?? this.maxFatigueBudget,
      preferCompound: preferCompound ?? this.preferCompound,
      sessionFatigueAccumulated:
          sessionFatigueAccumulated ?? this.sessionFatigueAccumulated,
    );
  }
}
