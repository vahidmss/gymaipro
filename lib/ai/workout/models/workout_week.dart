import 'package:gymaipro/ai/workout/models/workout_day.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// A week block inside a workout program.
class WorkoutWeek {
  const WorkoutWeek({
    required this.id,
    required this.weekIndex,
    required this.days,
  });

  factory WorkoutWeek.fromJson(Map<String, Object?> json) {
    return WorkoutWeek(
      id: (json['id'] as String?) ?? '',
      weekIndex: (json['weekIndex'] as int?) ?? 0,
      days: (json['days'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutDay.fromJson(_mapFromJson(item)))
          .toList(),
    );
  }

  final String id;
  final int weekIndex;
  final List<WorkoutDay> days;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'weekIndex': weekIndex,
    'days': days.map((day) => day.toJson()).toList(),
  };
}
