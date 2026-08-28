import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_quality_gate.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_enums.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_issue.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_reason.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_request.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_score.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_trace.dart';
import 'package:gymaipro/config/app_config.dart';

import '../workout_review/fixtures/workout_review_program_fixture.dart';

void main() {
  test('paid program model is stronger than chat model', () {
    expect(AppConfig.aiDefaultModel, 'gpt-4o-mini');
    expect(AppConfig.aiWorkoutProgramModel, 'gpt-4o');
    expect(AppConfig.aiWorkoutProgramModel, isNot(AppConfig.aiDefaultModel));
  });

  test('quality gate only repairs high and critical review issues', () {
    final result = WorkoutReviewResult(
      enabled: true,
      request: WorkoutReviewRequest(
        program: WorkoutReviewProgramFixture.balancedProgram(),
        context: CoachContext.empty(),
      ),
      scores: const WorkoutReviewScore(
        volumeScore: 70,
        recoveryScore: 70,
        balanceScore: 70,
        goalAlignmentScore: 70,
        safetyScore: 40,
        progressionScore: 70,
        equipmentCompatibility: 70,
        experienceMatch: 70,
        weeklyDistribution: 70,
        muscleCoverage: 70,
        overall: 60,
      ),
      issues: const <WorkoutReviewIssue>[
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.tooMuchKneeStress,
          severity: WorkoutReviewIssueSeverity.high,
          subject: 'Knee',
          message: 'Knee stress',
          reasons: <WorkoutReviewReason>[],
        ),
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.excessiveIsolation,
          severity: WorkoutReviewIssueSeverity.low,
          subject: 'Isolation',
          message: 'Too many isolations',
          reasons: <WorkoutReviewReason>[],
        ),
      ],
      recommendations: const [],
      trace: const WorkoutReviewTrace(
        exerciseCount: 12,
        weeklyVolume: <String, int>{},
        muscleCoverage: <String, double>{},
        jointStress: <String, double>{},
        recovery: <String, double>{},
        detectedIssues: <String>[],
        recommendations: <String>[],
      ),
      summary: 'issues',
    );

    final notes = LlmWorkoutQualityGate.repairNotes(result);
    expect(notes, hasLength(1));
    expect(notes.single, contains('زانو'));
  });

  test('disabled review emits no repair notes', () {
    final notes = LlmWorkoutQualityGate.repairNotes(
      WorkoutReviewResult.disabled(
        request: WorkoutReviewRequest(
          program: WorkoutReviewProgramFixture.balancedProgram(),
          context: CoachContext.empty(),
        ),
      ),
    );
    expect(notes, isEmpty);
  });
}
