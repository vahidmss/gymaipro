import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_note.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// A single training day inside a workout week.
class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.dayIndex,
    required this.label,
    required this.exercises,
    this.notes = const <WorkoutNote>[],
  });

  factory WorkoutDay.fromJson(Map<String, Object?> json) {
    return WorkoutDay(
      id: (json['id'] as String?) ?? '',
      dayIndex: (json['dayIndex'] as int?) ?? 0,
      label: (json['label'] as String?) ?? '',
      exercises: (json['exercises'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutExercise.fromJson(_mapFromJson(item)))
          .toList(),
      notes: (json['notes'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutNote.fromJson(_mapFromJson(item)))
          .toList(),
    );
  }

  final String id;
  final int dayIndex;
  final String label;
  final List<WorkoutExercise> exercises;
  final List<WorkoutNote> notes;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'dayIndex': dayIndex,
    'label': label,
    'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    'notes': notes.map((note) => note.toJson()).toList(),
  };
}
