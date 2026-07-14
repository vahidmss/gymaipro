import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Animated circular progress ring.
class GymProgressRing extends StatelessWidget {
  const GymProgressRing({
    required this.value,
    this.size = 72,
    this.strokeWidth = 8,
    this.animated = true,
    this.color,
    this.label,
    super.key,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final bool animated;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final ringColor = color ?? GymColors.primary;

    Widget ring(double progress) {
      return CustomPaint(
        size: Size(size, size),
        painter: _RingPainter(
          progress: progress,
          strokeWidth: strokeWidth,
          color: ringColor,
          trackColor: GymColors.neutral800,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (animated)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clamped),
              duration: GymMotion.slow,
              curve: GymMotion.standard,
              builder: (context, animatedValue, _) => ring(animatedValue),
            )
          else
            ring(clamped),
          if (label != null)
            Text(
              label!,
              style: GymTypography.caption.copyWith(
                color: GymColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
