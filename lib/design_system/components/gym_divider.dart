import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Horizontal or vertical divider with optional label.
class GymDivider extends StatelessWidget {
  const GymDivider({
    this.label,
    this.vertical = false,
    this.spacing = GymSpacing.lg,
    super.key,
  });

  final String? label;
  final bool vertical;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing),
        child: Container(width: 1, color: context.gymBorder),
      );
    }

    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: spacing),
        child: Divider(color: context.gymBorder, height: 1),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(color: context.gymBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GymSpacing.md),
            child: Text(
              label!,
              style: GymTypography.overline.copyWith(
                color: context.gymTextTertiary,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.gymBorder)),
        ],
      ),
    );
  }
}
