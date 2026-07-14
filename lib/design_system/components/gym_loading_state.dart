import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Centered loading state with optional message.
class GymLoadingState extends StatelessWidget {
  const GymLoadingState({
    this.message,
    this.compact = false,
    super.key,
  });

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: compact ? GymSpacing.paddingLg : GymSpacing.paddingXxl,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: GymColors.primary,
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: GymSpacing.lg),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: GymTypography.body,
            ),
          ],
        ],
      ),
    );
  }
}
