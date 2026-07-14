import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';

/// Fade + slide entrance animation.
class GymFadeSlide extends StatelessWidget {
  const GymFadeSlide({
    required this.child,
    this.duration = GymMotion.normal,
    this.curve = GymMotion.standard,
    this.offsetY = 12,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final double offsetY;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        final adjusted = delay == Duration.zero
            ? value
            : ((value * (duration.inMilliseconds + delay.inMilliseconds) -
                      delay.inMilliseconds) /
                  duration.inMilliseconds)
              .clamp(0.0, 1.0);
        return Opacity(
          opacity: adjusted,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - adjusted)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
