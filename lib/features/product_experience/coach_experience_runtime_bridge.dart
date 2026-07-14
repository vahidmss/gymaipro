import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart' as ai;
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_result.dart';
import 'package:gymaipro/ai/workout_modify/runtime/workout_modify_runtime.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';
import 'package:gymaipro/ai/workout_review/runtime/workout_review_runtime.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Bridges existing workout runtimes into Coach product quick actions.
class CoachExperienceRuntimeBridge {
  const CoachExperienceRuntimeBridge({
    WorkoutReviewRuntime? reviewRuntime,
    WorkoutModifyRuntime? modifyRuntime,
  }) : _reviewRuntime = reviewRuntime ?? const WorkoutReviewRuntime(),
       _modifyRuntime = modifyRuntime ?? const WorkoutModifyRuntime();

  final WorkoutReviewRuntime _reviewRuntime;
  final WorkoutModifyRuntime _modifyRuntime;

  WorkoutReviewResult? reviewProgram({
    required ai.WorkoutProgram? program,
    required CoachContext context,
  }) {
    if (program == null) return null;
    return _reviewRuntime.review(program: program, context: context);
  }

  WorkoutModificationResult? modifyProgram({
    required ai.WorkoutProgram? program,
    required CoachContext context,
    required List<WorkoutModificationType> modifications,
  }) {
    if (program == null) return null;
    return _modifyRuntime.modify(
      program: program,
      context: context,
      modifications: modifications,
    );
  }

  WorkoutModificationResult? replaceExercise({
    required ai.WorkoutProgram? program,
    required CoachContext context,
  }) {
    return modifyProgram(
      program: program,
      context: context,
      modifications: const <WorkoutModificationType>[
        WorkoutModificationType.replaceExercise,
      ],
    );
  }

  List<String> formatReview(WorkoutReviewResult? review) {
    if (review == null) return const <String>[];
    return ProductExperienceFormatter.reviewSummaryLines(review);
  }

  List<String> formatModification(WorkoutModificationResult? result) {
    if (result == null) return const <String>[];
    return result.trace.steps
        .map(ProductExperienceFormatter.humanizeReason)
        .where((item) => item.isNotEmpty)
        .take(4)
        .toList(growable: false);
  }

  static String normalizeQuickActionId(String id) {
    return switch (id) {
      'review' => 'review_program',
      'modify' => 'modify_program',
      'replace' => 'replace_exercise',
      _ => id,
    };
  }

  List<String> runQuickActionMessages({
    required String actionId,
    required ai.WorkoutProgram? program,
    required CoachContext context,
  }) {
    final normalized = normalizeQuickActionId(actionId);
    final review = normalized == 'review_program'
        ? reviewProgram(program: program, context: context)
        : null;
    final modification = switch (normalized) {
      'modify_program' => modifyProgram(
        program: program,
        context: context,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.recoveryAdaptation,
        ],
      ),
      'replace_exercise' => replaceExercise(program: program, context: context),
      _ => null,
    };
    return <String>[
      ...formatReview(review),
      ...formatModification(modification),
    ];
  }
}
