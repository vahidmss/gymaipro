import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';

/// Typed runtime model for one exercise within a live workout session.
class WorkoutExerciseSession {
  const WorkoutExerciseSession({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    required this.sets,
    this.exerciseId,
    this.defaultRestSeconds = 90,
  });

  final String id;
  final String name;
  final String primaryMuscle;
  final int? exerciseId;
  final List<WorkoutSetSession> sets;
  final int defaultRestSeconds;

  int get completedSets => sets
      .where(
        (set) =>
            set.status == WorkoutSetSessionStatus.completed ||
            set.status == WorkoutSetSessionStatus.skipped,
      )
      .length;

  bool get isCompleted =>
      sets.isNotEmpty &&
      sets.every((set) => set.status.isTerminal);

  WorkoutExerciseSession copyWith({List<WorkoutSetSession>? sets}) {
    return WorkoutExerciseSession(
      id: id,
      name: name,
      primaryMuscle: primaryMuscle,
      exerciseId: exerciseId,
      sets: sets ?? this.sets,
      defaultRestSeconds: defaultRestSeconds,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'primaryMuscle': primaryMuscle,
      'exerciseId': exerciseId,
      'defaultRestSeconds': defaultRestSeconds,
      'sets': sets.map((set) => set.toJson()).toList(growable: false),
    };
  }

  factory WorkoutExerciseSession.fromJson(Map<String, Object?> json) {
    final rawSets = json['sets'];
    return WorkoutExerciseSession(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      primaryMuscle: json['primaryMuscle']?.toString() ?? '',
      exerciseId: json['exerciseId'] == null
          ? null
          : int.tryParse(json['exerciseId'].toString()),
      defaultRestSeconds: int.tryParse(
            json['defaultRestSeconds']?.toString() ?? '',
          ) ??
          90,
      sets: rawSets is List<Object?>
          ? rawSets
                .whereType<Map<String, Object?>>()
                .map(WorkoutSetSession.fromJson)
                .toList(growable: false)
          : const <WorkoutSetSession>[],
    );
  }
}
