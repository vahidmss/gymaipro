import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modification.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_impact.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_request.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_versions.dart';
import 'package:gymaipro/ai/workout_modify/trace/workout_modify_trace_builder.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Output of a workout program modification run.
class WorkoutModificationResult {
  const WorkoutModificationResult({
    required this.enabled,
    required this.request,
    required this.originalProgram,
    required this.modifiedProgram,
    required this.modifications,
    required this.impact,
    required this.trace,
    required this.summary,
    this.engineVersion = WorkoutModifyVersions.engineVersion,
  });

  factory WorkoutModificationResult.disabled({
    required WorkoutModificationRequest request,
  }) {
    return WorkoutModificationResult(
      enabled: false,
      request: request,
      originalProgram: request.program,
      modifiedProgram: request.program,
      modifications: const <WorkoutModification>[],
      impact: const WorkoutModificationImpact(
        volumeDelta: 0,
        fatigueDelta: 0,
        recoveryDelta: 0,
        jointStressDelta: 0,
        goalAlignmentDelta: 0,
      ),
      trace: WorkoutModificationTrace(
        requested: const <WorkoutModification>[],
        applied: const <WorkoutModification>[],
        skipped: const <WorkoutModification>[],
        rejected: const <WorkoutModification>[],
        finalProgramId: request.program.id,
        steps: const <String>['coach_v2_disabled'],
      ),
      summary: 'Workout modify engine disabled (CoachV2 gate).',
    );
  }

  factory WorkoutModificationResult.fromJson(Map<String, Object?> json) {
    final requestRaw = json['request'];
    final originalRaw = json['originalProgram'];
    final modifiedRaw = json['modifiedProgram'];
    final impactRaw = json['impact'];
    final traceRaw = json['trace'];
    return WorkoutModificationResult(
      enabled: json['enabled'] == true,
      request: requestRaw is Map<String, Object?>
          ? WorkoutModificationRequest.fromJson(requestRaw)
          : WorkoutModificationRequest.fromJson(const <String, Object?>{}),
      originalProgram: originalRaw is Map<String, Object?>
          ? WorkoutProgram.fromJson(originalRaw)
          : WorkoutProgram.fromJson(const <String, Object?>{}),
      modifiedProgram: modifiedRaw is Map<String, Object?>
          ? WorkoutProgram.fromJson(modifiedRaw)
          : WorkoutProgram.fromJson(const <String, Object?>{}),
      modifications:
          (json['modifications'] as List<Object?>? ?? const <Object?>[])
              .whereType<Map<String, Object?>>()
              .map((item) => WorkoutModification.fromJson(_mapFromJson(item)))
              .toList(),
      impact: impactRaw is Map<String, Object?>
          ? WorkoutModificationImpact.fromJson(impactRaw)
          : WorkoutModificationImpact.fromJson(const <String, Object?>{}),
      trace: traceRaw is Map<String, Object?>
          ? WorkoutModificationTrace.fromJson(traceRaw)
          : WorkoutModificationTrace.fromJson(const <String, Object?>{}),
      summary: (json['summary'] as String?) ?? '',
      engineVersion:
          (json['engineVersion'] as String?) ??
          WorkoutModifyVersions.engineVersion,
    );
  }

  final bool enabled;
  final WorkoutModificationRequest request;
  final WorkoutProgram originalProgram;
  final WorkoutProgram modifiedProgram;
  final List<WorkoutModification> modifications;
  final WorkoutModificationImpact impact;
  final WorkoutModificationTrace trace;
  final String summary;
  final String engineVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'engineVersion': engineVersion,
    'summary': summary,
    'request': request.toJson(),
    'originalProgram': originalProgram.toJson(),
    'modifiedProgram': modifiedProgram.toJson(),
    'modifications': modifications.map((item) => item.toJson()).toList(),
    'impact': impact.toJson(),
    'trace': trace.toJson(),
  };

  WorkoutModificationResult copyWith({
    bool? enabled,
    WorkoutProgram? modifiedProgram,
    List<WorkoutModification>? modifications,
    WorkoutModificationImpact? impact,
    WorkoutModificationTrace? trace,
    String? summary,
  }) {
    return WorkoutModificationResult(
      enabled: enabled ?? this.enabled,
      request: request,
      originalProgram: originalProgram,
      modifiedProgram: modifiedProgram ?? this.modifiedProgram,
      modifications: modifications ?? this.modifications,
      impact: impact ?? this.impact,
      trace: trace ?? this.trace,
      summary: summary ?? this.summary,
      engineVersion: engineVersion,
    );
  }
}
