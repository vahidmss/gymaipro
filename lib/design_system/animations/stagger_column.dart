import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/fade_slide.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';

/// Staggered column of children with fade/slide entrance.
class GymStaggerColumn extends StatelessWidget {
  const GymStaggerColumn({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
    this.gap = GymSpacing.lg,
    this.duration = GymMotion.normal,
    super.key,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double gap;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: <Widget>[
        for (var i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: gap),
          GymFadeSlide(
            duration: duration,
            delay: GymMotion.staggerStep * i,
            child: children[i],
          ),
        ],
      ],
    );
  }
}
