import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

enum GymBadgeVariant { primary, success, warning, danger, info, neutral }

/// Compact status badge.
class GymBadge extends StatelessWidget {
  const GymBadge({
    required this.label,
    this.variant = GymBadgeVariant.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final GymBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GymSpacing.md,
        vertical: GymSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: GymRadius.pill,
        border: Border.all(color: colors.foreground.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: colors.foreground),
            const SizedBox(width: GymSpacing.xs),
          ],
          Text(
            label,
            style: GymTypography.overline.copyWith(color: colors.foreground),
          ),
        ],
      ),
    );
  }

  ({Color background, Color foreground}) _colors(BuildContext context) {
    return switch (variant) {
      GymBadgeVariant.primary => (
        background: context.gymGold.withValues(alpha: 0.14),
        foreground: context.gymPrimary,
      ),
      GymBadgeVariant.success => (
        background: context.gymSuccess.withValues(alpha: 0.14),
        foreground: context.gymSuccess,
      ),
      GymBadgeVariant.warning => (
        background: context.gymWarningMuted,
        foreground: context.gymWarning,
      ),
      GymBadgeVariant.danger => (
        background: context.gymDanger.withValues(alpha: 0.14),
        foreground: context.gymDanger,
      ),
      GymBadgeVariant.info => (
        background: context.gymInfo.withValues(alpha: 0.14),
        foreground: context.gymInfo,
      ),
      GymBadgeVariant.neutral => (
        background: context.gymNeutralFill,
        foreground: context.gymTextSecondary,
      ),
    };
  }
}
