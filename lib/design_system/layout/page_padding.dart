import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';

/// Page-level horizontal padding from spacing tokens.
class GymPagePadding extends StatelessWidget {
  const GymPagePadding({
    required this.child,
    this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? GymSpacing.page,
      child: child,
    );
  }
}
