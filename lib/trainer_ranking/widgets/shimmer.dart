import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';

class Shimmer extends StatefulWidget {
  const Shimmer({
    required this.width,
    required this.height,
    super.key,
    this.borderRadius,
  });
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _controller.safeRepeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _ShimmerPainter(
              progress: _controller.value,
              isDark: isDark,
              cardColor: context.cardColor,
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({
    required this.progress,
    required this.isDark,
    required this.cardColor,
  });
  final double progress;
  final bool isDark;
  final Color cardColor;

  @override
  void paint(Canvas canvas, Size size) {
    // پس‌زمینه اصلی
    final base = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [cardColor, cardColor.withValues(alpha: 0.8)]
            : [cardColor, cardColor.withValues(alpha: 0.9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, base);

    // افکت shimmer
    final shimmerWidth = size.width * 0.4;
    final dx = (size.width + shimmerWidth) * progress - shimmerWidth;
    final rect = Rect.fromLTWH(dx, 0, shimmerWidth, size.height);

    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
          AppTheme.goldColor.withValues(alpha: isDark ? 0.25 : 0.15),
          AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.saveLayer(rect, Paint());
    canvas.drawRect(rect, shimmerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.cardColor != cardColor;
  }
}
