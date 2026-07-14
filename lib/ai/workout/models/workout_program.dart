import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Source of a generated workout program.
enum WorkoutProgramSource { coachGeneratorV1 }

/// Lifecycle status for persistence and UI editing.
enum WorkoutProgramStatus { draft, active, archived }

/// Typed workout program produced by the Coach workout generator.
///
/// Designed for DB persistence, versioning, sync, and drag-and-drop UI.
class WorkoutProgram {
  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.goal,
    required this.experienceLevel,
    required this.daysPerWeek,
    required this.weeks,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.version = 1,
    this.status = WorkoutProgramStatus.draft,
    this.source = WorkoutProgramSource.coachGeneratorV1,
    this.programReasons = const <WorkoutGeneratorReason>[],
    this.sessionDurationMinutes,
  });

  factory WorkoutProgram.fromJson(Map<String, Object?> json) {
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    return WorkoutProgram(
      id: (json['id'] as String?) ?? '',
      userId: json['userId'] as String?,
      name: (json['name'] as String?) ?? '',
      version: (json['version'] as int?) ?? 1,
      status: WorkoutProgramStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => WorkoutProgramStatus.draft,
      ),
      source: WorkoutProgramSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => WorkoutProgramSource.coachGeneratorV1,
      ),
      goal: TrainingGoal.values.firstWhere(
        (value) => value.name == json['goal'],
        orElse: () => TrainingGoal.general,
      ),
      experienceLevel: (json['experienceLevel'] as String?) ?? 'متوسط',
      daysPerWeek: (json['daysPerWeek'] as int?) ?? 3,
      sessionDurationMinutes: json['sessionDurationMinutes'] as int?,
      weeks: (json['weeks'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutWeek.fromJson(_mapFromJson(item)))
          .toList(),
      programReasons:
          (json['programReasons'] as List<Object?>? ?? const <Object?>[])
              .whereType<Map<String, Object?>>()
              .map(
                (item) => WorkoutGeneratorReason.fromJson(_mapFromJson(item)),
              )
              .toList(),
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final String id;
  final String? userId;
  final String name;
  final int version;
  final WorkoutProgramStatus status;
  final WorkoutProgramSource source;
  final TrainingGoal goal;
  final String experienceLevel;
  final int daysPerWeek;
  final int? sessionDurationMinutes;
  final List<WorkoutWeek> weeks;
  final List<WorkoutGeneratorReason> programReasons;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<WorkoutDay> get allDays =>
      weeks.expand((week) => week.days).toList(growable: false);

  int get totalExercises =>
      allDays.fold<int>(0, (count, day) => count + day.exercises.length);

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'userId': userId,
    'name': name,
    'version': version,
    'status': status.name,
    'source': source.name,
    'goal': goal.name,
    'experienceLevel': experienceLevel,
    'daysPerWeek': daysPerWeek,
    if (sessionDurationMinutes != null)
      'sessionDurationMinutes': sessionDurationMinutes,
    'weeks': weeks.map((week) => week.toJson()).toList(),
    'programReasons':
        programReasons.map((reason) => reason.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
