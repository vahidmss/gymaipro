import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';

/// Compact coach note shell — content only, no decorative avatar.
class CoachSpeechCard extends StatelessWidget {
  const CoachSpeechCard({
    required this.child,
    this.title,
    this.avatarSize = 36,
    this.variant = GymCardVariant.compact,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GymSpacing.md,
      vertical: GymSpacing.sm,
    ),
    super.key,
  });

  final Widget child;
  final String? title;
  /// Kept for call-site compatibility; no longer rendered.
  final double avatarSize;
  final GymCardVariant variant;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: variant,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null && title!.trim().isNotEmpty) ...<Widget>[
            Text(
              title!,
              style: context.gymTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.gymTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          child,
        ],
      ),
    );
  }
}
