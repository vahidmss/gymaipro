import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';

/// Scale-in entrance animation.
class GymScaleIn extends StatelessWidget {
  const GymScaleIn({
    required this.child,
    this.duration = GymMotion.fast,
    this.curve = GymMotion.enter,
    this.beginScale = 0.94,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: beginScale, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: child,
    );
  }
}
