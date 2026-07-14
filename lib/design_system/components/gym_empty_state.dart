import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Empty state with icon, title, message, and optional action.
class GymEmptyState extends StatelessWidget {
  const GymEmptyState({
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: GymSpacing.paddingXxl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GymColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: GymColors.border),
              ),
              child: Icon(icon, color: GymColors.primary, size: 28),
            ),
          if (icon != null) const SizedBox(height: GymSpacing.xxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GymTypography.headline,
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: GymSpacing.md),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: GymTypography.body,
            ),
          ],
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: GymSpacing.xxl),
            GymButton(
              label: actionLabel!,
              onPressed: onAction,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}
