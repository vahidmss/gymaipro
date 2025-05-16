import 'package:flutter/material.dart';

class AnimationUtils {
  // Fade-in with slide animation for widgets
  static Widget fadeSlideIn({
    required Widget child,
    required Animation<double> animation,
    Offset? beginOffset,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset ?? const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }

  // Pulse animation for drawing attention to elements
  static Widget pulseAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scale = 1.0 +
            0.03 *
                Curves.easeInOut.transform(
                  (controller.value - 0.5).abs() * 2,
                );
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }

  // Staggered list item animation
  static Widget staggeredListItem({
    required Widget child,
    required Animation<double> animation,
    int index = 0,
  }) {
    // اطمینان از مقادیر صحیح برای محدوده انیمیشن
    final startInterval = (0.1 * index).clamp(0.0, 0.9);
    final endInterval = (startInterval + 0.6).clamp(0.0, 1.0);

    final delayedAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        startInterval,
        endInterval,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: delayedAnimation,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - delayedAnimation.value)),
        child: child,
      ),
    );
  }

  // Gold shimmer effect
  static Shader buildGoldGradient(Rect bounds) {
    return const LinearGradient(
      colors: [
        Color(0xFFD4AF37),
        Color(0xFFFFD700),
        Color(0xFFD4AF37),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(bounds);
  }

  // Create a custom page route transition
  static PageRouteBuilder<T> createPageRoute<T>({
    required Widget page,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 350),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return Stack(
          children: [
            FadeTransition(
              opacity:
                  Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: child,
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          ],
        );
      },
    );
  }
}
