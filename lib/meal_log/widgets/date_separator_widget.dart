import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DateSeparatorWidget extends StatelessWidget {
  const DateSeparatorWidget({
    required this.selectedDate,
    this.onTap,
    super.key,
  });

  final DateTime selectedDate;
  /// اگر مقدار داشته باشد، با کلیک روی تاریخ همان تقویم (دیالوگ انتخاب تاریخ) باز می‌شود.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateText = MealLogUtils.getPersianFormattedDate(selectedDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // محاسبه responsive padding بر اساس اندازه واقعی
        final horizontalPadding = screenWidth > 600
            ? (screenWidth * 0.04).clamp(16.0, 24.0)
            : (screenWidth * 0.043).clamp(12.0, 20.0);
        final containerHorizontalPadding = screenWidth > 600 ? 20.0 : 16.0;
        final containerVerticalPadding = screenWidth > 600 ? 10.0 : 8.0;
        final containerPadding = EdgeInsets.symmetric(
          horizontal: containerHorizontalPadding,
          vertical: containerVerticalPadding,
        );
        final borderRadius = screenWidth > 600 ? 24.0 : 20.0;
        
        return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GestureDetector(
            onTap: onTap,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: containerPadding,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.goldColor.withValues(alpha: 0.1),
                            AppTheme.goldColor.withValues(alpha: 0.05),
                          ],
                        ),
                  color: isDark ? AppTheme.darkCardColor : null,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 14.sp,
                      color: AppTheme.goldColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      dateText,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
        );
      },
    );
  }
}

