import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_badge.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_divider.dart';
import 'package:gymaipro/design_system/components/gym_progress_bar.dart';
import 'package:gymaipro/design_system/components/gym_progress_ring.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_exercise_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_completion_summary.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_rest_state.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class LiveWorkoutHeroCard extends StatelessWidget {
  const LiveWorkoutHeroCard({required this.session, super.key});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(ProductCopy.todayProgram, style: GymTypography.overline),
        GymSpacing.gapSm,
        Text(session.focus, style: GymTypography.display),
        GymSpacing.gapLg,
        Wrap(
          spacing: GymSpacing.md,
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
          color: GymColors.textPrimary,
        ),
        GymSpacing.gapLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(ProductCopy.progress, style: GymTypography.title),
              GymSpacing.gapSm,
              Text(
                '$exerciseNumber از ${state.totalExercises} حرکت',
                style: GymTypography.bodyStrong,
              ),
              GymSpacing.gapSm,
              Text(
                '${state.completedSets} از ${state.totalSets} ست',
                style: GymTypography.caption,
              ),
              GymSpacing.gapMd,
              GymProgressBar(
                value: progress.clamp(0, 1),
                animated: true,
                color: GymColors.textPrimary,
              ),
            ],
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
    super.key,
  });

  final WorkoutExerciseSession exercise;
  final WorkoutSetSession? currentSet;

  @override
  Widget build(BuildContext context) {
    final set = currentSet ?? exercise.sets.firstOrNull;
    return GymCard(
      variant: GymCardVariant.action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.currentExercise, style: GymTypography.overline),
          GymSpacing.gapSm,
          Text(exercise.name, style: GymTypography.display),
          GymSpacing.gapSm,
          Text(
            '${exercise.sets.length} ست  •  ست ${set?.index ?? 1}',
            style: GymTypography.body,
          ),
          if (set != null) ...<Widget>[
            GymSpacing.gapLg,
            Text(
              'هدف: ${set.targetReps} تکرار  •  ${_formatWeight(set.targetWeightKg)} کیلو',
              style: GymTypography.caption.copyWith(color: GymColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}

class UpcomingExerciseCard extends StatelessWidget {
  const UpcomingExerciseCard({required this.exercise, super.key});

  final WorkoutExerciseSession exercise;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.insight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(ProductCopy.upcomingExercise, style: GymTypography.overline),
          GymSpacing.gapSm,
          Text(exercise.name, style: GymTypography.title),
          GymSpacing.gapSm,
          Text(
            '${exercise.sets.length} ست  •  ${exercise.primaryMuscle}',
            style: GymTypography.caption,
          ),
        ],
      ),
    );
  }
}

class SetTrackerCard extends StatelessWidget {
  const SetTrackerCard({
    required this.state,
    required this.onSetTap,
    required this.onSetChanged,
    super.key,
  });

  final LiveWorkoutState state;
  final ValueChanged<int> onSetTap;
  final void Function({
    int? reps,
    double? weightKg,
    int? rpe,
    int? durationSeconds,
    String? notes,
  })
  onSetChanged;

  @override
  Widget build(BuildContext context) {
    final exercise = state.currentExercise;
    if (exercise == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(ProductCopy.sets, style: GymTypography.title),
        GymSpacing.gapMd,
        for (final set in exercise.sets) ...<Widget>[
          _SetRow(
            set: set,
            status: set.status,
            isCurrent: set.status == WorkoutSetSessionStatus.current,
            onTap: () => onSetTap(set.index - 1),
          ),
          if (set.status == WorkoutSetSessionStatus.current)
            _CurrentSetEditor(
              set: set,
              onChanged: onSetChanged,
            ),
          if (set != exercise.sets.last) const GymDivider(),
        ],
      ],
    );
  }
}

class RestTimerCard extends StatelessWidget {
  const RestTimerCard({
    required this.rest,
    required this.onPause,
    required this.onResume,
    required this.onSkip,
    required this.onExtend,
    super.key,
  });

  final LiveWorkoutRestState rest;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkip;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    if (!rest.active) return const SizedBox.shrink();

    return GymCard(
      child: Row(
        children: <Widget>[
          const Icon(GymIcons.clock, color: GymColors.textPrimary, size: 34),
          GymSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(ProductCopy.restTimer, style: GymTypography.title),
                GymSpacing.gapXs,
                Text(
                  '${rest.remainingSeconds} ثانیه',
                  style: GymTypography.metric,
                ),
                if (rest.paused)
                  Text(
                    'متوقف شده',
                    style: GymTypography.caption.copyWith(
                      color: GymColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: rest.paused ? 'ادامه' : 'توقف',
            onPressed: rest.paused ? onResume : onPause,
            icon: Icon(rest.paused ? Icons.play_arrow_rounded : Icons.pause),
          ),
          IconButton(
            tooltip: '+۳۰ ثانیه',
            onPressed: onExtend,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'رد کردن',
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next_rounded),
          ),
        ],
      ),
    );
  }
}

class LiveWorkoutCompletionCard extends StatelessWidget {
  const LiveWorkoutCompletionCard({required this.summary, super.key});

  final LiveWorkoutCompletionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(summary.focus, style: GymTypography.display),
        GymSpacing.gapSm,
        Text(summary.coachMessage, style: GymTypography.body),
        GymSpacing.gapLg,
        Wrap(
          spacing: GymSpacing.sm,
          runSpacing: GymSpacing.sm,
          children: summary.highlights
              .map(
                (item) => GymBadge(
                  label: item,
                  variant: GymBadgeVariant.neutral,
                ),
              )
              .toList(growable: false),
        ),
        GymSpacing.gapLg,
        Text(
          '${summary.durationMinutes} ${ProductCopy.minutes}  •  '
          '${summary.completedSets}/${summary.totalSets} ست',
          style: GymTypography.caption,
        ),
        if (!summary.synced) ...<Widget>[
          GymSpacing.gapSm,
          Text(
            'آفلاین ذخیره شد؛ بعداً همگام‌سازی می‌شود.',
            style: GymTypography.caption.copyWith(color: GymColors.warning),
          ),
        ],
      ],
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
    final displayItems =
        items.isEmpty ? const <String>['فعلاً نکته‌ای ثبت نشده.'] : items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: GymTypography.overline),
        GymSpacing.gapMd,
        for (final item in displayItems)
          Padding(
            padding: const EdgeInsets.only(bottom: GymSpacing.sm),
            child: Text(
              ProductCopy.humanizeReason(item),
              style: GymTypography.body.copyWith(
                fontSize: 15,
                height: 1.6,
                color: GymColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

class _CurrentSetEditor extends StatefulWidget {
  const _CurrentSetEditor({
    required this.set,
    required this.onChanged,
  });

  final WorkoutSetSession set;
  final void Function({
    int? reps,
    double? weightKg,
    int? rpe,
    int? durationSeconds,
    String? notes,
  })
  onChanged;

  @override
  State<_CurrentSetEditor> createState() => _CurrentSetEditorState();
}

class _CurrentSetEditorState extends State<_CurrentSetEditor> {
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _rpeController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: '${widget.set.effectiveReps}',
    );
    _weightController = TextEditingController(
      text: _formatWeight(widget.set.effectiveWeightKg),
    );
    _rpeController = TextEditingController(
      text: widget.set.rpe?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.set.durationSeconds?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget.set.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _CurrentSetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.index != widget.set.index) {
      _repsController.text = '${widget.set.effectiveReps}';
      _weightController.text = _formatWeight(widget.set.effectiveWeightKg);
      _rpeController.text = widget.set.rpe?.toString() ?? '';
      _durationController.text = widget.set.durationSeconds?.toString() ?? '';
      _notesController.text = widget.set.notes ?? '';
    }
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _rpeController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GymSpacing.md),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricField(
                  label: 'تکرار',
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _emit(),
                ),
              ),
              GymSpacing.gapMd,
              Expanded(
                child: _MetricField(
                  label: 'وزن (کیلو)',
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _emit(),
                ),
              ),
            ],
          ),
          GymSpacing.gapSm,
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricField(
                  label: 'شدت تلاش',
                  controller: _rpeController,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _emit(),
                ),
              ),
              GymSpacing.gapMd,
              Expanded(
                child: _MetricField(
                  label: 'مدت (ثانیه)',
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _emit(),
                ),
              ),
            ],
          ),
          GymSpacing.gapSm,
          _MetricField(
            label: 'یادداشت',
            controller: _notesController,
            onSubmitted: (_) => _emit(),
          ),
        ],
      ),
    );
  }

  void _emit() {
    widget.onChanged(
      reps: int.tryParse(_repsController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      rpe: int.tryParse(_rpeController.text.trim()),
      durationSeconds: int.tryParse(_durationController.text.trim()),
      notes: _notesController.text.trim(),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GymTypography.body,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(borderRadius: GymRadius.radiusMd),
      ),
      onSubmitted: onSubmitted,
      onEditingComplete: () => onSubmitted?.call(controller.text),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.status,
    required this.isCurrent,
    required this.onTap,
  });

  final WorkoutSetSession set;
  final WorkoutSetSessionStatus status;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? GymColors.elevated : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: GymRadius.radiusLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GymSpacing.md),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'ست ${set.index}',
                  style: GymTypography.bodyStrong.copyWith(
                    color: isCurrent ? GymColors.textPrimary : null,
                  ),
                ),
              ),
              _SmallMetric(
                label: 'وزن',
                value: '${_formatWeight(set.effectiveWeightKg)} کیلو',
              ),
              GymSpacing.gapLg,
              _SmallMetric(label: 'تکرار', value: '${set.effectiveReps}'),
              GymSpacing.gapLg,
              _StatusIcon(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final WorkoutSetSessionStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      WorkoutSetSessionStatus.completed => const Icon(
        Icons.check_circle_rounded,
        color: GymColors.textPrimary,
      ),
      WorkoutSetSessionStatus.skipped => const Icon(
        Icons.remove_circle_outline,
        color: GymColors.textSecondary,
      ),
      WorkoutSetSessionStatus.failed => const Icon(
        Icons.error_outline,
        color: GymColors.warning,
      ),
      WorkoutSetSessionStatus.current => const Icon(
        Icons.play_circle_fill_rounded,
        color: GymColors.textPrimary,
      ),
      WorkoutSetSessionStatus.pending => const Icon(
        Icons.radio_button_unchecked,
        color: GymColors.textDisabled,
      ),
    };
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: GymTypography.overline),
        Text(value, style: GymTypography.caption),
      ],
    );
  }
}

String _formatWeight(double value) {
  if (value == 0) return '0';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
