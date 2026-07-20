import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_enums.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/replacement/exercise_replacement_engine.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_engine.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_result.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_modify/modifier/workout_program_mutator.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modification.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_reason.dart';

/// Shared context passed to modification rule handlers.
class WorkoutModifyRuleContext {
  WorkoutModifyRuleContext({
    required this.program,
    required this.context,
    required this.catalog,
    required this.profileById,
    required this.query,
    required this.mutator,
    required this.replacementEngine,
    required this.safetyEngine,
    this.options = const <String, Object?>{},
  });

  WorkoutProgram program;
  final CoachContext context;
  final List<ExerciseProfile> catalog;
  final Map<int, ExerciseProfile> profileById;
  final ExerciseIntelligenceQuery query;
  final WorkoutProgramMutator mutator;
  final ExerciseReplacementEngine replacementEngine;
  final ExerciseSafetyEngine safetyEngine;
  final Map<String, Object?> options;
  final List<WorkoutModification> modifications = <WorkoutModification>[];
}

/// Applies individual modification rules to a workout program.
class WorkoutModifyRules {
  const WorkoutModifyRules();

  void apply({
    required WorkoutModificationType type,
    required WorkoutModifyRuleContext ctx,
  }) {
    switch (type) {
      case WorkoutModificationType.replaceExercise:
        _replaceExplicit(ctx);
      case WorkoutModificationType.removeExercise:
        _removeExplicit(ctx);
      case WorkoutModificationType.addExercise:
        _addExercise(ctx);
      case WorkoutModificationType.reduceVolume:
        _adjustVolume(ctx, delta: -1);
      case WorkoutModificationType.increaseVolume:
        _adjustVolume(ctx, delta: 1);
      case WorkoutModificationType.reduceIntensity:
        _adjustIntensity(ctx, repDelta: 2);
      case WorkoutModificationType.increaseIntensity:
        _adjustIntensity(ctx, repDelta: -2);
      case WorkoutModificationType.shortenSession:
        _shortenSession(ctx);
      case WorkoutModificationType.homeVersion:
        _equipmentVersion(ctx, home: true);
      case WorkoutModificationType.gymVersion:
        _equipmentVersion(ctx, home: false);
      case WorkoutModificationType.injuryAdaptation:
        _injuryAdaptation(ctx);
      case WorkoutModificationType.equipmentAdaptation:
        _equipmentAdaptation(ctx);
      case WorkoutModificationType.recoveryAdaptation:
        _recoveryAdaptation(ctx);
    }
  }

  void _replaceExplicit(WorkoutModifyRuleContext ctx) {
    final exerciseId = ctx.options['exerciseId']?.toString();
    if (exerciseId == null || exerciseId.isEmpty) {
      ctx.modifications.add(_skipped(
        type: WorkoutModificationType.replaceExercise,
        subject: 'Replace',
        because: <String>['No exerciseId in options'],
      ));
      return;
    }
    final located = _findExercise(ctx.program, exerciseId);
    if (located == null) {
      ctx.modifications.add(_skipped(
        type: WorkoutModificationType.replaceExercise,
        subject: exerciseId,
        because: <String>['Exercise not found'],
      ));
      return;
    }
    _replaceUnsafeExercise(ctx, located.exercise, located.dayLabel);
  }

  void _removeExplicit(WorkoutModifyRuleContext ctx) {
    final exerciseId = ctx.options['exerciseId']?.toString();
    if (exerciseId == null || exerciseId.isEmpty) {
      ctx.modifications.add(_skipped(
        type: WorkoutModificationType.removeExercise,
        subject: 'Remove',
        because: <String>['No exerciseId in options'],
      ));
      return;
    }
    final located = _findExercise(ctx.program, exerciseId);
    if (located == null) {
      ctx.modifications.add(_rejected(
        type: WorkoutModificationType.removeExercise,
        subject: exerciseId,
        because: <String>['Exercise not found'],
      ));
      return;
    }
    ctx.program = ctx.mutator.removeExercise(
      program: ctx.program,
      exerciseId: exerciseId,
    );
    ctx.modifications.add(
      WorkoutModification(
        type: WorkoutModificationType.removeExercise,
        status: WorkoutModificationStatus.applied,
        subject: located.exercise.name,
        dayLabel: located.dayLabel,
        exerciseId: exerciseId,
        beforeName: located.exercise.name,
        beforeCatalogId: located.exercise.catalogExerciseId,
        reasons: <WorkoutModificationReason>[
          WorkoutModificationReason(
            code: 'modify.remove',
            subject: located.exercise.name,
            because: <String>['Explicit removal requested'],
          ),
        ],
      ),
    );
  }

  void _addExercise(WorkoutModifyRuleContext ctx) {
    final catalogId = ctx.options['catalogExerciseId'] as int?;
    final dayId = ctx.options['dayId'] as String?;
    if (catalogId == null || dayId == null) {
      ctx.modifications.add(_skipped(
        type: WorkoutModificationType.addExercise,
        subject: 'Add',
        because: <String>['catalogExerciseId or dayId missing'],
      ));
      return;
    }
    final profile = ctx.profileById[catalogId];
    if (profile == null) {
      ctx.modifications.add(_rejected(
        type: WorkoutModificationType.addExercise,
        subject: 'catalog:$catalogId',
        because: <String>['Profile not in catalog'],
      ));
      return;
    }
    final safety = ctx.safetyEngine.evaluate(
      exercise: profile,
      query: ctx.query,
    );
    if (!safety.isSafe) {
      ctx.modifications.add(_rejected(
        type: WorkoutModificationType.addExercise,
        subject: profile.canonicalName,
        because: safety.reasons.map((r) => r.because.join('; ')).toList(),
      ));
      return;
    }
    ctx.program = ctx.mutator.addExercise(
      program: ctx.program,
      dayId: dayId,
      profile: profile,
    );
    ctx.modifications.add(
      WorkoutModification(
        type: WorkoutModificationType.addExercise,
        status: WorkoutModificationStatus.applied,
        subject: profile.canonicalName,
        dayLabel: dayId,
        afterName: profile.canonicalName,
        afterCatalogId: profile.id,
        reasons: <WorkoutModificationReason>[
          WorkoutModificationReason(
            code: 'modify.add',
            subject: profile.canonicalName,
            because: <String>['Exercise added to session'],
          ),
        ],
      ),
    );
  }

  void _adjustVolume(WorkoutModifyRuleContext ctx, {required int delta}) {
    final dayLabel = _selectedDayLabel(ctx);
    final beforeSets = _totalSets(ctx.program, dayLabel: dayLabel);
    ctx.program = ctx.mutator.adjustVolume(
      program: ctx.program,
      deltaSets: delta,
      dayLabel: dayLabel,
    );
    final afterSets = _totalSets(ctx.program, dayLabel: dayLabel);
    if (beforeSets == afterSets) {
      ctx.modifications.add(_skipped(
        type: delta < 0
            ? WorkoutModificationType.reduceVolume
            : WorkoutModificationType.increaseVolume,
        subject: 'Volume',
        because: <String>['No sets adjusted'],
        dayLabel: dayLabel ?? '',
      ));
      return;
    }
    ctx.modifications.add(
      WorkoutModification(
        type: delta < 0
            ? WorkoutModificationType.reduceVolume
            : WorkoutModificationType.increaseVolume,
        status: WorkoutModificationStatus.applied,
        subject: 'Program volume',
        dayLabel: dayLabel ?? 'all',
        reasons: <WorkoutModificationReason>[
          WorkoutModificationReason(
            code: delta < 0 ? 'modify.reduce_volume' : 'modify.increase_volume',
            subject: 'Sets',
            because: <String>[
              'Before sets = $beforeSets',
              'After sets = $afterSets',
              'Delta = ${afterSets - beforeSets}',
            ],
          ),
        ],
      ),
    );
  }

  void _adjustIntensity(WorkoutModifyRuleContext ctx, {required int repDelta}) {
    final dayLabel = _selectedDayLabel(ctx);
    ctx.program = ctx.mutator.adjustIntensity(
      program: ctx.program,
      repDelta: repDelta,
      dayLabel: dayLabel,
    );
    ctx.modifications.add(
      WorkoutModification(
        type: repDelta > 0
            ? WorkoutModificationType.reduceIntensity
            : WorkoutModificationType.increaseIntensity,
        status: WorkoutModificationStatus.applied,
        subject: 'Intensity',
        dayLabel: dayLabel ?? 'all',
        reasons: <WorkoutModificationReason>[
          WorkoutModificationReason(
            code: repDelta > 0
                ? 'modify.reduce_intensity'
                : 'modify.increase_intensity',
            subject: 'Reps',
            because: <String>[
              'Rep delta = $repDelta',
              if (repDelta > 0) 'Intensity reduced' else 'Intensity increased',
            ],
          ),
        ],
      ),
    );
  }

  void _shortenSession(WorkoutModifyRuleContext ctx) {
    final dayLabel = _selectedDayLabel(ctx);
    final beforeCount = _exerciseCount(ctx.program, dayLabel: dayLabel);
    ctx.program = ctx.mutator.shortenSessions(
      program: ctx.program,
      dayLabel: dayLabel,
    );
    final afterCount = _exerciseCount(ctx.program, dayLabel: dayLabel);
    if (beforeCount == afterCount) {
      ctx.modifications.add(_skipped(
        type: WorkoutModificationType.shortenSession,
        subject: 'Session',
        because: <String>['Sessions already minimal'],
        dayLabel: dayLabel ?? '',
      ));
      return;
    }
    ctx.modifications.add(
      WorkoutModification(
        type: WorkoutModificationType.shortenSession,
        status: WorkoutModificationStatus.applied,
        subject: 'Session length',
        dayLabel: dayLabel ?? 'all',
        reasons: <WorkoutModificationReason>[
          WorkoutModificationReason(
            code: 'modify.shorten_session',
            subject: 'Session',
            because: <String>[
              'Exercises before = $beforeCount',
              'Exercises after = $afterCount',
              'Removed trailing isolation per day',
            ],
          ),
        ],
      ),
    );
  }

  void _equipmentVersion(WorkoutModifyRuleContext ctx, {required bool home}) {
    final allowedLabels = home ? _homeEquipmentLabels : _gymEquipmentLabels;
    final adaptedQuery = ExerciseIntelligenceQuery(
      goal: ctx.query.goal,
      experience: ctx.query.experience,
      availableEquipment: allowedLabels,
      limitations: ctx.query.limitations,
      recoveryScore: ctx.query.recoveryScore,
    );

    final scopedDays = _scopedDays(ctx);
    if (scopedDays.isEmpty) {
      ctx.modifications.add(
        _skipped(
          type: home
              ? WorkoutModificationType.homeVersion
              : WorkoutModificationType.gymVersion,
          subject: 'Day',
          because: <String>['Selected day not found in program'],
          dayLabel: _selectedDayLabel(ctx) ?? '',
        ),
      );
      return;
    }

    for (final day in scopedDays) {
      for (final exercise in day.exercises) {
        final profile = ctx.profileById[exercise.catalogExerciseId];
        if (profile == null) continue;

        // Already fits the target environment — leave it alone.
        if (home
            ? _isHomeCompatible(profile, exerciseName: exercise.name)
            : _isGymCompatible(profile, exerciseName: exercise.name)) {
          continue;
        }

        final replacement = _findEquipmentBoundReplacement(
          ctx: ctx,
          original: profile,
          query: adaptedQuery,
          home: home,
        );
        if (replacement == null) {
          ctx.modifications.add(
            WorkoutModification(
              type: home
                  ? WorkoutModificationType.homeVersion
                  : WorkoutModificationType.gymVersion,
              status: WorkoutModificationStatus.skipped,
              subject: exercise.name,
              dayLabel: day.label,
              exerciseId: exercise.id,
              beforeName: exercise.name,
              reasons: <WorkoutModificationReason>[
                WorkoutModificationReason(
                  code: 'modify.equipment_skip',
                  subject: exercise.name,
                  because: <String>[
                    home
                        ? 'No home-friendly same-role replacement'
                        : 'No gym-friendly same-role replacement',
                  ],
                ),
              ],
            ),
          );
          continue;
        }

        // Hard reject: never put machines/cables into a home program.
        if (home && !_isHomeCompatible(replacement)) {
          ctx.modifications.add(
            WorkoutModification(
              type: WorkoutModificationType.homeVersion,
              status: WorkoutModificationStatus.rejected,
              subject: exercise.name,
              dayLabel: day.label,
              exerciseId: exercise.id,
              beforeName: exercise.name,
              afterName: replacement.canonicalName,
              reasons: const <WorkoutModificationReason>[
                WorkoutModificationReason(
                  code: 'modify.home_reject_gym_gear',
                  subject: 'Home',
                  because: <String>[
                    'Candidate was gym-only equipment',
                  ],
                ),
              ],
            ),
          );
          continue;
        }

        ctx.program = ctx.mutator.replaceExercise(
          program: ctx.program,
          exerciseId: exercise.id,
          replacement: replacement,
        );
        ctx.modifications.add(
          _replaceModification(
            type: home
                ? WorkoutModificationType.homeVersion
                : WorkoutModificationType.gymVersion,
            exercise: exercise,
            dayLabel: day.label,
            replacement: replacement,
            safetyReasons: const <ExerciseIntelligenceReason>[],
            extraBecause: <String>[
              if (home) 'Home equipment only' else 'Gym equipment available',
              'Equipment adapted',
              'Scoped to ${day.label}',
            ],
          ),
        );
      }
    }
  }

  void _injuryAdaptation(WorkoutModifyRuleContext ctx) {
    for (final day in ctx.program.allDays) {
      for (final exercise in List<WorkoutExercise>.from(day.exercises)) {
        final profile = ctx.profileById[exercise.catalogExerciseId];
        if (profile == null) continue;

        final safety = ctx.safetyEngine.evaluate(
          exercise: profile,
          query: ctx.query,
        );
        if (safety.isSafe) continue;

        final replacement = _findReplacement(
          ctx: ctx,
          original: profile,
          query: ctx.query,
          allowLenient: false,
        );
        if (replacement != null &&
            _isRoleCompatibleReplacement(profile, replacement)) {
          ctx.program = ctx.mutator.replaceExercise(
            program: ctx.program,
            exerciseId: exercise.id,
            replacement: replacement,
          );
          ctx.modifications.add(
            _replaceModification(
              type: WorkoutModificationType.injuryAdaptation,
              exercise: exercise,
              dayLabel: day.label,
              replacement: replacement,
              safetyReasons: safety.reasons,
              extraBecause: <String>[
                _limitationLabel(ctx.context.restrictions),
                'Joint load reduced',
              ],
            ),
          );
        } else if (_wouldEmptyDay(ctx.program, exercise.id)) {
          ctx.modifications.add(
            WorkoutModification(
              type: WorkoutModificationType.injuryAdaptation,
              status: WorkoutModificationStatus.skipped,
              subject: exercise.name,
              dayLabel: day.label,
              exerciseId: exercise.id,
              beforeName: exercise.name,
              beforeCatalogId: exercise.catalogExerciseId,
              reasons: <WorkoutModificationReason>[
                WorkoutModificationReason(
                  code: 'modify.injury_skip',
                  subject: exercise.name,
                  because: <String>[
                    ...safety.reasons.expand((r) => r.because).take(2),
                    'Cannot remove last exercise on day',
                    'No safe replacement found',
                  ],
                ),
              ],
            ),
          );
        } else {
          ctx.program = ctx.mutator.removeExercise(
            program: ctx.program,
            exerciseId: exercise.id,
          );
          ctx.modifications.add(
            WorkoutModification(
              type: WorkoutModificationType.injuryAdaptation,
              status: WorkoutModificationStatus.applied,
              subject: exercise.name,
              dayLabel: day.label,
              exerciseId: exercise.id,
              beforeName: exercise.name,
              beforeCatalogId: exercise.catalogExerciseId,
              reasons: _injuryRemoveReasons(exercise.name, safety),
            ),
          );
        }
      }
    }
  }

  void _equipmentAdaptation(WorkoutModifyRuleContext ctx) {
    if (ctx.context.equipment.isEmpty) {
      ctx.modifications.add(_skipped(
        type: WorkoutModificationType.equipmentAdaptation,
        subject: 'Equipment',
        because: <String>['No equipment constraints in context'],
      ));
      return;
    }

    final scopedDays = _scopedDays(ctx);
    if (scopedDays.isEmpty) {
      ctx.modifications.add(
        _skipped(
          type: WorkoutModificationType.equipmentAdaptation,
          subject: 'Day',
          because: <String>['Selected day not found in program'],
          dayLabel: _selectedDayLabel(ctx) ?? '',
        ),
      );
      return;
    }

    for (final day in scopedDays) {
      for (final exercise in day.exercises) {
        if (_equipmentMatches(ctx.context.equipment, exercise.equipment)) {
          continue;
        }
        final profile = ctx.profileById[exercise.catalogExerciseId];
        if (profile == null) continue;

        final replacement = _findEquipmentBoundReplacement(
          ctx: ctx,
          original: profile,
          query: ctx.query,
          home: _looksLikeHomeEquipmentList(ctx.context.equipment),
        );
        if (replacement == null) {
          ctx.modifications.add(_rejected(
            type: WorkoutModificationType.equipmentAdaptation,
            subject: exercise.name,
            dayLabel: day.label,
            because: <String>[
              'Equipment mismatch: ${exercise.equipment}',
              'No replacement found',
            ],
          ));
          continue;
        }

        ctx.program = ctx.mutator.replaceExercise(
          program: ctx.program,
          exerciseId: exercise.id,
          replacement: replacement,
        );
        ctx.modifications.add(
          _replaceModification(
            type: WorkoutModificationType.equipmentAdaptation,
            exercise: exercise,
            dayLabel: day.label,
            replacement: replacement,
            safetyReasons: const <ExerciseIntelligenceReason>[],
            extraBecause: <String>[
              'Equipment mismatch',
              'Available: ${ctx.context.equipment.join(', ')}',
            ],
          ),
        );
      }
    }
  }

  void _recoveryAdaptation(WorkoutModifyRuleContext ctx) {
    // Tired / low-recovery days: only reduce volume on the selected day.
    final dayLabel = _selectedDayLabel(ctx);
    ctx.program = ctx.mutator.adjustVolume(
      program: ctx.program,
      deltaSets: -1,
      dayLabel: dayLabel,
    );
    ctx.modifications.add(
      WorkoutModification(
        type: WorkoutModificationType.recoveryAdaptation,
        status: WorkoutModificationStatus.applied,
        subject: 'Volume trim',
        dayLabel: dayLabel ?? 'all',
        reasons: const <WorkoutModificationReason>[
          WorkoutModificationReason(
            code: 'modify.recovery_volume',
            subject: 'Recovery',
            because: <String>[
              'Recovery adaptation',
              'Reduced one set per exercise',
            ],
          ),
        ],
      ),
    );
  }

  void _replaceUnsafeExercise(
    WorkoutModifyRuleContext ctx,
    WorkoutExercise exercise,
    String dayLabel,
  ) {
    final profile = ctx.profileById[exercise.catalogExerciseId];
    if (profile == null) {
      ctx.modifications.add(_rejected(
        type: WorkoutModificationType.replaceExercise,
        subject: exercise.name,
        dayLabel: dayLabel,
        because: <String>['No profile for exercise'],
      ));
      return;
    }

    final replacement = _findReplacement(
      ctx: ctx,
      original: profile,
      query: ctx.query,
    );
    if (replacement == null) {
      ctx.modifications.add(_rejected(
        type: WorkoutModificationType.replaceExercise,
        subject: exercise.name,
        dayLabel: dayLabel,
        because: <String>['ExerciseReplacementEngine found no candidate'],
      ));
      return;
    }

    ctx.program = ctx.mutator.replaceExercise(
      program: ctx.program,
      exerciseId: exercise.id,
      replacement: replacement,
    );
    ctx.modifications.add(
      _replaceModification(
        type: WorkoutModificationType.replaceExercise,
        exercise: exercise,
        dayLabel: dayLabel,
        replacement: replacement,
        safetyReasons: const <ExerciseIntelligenceReason>[],
        extraBecause: <String>['Explicit replace requested'],
      ),
    );
  }

  bool _isHeavyLowerBody(ExerciseProfile profile) {
    return profile.movementPattern == ExerciseMovementPattern.squat ||
        profile.movementPattern == ExerciseMovementPattern.lunge ||
        profile.kneeLoad >= 0.55 ||
        profile.canonicalName.contains('اسکوات') ||
        profile.canonicalName.toLowerCase().contains('squat');
  }

  bool _isHeavyHinge(ExerciseProfile profile) {
    return profile.movementPattern == ExerciseMovementPattern.hinge ||
        profile.spineLoad >= 0.55 ||
        profile.canonicalName.contains('ددلیفت') ||
        profile.canonicalName.toLowerCase().contains('deadlift');
  }

  bool _sharesPrimaryMuscleFamily(
    ExerciseProfile a,
    ExerciseProfile b,
  ) {
    for (final muscleA in a.primaryMuscles) {
      final familyA = _muscleFamily(muscleA);
      if (familyA == null) continue;
      for (final muscleB in b.primaryMuscles) {
        final familyB = _muscleFamily(muscleB);
        if (familyB != null && familyA == familyB) return true;
      }
    }
    return false;
  }

  String? _muscleFamily(String raw) {
    final text = raw.trim().toLowerCase();
    if (text.length < 2) return null;
    if (text.contains('سینه') || text.contains('chest') || text.contains('pec')) {
      return 'chest';
    }
    if (text.contains('سرشانه') ||
        text.contains('شانه') ||
        text.contains('shoulder') ||
        text.contains('deltoid')) {
      return 'shoulder';
    }
    // Arms before generic «پشت» so «پشت بازو» is not classified as back.
    if (text.contains('جلو بازو') ||
        text.contains('پشت بازو') ||
        text.contains('bicep') ||
        text.contains('tricep')) {
      return 'arms';
    }
    if (text.contains('زیربغل') ||
        text.contains('لت') ||
        text.contains('back') ||
        text.contains('lat') ||
        (text.contains('پشت') && !text.contains('بازو'))) {
      return 'back';
    }
    if (text.contains('پا') ||
        text.contains('ران') ||
        text.contains('چهارسر') ||
        text.contains('همستر') ||
        text.contains('ساق') ||
        text.contains('quad') ||
        text.contains('ham') ||
        text.contains('glute') ||
        text.contains('leg')) {
      return 'legs';
    }
    if (text.contains('بازو') || text.contains('arm')) {
      return 'arms';
    }
    if (text.contains('شکم') ||
        text.contains('core') ||
        text.contains('abs')) {
      return 'core';
    }
    return text.length >= 3 ? text : null;
  }

  ExerciseProfile? _findReplacement({
    required WorkoutModifyRuleContext ctx,
    required ExerciseProfile original,
    required ExerciseIntelligenceQuery query,
    bool allowLenient = true,
    bool Function(ExerciseProfile candidate)? equipmentOk,
  }) {
    bool passes(ExerciseProfile candidate) {
      if (!_isRoleCompatibleReplacement(original, candidate)) return false;
      if (equipmentOk != null && !equipmentOk(candidate)) return false;
      return true;
    }

    final strict = ctx.replacementEngine.findReplacements(
      original: original,
      catalog: ctx.catalog,
      query: query,
      limit: 5,
    );
    if (strict.candidates.isNotEmpty) {
      final pick = _pickPreferred(
        candidates: strict.candidates
            .map((c) => c.exercise)
            .where(passes)
            .toList(),
        original: original,
        preferJoint: ctx.options['preferLowerJoint']?.toString(),
      );
      if (pick != null) return pick;
    }

    if (!allowLenient) {
      return _heuristicSameMuscleReplacement(
        ctx: ctx,
        original: original,
        preferJoint: ctx.options['preferLowerJoint']?.toString(),
        avoidNames: <String>[
          ...query.avoidExerciseNames,
          original.canonicalName,
        ],
        equipmentOk: equipmentOk,
      );
    }

    // Explicit user replace must not die on strict filters (equipment/fatigue).
    final preferJoint = ctx.options['preferLowerJoint']?.toString();
    final lenientQuery = ExerciseIntelligenceQuery(
      goal: query.goal,
      experience: query.experience,
      availableEquipment: query.availableEquipment.isEmpty
          ? const <String>['هالتر', 'دمبل', 'دستگاه', 'کابل', 'باشگاه']
          : query.availableEquipment,
      limitations: const <String>[],
      recoveryScore: 1,
      avoidExerciseNames: <String>[
        ...query.avoidExerciseNames,
        original.canonicalName,
      ],
      maxFatigueBudget: 1,
      preferCompound: query.preferCompound,
    );

    final lenient = ctx.replacementEngine.findReplacements(
      original: original,
      catalog: ctx.catalog,
      query: lenientQuery,
      limit: 8,
    );
    if (lenient.candidates.isNotEmpty) {
      final pick = _pickPreferred(
        candidates: lenient.candidates
            .map((c) => c.exercise)
            .where(passes)
            .toList(),
        original: original,
        preferJoint: preferJoint,
      );
      if (pick != null) return pick;
    }

    return _heuristicSameMuscleReplacement(
      ctx: ctx,
      original: original,
      preferJoint: preferJoint,
      avoidNames: lenientQuery.avoidExerciseNames,
      equipmentOk: equipmentOk,
    );
  }

  /// Home/gym swaps must keep role AND respect equipment — never fall back
  /// to unconstrained catalog picks (that caused dumbbell → machine).
  ExerciseProfile? _findEquipmentBoundReplacement({
    required WorkoutModifyRuleContext ctx,
    required ExerciseProfile original,
    required ExerciseIntelligenceQuery query,
    required bool home,
  }) {
    bool equipmentOk(ExerciseProfile candidate) {
      return home
          ? _isHomeCompatible(candidate)
          : _isGymCompatible(candidate);
    }

    return _findReplacement(
      ctx: ctx,
      original: original,
      query: query,
      allowLenient: false,
      equipmentOk: equipmentOk,
    );
  }

  static const List<String> _homeEquipmentLabels = <String>[
    'دمبل',
    'کش',
    'کتل',
    'بدون تجهیزات',
    'وزن بدن',
    'خانه',
  ];

  static const List<String> _gymEquipmentLabels = <String>[
    'هالتر',
    'دمبل',
    'دستگاه',
    'کابل',
    'پولی',
    'اسمیت',
    'باشگاه',
  ];

  bool _looksLikeHomeEquipmentList(List<String> equipment) {
    if (equipment.isEmpty) return false;
    final joined = equipment.join(' ').toLowerCase();
    final homeHint = joined.contains('خانه') ||
        joined.contains('home') ||
        joined.contains('کش') ||
        joined.contains('بدون');
    final gymHint = joined.contains('باشگاه') ||
        joined.contains('دستگاه') ||
        joined.contains('هالتر') ||
        joined.contains('gym');
    return homeHint && !gymHint;
  }

  bool _isHomeCompatible(
    ExerciseProfile profile, {
    String? exerciseName,
  }) {
    if (_isGymOnlyEquipment(profile, exerciseName: exerciseName)) {
      return false;
    }
    final types = profile.equipment.toSet();
    if (types.contains(ExerciseEquipmentType.cable) ||
        types.contains(ExerciseEquipmentType.machine) ||
        types.contains(ExerciseEquipmentType.barbell)) {
      // Barbell alone is gym-default unless also dumbbell/name says دمبل.
      if (!types.contains(ExerciseEquipmentType.dumbbell) &&
          !types.contains(ExerciseEquipmentType.bodyweight) &&
          !types.contains(ExerciseEquipmentType.band) &&
          !types.contains(ExerciseEquipmentType.kettlebell)) {
        return false;
      }
    }
    if (types.contains(ExerciseEquipmentType.dumbbell) ||
        types.contains(ExerciseEquipmentType.bodyweight) ||
        types.contains(ExerciseEquipmentType.band) ||
        types.contains(ExerciseEquipmentType.kettlebell)) {
      return true;
    }
    final name = '${profile.canonicalName} ${exerciseName ?? ''}'.toLowerCase();
    return _nameLooksLikeHomeGear(name);
  }

  bool _isGymCompatible(
    ExerciseProfile profile, {
    String? exerciseName,
  }) {
    final types = profile.equipment.toSet();
    if (types.contains(ExerciseEquipmentType.barbell) ||
        types.contains(ExerciseEquipmentType.machine) ||
        types.contains(ExerciseEquipmentType.cable) ||
        types.contains(ExerciseEquipmentType.dumbbell)) {
      return true;
    }
    final name = '${profile.canonicalName} ${exerciseName ?? ''}'.toLowerCase();
    return name.contains('هالتر') ||
        name.contains('دستگاه') ||
        _nameLooksLikeCable(name) ||
        name.contains('اسمیت') ||
        name.contains('دمبل');
  }

  bool _isGymOnlyEquipment(
    ExerciseProfile profile, {
    String? exerciseName,
  }) {
    final name = '${profile.canonicalName} ${exerciseName ?? ''}'.toLowerCase();
    if (_nameLooksLikeCable(name) ||
        name.contains('دستگاه') ||
        name.contains('اسمیت') ||
        name.contains('smith') ||
        name.contains('لگ پرس') ||
        name.contains('hack squat') ||
        name.contains('machine') ||
        name.contains('هالتر') ||
        name.contains('barbell')) {
      // Dumbbell variant of a barbell name is home-ok.
      if (name.contains('دمبل') || name.contains('dumbbell')) {
        return false;
      }
      return true;
    }
    final types = profile.equipment.toSet();
    if (types.contains(ExerciseEquipmentType.machine) ||
        types.contains(ExerciseEquipmentType.cable)) {
      return true;
    }
    if (types.contains(ExerciseEquipmentType.barbell) &&
        !types.contains(ExerciseEquipmentType.dumbbell) &&
        !name.contains('دمبل')) {
      return true;
    }
    return false;
  }

  bool _nameLooksLikeCable(String name) {
    final t = name.toLowerCase();
    return t.contains('کابل') ||
        t.contains('cable') ||
        t.contains('پولی') ||
        t.contains('pulley') ||
        t.contains('سیم‌کش') ||
        t.contains('سیمکش') ||
        t.contains('سیم کش') ||
        t.contains('سیمی');
  }

  bool _nameLooksLikeHomeGear(String name) {
    final t = name.toLowerCase();
    if (_nameLooksLikeCable(t)) return false;
    return t.contains('دمبل') ||
        t.contains('dumbbell') ||
        t.contains('کش مقاومتی') ||
        t.contains('کش ورزشی') ||
        t.contains('resistance band') ||
        (t.contains('band') && !t.contains('cable')) ||
        // Bare «کش» only if not cable stack.
        (t.contains('کش') && !t.contains('سیم')) ||
        t.contains('کتل') ||
        t.contains('kettlebell') ||
        t.contains('وزن بدن') ||
        t.contains('bodyweight') ||
        t.contains('شنا') ||
        t.contains('بارفیکس') ||
        t.contains('دیپ') ||
        t.contains('پلانک');
  }

  String? _selectedDayLabel(WorkoutModifyRuleContext ctx) {
    final raw = ctx.options['dayLabel']?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  List<WorkoutDay> _scopedDays(WorkoutModifyRuleContext ctx) {
    final wanted = _selectedDayLabel(ctx);
    if (wanted == null) return ctx.program.allDays.toList(growable: false);

    final exact = ctx.program.allDays
        .where((day) => day.label.trim() == wanted)
        .toList(growable: false);
    if (exact.isNotEmpty) return exact;

    final soft = ctx.program.allDays
        .where((day) {
          final label = day.label.trim();
          return label.contains(wanted) || wanted.contains(label);
        })
        .toList(growable: false);
    if (soft.isNotEmpty) return soft;

    final wantedNum = RegExp(r'روز\s*([0-9۰-۹]+)').firstMatch(wanted)?.group(1);
    if (wantedNum != null) {
      final byNum = ctx.program.allDays
          .where((day) {
            final currentNum =
                RegExp(r'روز\s*([0-9۰-۹]+)').firstMatch(day.label)?.group(1);
            return currentNum == wantedNum;
          })
          .toList(growable: false);
      if (byNum.isNotEmpty) return byNum;
    }

    // Never silently fall back to the whole program — that caused squat
    // from day 2/3 to appear when user asked for day 1 home version.
    return const <WorkoutDay>[];
  }

  int _totalSets(WorkoutProgram program, {String? dayLabel}) {
    return program.allDays.fold<int>(
      0,
      (sum, day) {
        if (!_dayLabelMatches(day.label, dayLabel)) return sum;
        return sum +
            day.exercises.fold<int>(0, (s, ex) => s + ex.sets.length);
      },
    );
  }

  int _exerciseCount(WorkoutProgram program, {String? dayLabel}) {
    return program.allDays.fold<int>(
      0,
      (sum, day) {
        if (!_dayLabelMatches(day.label, dayLabel)) return sum;
        return sum + day.exercises.length;
      },
    );
  }

  bool _dayLabelMatches(String dayLabel, String? filter) {
    final wanted = filter?.trim() ?? '';
    if (wanted.isEmpty) return true;
    final current = dayLabel.trim();
    if (current == wanted) return true;
    if (current.contains(wanted) || wanted.contains(current)) return true;
    final wantedNum = RegExp(r'روز\s*([0-9۰-۹]+)').firstMatch(wanted)?.group(1);
    final currentNum =
        RegExp(r'روز\s*([0-9۰-۹]+)').firstMatch(current)?.group(1);
    return wantedNum != null &&
        currentNum != null &&
        wantedNum == currentNum;
  }

  /// Blocks nonsense swaps like overhead press → squat even in lenient mode.
  bool _isRoleCompatibleReplacement(
    ExerciseProfile original,
    ExerciseProfile candidate,
  ) {
    if (_isHeavyLowerBody(candidate) && !_isHeavyLowerBody(original)) {
      return false;
    }
    if (_isHeavyHinge(candidate) && !_isHeavyHinge(original)) {
      return false;
    }
    if (_nameRoleBucket(original.canonicalName) != null &&
        _nameRoleBucket(candidate.canonicalName) != null &&
        _nameRoleBucket(original.canonicalName) !=
            _nameRoleBucket(candidate.canonicalName)) {
      return false;
    }

    final samePattern =
        candidate.movementPattern == original.movementPattern &&
        original.movementPattern != ExerciseMovementPattern.other;
    if (samePattern) return true;

    if (_sharesPrimaryMuscleFamily(original, candidate)) return true;

    if (original.movementPattern == ExerciseMovementPattern.verticalPush ||
        original.movementPattern == ExerciseMovementPattern.horizontalPush) {
      return candidate.movementPattern == ExerciseMovementPattern.isolation &&
          _sharesPrimaryMuscleFamily(original, candidate);
    }
    return false;
  }

  String? _nameRoleBucket(String name) {
    final text = name.toLowerCase();
    if (text.contains('اسکوات') ||
        text.contains('squat') ||
        text.contains('لانج') ||
        text.contains('lunge') ||
        text.contains('لگ پرس')) {
      return 'legs';
    }
    if (text.contains('ددلیفت') || text.contains('deadlift')) return 'hinge';
    if (text.contains('سرشانه') ||
        text.contains('overhead') ||
        text.contains('نشر') ||
        (text.contains('پرس') && text.contains('شانه'))) {
      return 'shoulders';
    }
    if (text.contains('سینه') ||
        text.contains('bench') ||
        text.contains('فلای') ||
        text.contains('شنا')) {
      return 'chest';
    }
    if (text.contains('زیربغل') ||
        text.contains('بارفیکس') ||
        text.contains('لت ') ||
        text.contains('row')) {
      return 'back';
    }
    if (text.contains('جلو بازو') || text.contains('پشت بازو')) return 'arms';
    if (text.contains('شکم') || text.contains('پلانک')) return 'core';
    return null;
  }

  ExerciseProfile? _pickPreferred({
    required List<ExerciseProfile> candidates,
    required ExerciseProfile original,
    String? preferJoint,
  }) {
    if (candidates.isEmpty) return null;
    final scored = List<ExerciseProfile>.from(candidates)
      ..sort((a, b) {
        final diff = _jointScore(a, preferJoint) - _jointScore(b, preferJoint);
        if (diff != 0) return diff.compareTo(0);
        return a.injuryRisk.compareTo(b.injuryRisk);
      });
    final safer = scored.where((c) {
      if (preferJoint == null || preferJoint.isEmpty) return true;
      return _jointScore(c, preferJoint) < _jointScore(original, preferJoint);
    }).toList();
    return safer.isNotEmpty ? safer.first : scored.first;
  }

  double _jointScore(ExerciseProfile profile, String? joint) {
    return switch (joint) {
      'shoulder' => profile.shoulderLoad,
      'knee' => profile.kneeLoad,
      'back' || 'spine' => profile.spineLoad,
      'wrist' => profile.wristLoad,
      'elbow' => profile.elbowLoad,
      _ => profile.injuryRisk,
    };
  }

  ExerciseProfile? _heuristicSameMuscleReplacement({
    required WorkoutModifyRuleContext ctx,
    required ExerciseProfile original,
    String? preferJoint,
    required List<String> avoidNames,
    bool Function(ExerciseProfile candidate)? equipmentOk,
  }) {
    final avoid = avoidNames.map((n) => n.toLowerCase()).toSet();
    final pool = <ExerciseProfile>[];
    for (final candidate in ctx.catalog) {
      if (candidate.id == original.id) continue;
      final names = candidate.searchableNames.map((n) => n.toLowerCase());
      if (names.any(avoid.contains)) continue;
      if (!_isRoleCompatibleReplacement(original, candidate)) continue;
      if (equipmentOk != null && !equipmentOk(candidate)) continue;
      pool.add(candidate);
    }
    return _pickPreferred(
      candidates: pool,
      original: original,
      preferJoint: preferJoint,
    );
  }

  WorkoutModification _replaceModification({
    required WorkoutModificationType type,
    required WorkoutExercise exercise,
    required String dayLabel,
    required ExerciseProfile replacement,
    required List<ExerciseIntelligenceReason> safetyReasons,
    required List<String> extraBecause,
  }) {
    final because = <String>[
      exercise.name,
      'Replace',
      replacement.canonicalName,
      ...safetyReasons
          .where((reason) => !reason.code.contains('safe'))
          .expand((reason) => reason.because)
          .take(2),
      ...extraBecause,
    ];
    return WorkoutModification(
      type: type,
      status: WorkoutModificationStatus.applied,
      subject: exercise.name,
      dayLabel: dayLabel,
      exerciseId: exercise.id,
      beforeName: exercise.name,
      afterName: replacement.canonicalName,
      beforeCatalogId: exercise.catalogExerciseId,
      afterCatalogId: replacement.id,
      reasons: <WorkoutModificationReason>[
        WorkoutModificationReason(
          code: 'modify.replace',
          subject: replacement.canonicalName,
          because: because,
        ),
      ],
    );
  }

  List<WorkoutModificationReason> _injuryRemoveReasons(
    String name,
    ExerciseSafetyResult safety,
  ) {
    return <WorkoutModificationReason>[
      WorkoutModificationReason(
        code: 'modify.injury_remove',
        subject: name,
        because: <String>[
          name,
          'Remove',
          ...safety.reasons.expand((r) => r.because).take(3),
          'No safe replacement found',
        ],
      ),
    ];
  }

  WorkoutModification _skipped({
    required WorkoutModificationType type,
    required String subject,
    required List<String> because,
    String dayLabel = '',
  }) {
    return WorkoutModification(
      type: type,
      status: WorkoutModificationStatus.skipped,
      subject: subject,
      dayLabel: dayLabel,
      reasons: <WorkoutModificationReason>[
        WorkoutModificationReason(
          code: 'modify.skipped',
          subject: subject,
          because: because,
        ),
      ],
    );
  }

  WorkoutModification _rejected({
    required WorkoutModificationType type,
    required String subject,
    required List<String> because,
    String dayLabel = '',
  }) {
    return WorkoutModification(
      type: type,
      status: WorkoutModificationStatus.rejected,
      subject: subject,
      dayLabel: dayLabel,
      reasons: <WorkoutModificationReason>[
        WorkoutModificationReason(
          code: 'modify.rejected',
          subject: subject,
          because: because,
        ),
      ],
    );
  }

  _LocatedExercise? _findExercise(WorkoutProgram program, String exerciseId) {
    for (final day in program.allDays) {
      for (final exercise in day.exercises) {
        if (exercise.id == exerciseId) {
          return _LocatedExercise(exercise: exercise, dayLabel: day.label);
        }
      }
    }
    return null;
  }

  bool _equipmentMatches(List<String> available, String exerciseEquipment) {
    if (available.isEmpty) return true;
    final token = exerciseEquipment.toLowerCase();
    if (token.contains('بدون')) return true;
    return available.any(
      (item) => token.contains(item.toLowerCase()),
    );
  }

  bool _wouldEmptyDay(WorkoutProgram program, String exerciseId) {
    for (final day in program.allDays) {
      if (day.exercises.any((e) => e.id == exerciseId)) {
        return day.exercises.length <= 1;
      }
    }
    return false;
  }

  String _limitationLabel(List<String> restrictions) {
    if (restrictions.isEmpty) return 'Safety constraint';
    return restrictions.first;
  }
}

class _LocatedExercise {
  const _LocatedExercise({required this.exercise, required this.dayLabel});

  final WorkoutExercise exercise;
  final String dayLabel;
}
