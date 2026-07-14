import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';

/// Typed runtime model for one set being logged in live workout.
class WorkoutSetSession {
  const WorkoutSetSession({
    required this.index,
    required this.targetReps,
    required this.targetWeightKg,
    this.actualReps,
    this.actualWeightKg,
    this.rpe,
    this.durationSeconds,
    this.notes,
    this.restSeconds = 90,
    this.status = WorkoutSetSessionStatus.pending,
  });

  final int index;
  final int targetReps;
  final double targetWeightKg;
  final int? actualReps;
  final double? actualWeightKg;
  final int? rpe;
  final int? durationSeconds;
  final String? notes;
  final int restSeconds;
  final WorkoutSetSessionStatus status;

  int get effectiveReps => actualReps ?? targetReps;

  double get effectiveWeightKg => actualWeightKg ?? targetWeightKg;

  WorkoutSetSession copyWith({
    int? actualReps,
    double? actualWeightKg,
    int? rpe,
    int? durationSeconds,
    String? notes,
    int? restSeconds,
    WorkoutSetSessionStatus? status,
    bool clearNotes = false,
  }) {
    return WorkoutSetSession(
      index: index,
      targetReps: targetReps,
      targetWeightKg: targetWeightKg,
      actualReps: actualReps ?? this.actualReps,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      rpe: rpe ?? this.rpe,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: clearNotes ? null : (notes ?? this.notes),
      restSeconds: restSeconds ?? this.restSeconds,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'index': index,
      'targetReps': targetReps,
      'targetWeightKg': targetWeightKg,
      'actualReps': actualReps,
      'actualWeightKg': actualWeightKg,
      'rpe': rpe,
      'durationSeconds': durationSeconds,
      'notes': notes,
      'restSeconds': restSeconds,
      'status': status.toJson(),
    };
  }

  factory WorkoutSetSession.fromJson(Map<String, Object?> json) {
    return WorkoutSetSession(
      index: _readInt(json['index'], fallback: 1),
      targetReps: _readInt(json['targetReps'], fallback: 0),
      targetWeightKg: _readDouble(json['targetWeightKg']),
      actualReps: json['actualReps'] == null
          ? null
          : _readInt(json['actualReps']),
      actualWeightKg: json['actualWeightKg'] == null
          ? null
          : _readDouble(json['actualWeightKg']),
      rpe: json['rpe'] == null ? null : _readInt(json['rpe']),
      durationSeconds: json['durationSeconds'] == null
          ? null
          : _readInt(json['durationSeconds']),
      notes: json['notes']?.toString(),
      restSeconds: _readInt(json['restSeconds'], fallback: 90),
      status: WorkoutSetSessionStatus.fromJson(json['status']?.toString()),
    );
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _readDouble(Object? value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
