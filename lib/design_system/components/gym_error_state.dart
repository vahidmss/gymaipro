import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Error state card with retry action.
class GymErrorState extends StatelessWidget {
  const GymErrorState({
    required this.message,
    this.title = 'خطا',
    this.onRetry,
    this.retryLabel = 'تلاش دوباره',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(GymIcons.error, color: GymColors.danger, size: 20),
              const SizedBox(width: GymSpacing.sm),
              Text(title, style: GymTypography.title),
            ],
          ),
          const SizedBox(height: GymSpacing.md),
          Text(message, style: GymTypography.body),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: GymSpacing.lg),
            GymButton(
              label: retryLabel,
              variant: GymButtonVariant.ghost,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
