import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({
    super.key,
    this.onTap,
    this.hasUnreadNotifications = false,
    this.unreadCount = 0,
  });
  final VoidCallback? onTap;
  final bool hasUnreadNotifications;
  final int unreadCount;

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Start pulse animation if there are unread notifications
    if (widget.hasUnreadNotifications) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start or stop pulse animation based on unread notifications
    if (widget.hasUnreadNotifications && !oldWidget.hasUnreadNotifications) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasUnreadNotifications &&
        oldWidget.hasUnreadNotifications) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Stack(
              children: [
                // Main notification container
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.hasUnreadNotifications
                          ? [
                              AppTheme.goldColor.withValues(alpha: 0.1),
                              AppTheme.darkGold.withValues(alpha: 0.1),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: widget.hasUnreadNotifications
                          ? AppTheme.goldColor.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 3.r,
                        offset: Offset(0.w, 1.h),
                      ),
                      if (widget.hasUnreadNotifications)
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.1),
                          blurRadius: 6 * _pulseAnimation.value,
                          spreadRadius: 1 * _pulseAnimation.value,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.bellRing,
                      color: widget.hasUnreadNotifications
                          ? AppTheme.goldColor
                          : Colors.white,
                      size: 18.sp,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 1.r,
                          offset: Offset(0.w, 1.h),
                        ),
                      ],
                    ),
                  ),
                ),
                // Unread count badge
                if (widget.unreadCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Color(0xFFE53E3E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.1),
                              blurRadius: 3.r,
                              offset: Offset(0.w, 1.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.unreadCount > 99
                                ? '99+'
                                : widget.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 1.r,
                                  offset: Offset(0.w, 1.h),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
