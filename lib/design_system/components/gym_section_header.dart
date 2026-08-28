import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Section header with optional action.
class GymSectionHeader extends StatelessWidget {
  const GymSectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GymSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: GymTypography.title.copyWith(
                    color: context.gymTextPrimary,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: GymSpacing.xs),
                  Text(
                    subtitle!,
                    style: GymTypography.caption.copyWith(
                      color: context.gymTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(
                actionLabel!,
                style: GymTypography.caption.copyWith(
                  color: context.gymPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
