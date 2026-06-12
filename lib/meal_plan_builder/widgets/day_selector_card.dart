import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DaySelectorCardMealPlanBuilder extends StatelessWidget {
  const DaySelectorCardMealPlanBuilder({
    required this.selectedDay,
    required this.mealPlan,
    required this.onDaySelected,
    required this.onCopyDay,
    super.key,
  });

  final int selectedDay;
  final MealPlan mealPlan;
  final void Function(int dayIndex) onDaySelected;
  final void Function(int dayIndex) onCopyDay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysFa = [
      'روز ۱',
      'روز ۲',
      'روز ۳',
      'روز ۴',
      'روز ۵',
      'روز ۶',
      'روز ۷',
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.goldGradientColors[0].withValues(alpha: 0.15),
                    context.cardColor,
                    context.goldGradientColors[1].withValues(alpha: 0.1),
                  ],
                ),
          color: isDark ? context.backgroundColor : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(
              alpha: isDark ? 0.3 : 0.5,
            ),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(
                alpha: isDark ? 0.15 : 0.35,
              ),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : AppTheme.lightTextColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 8.h,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, idx) {
              final isSelected = selectedDay == idx;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onDaySelected(idx),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.goldColor
                                  : (isDark
                                      ? AppTheme.goldColor.withValues(alpha: 0.1)
                                      : AppTheme.goldColor.withValues(
                                          alpha: 0.08,
                                        )),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.goldColor
                                    : AppTheme.goldColor.withValues(
                                        alpha: isDark ? 0.3 : 0.4,
                                      ),
                                width: isSelected ? 1.5.w : 1.w,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.goldColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8.r,
                                        offset: Offset(0.w, 2.h),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              daysFa[idx],
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.onGoldColor
                                    : (isDark
                                        ? AppTheme.goldColor
                                        : Colors.black),
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (mealPlan.days[idx].items.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(left: 4.w),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onCopyDay(idx),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                                  width: 1.w,
                                ),
                              ),
                              child: Icon(
                                LucideIcons.copy,
                                color: AppTheme.goldColor,
                                size: 16.sp,
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
        ),
      ),
    );
  }
}

