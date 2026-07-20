import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Extension برای فراخوانی ایمن متدهای AnimationController
/// جلوگیری از خطای "AnimationController methods called after dispose"
extension SafeAnimationController on AnimationController {
  /// بررسی اینکه controller هنوز dispose نشده
  /// با استفاده از try-catch برای بررسی خطای assertion
  bool get _isDisposed {
    try {
      // تلاش برای دسترسی به value - اگر dispose شده باشد خطا می‌دهد
      final _ = value;
      // بررسی اینکه ticker null نیست (از طریق isAnimating)
      final _ = isAnimating;
      return false;
    } catch (e) {
      // اگر خطای assertion یا هر خطای دیگری رخ داد، controller dispose شده
      return true;
    }
  }

  /// فراخوانی ایمن stop
  void safeStop() {
    if (_isDisposed) return;
    try {
      if (isAnimating) {
        stop();
      }
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// فراخوانی ایمن forward
  Future<void> safeForward() async {
    if (_isDisposed) return;
    try {
      await forward();
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// فراخوانی ایمن reverse
  Future<void> safeReverse() async {
    if (_isDisposed) return;
    try {
      await reverse();
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// فراخوانی ایمن repeat
  void safeRepeat({bool reverse = false}) {
    if (_isDisposed) return;
    try {
      repeat(reverse: reverse);
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// فراخوانی ایمن reset
  void safeReset() {
    if (_isDisposed) return;
    try {
      reset();
    } catch (e) {
      // ignore - controller already disposed
    }
  }

  /// بررسی اینکه controller هنوز valid است
  bool get isSafe {
    return !_isDisposed;
  }
}

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
        position:
            Tween<Offset>(
              begin: beginOffset ?? Offset(0.w, 0.1.h),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
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
        final scale =
            1.0 +
            0.03 *
                Curves.easeInOut.transform((controller.value - 0.5).abs() * 2);
        return Transform.scale(scale: scale, child: child);
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
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
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
      colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
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
              opacity: Tween<double>(begin: 0, end: 1).animate(curvedAnimation),
              child: child,
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.w, 0.1.h),
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
