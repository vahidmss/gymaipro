import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/entitlement/runtime/coach_entitlement_snapshot.dart';
import 'package:gymaipro/ai/knowledge/runtime/coach_knowledge_result.dart';
import 'package:gymaipro/ai/state/coach_conversation_state.dart';
import 'package:gymaipro/ai/strategy/coach_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_builder.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_validator.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/workout/generator/coach_workout_generator.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_follow_up_field.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/ai/workout/runtime/coach_workout_generator_runtime.dart';

/// Prepared workout generation path for future Coach pipeline wiring.
///
/// Not registered in CoachPipeline yet. Safe to call from tests and runtime
/// adapters behind `CoachV2Config.coachV2Enabled`.
///
/// CoachContext → WorkoutBlueprintBuilder → WorkoutBlueprint → CoachWorkoutGenerator
class WorkoutGenerationPipelinePath {
  const WorkoutGenerationPipelinePath({
    WorkoutBlueprintBuilder blueprintBuilder = const WorkoutBlueprintBuilder(),
    WorkoutBlueprintValidator blueprintValidator = const WorkoutBlueprintValidator(),
    CoachWorkoutGenerator generator = const CoachWorkoutGenerator(),
  }) : _blueprintBuilder = blueprintBuilder,
       _blueprintValidator = blueprintValidator,
       _generator = generator;

  final WorkoutBlueprintBuilder _blueprintBuilder;
  final WorkoutBlueprintValidator _blueprintValidator;
  final CoachWorkoutGenerator _generator;

  WorkoutGeneratorResult execute({
    required CoachContext context,
    required String userId,
    required WorkoutExerciseCatalog catalog,
    CoachKnowledgeResult? knowledgeResult,
    CoachStrategy? strategy,
    CoachEntitlementSnapshot? entitlementSnapshot,
    CoachConversationState? conversationState,
    int? varietySeed,
  }) {
    final blueprintResult = _blueprintBuilder.build(
      context: context,
      userId: userId,
      knowledgeResult: knowledgeResult,
      strategy: strategy,
      entitlementSnapshot: entitlementSnapshot,
      conversationState: conversationState,
      varietySeed: varietySeed,
    );

    if (blueprintResult.entitlementBlocked) {
      return WorkoutGeneratorResult.blocked(
        message: blueprintResult.message ?? 'Workout generation blocked.',
        reasons: _mapReasons(blueprintResult.reasons),
      );
    }

    if (blueprintResult.needsFollowUp || blueprintResult.blueprint == null) {
      return WorkoutGeneratorResult.followUp(
        fields: _mapFollowUpFields(blueprintResult.followUpFields),
        reasons: _mapReasons(blueprintResult.reasons),
      );
    }

    final validation = _blueprintValidator.validate(blueprintResult.blueprint!);
    if (!validation.isValid || validation.needsFollowUp) {
      return WorkoutGeneratorResult.followUp(
        fields: _mapFollowUpFields(validation.followUpFields),
        reasons: _mapReasons(blueprintResult.reasons),
      );
    }

    return _generator.generate(
      blueprint: blueprintResult.blueprint!,
      catalog: ListExerciseCatalogAdapter(catalog.loadCatalog()),
    );
  }

  List<WorkoutGeneratorReason> _mapReasons(
    List<WorkoutBlueprintReason> reasons,
  ) {
    return reasons
        .map(
          (reason) => WorkoutGeneratorReason(
            code: reason.code,
            subject: reason.subject,
            because: reason.because,
          ),
        )
        .toList();
  }

  List<WorkoutFollowUpField> _mapFollowUpFields(List<String> fields) {
    return fields
        .map(_followUpFieldFromName)
        .whereType<WorkoutFollowUpField>()
        .toList();
  }

  WorkoutFollowUpField? _followUpFieldFromName(String name) {
    for (final field in WorkoutFollowUpField.values) {
      if (field.name == name) return field;
    }
    return null;
  }
}
