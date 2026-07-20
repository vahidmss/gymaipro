import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/presentation/active_program_selector_sheet.dart';

/// Shared program picker used in Workout Today and Workout Log.
class ActiveProgramSelectorBar extends StatelessWidget {
  const ActiveProgramSelectorBar({
    required this.program,
    required this.onProgramChanged,
    this.supervisionLabel = 'تحت نظارت هوش مصنوعی',
    super.key,
  });

  final ActiveProgramOption? program;
  final Future<void> Function(ActiveProgramOption option) onProgramChanged;
  final String supervisionLabel;

  @override
  Widget build(BuildContext context) {
    if (program == null) return const SizedBox.shrink();

    return GymCard(
      variant: GymCardVariant.insight,
      onTap: () => _openSelector(context),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('برنامه فعال', style: context.gymTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.gymTextSecondary,
                )),
                GymSpacing.gapXs,
                Text(
                  program!.title,
                  style: context.gymTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.gymTextPrimary,
                  ),
                ),
                GymSpacing.gapXs,
                Text(
                  program!.displaySubtitle,
                  style: context.gymTextStyle(
                    fontSize: 13,
                    color: context.gymTextSecondary,
                  ),
                ),
                if (program!.isAiSupervised) ...<Widget>[
                  GymSpacing.gapXs,
                  Text(
                    supervisionLabel,
                    style: context.gymTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.gymPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.unfold_more_rounded, color: context.gymTextSecondary),
        ],
      ),
    );
  }

  Future<void> _openSelector(BuildContext context) async {
    final selected = await ActiveProgramSelectorSheet.show(
      context,
      currentProgramId: program?.id,
    );
    if (selected != null) {
      await onProgramChanged(selected);
    }
  }
}
