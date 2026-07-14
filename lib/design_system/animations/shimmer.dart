import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';

/// Shimmer loading effect overlay.
class GymShimmer extends StatefulWidget {
  const GymShimmer({
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  @override
  State<GymShimmer> createState() => _GymShimmerState();
}

class _GymShimmerState extends State<GymShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: GymMotion.shimmer,
    );
    if (widget.enabled) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void didUpdateWidget(covariant GymShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      unawaited(_controller.repeat());
    } else if (!widget.enabled) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final base = widget.baseColor ?? GymColors.neutral800;
    final highlight = widget.highlightColor ?? GymColors.neutral600;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 - _controller.value * 2, 0),
              end: Alignment(1 - _controller.value * 2, 0),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.2, 0.5, 0.8],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer block with design-system radius.
class GymShimmerBlock extends StatelessWidget {
  const GymShimmerBlock({
    this.width,
    this.height = 16,
    this.radius = GymRadius.md,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GymShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GymColors.neutral800,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
