import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SessionSelector extends StatelessWidget {
  const SessionSelector({
    required this.selectedPlan,
    required this.selectedSession,
    required this.onSessionSelected,
    super.key,
  });
  final MealPlan? selectedPlan;
  final int? selectedSession;
  final void Function(int) onSessionSelected;

  @override
  Widget build(BuildContext context) {
    if (selectedPlan == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // محاسبه responsive margin و padding بر اساس اندازه واقعی
        final horizontalMargin = screenWidth > 600
            ? (screenWidth * 0.05).clamp(20.0, 40.0)
            : (screenWidth * 0.053).clamp(16.0, 24.0);
        final containerMargin = EdgeInsets.symmetric(horizontal: horizontalMargin);
        
        final containerPadding = screenWidth > 600 ? 24.0 : 20.0;
        final borderRadius = screenWidth > 600 ? 24.0 : 20.0;
        
        return Container(
          margin: containerMargin,
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  context.cardColor,
                  context.backgroundColor.withValues(alpha: 0.8),
                  context.cardColor,
                ]
              : [
                  context.goldGradientColors[0].withValues(alpha: 0.15),
                  context.cardColor,
                  context.goldGradientColors[1].withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.lightTextColor.withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
            blurRadius: 10.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.2),
                      AppTheme.darkGold.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    width: 1.5.w,
                  ),
                ),
                child: Icon(
                  LucideIcons.utensils,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'جلسه رژیم را انتخاب کنید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedPlan!.days.length,
              itemBuilder: (context, index) {
                final isSelected = selectedSession == index;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () => onSessionSelected(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.goldColor.withValues(alpha: 0.2),
                                    AppTheme.darkGold.withValues(alpha: 0.1),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.goldColor.withValues(alpha: 0.1),
                                    AppTheme.darkGold.withValues(alpha: 0.05),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.goldColor
                                : AppTheme.goldColor.withValues(alpha: 0.3),
                            width: 1.5.w,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 8.r,
                                    offset: Offset(0.w, 2.h),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'جلسه ${index + 1}',
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.onGoldColor
                                : AppTheme.goldColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // نمایش کامنت روز (اگر وجود داشته باشد)
          if (selectedSession != null) ...[
            const SizedBox(height: 16),
            _buildDayComment(isDark),
          ],
        ],
      ),
        );
      },
    );
  }

  Widget _buildDayComment(bool isDark) {
    if (selectedPlan == null || selectedSession == null) {
      return const SizedBox.shrink();
    }

    try {
      final planDay = selectedPlan!.days.firstWhere(
        (d) => d.dayOfWeek == selectedSession,
      );

      if (planDay.comment == null || planDay.comment!.isEmpty) {
        return const SizedBox.shrink();
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: AppTheme.goldColor,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              planDay.comment!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.9)
                    : AppTheme.lightTextColor,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
