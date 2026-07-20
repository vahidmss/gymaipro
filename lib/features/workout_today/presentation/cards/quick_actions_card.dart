import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_speech_card.dart';
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

    return CoachSpeechCard(
      title: ProductCopy.quickActions,
      child: Wrap(
        spacing: GymSpacing.xs,
        runSpacing: GymSpacing.xs,
        children: actions
            .map(
              (action) => GymChip(
                label:
                    '${ProductCopy.quickActionEmoji(action.id)} ${ProductCopy.defaultQuickChipLabel(action.id, action.label)}',
                variant: GymChipVariant.outline,
                onTap: () => onActionTap(action),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
