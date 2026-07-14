/// Debug trace for exercise selection during workout generation.
class WorkoutGeneratorSelectionTrace {
  const WorkoutGeneratorSelectionTrace({
    required this.catalogCount,
    required this.filteredCount,
    required this.rejectedCount,
    required this.replacedCount,
    required this.selectedCount,
    required this.finalCount,
    this.steps = const <String>[],
  });

  factory WorkoutGeneratorSelectionTrace.empty() {
    return const WorkoutGeneratorSelectionTrace(
      catalogCount: 0,
      filteredCount: 0,
      rejectedCount: 0,
      replacedCount: 0,
      selectedCount: 0,
      finalCount: 0,
    );
  }

  factory WorkoutGeneratorSelectionTrace.fromJson(Map<String, Object?> json) {
    return WorkoutGeneratorSelectionTrace(
      catalogCount: (json['catalogCount'] as int?) ?? 0,
      filteredCount: (json['filteredCount'] as int?) ?? 0,
      rejectedCount: (json['rejectedCount'] as int?) ?? 0,
      replacedCount: (json['replacedCount'] as int?) ?? 0,
      selectedCount: (json['selectedCount'] as int?) ?? 0,
      finalCount: (json['finalCount'] as int?) ?? 0,
      steps: (json['steps'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final int catalogCount;
  final int filteredCount;
  final int rejectedCount;
  final int replacedCount;
  final int selectedCount;
  final int finalCount;
  final List<String> steps;

  Map<String, Object?> toJson() => <String, Object?>{
    'catalogCount': catalogCount,
    'filteredCount': filteredCount,
    'rejectedCount': rejectedCount,
    'replacedCount': replacedCount,
    'selectedCount': selectedCount,
    'finalCount': finalCount,
    'steps': steps,
  };

  WorkoutGeneratorSelectionTrace merge(WorkoutGeneratorSelectionTrace other) {
    return WorkoutGeneratorSelectionTrace(
      catalogCount: catalogCount + other.catalogCount,
      filteredCount: filteredCount + other.filteredCount,
      rejectedCount: rejectedCount + other.rejectedCount,
      replacedCount: replacedCount + other.replacedCount,
      selectedCount: selectedCount + other.selectedCount,
      finalCount: finalCount + other.finalCount,
      steps: <String>[...steps, ...other.steps],
    );
  }

  WorkoutGeneratorSelectionTrace copyWith({
    int? catalogCount,
    int? filteredCount,
    int? rejectedCount,
    int? replacedCount,
    int? selectedCount,
    int? finalCount,
    List<String>? steps,
  }) {
    return WorkoutGeneratorSelectionTrace(
      catalogCount: catalogCount ?? this.catalogCount,
      filteredCount: filteredCount ?? this.filteredCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      replacedCount: replacedCount ?? this.replacedCount,
      selectedCount: selectedCount ?? this.selectedCount,
      finalCount: finalCount ?? this.finalCount,
      steps: steps ?? this.steps,
    );
  }
}
