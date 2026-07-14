import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_review/analysis/workout_program_metrics.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_enums.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_issue.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_reason.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_score.dart';

/// Detects structural and load issues in a workout program.
class WorkoutReviewIssueDetector {
  const WorkoutReviewIssueDetector();

  List<WorkoutReviewIssue> detect({
    required WorkoutProgram program,
    required WorkoutProgramMetrics metrics,
    required WorkoutReviewScore scores,
  }) {
    final issues = <WorkoutReviewIssue>[];

    if (metrics.exerciseCount == 0) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.emptyProgram,
          severity: WorkoutReviewIssueSeverity.critical,
          subject: program.name,
          message: 'Program has no exercises to review.',
          reasons: const <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'program.empty',
              subject: 'WorkoutProgram',
              because: <String>['No exercises found in any training day'],
            ),
          ],
        ),
      );
      return List<WorkoutReviewIssue>.unmodifiable(issues);
    }

    final chestSets = metrics.setsFor(MuscleBucket.chest);
    final backSets = metrics.setsFor(MuscleBucket.back);

    if (chestSets > 18 || (backSets > 0 && chestSets > backSets * 1.5)) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.chestOverloaded,
          severity: WorkoutReviewIssueSeverity.high,
          subject: 'Chest volume',
          message: 'Chest volume is disproportionately high.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.chest_overloaded',
              subject: 'Chest',
              because: <String>[
                'Weekly chest sets = $chestSets',
                'Weekly back sets = $backSets',
                'Balance score = ${scores.balanceScore.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.legSets > 0 &&
        metrics.posteriorChainSets < metrics.legSets * 0.3) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.noPosteriorChain,
          severity: WorkoutReviewIssueSeverity.high,
          subject: 'Posterior chain',
          message: 'Posterior chain volume is too low relative to leg work.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.no_posterior_chain',
              subject: 'Hamstrings/Glutes',
              because: <String>[
                'Posterior chain sets = ${metrics.posteriorChainSets.toStringAsFixed(0)}',
                'Total leg sets = ${metrics.legSets.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.kneeStressTotal > 22 || metrics.kneeHeavyExerciseCount >= 3) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.tooMuchKneeStress,
          severity: WorkoutReviewIssueSeverity.high,
          subject: 'Knee stress',
          message: 'Knee joint stress is elevated across the program.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.knee_stress',
              subject: 'Knee',
              because: <String>[
                'Knee stress total = ${metrics.kneeStressTotal.toStringAsFixed(1)}',
                'Knee-heavy exercises = ${metrics.kneeHeavyExerciseCount}',
                'Safety score = ${scores.safetyScore.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (scores.recoveryScore < 55) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.recoveryTooLow,
          severity: WorkoutReviewIssueSeverity.medium,
          subject: 'Recovery',
          message: 'Program recovery demand exceeds recommended capacity.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.recovery_low',
              subject: 'Recovery',
              because: <String>[
                'Recovery score = ${scores.recoveryScore.toStringAsFixed(0)}',
                'Fatigue cost = ${metrics.totalFatigueCost.toStringAsFixed(1)}',
                'Leg days = ${metrics.legDayCount}',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.compoundRatio > 0.75 && metrics.exerciseCount >= 6) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.tooManyCompoundExercises,
          severity: WorkoutReviewIssueSeverity.medium,
          subject: 'Compound ratio',
          message: 'Compound exercises dominate the program.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.compound_heavy',
              subject: 'Compound',
              because: <String>[
                'Compound ratio = ${(metrics.compoundRatio * 100).toStringAsFixed(0)}%',
                'Compound count = ${metrics.compoundCount}',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.weekCount >= 4 && !metrics.hasDeload) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.missingDeload,
          severity: WorkoutReviewIssueSeverity.medium,
          subject: 'Periodization',
          message: 'Multi-week program lacks a deload phase.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.missing_deload',
              subject: 'Deload',
              because: <String>[
                'Week count = ${metrics.weekCount}',
                'Progression score = ${scores.progressionScore.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.shoulderPushSets > 8 && metrics.rearDeltProxySets < 4) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.weakShoulderBalance,
          severity: WorkoutReviewIssueSeverity.medium,
          subject: 'Shoulder balance',
          message: 'Shoulder pushing volume lacks rear-delt counterbalance.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.shoulder_balance',
              subject: 'Shoulders',
              because: <String>[
                'Shoulder push sets = ${metrics.shoulderPushSets}',
                'Rear-delt proxy sets = ${metrics.rearDeltProxySets}',
                'Balance score = ${scores.balanceScore.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.pullSets < 8 || metrics.pullSets < metrics.pushSets * 0.6) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.noPullingVolume,
          severity: WorkoutReviewIssueSeverity.high,
          subject: 'Pull volume',
          message: 'Weekly pulling volume is insufficient.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.no_pulling',
              subject: 'Back/Biceps',
              because: <String>[
                'Weekly pull volume = ${metrics.pullSets}',
                'Weekly push volume = ${metrics.pushSets}',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.isolationRatio > 0.6 && metrics.exerciseCount >= 6) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.excessiveIsolation,
          severity: WorkoutReviewIssueSeverity.low,
          subject: 'Isolation ratio',
          message: 'Isolation exercises dominate the program.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.excessive_isolation',
              subject: 'Isolation',
              because: <String>[
                'Isolation ratio = ${(metrics.isolationRatio * 100).toStringAsFixed(0)}%',
              ],
            ),
          ],
        ),
      );
    }

    if (metrics.equipmentConflicts.isNotEmpty) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.equipmentConflict,
          severity: WorkoutReviewIssueSeverity.high,
          subject: 'Equipment',
          message: 'Some exercises require unavailable equipment.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.equipment_conflict',
              subject: 'Equipment',
              because: <String>[
                'Conflicts = ${metrics.equipmentConflicts.join(', ')}',
                'Equipment score = ${scores.equipmentCompatibility.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (WorkoutScience.isBeginnerExperience(program.experienceLevel) &&
        program.totalExercises > program.daysPerWeek * 6) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.beginnerVolumeTooHigh,
          severity: WorkoutReviewIssueSeverity.high,
          subject: 'Beginner volume',
          message: 'Exercise count is too high for a beginner.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.beginner_volume',
              subject: program.experienceLevel,
              because: <String>[
                'Total exercises = ${program.totalExercises}',
                'Volume score = ${scores.volumeScore.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (WorkoutScience.isAdvancedExperience(program.experienceLevel) &&
        program.totalExercises < program.daysPerWeek * 2) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.advancedVolumeTooLow,
          severity: WorkoutReviewIssueSeverity.medium,
          subject: 'Advanced volume',
          message: 'Exercise count is too low for an advanced lifter.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.advanced_volume',
              subject: program.experienceLevel,
              because: <String>[
                'Total exercises = ${program.totalExercises}',
                'Volume score = ${scores.volumeScore.toStringAsFixed(0)}',
              ],
            ),
          ],
        ),
      );
    }

    if (scores.goalAlignmentScore < 50) {
      issues.add(
        WorkoutReviewIssue(
          code: WorkoutReviewIssueCode.goalMismatch,
          severity: WorkoutReviewIssueSeverity.medium,
          subject: program.goal.name,
          message: 'Set/rep profile does not align well with training goal.',
          reasons: <WorkoutReviewReason>[
            WorkoutReviewReason(
              code: 'issue.goal_mismatch',
              subject: program.goal.name,
              because: <String>[
                'Goal alignment score = ${scores.goalAlignmentScore.toStringAsFixed(0)}',
                'Average reps = ${metrics.avgReps.toStringAsFixed(1)}',
              ],
            ),
          ],
        ),
      );
    }

    return List<WorkoutReviewIssue>.unmodifiable(issues);
  }
}
