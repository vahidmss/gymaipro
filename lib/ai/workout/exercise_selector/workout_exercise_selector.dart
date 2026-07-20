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
    final allowedBuckets = Set<MuscleBucket>.from(dayPlan.targetBuckets);

    for (final entry in entries) {
      if (usedInProgram.contains(entry.profile.id)) continue;

      final bucket = WorkoutScience.muscleBucket(entry.exercise.mainMuscle);
      if (!_isAllowedForDay(bucket, allowedBuckets)) continue;

      filteredCount++;
      final selection = _evaluateStrict(
        entry: entry,
        catalog: catalog,
        profiles: profiles,
        query: baseQuery,
        usedInProgram: usedInProgram,
        allowedBuckets: allowedBuckets,
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
      final bucket = WorkoutScience.muscleBucket(candidate.exercise.mainMuscle);
      // Drop any leaked off-day muscles (e.g. bad replacement).
      if (!_isAllowedForDay(bucket, allowedBuckets)) continue;
      uniqueCandidates[candidate.exercise.id] = candidate;
    }

    final dedupedCandidates = uniqueCandidates.values.toList()
      ..sort(_compareCandidates);

    final selected = _pickForDay(
      candidates: dedupedCandidates,
      dayPlan: dayPlan,
      allowedBuckets: allowedBuckets,
    );

    trace = trace.copyWith(
      filteredCount: filteredCount,
      rejectedCount: rejectedCount,
      replacedCount: replacedCount,
      selectedCount: dedupedCandidates.length,
      finalCount: selected.length,
      steps: <String>[
        ...trace.steps,
        'AllowedBuckets=${allowedBuckets.map((b) => b.name).join(',')}',
        'Filtered=$filteredCount',
        'Rejected=$rejectedCount',
        'Replaced=$replacedCount',
        'Selected=${dedupedCandidates.length}',
        'Final=${selected.length}',
      ],
    );

    return WorkoutDaySelectionResult(selected: selected, trace: trace);
  }

  bool _isAllowedForDay(MuscleBucket bucket, Set<MuscleBucket> allowed) {
    if (allowed.contains(bucket)) return true;
    // Never let misc/cardio/full-body leak into a focused day.
    return false;
  }

  WorkoutExerciseSelection? _evaluateStrict({
    required ExerciseCatalogEntry entry,
    required ExerciseCatalogAdapter catalog,
    required List<ExerciseProfile> profiles,
    required ExerciseIntelligenceQuery query,
    required Set<int> usedInProgram,
    required Set<MuscleBucket> allowedBuckets,
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

    // Only replace with exercises that still fit THIS day's muscle focus.
    final dayProfiles = profiles.where((profile) {
      final entryForProfile = catalog.findById(profile.id);
      if (entryForProfile == null) return false;
      final bucket = WorkoutScience.muscleBucket(
        entryForProfile.exercise.mainMuscle,
      );
      return _isAllowedForDay(bucket, allowedBuckets);
    }).toList(growable: false);

    final replacement = _intelligenceRuntime.findReplacement(
      original: entry.profile,
      catalog: dayProfiles,
      query: query,
    );

    if (replacement.candidates.isEmpty) return null;

    for (final candidate in replacement.candidates) {
      final replacementEntry = catalog.findById(candidate.exercise.id);
      if (replacementEntry == null ||
          usedInProgram.contains(replacementEntry.profile.id)) {
        continue;
      }

      final bucket = WorkoutScience.muscleBucket(
        replacementEntry.exercise.mainMuscle,
      );
      if (!_isAllowedForDay(bucket, allowedBuckets)) continue;

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

  int _compareCandidates(
    WorkoutExerciseSelection a,
    WorkoutExerciseSelection b,
  ) {
    final aCompound = a.evaluation.exercise.compound ? 1 : 0;
    final bCompound = b.evaluation.exercise.compound ? 1 : 0;
    if (aCompound != bCompound) return bCompound.compareTo(aCompound);
    return b.score.compareTo(a.score);
  }

  /// Round-robin across the day's target buckets, compounds first.
  List<WorkoutExerciseSelection> _pickForDay({
    required List<WorkoutExerciseSelection> candidates,
    required WorkoutDayPlan dayPlan,
    required Set<MuscleBucket> allowedBuckets,
  }) {
    final selected = <WorkoutExerciseSelection>[];
    final usedIds = <int>{};
    final perBucketCount = <MuscleBucket, int>{
      for (final bucket in allowedBuckets) bucket: 0,
    };

    final byBucket = <MuscleBucket, List<WorkoutExerciseSelection>>{};
    for (final candidate in candidates) {
      final bucket = WorkoutScience.muscleBucket(candidate.exercise.mainMuscle);
      if (!_isAllowedForDay(bucket, allowedBuckets)) continue;
      byBucket.putIfAbsent(bucket, () => <WorkoutExerciseSelection>[]).add(
        candidate,
      );
    }

    final orderedBuckets = allowedBuckets.toList(growable: false);
    // Prefer large movers first (chest/back/quads before arms/core/calves).
    orderedBuckets.sort((a, b) {
      return _bucketPriority(a).compareTo(_bucketPriority(b));
    });

    while (selected.length < dayPlan.exerciseCount) {
      var addedThisRound = false;
      for (final bucket in orderedBuckets) {
        if (selected.length >= dayPlan.exerciseCount) break;
        final pool = byBucket[bucket];
        if (pool == null || pool.isEmpty) continue;

        // Soft cap: accessories (core/calves/arms) max 1–2 depending on day size.
        final maxForBucket = _maxPerBucket(
          bucket,
          dayPlan.exerciseCount,
          orderedBuckets.length,
        );
        if ((perBucketCount[bucket] ?? 0) >= maxForBucket) continue;

        final nextIndex = pool.indexWhere(
          (item) => !usedIds.contains(item.exercise.id),
        );
        if (nextIndex < 0) continue;

        final pick = pool.removeAt(nextIndex);
        selected.add(pick);
        usedIds.add(pick.exercise.id);
        perBucketCount[bucket] = (perBucketCount[bucket] ?? 0) + 1;
        addedThisRound = true;
      }
      if (!addedThisRound) break;
    }

    return selected;
  }

  int _bucketPriority(MuscleBucket bucket) {
    return switch (bucket) {
      MuscleBucket.chest ||
      MuscleBucket.back ||
      MuscleBucket.quads ||
      MuscleBucket.hamstrings ||
      MuscleBucket.glutes ||
      MuscleBucket.shoulders => 0,
      MuscleBucket.biceps || MuscleBucket.triceps => 1,
      MuscleBucket.core || MuscleBucket.calves => 2,
      MuscleBucket.fullBody || MuscleBucket.cardio || MuscleBucket.other => 3,
    };
  }

  int _maxPerBucket(MuscleBucket bucket, int daySize, int bucketCount) {
    final isAccessory =
        bucket == MuscleBucket.core ||
        bucket == MuscleBucket.calves ||
        bucket == MuscleBucket.biceps ||
        bucket == MuscleBucket.triceps;
    if (isAccessory) {
      return daySize <= 4 ? 1 : 2;
    }
    // Primary movers can take more slots.
    return (daySize / bucketCount).ceil().clamp(1, daySize);
  }
}
