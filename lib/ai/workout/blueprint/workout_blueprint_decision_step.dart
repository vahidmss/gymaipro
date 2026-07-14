/// One explainable decision step recorded during blueprint planning.
class WorkoutBlueprintDecisionStep {
  const WorkoutBlueprintDecisionStep({
    required this.decision,
    required this.outcome,
    required this.factors,
  });

  factory WorkoutBlueprintDecisionStep.fromJson(Map<String, Object?> json) {
    return WorkoutBlueprintDecisionStep(
      decision: (json['decision'] as String?) ?? '',
      outcome: (json['outcome'] as String?) ?? '',
      factors: (json['factors'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final String decision;
  final String outcome;
  final List<String> factors;

  Map<String, Object?> toJson() => <String, Object?>{
    'decision': decision,
    'outcome': outcome,
    'factors': factors,
  };

  WorkoutBlueprintDecisionStep copyWith({
    String? decision,
    String? outcome,
    List<String>? factors,
  }) {
    return WorkoutBlueprintDecisionStep(
      decision: decision ?? this.decision,
      outcome: outcome ?? this.outcome,
      factors: factors ?? this.factors,
    );
  }
}
