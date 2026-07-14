import 'package:gymaipro/ai/coach/coach_rules.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/skills/coach_skill.dart';
import 'package:gymaipro/ai/skills/coach_skill_type.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason.dart';
import 'package:gymaipro/ai/skills/intelligence/skill_reason_type.dart';
import 'package:gymaipro/ai/skills/runtime/coach_skill_response.dart';
import 'package:gymaipro/ai/skills/skill_capability.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_result.dart';
import 'package:gymaipro/ai/workout/runtime/coach_workout_generator_runtime.dart';
import 'package:gymaipro/models/exercise.dart';

/// Local rule-based workout program generation skill.
class WorkoutGenerationSkill extends CoachRunnableSkill {
  const WorkoutGenerationSkill({
    this.runtime = const CoachWorkoutGeneratorRuntime(),
    this.catalog = const <Exercise>[],
    this.userId = 'coach_user',
  });

  final CoachWorkoutGeneratorRuntime runtime;
  final List<Exercise> catalog;
  final String userId;

  @override
  String get id => 'workout_generation_skill';

  @override
  CoachSkillType get type => CoachSkillType.workoutGeneration;

  @override
  String get title => 'Workout Generation';

  @override
  Set<AIIntent> get supportedIntents =>
      const <AIIntent>{AIIntent.workoutGeneration};

  @override
  Set<AIContextProviderKey> get requiredContext => const <AIContextProviderKey>{
    AIContextProviderKey.profile,
    AIContextProviderKey.goals,
    AIContextProviderKey.equipment,
  };

  @override
  Set<AIContextProviderKey> get optionalContext => const <AIContextProviderKey>{
    AIContextProviderKey.restrictions,
    AIContextProviderKey.heatmap,
    AIContextProviderKey.workoutHistory,
    AIContextProviderKey.memory,
    AIContextProviderKey.activeProgram,
  };

  @override
  double get baseConfidence => 0.92;

  @override
  Duration get estimatedLatency => const Duration(milliseconds: 220);

  @override
  bool get requiresAIFallback => false;

  @override
  SkillCapability get capability => const SkillCapability(
    id: 'generate_workout_program',
    title: 'Generate Workout Program',
    description: 'Build a typed offline workout program from Coach context.',
    kind: SkillCapabilityKind.navigationHint,
    outputs: <String>['workout_program', 'program_summary'],
    navigationTargets: <String>['workout_program_builder'],
  );

  @override
  SkillEvaluation evaluate({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final missingData = CoachRules.missingWorkoutGenerationData(context);
    if (missingData.isNotEmpty || context.equipment.isEmpty) {
      return SkillEvaluation(
        skillId: id,
        skillType: type,
        outcome: SkillOutcome.insufficientContext,
        confidence: 0.25,
        estimatedLatency: estimatedLatency,
        requiresAIFallback: false,
        missingContext: CoachSkillContextChecks.missingRequired(
          context,
          requiredContext,
        ),
        notes: <String>[
          if (missingData.isNotEmpty)
            'Need follow-up: ${missingData.join(', ')}',
          if (context.equipment.isEmpty) 'Need follow-up: equipment',
        ],
      );
    }

    if (catalog.isEmpty) {
      return SkillEvaluation(
        skillId: id,
        skillType: type,
        outcome: SkillOutcome.requiresAI,
        confidence: 0.5,
        estimatedLatency: estimatedLatency,
        requiresAIFallback: true,
        missingContext: const <AIContextProviderKey>[],
        notes: const <String>['Exercise catalog not loaded.'],
      );
    }

    return SkillEvaluation(
      skillId: id,
      skillType: type,
      outcome: SkillOutcome.handledLocally,
      confidence: baseConfidence,
      estimatedLatency: estimatedLatency,
      requiresAIFallback: false,
      missingContext: const <AIContextProviderKey>[],
      previewMessage: 'Offline workout program can be generated.',
    );
  }

  @override
  CoachSkillResponse execute({
    required CoachContext context,
    required AIIntent intent,
  }) {
    final result = runtime.generate(
      context: context,
      userId: userId,
      catalog: InMemoryWorkoutExerciseCatalog(catalog),
    );
    return _toResponse(result);
  }
}

CoachSkillResponse _toResponse(WorkoutGeneratorResult result) {
  if (result.needsFollowUp) {
    return CoachSkillResponse(
      confidence: 0.4,
      requiresAI: false,
      message: result.message,
      structuredData: <String, Object?>{
        'followUpFields':
            result.followUpFields.map((field) => field.name).toList(),
      },
      reasons: result.reasons
          .map(
            (reason) => SkillReason(
              type: SkillReasonType.dataCoverage,
              message: '${reason.subject}: ${reason.because.join('; ')}',
            ),
          )
          .toList(),
    );
  }

  if (!result.isSuccess || result.program == null) {
    return CoachSkillResponse(
      confidence: 0.2,
      requiresAI: false,
      message: result.message ?? 'Workout generation failed.',
      warnings: result.validationIssues,
    );
  }

  final program = result.program!;
  return CoachSkillResponse(
    confidence: 0.95,
    requiresAI: false,
    message: 'برنامه ${program.name} با ${program.totalExercises} حرکت آماده است.',
    structuredData: <String, Object?>{
      'workoutProgram': program.toJson(),
      'programId': program.id,
      'daysPerWeek': program.daysPerWeek,
    },
    reasons: result.reasons
        .map(
          (reason) => SkillReason(
            type: SkillReasonType.goalAlignment,
            message: '${reason.subject}: ${reason.because.join('; ')}',
          ),
        )
        .toList(),
  );
}
