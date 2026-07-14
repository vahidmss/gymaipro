/// Full analysis trace for a workout review run.
class WorkoutReviewTrace {
  const WorkoutReviewTrace({
    required this.exerciseCount,
    required this.weeklyVolume,
    required this.muscleCoverage,
    required this.jointStress,
    required this.recovery,
    required this.detectedIssues,
    required this.recommendations,
    this.steps = const <String>[],
    this.analysisDuration = Duration.zero,
  });

  factory WorkoutReviewTrace.fromJson(Map<String, Object?> json) {
    return WorkoutReviewTrace(
      exerciseCount: (json['exerciseCount'] as int?) ?? 0,
      weeklyVolume: _stringIntMap(json['weeklyVolume']),
      muscleCoverage: _stringDoubleMap(json['muscleCoverage']),
      jointStress: _stringDoubleMap(json['jointStress']),
      recovery: _stringDoubleMap(json['recovery']),
      detectedIssues: (json['detectedIssues'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      recommendations: (json['recommendations'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      steps: (json['steps'] as List<Object?>? ?? const <Object?>[])
          .map((item) => item.toString())
          .toList(),
      analysisDuration: Duration(
        milliseconds: (json['analysisDurationMs'] as int?) ?? 0,
      ),
    );
  }

  final int exerciseCount;
  final Map<String, int> weeklyVolume;
  final Map<String, double> muscleCoverage;
  final Map<String, double> jointStress;
  final Map<String, double> recovery;
  final List<String> detectedIssues;
  final List<String> recommendations;
  final List<String> steps;
  final Duration analysisDuration;

  static Map<String, int> _stringIntMap(Object? value) {
    if (value is! Map) return const <String, int>{};
    return value.map(
      (key, item) => MapEntry(key.toString(), (item as num?)?.toInt() ?? 0),
    );
  }

  static Map<String, double> _stringDoubleMap(Object? value) {
    if (value is! Map) return const <String, double>{};
    return value.map(
      (key, item) => MapEntry(key.toString(), (item as num?)?.toDouble() ?? 0),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'exerciseCount': exerciseCount,
    'weeklyVolume': weeklyVolume,
    'muscleCoverage': muscleCoverage,
    'jointStress': jointStress,
    'recovery': recovery,
    'detectedIssues': detectedIssues,
    'recommendations': recommendations,
    'steps': steps,
    'analysisDurationMs': analysisDuration.inMilliseconds,
  };

  WorkoutReviewTrace copyWith({
    int? exerciseCount,
    Map<String, int>? weeklyVolume,
    Map<String, double>? muscleCoverage,
    Map<String, double>? jointStress,
    Map<String, double>? recovery,
    List<String>? detectedIssues,
    List<String>? recommendations,
    List<String>? steps,
    Duration? analysisDuration,
  }) {
    return WorkoutReviewTrace(
      exerciseCount: exerciseCount ?? this.exerciseCount,
      weeklyVolume: weeklyVolume ?? this.weeklyVolume,
      muscleCoverage: muscleCoverage ?? this.muscleCoverage,
      jointStress: jointStress ?? this.jointStress,
      recovery: recovery ?? this.recovery,
      detectedIssues: detectedIssues ?? this.detectedIssues,
      recommendations: recommendations ?? this.recommendations,
      steps: steps ?? this.steps,
      analysisDuration: analysisDuration ?? this.analysisDuration,
    );
  }
}
