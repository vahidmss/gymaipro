import 'package:gymaipro/ai/exercise/intelligence/exercise_intelligence_evaluation.dart';
import 'package:gymaipro/ai/exercise/models/exercise_intelligence_query.dart';
import 'package:gymaipro/ai/exercise/models/exercise_profile.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_catalog_adapter.dart';
import 'package:gymaipro/ai/exercise/runtime/exercise_intelligence_runtime.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/exercise_selector/exercise_intelligence_reason_mapper.dart';
import 'package:gymaipro/ai/workout/exercise_selector/workout_exercise_intelligence_query_builder.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_selection_trace.dart';
import 'package:gymaipro/ai/workout/planner/workout_split_planner.dart';
import 'package:gymaipro/models/exercise.dart';

/// Selected exercise with intelligence evaluation metadata.
class WorkoutExerciseSelection {
  const WorkoutExerciseSelection({
    required this.evaluation,
    required this.exercise,
    required this.reasons,
    this.replacedFromName,
  });

  final ExerciseIntelligenceEvaluation evaluation;
  final Exercise exercise;
  final List<WorkoutGeneratorReason> reasons;
  final String? replacedFromName;

  double get score => evaluation.scoring.score;
}

/// Day-level selection output with trace.
class WorkoutDaySelectionResult {
  const WorkoutDaySelectionResult({
    required this.selected,
    required this.trace,
  });

  final List<WorkoutExerciseSelection> selected;
  final WorkoutGeneratorSelectionTrace trace;
}

/// Exercise selection orchestrator backed by exercise intelligence runtime.
class WorkoutExerciseSelector {
  const WorkoutExerciseSelector({
    ExerciseIntelligenceRuntime? intelligenceRuntime,
    WorkoutExerciseIntelligenceQueryBuilder? queryBuilder,
    ExerciseIntelligenceReasonMapper? reasonMapper,
  }) : _intelligenceRuntime = intelligenceRuntime ??
           const ExerciseIntelligenceRuntime(enforceCoachV2Gate: false),
       _queryBuilder = queryBuilder ??
           const WorkoutExerciseIntelligenceQueryBuilder(),
       _reasonMapper = reasonMapper ?? const ExerciseIntelligenceReasonMapper();

  final ExerciseIntelligenceRuntime _intelligenceRuntime;
  final WorkoutExerciseIntelligenceQueryBuilder _queryBuilder;
  final ExerciseIntelligenceReasonMapper _reasonMapper;

  WorkoutDaySelectionResult selectForDay({
    required WorkoutDayPlan dayPlan,
    required WorkoutBlueprint blueprint,
    required ExerciseCatalogAdapter catalog,
    required Set<int> usedInProgram,
  }) {
    final entries = catalog.loadEntries();
    final profiles = catalog.loadProfiles();
    var trace = WorkoutGeneratorSelectionTrace.empty().copyWith(
      catalogCount: entries.length,
      steps: <String>['Catalog Count=${entries.length}'],
    );

    final candidates = <WorkoutExerciseSelection>[];
    var filteredCount = 0;
    var rejectedCount = 0;
    var replacedCount = 0;

    final baseQuery = _queryBuilder.build(
      blueprint: blueprint,
      dayPlan: dayPlan,
    );

    for (final entry in entries) {
      if (usedInProgram.contains(entry.profile.id)) continue;

      final bucket = WorkoutScience.muscleBucket(entry.exercise.mainMuscle);
      if (!dayPlan.targetBuckets.contains(bucket) &&
          bucket != MuscleBucket.other) {
        continue;
      }

      filteredCount++;
      final selection = _evaluateWithReplacement(
        entry: entry,
        catalog: catalog,
        profiles: profiles,
        query: baseQuery,
        usedInProgram: usedInProgram,
      );

      if (selection == null) {
        rejectedCount++;
        continue;
      }

      if (selection.replacedFromName != null) {
        replacedCount++;
      }

      candidates.add(selection);
    }

    final uniqueCandidates = <int, WorkoutExerciseSelection>{};
    for (final candidate in candidates) {
      uniqueCandidates[candidate.exercise.id] = candidate;
    }
    final dedupedCandidates = uniqueCandidates.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final selected = _pickWithBucketBalance(
      candidates: dedupedCandidates,
      dayPlan: dayPlan,
    );

    if (selected.length < 2 && dedupedCandidates.isNotEmpty) {
      for (final candidate in dedupedCandidates) {
        if (selected.any(
          (item) => item.exercise.id == candidate.exercise.id,
        )) {
          continue;
        }
        selected.add(candidate);
        if (selected.length >= 2) break;
      }
    }

    trace = trace.copyWith(
      filteredCount: filteredCount,
      rejectedCount: rejectedCount,
      replacedCount: replacedCount,
      selectedCount: dedupedCandidates.length,
      finalCount: selected.length,
      steps: <String>[
        ...trace.steps,
        'Filtered=$filteredCount',
        'Rejected=$rejectedCount',
        'Replaced=$replacedCount',
        'Selected=${dedupedCandidates.length}',
        'Final=${selected.length}',
      ],
    );

    return WorkoutDaySelectionResult(selected: selected, trace: trace);
  }

  WorkoutExerciseSelection? _evaluateWithReplacement({
    required ExerciseCatalogEntry entry,
    required ExerciseCatalogAdapter catalog,
    required List<ExerciseProfile> profiles,
    required ExerciseIntelligenceQuery query,
    required Set<int> usedInProgram,
  }) {
    final evaluation = _intelligenceRuntime.evaluate(
      exercise: entry.profile,
      query: query,
    );

    if (evaluation.recommended) {
      return WorkoutExerciseSelection(
        evaluation: evaluation,
        exercise: entry.exercise,
        reasons: _reasonMapper.toGeneratorReasons(evaluation.reasons),
      );
    }

    final replacement = _intelligenceRuntime.findReplacement(
      original: entry.profile,
      catalog: profiles,
      query: query,
    );

    if (replacement.candidates.isEmpty) {
      return null;
    }

    for (final candidate in replacement.candidates) {
      final replacementEntry = catalog.findById(candidate.exercise.id);
      if (replacementEntry == null ||
          usedInProgram.contains(replacementEntry.profile.id)) {
        continue;
      }

      final replacementEvaluation = _intelligenceRuntime.evaluate(
        exercise: candidate.exercise,
        query: query,
      );
      if (!replacementEvaluation.recommended) continue;

      final reasons = <WorkoutGeneratorReason>[
        ..._reasonMapper.toGeneratorReasons(replacementEvaluation.reasons),
        ..._reasonMapper.toGeneratorReasons(candidate.reasons),
        _reasonMapper.replacementReason(
          selectedName: candidate.exercise.canonicalName,
          replacedName: entry.profile.canonicalName,
        ),
      ];

      return WorkoutExerciseSelection(
        evaluation: replacementEvaluation,
        exercise: replacementEntry.exercise,
        reasons: reasons,
        replacedFromName: entry.profile.canonicalName,
      );
    }

    return null;
  }

  List<WorkoutExerciseSelection> _pickWithBucketBalance({
    required List<WorkoutExerciseSelection> candidates,
    required WorkoutDayPlan dayPlan,
  }) {
    final selected = <WorkoutExerciseSelection>[];
    final bucketsFilled = <MuscleBucket>{};

    for (final candidate in candidates) {
      if (selected.length >= dayPlan.exerciseCount) break;
      final bucket = WorkoutScience.muscleBucket(candidate.exercise.mainMuscle);
      if (bucketsFilled.contains(bucket) &&
          !candidate.evaluation.exercise.compound &&
          selected.length >= dayPlan.exerciseCount - 1) {
        continue;
      }
      selected.add(candidate);
      bucketsFilled.add(bucket);
    }

    return selected;
  }
}
