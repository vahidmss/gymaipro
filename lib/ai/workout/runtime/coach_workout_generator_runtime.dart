import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_runtime.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/strategy/coach_strategy.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/ai/workout/runtime/workout_generation_pipeline_path.dart';
import 'package:gymaipro/models/exercise.dart';

/// Exercise catalog for the workout generator.
abstract class WorkoutExerciseCatalog {
  List<Exercise> loadCatalog();

  bool get isEmpty;
}

/// In-memory catalog for offline generation and tests.
class InMemoryWorkoutExerciseCatalog implements WorkoutExerciseCatalog {
  InMemoryWorkoutExerciseCatalog(this.exercises);

  final List<Exercise> exercises;

  @override
  List<Exercise> loadCatalog() => exercises;

  @override
  bool get isEmpty => exercises.isEmpty;
}

/// Runtime entry that consumes existing Coach pipeline artifacts.
class CoachWorkoutGeneratorRuntime {
  const CoachWorkoutGeneratorRuntime({
    WorkoutGenerationPipelinePath pipelinePath =
        const WorkoutGenerationPipelinePath(),
  }) : _pipelinePath = pipelinePath;

  final WorkoutGenerationPipelinePath _pipelinePath;

  WorkoutGeneratorResult generate({
    required CoachContext context,
    required String userId,
    required WorkoutExerciseCatalog catalog,
    CoachKnowledgeResult? knowledgeResult,
    CoachEntitlementRuntimeResult? entitlementResult,
    CoachStrategy? strategy,
    CoachEntitlementSnapshot? entitlementSnapshot,
    CoachConversationState? conversationState,
    int? varietySeed,
  }) {
    return _pipelinePath.execute(
      context: context,
      userId: userId,
      catalog: catalog,
      knowledgeResult: knowledgeResult,
      strategy: strategy,
      entitlementSnapshot: entitlementSnapshot ??
          _snapshotWhenBlocked(entitlementResult, userId),
      conversationState: conversationState,
      varietySeed: varietySeed,
    );
  }

  CoachEntitlementSnapshot? _snapshotWhenBlocked(
    CoachEntitlementRuntimeResult? entitlementResult,
    String userId,
  ) {
    if (entitlementResult != null && !entitlementResult.allowed) {
      return CoachEntitlementSnapshot.free(userId: userId);
    }
    return null;
  }
}
