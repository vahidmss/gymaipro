import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نقطه کانونی Home: فقط شروع تمرین امروز.
class TodaysProgramSection extends StatefulWidget {
  const TodaysProgramSection({super.key});

  @override
  State<TodaysProgramSection> createState() => _TodaysProgramSectionState();
}

class _TodaysProgramSectionState extends State<TodaysProgramSection> {
  bool _isNavigating = false;

  Future<void> _openWorkoutLog() async {
    if (_isNavigating) return;
    WidgetSafetyUtils.safeSetState(this, () => _isNavigating = true);
    try {
      if (!mounted) return;
      await Navigator.pushNamed(context, '/workout-log');
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isNavigating,
      child: Opacity(
        opacity: _isNavigating ? 0.7 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openWorkoutLog,
            borderRadius: BorderRadius.circular(20.r),
            child: Ink(
              height: 196.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: context.separatorColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'images/log.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.2),
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: context.surfaceElevated,
                          child: Icon(
                            LucideIcons.dumbbell,
                            size: 48.sp,
                            color: context.textSecondary,
                          ),
                        );
                      },
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x22000000),
                            Color(0x33000000),
                            Color(0xF2000000),
                          ],
                          stops: [0, 0.4, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18.w,
                      right: 18.w,
                      bottom: 16.h,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'برنامه امروز',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.sp,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'شروع تمرین',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 23.sp,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  'ثبت ست‌ها، وزنه و پیشرفت جلسه',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.5.sp,
                                    color: Colors.white.withValues(alpha: 0.82),
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: context.actionFill,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 14.r,
                                  offset: Offset(0, 5.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              LucideIcons.play,
                              color: context.actionOnFill,
                              size: 22.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
