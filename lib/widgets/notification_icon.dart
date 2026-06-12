import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({
    super.key,
    this.onTap,
  });
  final VoidCallback? onTap;

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

    // Load unread count on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.refreshUnreadCount();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<NotificationProvider>();
    final hasUnread = provider.unreadCount > 0;
    
    if (hasUnread) {
      _pulseController.safeRepeat();
    } else {
      _pulseController.safeStop();
      _pulseController.safeReset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _bounceController.safeForward().then((_) {
      _bounceController.safeReverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hasUnread = provider.unreadCount > 0;
        final unreadCount = provider.unreadCount;
        final iconColor = hasUnread
            ? AppTheme.goldColor
            : context.textSecondary;

        return GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main notification container
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        gradient: hasUnread
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.goldColor.withValues(alpha: 0.2),
                                  AppTheme.darkGold.withValues(alpha: 0.15),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [context.cardColor, context.cardColor],
                              ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: hasUnread
                              ? AppTheme.goldColor.withValues(alpha: 0.5)
                              : context.separatorColor,
                          width: hasUnread ? 1.5.w : 1.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : context.textColor.withValues(alpha: 0.08),
                            blurRadius: 6.r,
                            offset: Offset(0.w, 2.h),
                          ),
                          if (hasUnread)
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(
                                alpha: 0.4 * _pulseAnimation.value,
                              ),
                              blurRadius: 12 * _pulseAnimation.value,
                              spreadRadius: 2 * _pulseAnimation.value,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.bellRing,
                          color: iconColor,
                          size: 22.sp,
                          shadows: hasUnread
                              ? [
                                  Shadow(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 6.r,
                                    offset: Offset(0.w, 0.h),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                    // Unread count badge or red dot
                    if (hasUnread)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: unreadCount > 0
                              ? Container(
                                  constraints: BoxConstraints(
                                    minWidth: 20.w,
                                    minHeight: 20.h,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: unreadCount > 9 ? 6.w : 5.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF4444),
                                        Color(0xFFE53E3E),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.5),
                                        blurRadius: 6.r,
                                        offset: Offset(0.w, 2.h),
                                        spreadRadius: 1.r,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount.toString(),
                                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        height: 1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              : // Red dot when has unread but count is 0
                                Container(
                                  width: 12.w,
                                  height: 12.h,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF4444),
                                        Color(0xFFE53E3E),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withValues(alpha: 0.6),
                                        blurRadius: 6.r,
                                        spreadRadius: 1.5.r,
                                      ),
                                    ],
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
      },
    );
  }
}
