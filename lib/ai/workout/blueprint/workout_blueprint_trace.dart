import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_decision_step.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Trace emitted while building a workout blueprint.
class WorkoutBlueprintTrace {
  const WorkoutBlueprintTrace({
    required this.steps,
    required this.recoveryScore,
    this.knowledgeNodeId,
    this.memorySignals = const <String>[],
    this.decisions = const <WorkoutBlueprintDecisionStep>[],
    this.buildDuration = Duration.zero,
  });

  factory WorkoutBlueprintTrace.fromJson(Map<String, Object?> json) {
    return WorkoutBlueprintTrace(
      steps: (json['steps'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      recoveryScore: (json['recoveryScore'] as num?)?.toDouble() ?? 1,
      knowledgeNodeId: json['knowledgeNodeId'] as String?,
      memorySignals:
          (json['memorySignals'] as List<Object?>? ?? const <Object?>[])
              .map((item) => item.toString())
              .toList(),
      decisions: (json['decisions'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map(
            (item) =>
                WorkoutBlueprintDecisionStep.fromJson(_mapFromJson(item)),
          )
          .toList(),
      buildDuration: Duration(
        milliseconds: (json['buildDurationMs'] as int?) ?? 0,
      ),
    );
  }

  final List<String> steps;
  final double recoveryScore;
  final String? knowledgeNodeId;
  final List<String> memorySignals;
  final List<WorkoutBlueprintDecisionStep> decisions;
  final Duration buildDuration;

  Map<String, Object?> toJson() => <String, Object?>{
    'steps': steps,
    'recoveryScore': recoveryScore,
    if (knowledgeNodeId != null) 'knowledgeNodeId': knowledgeNodeId,
    'memorySignals': memorySignals,
    'decisions': decisions.map((step) => step.toJson()).toList(),
    'buildDurationMs': buildDuration.inMilliseconds,
  };

  WorkoutBlueprintTrace copyWith({
    List<String>? steps,
    double? recoveryScore,
    String? knowledgeNodeId,
    List<String>? memorySignals,
    List<WorkoutBlueprintDecisionStep>? decisions,
    Duration? buildDuration,
  }) {
    return WorkoutBlueprintTrace(
      steps: steps ?? this.steps,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      knowledgeNodeId: knowledgeNodeId ?? this.knowledgeNodeId,
      memorySignals: memorySignals ?? this.memorySignals,
      decisions: decisions ?? this.decisions,
      buildDuration: buildDuration ?? this.buildDuration,
    );
  }
}
