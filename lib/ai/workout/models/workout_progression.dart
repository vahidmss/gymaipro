/// Progressive overload strategy applied to a set or exercise block.
enum WorkoutProgressionStrategy {
  increaseWeight,
  increaseReps,
  increaseVolume,
  deload,
  maintenance,
}

/// Describes how load should progress across future sessions.
class WorkoutProgression {
  const WorkoutProgression({
    required this.strategy,
    required this.description,
    this.targetDeltaPercent,
    this.targetRepDelta,
  });

  factory WorkoutProgression.fromJson(Map<String, Object?> json) {
    return WorkoutProgression(
      strategy: WorkoutProgressionStrategy.values.firstWhere(
        (value) => value.name == json['strategy'],
        orElse: () => WorkoutProgressionStrategy.maintenance,
      ),
      description: (json['description'] as String?) ?? '',
      targetDeltaPercent: (json['targetDeltaPercent'] as num?)?.toDouble(),
      targetRepDelta: json['targetRepDelta'] as int?,
    );
  }

  final WorkoutProgressionStrategy strategy;
  final String description;
  final double? targetDeltaPercent;
  final int? targetRepDelta;

  Map<String, Object?> toJson() => <String, Object?>{
    'strategy': strategy.name,
    'description': description,
    if (targetDeltaPercent != null) 'targetDeltaPercent': targetDeltaPercent,
    if (targetRepDelta != null) 'targetRepDelta': targetRepDelta,
  };
}
