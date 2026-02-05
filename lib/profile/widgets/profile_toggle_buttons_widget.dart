import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// ویجت دکمه‌های تغییر حالت نمایش/ویرایش پروفایل
class ProfileToggleButtonsWidget extends StatelessWidget {
  const ProfileToggleButtonsWidget({
    required this.isEditing,
    required this.onEditPressed,
    required this.onOverviewPressed,
    super.key,
  });

  final bool isEditing;
  final VoidCallback onEditPressed;
  final VoidCallback onOverviewPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onEditPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEditing
                    ? AppTheme.goldColor
                    : context.cardColor,
                foregroundColor: isEditing
                    ? AppTheme.onGoldColor
                    : context.textColor,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: isEditing
                        ? AppTheme.goldColor
                        : AppTheme.goldColor.withValues(alpha: 0.3),
                    width: isEditing ? 1.5 : 1,
                  ),
                ),
                elevation: isEditing ? 4 : 0,
                shadowColor: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.2 : 0.3,
                ),
              ),
              child: Text(
                'ویرایش',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: onOverviewPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: !isEditing
                    ? AppTheme.goldColor
                    : context.cardColor,
                foregroundColor: !isEditing
                    ? AppTheme.onGoldColor
                    : context.textColor,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: !isEditing
                        ? AppTheme.goldColor
                        : AppTheme.goldColor.withValues(alpha: 0.3),
                    width: !isEditing ? 1.5 : 1,
                  ),
                ),
                elevation: !isEditing ? 4 : 0,
                shadowColor: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.2 : 0.3,
                ),
              ),
              child: Text(
                'نمای کلی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

