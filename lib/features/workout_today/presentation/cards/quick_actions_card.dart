import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/state/workout_today_state.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({
    required this.actions,
    required this.onActionTap,
    super.key,
  });

  final List<WorkoutTodayQuickAction> actions;
  final ValueChanged<WorkoutTodayQuickAction> onActionTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ProductCopy.quickActions,
          style: GymTypography.caption,
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
