import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout_review/analysis/workout_program_analyzer.dart';
import 'package:gymaipro/ai/workout_review/explainability/workout_review_recommendation_builder.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_issue.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_request.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_score.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_trace.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_versions.dart';
import 'package:gymaipro/ai/workout_review/scoring/workout_review_scoring_engine.dart';
import 'package:gymaipro/ai/workout_review/validator/workout_review_issue_detector.dart';

/// Main analysis engine for workout program review.
///
/// Analysis only — does not generate or mutate programs.
class WorkoutReviewEngine {
  const WorkoutReviewEngine({
    this.analyzer = const WorkoutProgramAnalyzer(),
    this.scoringEngine = const WorkoutReviewScoringEngine(),
    this.issueDetector = const WorkoutReviewIssueDetector(),
    this.recommendationBuilder = const WorkoutReviewRecommendationBuilder(),
    this.enforceCoachV2Gate = true,
  });

  final WorkoutProgramAnalyzer analyzer;
  final WorkoutReviewScoringEngine scoringEngine;
  final WorkoutReviewIssueDetector issueDetector;
  final WorkoutReviewRecommendationBuilder recommendationBuilder;
  final bool enforceCoachV2Gate;

  String get engineVersion => WorkoutReviewVersions.engineVersion;

  WorkoutReviewResult review(WorkoutReviewRequest request) {
    if (enforceCoachV2Gate && !CoachV2Config.coachV2Enabled) {
      return WorkoutReviewResult.disabled(request: request);
    }

    final started = DateTime.now();
    final steps = <String>[
      'load_program',
      'map_exercise_profiles',
      'analyze_metrics',
      'score_dimensions',
      'detect_issues',
      'build_recommendations',
      'emit_trace',
    ];

    final profileById = <int, ExerciseProfile>{
      for (final profile in request.catalogProfiles) profile.id: profile,
    };

    final metrics = analyzer.analyze(
      program: request.program,
      context: request.context,
      profileById: profileById,
    );

    final scores = scoringEngine.score(
      program: request.program,
      metrics: metrics,
    );

    final issues = issueDetector.detect(
      program: request.program,
      metrics: metrics,
      scores: scores,
    );

    final recommendations = recommendationBuilder.build(
      issues: issues,
      metrics: metrics,
    );

    final weeklyVolume = <String, int>{
      for (final entry in metrics.weeklySetsByMuscle.entries)
        entry.key.name: entry.value,
    };

    final muscleCoverage = <String, double>{
      for (final bucket in MuscleBucket.values)
        bucket.name: metrics.setsFor(bucket) >= 4 ? 1 : 0,
    };

    final trace = WorkoutReviewTrace(
      exerciseCount: metrics.exerciseCount,
      weeklyVolume: weeklyVolume,
      muscleCoverage: muscleCoverage,
      jointStress: <String, double>{
        'knee': metrics.kneeStressTotal,
        'shoulder': metrics.shoulderStressTotal,
        'spine': metrics.spineStressTotal,
      },
      recovery: <String, double>{
        'fatigueCost': metrics.totalFatigueCost,
        'recoveryCost': metrics.totalRecoveryCost,
        'recoveryScore': scores.recoveryScore,
      },
      detectedIssues: issues.map((issue) => issue.code.name).toList(),
      recommendations:
          recommendations.map((item) => item.code.name).toList(),
      steps: steps,
      analysisDuration: DateTime.now().difference(started),
    );

    final summary = _buildSummary(scores, issues);

    return WorkoutReviewResult(
      enabled: true,
      request: request,
      scores: scores,
      issues: issues,
      recommendations: recommendations,
      trace: trace,
      summary: summary,
      engineVersion: engineVersion,
    );
  }

  String _buildSummary(WorkoutReviewScore scores, List<WorkoutReviewIssue> issues) {
    if (issues.isEmpty) {
      return 'Program looks balanced (overall ${scores.overall.toStringAsFixed(0)}/100).';
    }
    return 'Found ${issues.length} issue(s); overall ${scores.overall.toStringAsFixed(0)}/100.';
  }
}
