import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/replacement/exercise_replacement_engine.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_engine.dart';
import 'package:gymaipro/ai/workout_modify/modifier/workout_modify_impact_calculator.dart';
import 'package:gymaipro/ai/workout_modify/modifier/workout_program_mutator.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modification.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_reason.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_request.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_result.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_versions.dart';
import 'package:gymaipro/ai/workout_modify/rules/workout_modify_rules.dart';
import 'package:gymaipro/ai/workout_modify/trace/workout_modify_trace_builder.dart';
import 'package:gymaipro/ai/workout_modify/validator/workout_modify_validator.dart';

/// Main engine that modifies existing workout programs.
///
/// Does not generate new programs from scratch — only mutates the input program.
class WorkoutModifyEngine {
  const WorkoutModifyEngine({
    this.mutator = const WorkoutProgramMutator(),
    this.rules = const WorkoutModifyRules(),
    this.impactCalculator = const WorkoutModifyImpactCalculator(),
    this.validator = const WorkoutModifyValidator(),
    this.replacementEngine = const ExerciseReplacementEngine(),
    this.safetyEngine = const ExerciseSafetyEngine(),
    this.enforceCoachV2Gate = true,
  });

  final WorkoutProgramMutator mutator;
  final WorkoutModifyRules rules;
  final WorkoutModifyImpactCalculator impactCalculator;
  final WorkoutModifyValidator validator;
  final ExerciseReplacementEngine replacementEngine;
  final ExerciseSafetyEngine safetyEngine;
  final bool enforceCoachV2Gate;

  String get engineVersion => WorkoutModifyVersions.engineVersion;

  WorkoutModificationResult modify(WorkoutModificationRequest request) {
    if (enforceCoachV2Gate && !CoachV2Config.coachV2Enabled) {
      return WorkoutModificationResult.disabled(request: request);
    }

    final started = DateTime.now();
    final original = request.program;
    final profileById = <int, ExerciseProfile>{
      for (final profile in request.catalogProfiles) profile.id: profile,
    };

    final experience =
        original.experienceLevel.isNotEmpty
            ? original.experienceLevel
            : (request.context.profile['experience_level'] as String?) ??
                'متوسط';

    final query = ExerciseIntelligenceQuery(
      goal: original.goal,
      experience: experience,
      availableEquipment: request.context.equipment,
      limitations: request.context.restrictions,
      recoveryScore: 0.85,
    );

    final ruleCtx = WorkoutModifyRuleContext(
      program: mutator.clone(original),
      context: request.context,
      catalog: request.catalogProfiles,
      profileById: profileById,
      query: query,
      mutator: mutator,
      replacementEngine: replacementEngine,
      safetyEngine: safetyEngine,
      options: request.options,
    );

    final requestedMods = request.modifications
        .map(
          (type) => WorkoutModification(
            type: type,
            status: WorkoutModificationStatus.skipped,
            subject: type.name,
            dayLabel: '',
            reasons: const <WorkoutModificationReason>[],
          ),
        )
        .toList();

    for (final type in request.modifications) {
      rules.apply(type: type, ctx: ruleCtx);
    }

    var modified = mutator.withUpdatedAt(ruleCtx.program);
    final validation = validator.validate(
      original: original,
      modified: modified,
    );

    if (!validation.isValid) {
      modified = mutator.clone(original);
      for (var i = 0; i < ruleCtx.modifications.length; i++) {
        final mod = ruleCtx.modifications[i];
        if (mod.status == WorkoutModificationStatus.applied) {
          ruleCtx.modifications[i] = mod.copyWith(
            status: WorkoutModificationStatus.rejected,
          );
        }
      }
    }

    final applied = ruleCtx.modifications
        .where((m) => m.status == WorkoutModificationStatus.applied)
        .toList();
    final skipped = ruleCtx.modifications
        .where((m) => m.status == WorkoutModificationStatus.skipped)
        .toList();
    final rejected = ruleCtx.modifications
        .where((m) => m.status == WorkoutModificationStatus.rejected)
        .toList();

    final impact = impactCalculator.calculate(
      before: original,
      after: modified,
      context: request.context,
      profileById: profileById,
    );

    final trace = WorkoutModificationTrace(
      requested: requestedMods,
      applied: applied,
      skipped: skipped,
      rejected: rejected,
      finalProgramId: modified.id,
      steps: <String>[
        'load_program',
        'clone_program',
        'apply_modifications',
        'validate_result',
        'calculate_impact',
        'emit_trace',
      ],
      modifyDuration: DateTime.now().difference(started),
    );

    final summary = applied.isEmpty
        ? 'No modifications applied (${rejected.length} rejected, ${skipped.length} skipped).'
        : 'Applied ${applied.length} modification(s) to program.';

    return WorkoutModificationResult(
      enabled: true,
      request: request,
      originalProgram: original,
      modifiedProgram: modified,
      modifications: ruleCtx.modifications,
      impact: impact,
      trace: trace,
      summary: summary,
      engineVersion: engineVersion,
    );
  }
}
