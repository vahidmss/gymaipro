import 'package:gymaipro/ai/workout_modify/models/workout_modification.dart';

/// Full modification audit trail.
class WorkoutModificationTrace {
  const WorkoutModificationTrace({
    required this.requested,
    required this.applied,
    required this.skipped,
    required this.rejected,
    required this.finalProgramId,
    this.steps = const <String>[],
    this.modifyDuration = Duration.zero,
  });

  factory WorkoutModificationTrace.fromJson(Map<String, Object?> json) {
    return WorkoutModificationTrace(
      requested: _mods(json['requested']),
      applied: _mods(json['applied']),
      skipped: _mods(json['skipped']),
      rejected: _mods(json['rejected']),
      finalProgramId: (json['finalProgramId'] as String?) ?? '',
      steps: (json['steps'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      modifyDuration: Duration(
        milliseconds: (json['modifyDurationMs'] as int?) ?? 0,
      ),
    );
  }

  final List<WorkoutModification> requested;
  final List<WorkoutModification> applied;
  final List<WorkoutModification> skipped;
  final List<WorkoutModification> rejected;
  final String finalProgramId;
  final List<String> steps;
  final Duration modifyDuration;

  static List<WorkoutModification> _mods(Object? value) {
    if (value is! List<Object?>) return const <WorkoutModification>[];
    return value
        .whereType<Map<String, Object?>>()
        .map(WorkoutModification.fromJson)
        .toList();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'requested': requested.map((item) => item.toJson()).toList(),
    'applied': applied.map((item) => item.toJson()).toList(),
    'skipped': skipped.map((item) => item.toJson()).toList(),
    'rejected': rejected.map((item) => item.toJson()).toList(),
    'finalProgramId': finalProgramId,
    'steps': steps,
    'modifyDurationMs': modifyDuration.inMilliseconds,
  };

  WorkoutModificationTrace copyWith({
    List<WorkoutModification>? applied,
    String? finalProgramId,
  }) {
    return WorkoutModificationTrace(
      requested: requested,
      applied: applied ?? this.applied,
      skipped: skipped,
      rejected: rejected,
      finalProgramId: finalProgramId ?? this.finalProgramId,
      steps: steps,
      modifyDuration: modifyDuration,
    );
  }
}
