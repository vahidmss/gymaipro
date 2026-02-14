import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// wrapper برای بخش‌های داشبورد با انیمیشن ورود تدریجی
class DashboardAnimatedSection extends StatelessWidget {
  const DashboardAnimatedSection({
    super.key,
    required this.child,
    this.index = 0,
  });

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 60).toInt();
    return child
        .animate()
        .fadeIn(duration: 420.ms, delay: delay.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.035,
          end: 0,
          duration: 420.ms,
          delay: delay.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
