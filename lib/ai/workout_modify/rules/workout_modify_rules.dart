import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_reason.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/replacement/exercise_replacement_engine.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_engine.dart';
import 'package:gymaipro/ai/exercise/safety/exercise_safety_result.dart';
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
    final exerciseId = ctx.options['exerciseId'] as String?;
    if (exerciseId == null) {
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
    final exerciseId = ctx.options['exerciseId'] as String?;
    if (exerciseId == null) {
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
    final beforeSets = _totalSets(ctx.program);
    ctx.program = ctx.mutator.adjustVolume(
      program: ctx.program,
      deltaSets: delta,
    );
    final afterSets = _totalSets(ctx.program);
    if (beforeSets == afterSets) {
      ctx.modifications.add(_skipped(
        type: delta < 0
            ? WorkoutModificationType.reduceVolume
            : WorkoutModificationType.increaseVolume,
        subject: 'Volume',
        because: <String>['No sets adjusted'],
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
        dayLabel: 'all',
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
    ctx.program = ctx.mutator.adjustIntensity(
      program: ctx.program,
      repDelta: repDelta,
    );
    ctx.modifications.add(
      WorkoutModification(
        type: repDelta > 0
            ? WorkoutModificationType.reduceIntensity
            : WorkoutModificationType.increaseIntensity,
        status: WorkoutModificationStatus.applied,
        subject: 'Intensity',
        dayLabel: 'all',
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
    final beforeCount = ctx.program.totalExercises;
    ctx.program = ctx.mutator.shortenSessions(program: ctx.program);
    final afterCount = ctx.program.totalExercises;
    if (beforeCount == afterCount) {
      ctx.modifications.add(_skipped(
        type: WorkoutModificationType.shortenSession,
        subject: 'Session',
        because: <String>['Sessions already minimal'],
      ));
      return;
    }
    ctx.modifications.add(
      WorkoutModification(
        type: WorkoutModificationType.shortenSession,
        status: WorkoutModificationStatus.applied,
        subject: 'Session length',
        dayLabel: 'all',
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
    final allowed = home
        ? <String>['دمبل', 'بدون تجهیزات']
        : <String>['هالتر', 'دمبل', 'دستگاه'];
    final adaptedQuery = ExerciseIntelligenceQuery(
      goal: ctx.query.goal,
      experience: ctx.query.experience,
      availableEquipment: allowed,
      limitations: ctx.query.limitations,
      recoveryScore: ctx.query.recoveryScore,
    );

    for (final day in ctx.program.allDays) {
      for (final exercise in day.exercises) {
        final profile = ctx.profileById[exercise.catalogExerciseId];
        if (profile == null) continue;
        if (_equipmentMatches(allowed, exercise.equipment)) continue;

        final replacement = _findReplacement(
          ctx: ctx,
          original: profile,
          query: adaptedQuery,
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
                  because: <String>['No replacement for equipment version'],
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
        );
        if (replacement != null) {
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

    for (final day in ctx.program.allDays) {
      for (final exercise in day.exercises) {
        if (_equipmentMatches(ctx.context.equipment, exercise.equipment)) {
          continue;
        }
        final profile = ctx.profileById[exercise.catalogExerciseId];
        if (profile == null) continue;

        final replacement = _findReplacement(
          ctx: ctx,
          original: profile,
          query: ctx.query,
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
    final highFatigue = <WorkoutExercise>[];
    for (final day in ctx.program.allDays) {
      for (final exercise in day.exercises) {
        final profile = ctx.profileById[exercise.catalogExerciseId];
        if (profile != null && profile.fatigueScore >= 0.65) {
          highFatigue.add(exercise);
        }
      }
    }

    if (highFatigue.isEmpty) {
      ctx.program = ctx.mutator.adjustVolume(program: ctx.program, deltaSets: -1);
      ctx.modifications.add(
        const WorkoutModification(
          type: WorkoutModificationType.recoveryAdaptation,
          status: WorkoutModificationStatus.applied,
          subject: 'Global volume',
          dayLabel: 'all',
          reasons: <WorkoutModificationReason>[
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
      return;
    }

    for (final exercise in highFatigue) {
      final profile = ctx.profileById[exercise.catalogExerciseId]!;
      final replacement = _findReplacement(
        ctx: ctx,
        original: profile,
        query: ctx.query.copyWith(maxFatigueBudget: 0.5),
      );
      if (replacement != null && replacement.fatigueScore < profile.fatigueScore) {
        final dayLabel = _dayLabelFor(ctx.program, exercise.id);
        ctx.program = ctx.mutator.replaceExercise(
          program: ctx.program,
          exerciseId: exercise.id,
          replacement: replacement,
        );
        ctx.modifications.add(
          _replaceModification(
            type: WorkoutModificationType.recoveryAdaptation,
            exercise: exercise,
            dayLabel: dayLabel,
            replacement: replacement,
            safetyReasons: const <ExerciseIntelligenceReason>[],
            extraBecause: <String>[
              'High fatigue exercise',
              'Recovery adaptation',
              'Fatigue reduced',
            ],
          ),
        );
      }
    }

    if (!ctx.modifications.any(
      (m) => m.type == WorkoutModificationType.recoveryAdaptation,
    )) {
      ctx.program = ctx.mutator.adjustVolume(program: ctx.program, deltaSets: -1);
      ctx.modifications.add(
        const WorkoutModification(
          type: WorkoutModificationType.recoveryAdaptation,
          status: WorkoutModificationStatus.applied,
          subject: 'Volume trim',
          dayLabel: 'all',
          reasons: <WorkoutModificationReason>[
            WorkoutModificationReason(
              code: 'modify.recovery_trim',
              subject: 'Recovery',
              because: <String>['No lower-fatigue replacement; volume trimmed'],
            ),
          ],
        ),
      );
    }
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

  ExerciseProfile? _findReplacement({
    required WorkoutModifyRuleContext ctx,
    required ExerciseProfile original,
    required ExerciseIntelligenceQuery query,
  }) {
    final result = ctx.replacementEngine.findReplacements(
      original: original,
      catalog: ctx.catalog,
      query: query,
      limit: 1,
    );
    if (result.candidates.isEmpty) return null;
    return result.candidates.first.exercise;
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

  String _dayLabelFor(WorkoutProgram program, String exerciseId) {
    return _findExercise(program, exerciseId)?.dayLabel ?? '';
  }

  int _totalSets(WorkoutProgram program) {
    return program.allDays.fold<int>(
      0,
      (sum, day) =>
          sum +
          day.exercises.fold<int>(0, (s, ex) => s + ex.sets.length),
    );
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
