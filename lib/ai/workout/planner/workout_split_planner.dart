import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_blueprint.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_recovery_strategy.dart';
import 'package:gymaipro/ai/workout/blueprint/workout_split_strategy.dart';
import 'package:gymaipro/ai/workout/labels/workout_session_labels.dart';
import 'package:gymaipro/ai/workout/models/workout_generator_reason.dart';

/// Planned split for one training day.
class WorkoutDayPlan {
  const WorkoutDayPlan({
    required this.dayIndex,
    required this.label,
    required this.targetBuckets,
    required this.exerciseCount,
    required this.reasons,
  });

  final int dayIndex;
  final String label;
  final Set<MuscleBucket> targetBuckets;
  final int exerciseCount;
  final List<WorkoutGeneratorReason> reasons;
}

/// Maps a [WorkoutBlueprint] to executable day plans.
///
/// Execution-only: no planning decisions beyond blueprint interpretation.
class WorkoutSplitPlanner {
  const WorkoutSplitPlanner();

  List<WorkoutDayPlan> planFromBlueprint(WorkoutBlueprint blueprint) {
    final days = blueprint.daysPerWeek;
    final buckets = _bucketsForStrategy(
      blueprint.splitStrategy,
      days,
    );
    final labels = _labelsForStrategy(blueprint.splitStrategy, days);
    final recoveryAdjusted = _applyRecoveryStrategy(
      buckets,
      blueprint.recoveryStrategy,
    );
    final perSession = blueprint.exercisesPerSession;
    final priorityBuckets = WorkoutScience.priorityBucketsFromText(
      blueprint.preferredMuscles.join(' '),
    );

    return List<WorkoutDayPlan>.generate(days, (index) {
      // Start from the day's planned focus only — do NOT merge priority
      // muscles into every day (that turns PPL into a mashup).
      var target = Set<MuscleBucket>.from(recoveryAdjusted[index]);
      if (priorityBuckets.isNotEmpty) {
        final overlap = priorityBuckets.intersection(target);
        if (overlap.isNotEmpty) {
          // Keep day focus; priority only boosts slots already on-plan.
          target = <MuscleBucket>{...target};
        }
      }
      final exerciseCount = perSession;
      return WorkoutDayPlan(
        dayIndex: index,
        label: labels[index],
        targetBuckets: target,
        exerciseCount: exerciseCount,
        reasons: <WorkoutGeneratorReason>[
          WorkoutGeneratorReason(
            code: 'day.focus',
            subject: labels[index],
            because: <String>[
              'Muscles=${target.map((b) => b.name).join(',')}',
              'ExerciseSlots=$exerciseCount',
              'Split=${blueprint.splitStrategy.name}',
            ],
          ),
        ],
      );
    });
  }

  List<String> _labelsForStrategy(WorkoutSplitStrategy strategy, int days) {
    return WorkoutSessionLabels.forStrategy(strategy, days);
  }

  List<Set<MuscleBucket>> _bucketsForStrategy(
    WorkoutSplitStrategy strategy,
    int days,
  ) {
    switch (strategy) {
      case WorkoutSplitStrategy.fullBody:
        return _repeatFullBody(days);
      case WorkoutSplitStrategy.upperLower:
        return _upperLowerLayout(days);
      case WorkoutSplitStrategy.pushPullLegs:
        return _pushPullLegsLayout(days);
      case WorkoutSplitStrategy.broSplit:
        return WorkoutScience.bucketsPerDay(days);
      case WorkoutSplitStrategy.phul:
      case WorkoutSplitStrategy.phat:
      case WorkoutSplitStrategy.custom:
        return WorkoutScience.bucketsPerDay(days);
    }
  }

  List<Set<MuscleBucket>> _repeatFullBody(int days) {
    const fullBody = <MuscleBucket>{
      MuscleBucket.chest,
      MuscleBucket.back,
      MuscleBucket.quads,
      MuscleBucket.shoulders,
      MuscleBucket.core,
    };
    return List<Set<MuscleBucket>>.generate(days, (_) => fullBody);
  }

  List<Set<MuscleBucket>> _upperLowerLayout(int days) {
    const upper = <MuscleBucket>{
      MuscleBucket.chest,
      MuscleBucket.back,
      MuscleBucket.shoulders,
      MuscleBucket.biceps,
      MuscleBucket.triceps,
    };
    const lower = <MuscleBucket>{
      MuscleBucket.quads,
      MuscleBucket.hamstrings,
      MuscleBucket.glutes,
      MuscleBucket.calves,
      MuscleBucket.core,
    };
    return List<Set<MuscleBucket>>.generate(
      days,
      (index) => index.isEven ? upper : lower,
    );
  }

  List<Set<MuscleBucket>> _pushPullLegsLayout(int days) {
    const push = <MuscleBucket>{
      MuscleBucket.chest,
      MuscleBucket.shoulders,
      MuscleBucket.triceps,
    };
    const pull = <MuscleBucket>{
      MuscleBucket.back,
      MuscleBucket.biceps,
      MuscleBucket.core,
    };
    const legs = <MuscleBucket>{
      MuscleBucket.quads,
      MuscleBucket.hamstrings,
      MuscleBucket.glutes,
      MuscleBucket.calves,
    };
    const cycle = <Set<MuscleBucket>>[push, pull, legs];
    return List<Set<MuscleBucket>>.generate(
      days,
      (index) => cycle[index % cycle.length],
    );
  }

  List<Set<MuscleBucket>> _applyRecoveryStrategy(
    List<Set<MuscleBucket>> buckets,
    WorkoutRecoveryStrategy recoveryStrategy,
  ) {
    // Never strip a day's primary focus. Conservative recovery is handled by
    // lower fatigue budgets / volume — not by deleting legs from leg day.
    if (recoveryStrategy != WorkoutRecoveryStrategy.conservative) {
      return buckets;
    }
    return buckets.map((day) {
      final isLegDay =
          day.contains(MuscleBucket.quads) ||
          day.contains(MuscleBucket.hamstrings) ||
          day.contains(MuscleBucket.glutes);
      if (isLegDay) return day;
      // On non-leg days, drop leftover leg accessories only.
      return day
          .where(
            (bucket) =>
                bucket != MuscleBucket.quads &&
                bucket != MuscleBucket.hamstrings,
          )
          .toSet();
    }).toList();
  }
}
