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
    this.supervisionLabel = 'برنامه مربی هوشمند',
    this.aiOnly = true,
    this.placeholderTitle = 'انتخاب برنامه هوش مصنوعی',
    super.key,
  });

  final ActiveProgramOption? program;
  final Future<void> Function(ActiveProgramOption option) onProgramChanged;
  final String supervisionLabel;

  /// Coach surfaces default to AI-only picker.
  final bool aiOnly;
  final String placeholderTitle;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.insight,
      onTap: () => _openSelector(context),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'برنامه فعال',
                  style: context.gymTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.gymTextSecondary,
                  ),
                ),
                GymSpacing.gapXs,
                Text(
                  program?.title ?? placeholderTitle,
                  style: context.gymTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.gymTextPrimary,
                  ),
                ),
                if (program != null) ...<Widget>[
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
                ] else ...<Widget>[
                  GymSpacing.gapXs,
                  Text(
                    'برای استفاده از مربی هوشمند، یک برنامه AI انتخاب کن',
                    style: context.gymTextStyle(
                      fontSize: 13,
                      color: context.gymTextSecondary,
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
      aiOnly: aiOnly,
    );
    if (selected != null) {
      await onProgramChanged(selected);
    }
  }
}
