import 'package:gymaipro/ai/workout/models/workout_progression.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Set type for a workout exercise.
enum WorkoutSetType { reps, time, amrap }

/// A single work set inside an exercise block.
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.order,
    required this.type,
    this.reps,
    this.timeSeconds,
    this.weightKg,
    this.rir,
    this.progression,
  });

  factory WorkoutSet.fromJson(Map<String, Object?> json) {
    final progressionRaw = json['progression'];
    return WorkoutSet(
      id: (json['id'] as String?) ?? '',
      order: (json['order'] as int?) ?? 0,
      type: WorkoutSetType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => WorkoutSetType.reps,
      ),
      reps: json['reps'] as int?,
      timeSeconds: json['timeSeconds'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      rir: json['rir'] as int?,
      progression: progressionRaw is Map
          ? WorkoutProgression.fromJson(_mapFromJson(progressionRaw))
          : null,
    );
  }

  final String id;
  final int order;
  final WorkoutSetType type;
  final int? reps;
  final int? timeSeconds;
  final double? weightKg;
  final int? rir;
  final WorkoutProgression? progression;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'order': order,
    'type': type.name,
    if (reps != null) 'reps': reps,
    if (timeSeconds != null) 'timeSeconds': timeSeconds,
    if (weightKg != null) 'weightKg': weightKg,
    if (rir != null) 'rir': rir,
    if (progression != null) 'progression': progression!.toJson(),
  };
}
