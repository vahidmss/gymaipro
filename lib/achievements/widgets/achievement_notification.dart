import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نمایش نوتیفیکیشن زیبا برای دستاوردهای unlock شده
/// طراحی شده شبیه به push notification واقعی
class AchievementNotification {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// نمایش نوتیفیکیشن دستاورد
  static void show(BuildContext context, Achievement achievement) {
    // اگر قبلاً نمایش داده شده، اول ببند
    if (_isShowing) {
      hide();
      // کمی صبر کن تا بسته شود
      Future.delayed(const Duration(milliseconds: 200), () {
        _showNotification(context, achievement);
      });
      return;
    }

    _showNotification(context, achievement);
  }

  static void _showNotification(BuildContext context, Achievement achievement) {
    if (_isShowing) return;

    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    _isShowing = true;

    // ویبره کوتاه برای جلب توجه
    HapticFeedback.lightImpact();

    _overlayEntry = OverlayEntry(
      builder: (context) => _AchievementNotificationWidget(
        achievement: achievement,
        onDismiss: hide,
      ),
    );

    overlayState.insert(_overlayEntry!);

    // خودکار بستن بعد از 4.5 ثانیه
    Future.delayed(const Duration(milliseconds: 4500), () {
      hide();
    });
  }

  /// بستن نوتیفیکیشن
  static void hide() {
    if (!_isShowing || _overlayEntry == null) return;

    _overlayEntry!.remove();
    _overlayEntry = null;
    _isShowing = false;
  }
}

class _AchievementNotificationWidget extends StatefulWidget {
  const _AchievementNotificationWidget({
    required this.achievement,
    required this.onDismiss,
  });

  final Achievement achievement;
  final VoidCallback onDismiss;

  @override
  State<_AchievementNotificationWidget> createState() =>
      _AchievementNotificationWidgetState();
}

class _AchievementNotificationWidgetState
    extends State<_AchievementNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.safeForward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.safeReverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    return Positioned(
      top: safeAreaTop + 8.h,
      left: 12.w,
      right: 12.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _handleDismiss,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _handleDismiss();
                }
              },
              child: Container(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[900]!.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey[800]!.withValues(alpha: 0.5)
                        : Colors.grey[200]!.withValues(alpha: 0.8),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.5 : 0.15,
                      ),
                      blurRadius: 20.r,
                      offset: Offset(0.w, 8.h),
                      spreadRadius: 0.r,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(14.w),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // آیکون دستاورد
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Center(
                              child: Text(
                                widget.achievement.icon,
                                style: TextStyle(fontSize: 24.sp),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // محتوای اصلی
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // عنوان و امتیاز در یک ردیف
                                Row(
                                  textDirection: TextDirection.rtl,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.achievement.title,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: context.textColor,
                                          fontFamily: AppTheme.fontFamily,
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    // امتیاز
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.star,
                                            size: 12.sp,
                                            color: AppTheme.goldColor,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            '+${widget.achievement.points}',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.goldColor,
                                              fontFamily: AppTheme.fontFamily,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                // توضیحات
                                Text(
                                  widget.achievement.description,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: context.textSecondary,
                                    fontFamily: AppTheme.fontFamily,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // دکمه بستن
                          GestureDetector(
                            onTap: _handleDismiss,
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.x,
                                size: 16.sp,
                                color: context.textSecondary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
