/// Multi-dimensional scores for a workout program review (0–100 each).
class WorkoutReviewScore {
  const WorkoutReviewScore({
    required this.volumeScore,
    required this.recoveryScore,
    required this.balanceScore,
    required this.goalAlignmentScore,
    required this.safetyScore,
    required this.progressionScore,
    required this.equipmentCompatibility,
    required this.experienceMatch,
    required this.weeklyDistribution,
    required this.muscleCoverage,
    required this.overall,
  });

  factory WorkoutReviewScore.fromJson(Map<String, Object?> json) {
    return WorkoutReviewScore(
      volumeScore: _readScore(json['volumeScore']),
      recoveryScore: _readScore(json['recoveryScore']),
      balanceScore: _readScore(json['balanceScore']),
      goalAlignmentScore: _readScore(json['goalAlignmentScore']),
      safetyScore: _readScore(json['safetyScore']),
      progressionScore: _readScore(json['progressionScore']),
      equipmentCompatibility: _readScore(json['equipmentCompatibility']),
      experienceMatch: _readScore(json['experienceMatch']),
      weeklyDistribution: _readScore(json['weeklyDistribution']),
      muscleCoverage: _readScore(json['muscleCoverage']),
      overall: _readScore(json['overall']),
    );
  }

  final double volumeScore;
  final double recoveryScore;
  final double balanceScore;
  final double goalAlignmentScore;
  final double safetyScore;
  final double progressionScore;
  final double equipmentCompatibility;
  final double experienceMatch;
  final double weeklyDistribution;
  final double muscleCoverage;
  final double overall;

  static double _readScore(Object? value) {
    if (value is num) return value.toDouble().clamp(0, 100);
    return 0;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'volumeScore': volumeScore,
    'recoveryScore': recoveryScore,
    'balanceScore': balanceScore,
    'goalAlignmentScore': goalAlignmentScore,
    'safetyScore': safetyScore,
    'progressionScore': progressionScore,
    'equipmentCompatibility': equipmentCompatibility,
    'experienceMatch': experienceMatch,
    'weeklyDistribution': weeklyDistribution,
    'muscleCoverage': muscleCoverage,
    'overall': overall,
  };

  WorkoutReviewScore copyWith({
    double? volumeScore,
    double? recoveryScore,
    double? balanceScore,
    double? goalAlignmentScore,
    double? safetyScore,
    double? progressionScore,
    double? equipmentCompatibility,
    double? experienceMatch,
    double? weeklyDistribution,
    double? muscleCoverage,
    double? overall,
  }) {
    return WorkoutReviewScore(
      volumeScore: volumeScore ?? this.volumeScore,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      balanceScore: balanceScore ?? this.balanceScore,
      goalAlignmentScore: goalAlignmentScore ?? this.goalAlignmentScore,
      safetyScore: safetyScore ?? this.safetyScore,
      progressionScore: progressionScore ?? this.progressionScore,
      equipmentCompatibility:
          equipmentCompatibility ?? this.equipmentCompatibility,
      experienceMatch: experienceMatch ?? this.experienceMatch,
      weeklyDistribution: weeklyDistribution ?? this.weeklyDistribution,
      muscleCoverage: muscleCoverage ?? this.muscleCoverage,
      overall: overall ?? this.overall,
    );
  }
}
