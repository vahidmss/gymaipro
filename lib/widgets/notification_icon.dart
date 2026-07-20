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
  late AnimationController _badgePulseController;
  late AnimationController _bounceController;
  late Animation<double> _badgePulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _badgePulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _badgePulseAnimation = Tween<double>(begin: 1, end: 1.12).animate(
      CurvedAnimation(
        parent: _badgePulseController,
        curve: Curves.easeInOut,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.attachForCurrentUser();
      provider.refreshUnreadCount();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<NotificationProvider>();
    final hasUnread = provider.unreadCount > 0;

    if (hasUnread) {
      _badgePulseController.safeRepeat(reverse: true);
    } else {
      _badgePulseController.safeStop();
      _badgePulseController.safeReset();
    }
  }

  @override
  void dispose() {
    _badgePulseController.dispose();
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

        return GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _badgePulseAnimation,
              _bounceAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: hasUnread
                              ? const Color(0xFFE53E3E).withValues(alpha: 0.45)
                              : context.separatorColor,
                          width: 1.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : context.textColor.withValues(alpha: 0.08),
                            blurRadius: 6.r,
                            offset: Offset(0.w, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        hasUnread ? LucideIcons.bellRing : LucideIcons.bell,
                        color: context.textColor,
                        size: 22.sp,
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: -4.w,
                        top: -4.h,
                        child: Transform.scale(
                          scale: _badgePulseAnimation.value,
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: 18.w,
                              minHeight: 18.h,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: unreadCount > 9 ? 5.w : 4.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53E3E),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: context.cardColor,
                                width: 1.5.w,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
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
      },
    );
  }
}
