import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/dialogs/persian_food_log_date_picker_dialog.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MealLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MealLogAppBar({
    required this.selectedDate,
    required this.onDateSelected,
    this.isFromMealPlan = false,
    this.preloadedFoodLogDates,
    this.preloadedCaloriesByDate,
    super.key,
  });
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final bool isFromMealPlan;
  final Map<DateTime, bool>? preloadedFoodLogDates;
  final Map<DateTime, double>? preloadedCaloriesByDate;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // محاسبه responsive font size برای AppBar بر اساس اندازه واقعی
        // استفاده از نسبت ثابت برای همه دستگاه‌ها
        final baseFontSize = screenWidth > 600 ? 22.0 : 20.0;
        final baseIconSize = screenWidth > 600 ? 30.0 : 28.0;
        final baseActionIconSize = screenWidth > 600 ? 24.0 : 22.0;
        
        // تبدیل به sp برای فونت و اندازه واقعی برای آیکون
        final titleFontSize = baseFontSize.sp;
        final iconSize = baseIconSize.sp;
        final actionIconSize = baseActionIconSize.sp;
        
        return AppBar(
          backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowRight,
              color: AppTheme.goldColor,
              size: iconSize,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            isFromMealPlan ? 'ثبت تغذیه' : 'کالری شماری',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark ? AppTheme.goldColor : context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                LucideIcons.calendar,
                color: AppTheme.goldColor,
                size: actionIconSize,
              ),
              tooltip: 'انتخاب تاریخ',
              onPressed: () async {
                await showDialog<void>(
                  context: context,
                  barrierColor: isDark
                      ? Colors.black.withValues(alpha: 0.7)
                      : AppTheme.lightTextColor.withValues(alpha: 0.5),
                  builder: (context) => PersianFoodLogDatePickerDialog(
                    selectedDate: selectedDate,
                    onDateSelected: onDateSelected,
                    preloadedFoodLogDates: preloadedFoodLogDates,
                    preloadedCaloriesByDate: preloadedCaloriesByDate,
                  ),
                );
              },
            ),
            SizedBox(width: 8.w),
          ],
        );
      },
    );
  }
}
