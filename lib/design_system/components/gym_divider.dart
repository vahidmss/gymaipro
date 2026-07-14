import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
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
        child: Container(width: 1, color: GymColors.divider),
      );
    }

    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: spacing),
        child: const Divider(color: GymColors.divider, height: 1),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider(color: GymColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GymSpacing.md),
            child: Text(label!, style: GymTypography.overline),
          ),
          const Expanded(child: Divider(color: GymColors.divider)),
        ],
      ),
    );
  }
}
