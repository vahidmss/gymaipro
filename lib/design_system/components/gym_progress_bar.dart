import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';

/// Animated linear progress bar.
class GymProgressBar extends StatelessWidget {
  const GymProgressBar({
    required this.value,
    this.height = 8,
    this.animated = true,
    this.color,
    this.backgroundColor,
    super.key,
  });

  final double value;
  final double height;
  final bool animated;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final fillColor = color ?? GymColors.primary;
    final trackColor = backgroundColor ?? GymColors.neutral800;

    final fill = FractionallySizedBox(
      alignment: Alignment.centerRight,
      widthFactor: clamped,
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: GymRadius.pill,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: GymRadius.pill,
      child: Container(
        height: height,
        color: trackColor,
        child: animated
            ? TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: clamped),
                duration: GymMotion.slow,
                curve: GymMotion.standard,
                builder: (context, animatedValue, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: animatedValue,
                    child: Container(
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: GymRadius.pill,
                      ),
                    ),
                  );
                },
              )
            : fill,
      ),
    );
  }
}
