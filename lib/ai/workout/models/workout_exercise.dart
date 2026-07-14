import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_note.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Exercise block inside a workout day.
class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.catalogExerciseId,
    required this.name,
    required this.primaryMuscle,
    required this.order,
    required this.sets,
    this.secondaryMuscles = const <String>[],
    this.equipment = '',
    this.difficulty = '',
    this.isCompound = false,
    this.notes = const <WorkoutNote>[],
    this.selectionReasons = const <WorkoutGeneratorReason>[],
  });

  factory WorkoutExercise.fromJson(Map<String, Object?> json) {
    return WorkoutExercise(
      id: (json['id'] as String?) ?? '',
      catalogExerciseId: (json['catalogExerciseId'] as int?) ?? 0,
      name: (json['name'] as String?) ?? '',
      primaryMuscle: (json['primaryMuscle'] as String?) ?? '',
      secondaryMuscles: List<String>.from(
        (json['secondaryMuscles'] as List<Object?>?) ?? const <Object?>[],
      ),
      equipment: (json['equipment'] as String?) ?? '',
      difficulty: (json['difficulty'] as String?) ?? '',
      isCompound: json['isCompound'] == true,
      order: (json['order'] as int?) ?? 0,
      sets: (json['sets'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutSet.fromJson(_mapFromJson(item)))
          .toList(),
      notes: (json['notes'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutNote.fromJson(_mapFromJson(item)))
          .toList(),
      selectionReasons:
          (json['selectionReasons'] as List<Object?>? ?? const <Object?>[])
              .whereType<Map<String, Object?>>()
              .map(
                (item) => WorkoutGeneratorReason.fromJson(_mapFromJson(item)),
              )
              .toList(),
    );
  }

  final String id;
  final int catalogExerciseId;
  final String name;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final String difficulty;
  final bool isCompound;
  final int order;
  final List<WorkoutSet> sets;
  final List<WorkoutNote> notes;
  final List<WorkoutGeneratorReason> selectionReasons;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'catalogExerciseId': catalogExerciseId,
    'name': name,
    'primaryMuscle': primaryMuscle,
    'secondaryMuscles': secondaryMuscles,
    'equipment': equipment,
    'difficulty': difficulty,
    'isCompound': isCompound,
    'order': order,
    'sets': sets.map((set) => set.toJson()).toList(),
    'notes': notes.map((note) => note.toJson()).toList(),
    'selectionReasons':
        selectionReasons.map((reason) => reason.toJson()).toList(),
  };
}
