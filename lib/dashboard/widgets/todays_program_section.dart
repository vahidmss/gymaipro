import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/screens/meal_log_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TodaysProgramSection extends StatefulWidget {
  const TodaysProgramSection({super.key});

  @override
  State<TodaysProgramSection> createState() => _TodaysProgramSectionState();
}

class _TodaysProgramSectionState extends State<TodaysProgramSection> {
  bool _isNavigatingMealLog = false;
  bool _isNavigatingWorkoutLog = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // هدر با عنوان و آیکون چرخ‌دنده
        Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // عنوان با gradient
            Flexible(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [context.textColor, AppTheme.goldColor]
                        : [context.textColor, AppTheme.goldColor],
                  ).createShader(bounds);
                },
                child: Text(
                  '«برنامه امروز من»',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 25.sp,
                    height: 1.611,
                    color: context.textColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // آیکون برنامه امروز
            Icon(LucideIcons.calendar, color: context.textColor, size: 28.sp),
          ],
        ),
        SizedBox(height: 17.h),
        // دکمه‌های ثبت رژیم و تمرین با خط جداکننده
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final horizontalPadding = 16.w; // padding از dashboard_screen

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // خط جداکننده که از کل عرض صفحه رد می‌شود (زیر دکمه‌ها)
                Positioned(
                  top: 20.h,
                  left: -horizontalPadding + 2.w,
                  child: Container(
                    width: screenWidth - 4.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0x33E6B422)
                          : AppTheme.goldColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                // دکمه‌ها (روی خط جداکننده)
                Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // دکمه ثبت رژیم غذایی
                    Flexible(
                      child: _buildActionButton(
                        context,
                        title: 'ثبت رژیم غذایی',
                        iconPath: 'images/diet_icon.png',
                        width: 139.w,
                        isDisabled: _isNavigatingMealLog,
                        onTap: () async {
                          // جلوگیری از کلیک‌های مکرر
                          if (_isNavigatingMealLog) return;

                          WidgetSafetyUtils.safeSetState(this, () {
                            _isNavigatingMealLog = true;
                          });

                          // Navigation فوری - mealPlanId در خود صفحه meal log خوانده می‌شود
                          WidgetSafetyUtils.safeNavigate(
                            context,
                            () => const FoodLogScreen(),
                          );
                          // Reset flag بعد از بسته شدن صفحه
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              WidgetSafetyUtils.safeSetState(this, () {
                                _isNavigatingMealLog = false;
                              });
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 30.w),
                    // دکمه ثبت تمرین
                    Flexible(
                      child: _buildActionButton(
                        context,
                        title: 'ثبت تمرین',
                        iconPath: 'images/workout_icon.png',
                        width: 140.w,
                        isRotated: true,
                        isDisabled: _isNavigatingWorkoutLog,
                        onTap: () async {
                          // جلوگیری از کلیک‌های مکرر
                          if (_isNavigatingWorkoutLog) return;

                          WidgetSafetyUtils.safeSetState(this, () {
                            _isNavigatingWorkoutLog = true;
                          });

                          try {
                            if (!mounted) return;
                            if (context.mounted) {
                              await Navigator.pushNamed(
                                context,
                                '/workout-log',
                              );
                            }
                          } finally {
                            if (mounted) {
                              WidgetSafetyUtils.safeSetState(this, () {
                                _isNavigatingWorkoutLog = false;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required String iconPath,
    required double width,
    required VoidCallback onTap,
    bool isRotated = false,
    bool isDisabled = false,
  }) {
    return AbsorbPointer(
      absorbing: isDisabled,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            constraints: BoxConstraints(
              maxWidth: width,
            ), // برای جلوگیری از overflow
            height: 110.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.lightGoldGradient, AppTheme.goldColor],
              ),
              borderRadius: BorderRadius.circular(15.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // آیکون
                Transform.rotate(
                  angle: isRotated ? -29.66 * 3.14159 / 180 : 0,
                  child: Image.asset(
                    iconPath,
                    width: isRotated ? 60.w : 35.w,
                    height: isRotated ? 60.h : 35.h,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image not found
                      return Icon(
                        title.contains('رژیم')
                            ? Icons.apple
                            : Icons.directions_run,
                        size: isRotated ? 60.sp : 35.sp,
                        color: AppTheme.onGoldColor,
                      );
                    },
                  ),
                ),
                // فاصله متغیر برای هم‌تراز کردن متن‌ها
                SizedBox(height: isRotated ? 2.h : 14.h),
                // متن
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    height: 1.611,
                    color: AppTheme.onGoldColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
