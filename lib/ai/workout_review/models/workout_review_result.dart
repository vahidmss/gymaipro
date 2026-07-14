import 'package:gymaipro/ai/workout_review/models/workout_review_issue.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_recommendation.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_request.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_score.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_trace.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_versions.dart';

Map<String, Object?> _mapFromJson(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const <String, Object?>{};
}

/// Output of a workout program review run.
class WorkoutReviewResult {
  const WorkoutReviewResult({
    required this.enabled,
    required this.request,
    required this.scores,
    required this.issues,
    required this.recommendations,
    required this.trace,
    required this.summary,
    this.engineVersion = WorkoutReviewVersions.engineVersion,
  });

  factory WorkoutReviewResult.disabled({
    required WorkoutReviewRequest request,
  }) {
    const emptyScores = WorkoutReviewScore(
      volumeScore: 0,
      recoveryScore: 0,
      balanceScore: 0,
      goalAlignmentScore: 0,
      safetyScore: 0,
      progressionScore: 0,
      equipmentCompatibility: 0,
      experienceMatch: 0,
      weeklyDistribution: 0,
      muscleCoverage: 0,
      overall: 0,
    );
    return WorkoutReviewResult(
      enabled: false,
      request: request,
      scores: emptyScores,
      issues: const <WorkoutReviewIssue>[],
      recommendations: const <WorkoutReviewRecommendation>[],
      trace: const WorkoutReviewTrace(
        exerciseCount: 0,
        weeklyVolume: <String, int>{},
        muscleCoverage: <String, double>{},
        jointStress: <String, double>{},
        recovery: <String, double>{},
        detectedIssues: <String>[],
        recommendations: <String>[],
        steps: <String>['coach_v2_disabled'],
      ),
      summary: 'Workout review engine disabled (CoachV2 gate).',
    );
  }

  factory WorkoutReviewResult.fromJson(Map<String, Object?> json) {
    final requestRaw = json['request'];
    final scoresRaw = json['scores'];
    final traceRaw = json['trace'];
    return WorkoutReviewResult(
      enabled: json['enabled'] == true,
      request: requestRaw is Map<String, Object?>
          ? WorkoutReviewRequest.fromJson(requestRaw)
          : WorkoutReviewRequest.fromJson(const <String, Object?>{}),
      scores: scoresRaw is Map<String, Object?>
          ? WorkoutReviewScore.fromJson(scoresRaw)
          : WorkoutReviewScore.fromJson(const <String, Object?>{}),
      issues: (json['issues'] as List<Object?>? ?? const <Object?>[])
          .whereType<Map<String, Object?>>()
          .map((item) => WorkoutReviewIssue.fromJson(_mapFromJson(item)))
          .toList(),
      recommendations:
          (json['recommendations'] as List<Object?>? ?? const <Object?>[])
              .whereType<Map<String, Object?>>()
              .map(
                (item) =>
                    WorkoutReviewRecommendation.fromJson(_mapFromJson(item)),
              )
              .toList(),
      trace: traceRaw is Map<String, Object?>
          ? WorkoutReviewTrace.fromJson(traceRaw)
          : WorkoutReviewTrace.fromJson(const <String, Object?>{}),
      summary: (json['summary'] as String?) ?? '',
      engineVersion:
          (json['engineVersion'] as String?) ??
          WorkoutReviewVersions.engineVersion,
    );
  }

  final bool enabled;
  final WorkoutReviewRequest request;
  final WorkoutReviewScore scores;
  final List<WorkoutReviewIssue> issues;
  final List<WorkoutReviewRecommendation> recommendations;
  final WorkoutReviewTrace trace;
  final String summary;
  final String engineVersion;

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'engineVersion': engineVersion,
    'summary': summary,
    'request': request.toJson(),
    'scores': scores.toJson(),
    'issues': issues.map((issue) => issue.toJson()).toList(),
    'recommendations':
        recommendations.map((item) => item.toJson()).toList(),
    'trace': trace.toJson(),
  };

  WorkoutReviewResult copyWith({
    bool? enabled,
    WorkoutReviewRequest? request,
    WorkoutReviewScore? scores,
    List<WorkoutReviewIssue>? issues,
    List<WorkoutReviewRecommendation>? recommendations,
    WorkoutReviewTrace? trace,
    String? summary,
    String? engineVersion,
  }) {
    return WorkoutReviewResult(
      enabled: enabled ?? this.enabled,
      request: request ?? this.request,
      scores: scores ?? this.scores,
      issues: issues ?? this.issues,
      recommendations: recommendations ?? this.recommendations,
      trace: trace ?? this.trace,
      summary: summary ?? this.summary,
      engineVersion: engineVersion ?? this.engineVersion,
    );
  }
}
