import 'package:gymaipro/ai/workout_review/analysis/workout_program_metrics.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_enums.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_issue.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_reason.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_recommendation.dart';

/// Builds actionable recommendations with explainability chains.
class WorkoutReviewRecommendationBuilder {
  const WorkoutReviewRecommendationBuilder();

  List<WorkoutReviewRecommendation> build({
    required List<WorkoutReviewIssue> issues,
    required WorkoutProgramMetrics metrics,
  }) {
    final recommendations = <WorkoutReviewRecommendation>[];

    for (final issue in issues) {
      switch (issue.code) {
        case WorkoutReviewIssueCode.chestOverloaded:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.reduceChestVolume,
              action: 'کاهش حجم سینه در روز فشار',
              priority: 1,
              target: 'Chest',
              chain: <String>[
                'Chest sets too high',
                'Chest Overloaded',
                'Balance score low',
              ],
            ),
          );
        case WorkoutReviewIssueCode.noPosteriorChain:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.addHamstringExercise,
              action: 'افزودن حرکت برای همسترینگ',
              priority: 1,
              target: 'Hamstrings',
              chain: <String>[
                'Posterior chain undertrained',
                'No Posterior Chain',
                'Leg volume skewed to quads',
              ],
            ),
          );
        case WorkoutReviewIssueCode.tooMuchKneeStress:
          recommendations.addAll(<WorkoutReviewRecommendation>[
            _recommendation(
              code: WorkoutReviewRecommendationCode.replaceSquatWithHackSquat,
              action: 'جایگزینی اسکوات با Hack Squat',
              priority: 1,
              target: 'Squat',
              chain: <String>[
                'Knee load elevated',
                'Too Much Knee Stress',
                'Knee stress total = ${metrics.kneeStressTotal.toStringAsFixed(1)}',
              ],
            ),
            _recommendation(
              code: WorkoutReviewRecommendationCode.reduceLegDayVolume,
              action: 'کاهش حجم روز پا',
              priority: 2,
              target: 'Leg day',
              chain: <String>[
                'Knee-heavy exercises = ${metrics.kneeHeavyExerciseCount}',
                'Too Much Knee Stress',
                'Recovery demand high',
              ],
            ),
          ]);
        case WorkoutReviewIssueCode.recoveryTooLow:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.increaseRest,
              action: 'افزایش استراحت بین ست‌ها',
              priority: 1,
              target: 'Recovery',
              chain: <String>[
                'Fatigue cost high',
                'Recovery Too Low',
                'Leg days = ${metrics.legDayCount}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.weakShoulderBalance:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.addFacePull,
              action: 'افزودن Face Pull',
              priority: 1,
              target: 'Rear delts',
              chain: <String>[
                'Rear delts undertrained',
                'Shoulder Balance Low',
                'Weekly pull volume = ${metrics.pullSets}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.noPullingVolume:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.addBackExercise,
              action: 'افزودن حرکت کششی برای پشت',
              priority: 1,
              target: 'Back',
              chain: <String>[
                'Pull volume low',
                'No Pulling Volume',
                'Weekly pull volume = ${metrics.pullSets}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.missingDeload:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.addDeloadWeek,
              action: 'افزودن هفته دیلود',
              priority: 2,
              target: 'Week ${metrics.weekCount}',
              chain: <String>[
                'No deload detected',
                'Missing Deload',
                'Week count = ${metrics.weekCount}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.equipmentConflict:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.swapToHomeEquipment,
              action: 'جایگزینی حرکات با تجهیزات موجود',
              priority: 1,
              target: 'Equipment',
              chain: <String>[
                'Equipment mismatch',
                'Equipment Conflict',
                'Conflicts = ${metrics.equipmentConflicts.length}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.tooManyCompoundExercises:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.reduceCompoundCount,
              action: 'کاهش تعداد حرکات چندمفصلی در هر جلسه',
              priority: 2,
              target: 'Session structure',
              chain: <String>[
                'Compound ratio high',
                'Too Many Compound Exercises',
                'Compound count = ${metrics.compoundCount}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.excessiveIsolation:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.addIsolationBalance,
              action: 'افزودن حرکات پایه برای تعادل بهتر',
              priority: 3,
              target: 'Compound balance',
              chain: <String>[
                'Isolation ratio high',
                'Excessive Isolation',
                'Isolation count = ${metrics.isolationCount}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.beginnerVolumeTooHigh:
          recommendations.add(
            _recommendation(
              code: WorkoutReviewRecommendationCode.lowerSessionIntensity,
              action: 'کاهش تعداد حرکات هر جلسه برای مبتدی',
              priority: 1,
              target: 'Beginner',
              chain: <String>[
                'Exercise count high',
                'Beginner Volume Too High',
                'Total exercises = ${metrics.exerciseCount}',
              ],
            ),
          );
        case WorkoutReviewIssueCode.advancedVolumeTooLow:
        case WorkoutReviewIssueCode.goalMismatch:
        case WorkoutReviewIssueCode.emptyProgram:
          break;
      }
    }

    recommendations.sort((a, b) => a.priority.compareTo(b.priority));
    return List<WorkoutReviewRecommendation>.unmodifiable(recommendations);
  }

  WorkoutReviewRecommendation _recommendation({
    required WorkoutReviewRecommendationCode code,
    required String action,
    required int priority,
    required String target,
    required List<String> chain,
  }) {
    return WorkoutReviewRecommendation(
      code: code,
      action: action,
      priority: priority,
      target: target,
      reasons: <WorkoutReviewReason>[
        WorkoutReviewReason(
          code: 'recommendation.${code.name}',
          subject: action,
          because: chain,
        ),
      ],
    );
  }
}
