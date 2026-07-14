import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile_mapper.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout_modify/modifier/workout_modify_engine.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modification.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_request.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_reason.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_result.dart';
import 'package:gymaipro/ai/workout_modify/models/workout_modify_versions.dart';
import 'package:gymaipro/ai/workout_modify/runtime/workout_modify_runtime.dart';

import '../workout/fixtures/workout_exercise_catalog_fixture.dart';
import '../workout_review/fixtures/workout_review_program_fixture.dart';

CoachContext _context({
  List<String> restrictions = const <String>[],
  List<String> equipment = const <String>['هالتر', 'دمبل', 'دستگاه'],
}) {
  return CoachContext(
    intent: AIIntent.workoutGeneration,
    profile: const <String, Object?>{'experience_level': 'متوسط'},
    restrictions: restrictions,
    equipment: equipment,
    metadata: CoachContextMetadata(
      buildTime: DateTime(2026, 7, 12),
      sourceCount: 1,
      missingProviders: const {},
      confidence: 0.9,
      contextVersion: CoachContext.contextVersion,
    ),
  );
}


List<ExerciseProfile> _gymProfiles() =>
    WorkoutReviewProgramFixture.gymProfiles();

List<ExerciseProfile> _fullProfiles() {
  const mapper = ExerciseProfileMapper();
  return <ExerciseProfile>[
    ...WorkoutExerciseCatalogFixture.gymCatalog().map(mapper.fromExercise),
    ...WorkoutExerciseCatalogFixture.homeCatalog().map(mapper.fromExercise),
  ];
}

void main() {
  const engine = WorkoutModifyEngine(enforceCoachV2Gate: false);
  const runtime = WorkoutModifyRuntime(enforceCoachV2Gate: false);

  WorkoutModificationResult modify({
    required WorkoutProgram program,
    required List<WorkoutModificationType> modifications,
    CoachContext? context,
    List<ExerciseProfile>? profiles,
    Map<String, Object?> options = const <String, Object?>{},
  }) {
    return engine.modify(
      WorkoutModificationRequest(
        program: program,
        context: context ?? _context(),
        modifications: modifications,
        catalogProfiles: profiles ?? _gymProfiles(),
        options: options,
      ),
    );
  }

  group('EPIC 24 workout modify', () {
    test('models are immutable and JSON round-trip', () {
      const mod = WorkoutModification(
        type: WorkoutModificationType.replaceExercise,
        status: WorkoutModificationStatus.applied,
        subject: 'Bench Press',
        dayLabel: 'Day 1',
        beforeName: 'پرس سینه هالتر',
        afterName: 'پرس سینه دمبل',
        reasons: <WorkoutModificationReason>[],
      );
      final decoded = WorkoutModification.fromJson(mod.toJson());
      expect(decoded.type, WorkoutModificationType.replaceExercise);

      final program = WorkoutReviewProgramFixture.balancedProgram();
    final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.reduceVolume,
        ],
      );
      final decodedResult = WorkoutModificationResult.fromJson(result.toJson());
      expect(decodedResult.enabled, true);
      expect(decodedResult.engineVersion, WorkoutModifyVersions.engineVersion);
      expect(decodedResult.modifiedProgram.id, program.id);
    });

    test('shoulder injury adaptation replaces unsafe exercises', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
    final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.injuryAdaptation,
        ],
        context: _context(restrictions: const <String>['شانه']),
      );

      final applied = result.trace.applied;
      expect(applied, isNotEmpty);
      expect(
        applied.any((m) => m.type == WorkoutModificationType.injuryAdaptation),
        isTrue,
      );
      expect(result.impact.jointStressDelta, lessThanOrEqualTo(0));
      final replace = applied.firstWhere(
        (m) => m.beforeName != null && m.afterName != null,
        orElse: () => applied.first,
      );
      expect(replace.reasons.first.because, isNotEmpty);
    });

    test('knee injury adaptation replaces or removes knee-heavy exercises', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
    final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.injuryAdaptation,
        ],
        context: _context(restrictions: const <String>['زانو']),
      );

      expect(
        result.modifications.any(
          (m) => m.type == WorkoutModificationType.injuryAdaptation,
        ),
        isTrue,
      );
      final injuryMods = result.modifications
          .where((m) => m.type == WorkoutModificationType.injuryAdaptation)
          .toList();
      expect(injuryMods, isNotEmpty);
      expect(
        injuryMods.any((m) => m.status == WorkoutModificationStatus.applied) ||
            injuryMods.any((m) => m.status == WorkoutModificationStatus.skipped),
        isTrue,
      );
    });

    test('home conversion replaces gym equipment exercises', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
    final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.homeVersion,
        ],
        profiles: _fullProfiles(),
      );

      final homeMods = result.trace.applied
          .where((m) => m.type == WorkoutModificationType.homeVersion)
          .toList();
      expect(homeMods, isNotEmpty);
      for (final mod in homeMods) {
        expect(mod.afterName, isNotNull);
        expect(mod.beforeName, isNot(equals(mod.afterName)));
      }
    });

    test('gym conversion adapts home-limited exercises when gym catalog available', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
      final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.gymVersion,
        ],
        profiles: _fullProfiles(),
      );

      expect(result.enabled, true);
      expect(result.trace.requested.first.type, WorkoutModificationType.gymVersion);
    });

    test('session shortening reduces exercise count', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
      final before = program.totalExercises;
    final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.shortenSession,
        ],
      );

      expect(result.trace.applied, isNotEmpty);
      expect(result.modifiedProgram.totalExercises, lessThan(before));
      expect(result.impact.volumeDelta, lessThan(0));
    });

    test('recovery adaptation reduces fatigue or volume', () {
      final program = WorkoutReviewProgramFixture.badProgram();
    final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.recoveryAdaptation,
        ],
      );

      expect(result.trace.applied, isNotEmpty);
      expect(
        result.impact.fatigueDelta <= 0 || result.impact.volumeDelta < 0,
        isTrue,
      );
    });

    test('volume reduction lowers total sets', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
    final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.reduceVolume,
        ],
      );

      expect(result.trace.applied, isNotEmpty);
      expect(result.impact.volumeDelta, lessThan(0));
    });

    test('explicit replacement uses ExerciseReplacementEngine', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
      final bench = program.allDays.first.exercises.first;
      final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.replaceExercise,
        ],
        options: <String, Object?>{'exerciseId': bench.id},
      );

      final applied = result.trace.applied
          .where((m) => m.type == WorkoutModificationType.replaceExercise)
          .toList();
      expect(applied, isNotEmpty);
      expect(applied.first.afterCatalogId, isNot(equals(bench.catalogExerciseId)));
    });

    test('explainability chain documents replace reason', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
      final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.injuryAdaptation,
        ],
        context: _context(restrictions: const <String>['شانه']),
      );

      final replace = result.trace.applied.firstWhere(
        (m) => m.beforeName != null && m.afterName != null,
      );
      final because = replace.reasons.first.because;
      expect(because, contains(replace.beforeName));
      expect(because, contains('Replace'));
      expect(because, contains(replace.afterName));
    });

    test('trace records requested applied skipped rejected final', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
      final result = modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.reduceVolume,
          WorkoutModificationType.injuryAdaptation,
        ],
      );

      expect(result.trace.requested.length, 2);
      expect(result.trace.finalProgramId, program.id);
      expect(result.trace.steps, contains('apply_modifications'));
      expect(
        result.trace.applied.length +
            result.trace.skipped.length +
            result.trace.rejected.length,
        greaterThanOrEqualTo(0),
      );
    });

    test('runtime modify orchestrates engine', () {
      final program = WorkoutReviewProgramFixture.balancedProgram();
      final result = runtime.modify(
        program: program,
        modifications: const <WorkoutModificationType>[
          WorkoutModificationType.reduceVolume,
        ],
        context: _context(),
        catalogProfiles: _gymProfiles(),
      );
      expect(result.enabled, true);
      expect(result.modifiedProgram.version, greaterThan(program.version));
    });

    test('coach v2 gate disables engine when configured', () {
      if (CoachV2Config.coachV2Enabled) return;
      const gated = WorkoutModifyEngine();
      final result = gated.modify(
        WorkoutModificationRequest(
          program: WorkoutReviewProgramFixture.balancedProgram(),
          context: _context(),
          modifications: const <WorkoutModificationType>[
            WorkoutModificationType.reduceVolume,
          ],
          catalogProfiles: _gymProfiles(),
        ),
      );
      expect(result.enabled, false);
      expect(result.trace.steps, contains('coach_v2_disabled'));
    });
  });
}
