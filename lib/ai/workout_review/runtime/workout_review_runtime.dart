import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_review/analysis/workout_review_engine.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_request.dart';
import 'package:gymaipro/ai/workout_review/models/workout_review_result.dart';

/// Runtime entry for workout program review.
///
/// Not wired to CoachPipeline — prepared for future integration.
class WorkoutReviewRuntime {
  const WorkoutReviewRuntime({
    WorkoutReviewEngine? engine,
    this.profileMapper = const ExerciseProfileMapper(),
    this.enforceCoachV2Gate = true,
  }) : _engine = engine;

  final WorkoutReviewEngine? _engine;
  final ExerciseProfileMapper profileMapper;
  final bool enforceCoachV2Gate;

  WorkoutReviewEngine get engine => _engine ??
      WorkoutReviewEngine(enforceCoachV2Gate: enforceCoachV2Gate);

  /// Reviews a [program] using optional [context], [catalogProfiles], and [knowledgeResult].
  WorkoutReviewResult review({
    required WorkoutProgram program,
    CoachContext? context,
    List<ExerciseProfile>? catalogProfiles,
    CoachKnowledgeResult? knowledgeResult,
  }) {
    final request = WorkoutReviewRequest(
      program: program,
      context: context ?? CoachContext.empty(),
      catalogProfiles: catalogProfiles ?? const <ExerciseProfile>[],
      knowledgeResult: knowledgeResult,
    );
    return engine.review(request);
  }
}
