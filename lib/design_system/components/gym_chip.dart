import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

enum GymChipVariant { filled, outline, ghost }

/// Selectable or action chip.
class GymChip extends StatelessWidget {
  const GymChip({
    required this.label,
    this.onTap,
    this.selected = false,
    this.variant = GymChipVariant.outline,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final GymChipVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? GymColors.primary.withValues(alpha: 0.16)
        : switch (variant) {
            GymChipVariant.filled => GymColors.surface,
            GymChipVariant.outline => Colors.transparent,
            GymChipVariant.ghost => Colors.transparent,
          };

    final borderColor = selected
        ? GymColors.primary
        : switch (variant) {
            GymChipVariant.filled => GymColors.borderSubtle,
            GymChipVariant.outline => GymColors.border,
            GymChipVariant.ghost => Colors.transparent,
          };

    final textColor = selected ? GymColors.primary : GymColors.textSecondary;

    return Material(
      color: background,
      borderRadius: GymRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: GymRadius.pill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: GymSpacing.lg,
            vertical: GymSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: GymRadius.pill,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: GymSpacing.xs),
              ],
              Text(
                label,
                style: GymTypography.caption.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
