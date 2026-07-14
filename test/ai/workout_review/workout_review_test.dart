import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_review/analysis/workout_review_engine.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_enums.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_reason.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_request.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_score.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_versions.dart';
import 'package:gymaipro/ai/workout_review/runtime/workout_review_runtime.dart';

import 'fixtures/workout_review_program_fixture.dart';

CoachContext _context({List<String> equipment = const <String>['دمبل']}) {
  return CoachContext(
    intent: AIIntent.workoutGeneration,
    profile: const <String, Object?>{'experience_level': 'متوسط'},
    equipment: equipment,
    metadata: CoachContextMetadata(
      buildTime: DateTime(2026, 7, 12),
      sourceCount: 1,
      missingProviders: const {},
      confidence: 0.9,
      contextVersion: CoachContext.contextVersion,
    ),
  );
}

void main() {
  const engine = WorkoutReviewEngine(enforceCoachV2Gate: false);
  const runtime = WorkoutReviewRuntime(enforceCoachV2Gate: false);
  final profiles = WorkoutReviewProgramFixture.gymProfiles();

  WorkoutReviewResult review(
    WorkoutProgram program, {
    CoachContext? context,
  }) {
    return engine.review(
      WorkoutReviewRequest(
        program: program,
        context: context ?? _context(),
        catalogProfiles: profiles,
      ),
    );
  }

  group('EPIC 23 workout review', () {
    test('models are immutable and JSON round-trip', () {
      const reason = WorkoutReviewReason(
        code: 'test.code',
        subject: 'Face Pull',
        because: <String>['Rear delts undertrained'],
      );
      final decodedReason = WorkoutReviewReason.fromJson(reason.toJson());
      expect(decodedReason.code, reason.code);

      const scores = WorkoutReviewScore(
        volumeScore: 80,
        recoveryScore: 75,
        balanceScore: 70,
        goalAlignmentScore: 85,
        safetyScore: 90,
        progressionScore: 60,
        equipmentCompatibility: 95,
        experienceMatch: 88,
        weeklyDistribution: 77,
        muscleCoverage: 82,
        overall: 80.2,
      );
      final decodedScores = WorkoutReviewScore.fromJson(scores.toJson());
      expect(decodedScores.volumeScore, 80);

      final program = WorkoutReviewProgramFixture.balancedProgram();
      final request = WorkoutReviewRequest(
        program: program,
        context: _context(),
        catalogProfiles: profiles,
      );
      final result = review(program);
      final decodedResult = WorkoutReviewResult.fromJson(result.toJson());
      expect(decodedResult.enabled, true);
      expect(decodedResult.engineVersion, WorkoutReviewVersions.engineVersion);
      expect(decodedResult.request.program.id, program.id);
      expect(decodedResult.trace.exerciseCount, greaterThan(0));
      expect(
        WorkoutReviewRequest.fromJson(request.toJson()).program.name,
        program.name,
      );
    });

    test('balanced program scores well with few issues', () {
      final result = review(WorkoutReviewProgramFixture.balancedProgram());
      expect(result.enabled, true);
      expect(result.scores.overall, greaterThan(55));
      expect(result.scores.balanceScore, greaterThan(40));
      expect(result.scores.muscleCoverage, greaterThan(40));
      expect(result.trace.exerciseCount, 9);
      expect(result.trace.weeklyVolume['back'], greaterThan(0));
      expect(result.trace.steps, contains('detect_issues'));
    });

    test('bad program detects multiple issues', () {
      final result = review(WorkoutReviewProgramFixture.badProgram());
      expect(result.issues.length, greaterThan(2));
      expect(result.scores.overall, lessThan(80));
      expect(result.recommendations, isNotEmpty);
    });

    test('high knee stress program flags knee issue', () {
      final result = review(WorkoutReviewProgramFixture.highKneeStressProgram());
      expect(
        result.issues.map((issue) => issue.code),
        contains(WorkoutReviewIssueCode.tooMuchKneeStress),
      );
      expect(result.trace.jointStress['knee'], greaterThan(15));
      expect(
        result.recommendations.map((item) => item.code),
        contains(WorkoutReviewRecommendationCode.replaceSquatWithHackSquat),
      );
    });

    test('chest dominant program flags chest overload', () {
      final result = review(WorkoutReviewProgramFixture.chestDominantProgram());
      expect(
        result.issues.map((issue) => issue.code),
        contains(WorkoutReviewIssueCode.chestOverloaded),
      );
      expect(
        result.recommendations.map((item) => item.code),
        contains(WorkoutReviewRecommendationCode.reduceChestVolume),
      );
    });

    test('missing back program flags low pull volume', () {
      final result = review(WorkoutReviewProgramFixture.missingBackProgram());
      expect(
        result.issues.map((issue) => issue.code),
        contains(WorkoutReviewIssueCode.noPullingVolume),
      );
      expect(
        result.recommendations.map((item) => item.code),
        contains(WorkoutReviewRecommendationCode.addBackExercise),
      );
    });

    test('equipment conflict program flags equipment issue', () {
      final result = review(WorkoutReviewProgramFixture.equipmentConflictProgram());
      expect(
        result.issues.map((issue) => issue.code),
        contains(WorkoutReviewIssueCode.equipmentConflict),
      );
      expect(result.scores.equipmentCompatibility, lessThan(90));
      expect(
        result.recommendations.map((item) => item.code),
        contains(WorkoutReviewRecommendationCode.swapToHomeEquipment),
      );
    });

    test('beginner high volume flags beginner volume issue', () {
      final result = review(
        WorkoutReviewProgramFixture.beginnerHighVolumeProgram(),
      );
      expect(
        result.issues.map((issue) => issue.code),
        contains(WorkoutReviewIssueCode.beginnerVolumeTooHigh),
      );
      expect(result.scores.volumeScore, lessThan(90));
    });

    test('advanced low volume flags advanced volume issue', () {
      final result = review(
        WorkoutReviewProgramFixture.advancedLowVolumeProgram(),
      );
      expect(
        result.issues.map((issue) => issue.code),
        contains(WorkoutReviewIssueCode.advancedVolumeTooLow),
      );
    });

    test('goal mismatch program lowers goal alignment score', () {
      final result = review(WorkoutReviewProgramFixture.goalMismatchProgram());
      expect(result.programGoalMatches(TrainingGoal.strength), isTrue);
      expect(
        result.issues.map((issue) => issue.code),
        contains(WorkoutReviewIssueCode.goalMismatch),
      );
      expect(result.scores.goalAlignmentScore, lessThan(70));
    });

    test('recommendations include explainability chains', () {
      final result = review(WorkoutReviewProgramFixture.chestDominantProgram());
      final facePull = result.recommendations
          .where((item) => item.code == WorkoutReviewRecommendationCode.addFacePull);
      if (facePull.isNotEmpty) {
        expect(facePull.first.reasons.first.because, isNotEmpty);
      }
      final chestRec = result.recommendations.firstWhere(
        (item) => item.code == WorkoutReviewRecommendationCode.reduceChestVolume,
      );
      expect(chestRec.reasons.first.because, contains('Chest Overloaded'));
      expect(chestRec.reasons.first.subject, isNotEmpty);
    });

    test('runtime review(program) orchestrates engine', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
      final result = runtime.review(
        program: program,
        context: _context(),
        catalogProfiles: profiles,
      );
      expect(result.enabled, true);
      expect(result.trace.detectedIssues, isA<List<String>>());
      expect(result.trace.recommendations, isA<List<String>>());
    });

    test('coach v2 gate disables engine when configured', () {
      if (CoachV2Config.coachV2Enabled) return;
      const gatedEngine = WorkoutReviewEngine();
      final result = gatedEngine.review(
        WorkoutReviewRequest(
          program: WorkoutReviewProgramFixture.balancedProgram(),
          context: _context(),
          catalogProfiles: profiles,
        ),
      );
      expect(result.enabled, false);
      expect(result.trace.steps, contains('coach_v2_disabled'));
    });
  });
}

extension on WorkoutReviewResult {
  bool programGoalMatches(TrainingGoal goal) =>
      request.program.goal == goal;
}
