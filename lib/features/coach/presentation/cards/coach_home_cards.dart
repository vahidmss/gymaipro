import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/scale_in.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/components/gym_progress_ring.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class CoachHeroCard extends StatelessWidget {
  const CoachHeroCard({
    required this.state,
    required this.onStartWorkout,
    super.key,
  });

  final CoachHomeState state;
  final VoidCallback onStartWorkout;

  @override
  Widget build(BuildContext context) {
    final workout = state.todayWorkout;
    final greetingLine = state.greeting.split('\n').first;

    return GymScaleIn(
      child: Padding(
        padding: const EdgeInsets.only(bottom: GymSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              greetingLine,
              style: context.gymTextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            GymSpacing.gapMd,
            Text(
              workout == null
                  ? 'هنوز برنامه مشخصی برای امروز نداری.'
                  : 'امروز برنامه ${workout.focus} آماده است.',
              style: context.gymTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            if (workout != null) ...<Widget>[
              GymSpacing.gapXl,
              Wrap(
                spacing: GymSpacing.xl,
                runSpacing: GymSpacing.md,
                children: <Widget>[
                  _HeroMetric(
                    value: '${workout.exerciseCount}',
                    label: ProductCopy.exercisesCount,
                  ),
                  _HeroMetric(
                    value: '${workout.durationMinutes}',
                    label: ProductCopy.minutes,
                  ),
                ],
              ),
              GymSpacing.gapXxl,
              GymButton(
                label: ProductCopy.startWorkout,
                fullWidth: true,
                onPressed: onStartWorkout,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CoachBriefCard extends StatelessWidget {
  const CoachBriefCard({required this.state, super.key});

  final CoachHomeState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GymProgressRing(
          value: state.recovery.readiness / 100,
          label: '${state.recovery.readiness}٪',
          size: 72,
          color: context.gymPrimary,
        ),
        GymSpacing.gapLg,
        Expanded(
          child: Container(
            padding: GymSpacing.card,
            decoration: BoxDecoration(
              color: context.gymCard,
              borderRadius: BorderRadius.circular(GymSpacing.xl),
              border: Border.all(color: context.gymBorderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ProductCopy.coachBriefTitle,
                  style: context.gymTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.gymTextTertiary,
                  ),
                ),
                GymSpacing.gapMd,
                Text(
                  state.coachBrief.trim().isNotEmpty
                      ? state.coachBrief
                      : ProductCopy.buildCoachBrief(state),
                  style: context.gymTextStyle(
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CoachQuickActionChips extends StatelessWidget {
  const CoachQuickActionChips({
    required this.actions,
    required this.onActionTap,
    super.key,
  });

  final List<CoachQuickAction> actions;
  final ValueChanged<CoachQuickAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ProductCopy.quickActions,
          style: context.gymTextStyle(
            fontSize: 12,
            color: context.gymTextTertiary,
          ),
        ),
        GymSpacing.gapMd,
        Wrap(
          spacing: GymSpacing.sm,
          runSpacing: GymSpacing.sm,
          children: actions
              .map(
                (action) => GymChip(
                  label:
                      '${ProductCopy.quickActionEmoji(action.id)} ${ProductCopy.defaultQuickChipLabel(action.id, action.label)}',
                  variant: GymChipVariant.filled,
                  onTap: () => onActionTap(action),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class CoachWhyCard extends StatelessWidget {
  const CoachWhyCard({required this.item, super.key});

  final CoachExplainabilityItem item;

  @override
  Widget build(BuildContext context) {
    if (item.question.trim().isEmpty && item.reasons.isEmpty) {
      return const SizedBox.shrink();
    }

    final reasons = item.reasons
        .map(ProductCopy.humanizeReason)
        .where((reason) => reason.isNotEmpty)
        .toList();

    return GymExpandableCard(
      title: ProductCopy.whyThisSuggestion,
      subtitle: item.question.trim().isEmpty ? null : item.question,
      variant: GymCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: GymSpacing.md),
              child: Text(
                reason,
                style: context.gymTextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: context.gymTextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        Text(
          label,
          style: context.gymTextStyle(
            fontSize: 12,
            color: context.gymTextTertiary,
          ),
        ),
      ],
    );
  }
}
