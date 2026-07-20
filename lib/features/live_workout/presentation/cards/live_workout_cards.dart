import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_badge.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_progress_bar.dart';
import 'package:gymaipro/design_system/components/gym_progress_ring.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/presentation/live_workout_theme.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_completion_summary.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:gymaipro/workout_log/widgets/workout_log_colors.dart';
import 'package:gymaipro/workout_log/widgets/workout_set_entry_row.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart'
    show ExerciseStyle;

class LiveWorkoutHeroCard extends StatelessWidget {
  const LiveWorkoutHeroCard({required this.session, super.key});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.todayProgram, style: context.lwCaption),
          GymSpacing.gapSm,
          Text(session.focus, style: context.lwTitle),
          GymSpacing.gapLg,
          Wrap(
            spacing: GymSpacing.sm,
            runSpacing: GymSpacing.sm,
            children: <Widget>[
              GymBadge(
                label: '${session.estimatedMinutes} ${ProductCopy.minutes}',
                variant: GymBadgeVariant.neutral,
                icon: GymIcons.clock,
              ),
              GymBadge(
                label: '${session.totalExercises} ${ProductCopy.exercisesCount}',
                variant: GymBadgeVariant.neutral,
                icon: GymIcons.workout,
              ),
              GymBadge(
                label: '${session.totalSets} ست',
                variant: GymBadgeVariant.neutral,
                icon: GymIcons.activity,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LiveWorkoutProgressCard extends StatelessWidget {
  const LiveWorkoutProgressCard({required this.state, super.key});

  final LiveWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.totalSets == 0
        ? 0.0
        : state.completedSets / state.totalSets;
    final exerciseNumber = (state.currentExerciseIndex ?? 0) + 1;
    return Row(
      children: <Widget>[
        GymProgressRing(
          value: progress.clamp(0, 1),
          label: '${(progress * 100).round()}٪',
          size: 84,
          color: context.gymPrimary,
        ),
        GymSpacing.gapLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(ProductCopy.progress, style: context.lwSection),
              GymSpacing.gapSm,
              Text(
                '$exerciseNumber از ${state.totalExercises} حرکت',
                style: context.lwBodyStrong,
              ),
              GymSpacing.gapSm,
              Text(
                '${state.completedSets} از ${state.totalSets} ست',
                style: context.lwCaption,
              ),
              GymSpacing.gapMd,
              GymProgressBar(
                value: progress.clamp(0, 1),
                animated: true,
                color: context.gymPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SessionExerciseListCard extends StatelessWidget {
  const SessionExerciseListCard({required this.state, super.key});

  final LiveWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    if (session == null || session.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentIndex = state.currentExerciseIndex ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const LiveWorkoutSectionHeader(title: 'برنامه حرکات'),
        GymCard(
          variant: GymCardVariant.insight,
          padding: const EdgeInsets.symmetric(
            horizontal: GymSpacing.lg,
            vertical: GymSpacing.md,
          ),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < session.exercises.length; i++) ...<Widget>[
                _ExerciseListRow(
                  index: i,
                  exercise: session.exercises[i],
                  isCurrent: i == currentIndex,
                  isDone: i < currentIndex,
                ),
                if (i < session.exercises.length - 1)
                  Divider(height: GymSpacing.lg, color: context.gymBorderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseListRow extends StatelessWidget {
  const _ExerciseListRow({
    required this.index,
    required this.exercise,
    required this.isCurrent,
    required this.isDone,
  });

  final int index;
  final WorkoutExerciseSession exercise;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(exercise, index);
    return Row(
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrent
                ? context.gymPrimary.withValues(alpha: 0.16)
                : context.gymElevated.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: context.gymTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isCurrent ? context.gymPrimary : context.gymTextSecondary,
            ),
          ),
        ),
        GymSpacing.gapMd,
        Expanded(
          child: Text(
            displayName,
            style: isCurrent ? context.lwBodyStrong : context.lwBody,
          ),
        ),
        if (isDone)
          Icon(Icons.check_circle_rounded, color: context.gymPrimary, size: 20),
        if (isCurrent)
          Text(
            'فعلی',
            style: context.gymTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.gymPrimary,
            ),
          ),
      ],
    );
  }
}

class CurrentExerciseCard extends StatelessWidget {
  const CurrentExerciseCard({
    required this.exercise,
    required this.currentSet,
    required this.exerciseIndex,
    super.key,
  });

  final WorkoutExerciseSession exercise;
  final WorkoutSetSession? currentSet;
  final int exerciseIndex;

  @override
  Widget build(BuildContext context) {
    final set = currentSet ?? exercise.sets.firstOrNull;
    final displayName = _displayName(exercise, exerciseIndex);
    final muscle = ProductExperienceFormatter.displayMuscle(exercise.primaryMuscle);
    return GymCard(
      variant: GymCardVariant.action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.currentExercise, style: context.lwCaption),
          GymSpacing.gapMd,
          Text(displayName, style: context.lwExerciseName),
          if (muscle.isNotEmpty) ...<Widget>[
            GymSpacing.gapSm,
            Text(muscle, style: context.lwCaption),
          ],
          GymSpacing.gapMd,
          Text(
            '${exercise.sets.length} ست  •  ست ${set?.index ?? 1}',
            style: context.lwBody,
          ),
          if (set != null) ...<Widget>[
            GymSpacing.gapMd,
            Text(
              'هدف: ${set.targetReps} تکرار  •  ${_formatWeight(set.targetWeightKg)} کیلو',
              style: context.lwBodyStrong,
            ),
          ],
        ],
      ),
    );
  }
}

class UpcomingExerciseCard extends StatelessWidget {
  const UpcomingExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    super.key,
  });

  final WorkoutExerciseSession exercise;
  final int exerciseIndex;

  @override
  Widget build(BuildContext context) {
    final muscle = ProductExperienceFormatter.displayMuscle(exercise.primaryMuscle);
    return GymCard(
      variant: GymCardVariant.insight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.upcomingExercise, style: context.lwCaption),
          GymSpacing.gapSm,
          Text(
            _displayName(exercise, exerciseIndex),
            style: context.lwBodyStrong,
          ),
          GymSpacing.gapSm,
          Text(
            '${exercise.sets.length} ست${muscle.isNotEmpty ? '  •  $muscle' : ''}',
            style: context.lwCaption,
          ),
        ],
      ),
    );
  }
}

class SetTrackerCard extends StatelessWidget {
  const SetTrackerCard({
    required this.exercise,
    required this.setControllers,
    required this.setSavedStatus,
    required this.setFocusNodes,
    required this.onSaveSet,
    required this.onFocusNextSet,
    super.key,
  });

  final WorkoutExerciseSession exercise;
  final List<Map<String, TextEditingController>> setControllers;
  final List<bool> setSavedStatus;
  final List<Map<String, FocusNode>> setFocusNodes;
  final void Function(int setIndex) onSaveSet;
  final void Function(int nextSetIndex, String fieldType) onFocusNextSet;

  @override
  Widget build(BuildContext context) {
    if (exercise.sets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LiveWorkoutSectionHeader(title: ProductCopy.sets),
        GymCard(
          variant: GymCardVariant.insight,
          padding: EdgeInsets.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: WorkoutLogColors.setsPanelBackground(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GymSpacing.sm,
                vertical: GymSpacing.sm,
              ),
              child: Column(
                children: List.generate(exercise.sets.length, (setIndex) {
                  if (setControllers.length <= setIndex) {
                    return const SizedBox.shrink();
                  }
                  final set = exercise.sets[setIndex];
                  return WorkoutSetEntryRow(
                    setIndex: setIndex,
                    isSaved: setSavedStatus.length > setIndex &&
                        setSavedStatus[setIndex],
                    setControllers: setControllers[setIndex],
                    style: ExerciseStyle.setsReps,
                    focusNodes: setFocusNodes.length > setIndex
                        ? setFocusNodes[setIndex]
                        : null,
                    isLastSet: setIndex == exercise.sets.length - 1,
                    defaultReps: set.targetReps,
                    onSaveSet: () => onSaveSet(setIndex),
                    onFocusNextSet: onFocusNextSet,
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LiveWorkoutCompletionCard extends StatelessWidget {
  const LiveWorkoutCompletionCard({
    required this.summary,
    this.onOpenAnalysis,
    super.key,
  });

  final LiveWorkoutCompletionSummary summary;
  final VoidCallback? onOpenAnalysis;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GymCard(
      variant: GymCardVariant.insight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(GymIcons.success, color: context.gymPrimary, size: 22),
              GymSpacing.gapSm,
              Expanded(
                child: Text(summary.headline, style: context.lwTitle),
              ),
            ],
          ),
          GymSpacing.gapSm,
          Text(summary.bodyLine, style: context.lwBody),
          GymSpacing.gapMd,
          Wrap(
            spacing: GymSpacing.sm,
            runSpacing: GymSpacing.sm,
            children: <Widget>[
              GymBadge(
                label: '${summary.completedSets} ست',
                variant: GymBadgeVariant.neutral,
                icon: GymIcons.activity,
              ),
              if (summary.totalVolumeKg > 0)
                GymBadge(
                  label:
                      '${LiveWorkoutCompletionSummary.formatVolume(summary.totalVolumeKg)} کیلو',
                  variant: GymBadgeVariant.neutral,
                  icon: GymIcons.workout,
                ),
              if (summary.focus.trim().isNotEmpty)
                GymBadge(
                  label: summary.focus,
                  variant: GymBadgeVariant.neutral,
                ),
            ],
          ),
          if (summary.hasHeatmapData) ...<Widget>[
            GymSpacing.gapLg,
            Text(
              'نقشهٔ عضلانی این جلسه',
              style: context.lwCaption.copyWith(fontWeight: FontWeight.w700),
            ),
            GymSpacing.gapSm,
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: isDark
                    ? const Color(0xFF0E1016)
                    : Colors.white.withValues(alpha: 0.55),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ExerciseMuscleHeatmapWidget(
                    key: ValueKey(
                      summary.muscleTargets.entries
                          .map((e) => '${e.key}:${e.value}')
                          .join(','),
                    ),
                    muscleTargets: summary.muscleTargets,
                    compact: true,
                    mapHeight: 200,
                  ),
                ),
              ),
            ),
            if (summary.topMuscleLabel != null) ...<Widget>[
              GymSpacing.gapSm,
              Wrap(
                spacing: GymSpacing.sm,
                children: MuscleTargets.sortedEntries(summary.muscleTargets)
                    .take(3)
                    .map(
                      (e) => GymBadge(
                        label: MuscleTargets.label(e.key),
                        variant: GymBadgeVariant.neutral,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
          GymSpacing.gapMd,
          Text(summary.tipLine, style: context.lwCaption),
          if (!summary.synced) ...<Widget>[
            GymSpacing.gapSm,
            Text(
              'آفلاین ذخیره شد؛ وقتی آنلاین شوی همگام می‌شود.',
              style: context.lwCaption.copyWith(color: context.gymWarning),
            ),
          ],
          if (onOpenAnalysis != null) ...<Widget>[
            GymSpacing.gapLg,
            GymButton(
              label: 'برو به تحلیل امروز',
              fullWidth: true,
              icon: GymIcons.progress,
              onPressed: onOpenAnalysis,
            ),
          ],
        ],
      ),
    );
  }
}

class LiveWorkoutTextListCard extends StatelessWidget {
  const LiveWorkoutTextListCard({
    required this.title,
    required this.items,
    super.key,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final displayItems = items
        .map(ProductCopy.humanizeReason)
        .where((item) => item.trim().isNotEmpty)
        .toList();
    if (displayItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LiveWorkoutSectionHeader(title: title),
        GymCard(
          variant: GymCardVariant.insight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final item in displayItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: GymSpacing.sm),
                  child: Text(item, style: context.lwBody),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _displayName(WorkoutExerciseSession exercise, int index) {
  return ProductExperienceFormatter.displayExerciseName(
    name: exercise.name,
    primaryMuscle: exercise.primaryMuscle,
    exerciseId: exercise.exerciseId,
    orderIndex: index,
  );
}

String _formatWeight(double value) {
  if (value == 0) return '0';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
