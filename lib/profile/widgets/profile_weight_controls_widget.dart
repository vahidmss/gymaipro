import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileWeightControlsWidget extends StatelessWidget {
  const ProfileWeightControlsWidget({
    required this.onAddWeightPressed,
    required this.onWeightHistoryPressed,
    super.key,
  });
  final VoidCallback onAddWeightPressed;
  final VoidCallback onWeightHistoryPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: AppTheme.goldColor,
              borderRadius: BorderRadius.circular(10.r),
              child: InkWell(
                onTap: onAddWeightPressed,
                borderRadius: BorderRadius.circular(10.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 15.sp,
                        color: AppTheme.onGoldColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'ثبت وزن',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppTheme.onGoldColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Material(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.lightButtonBackground,
              borderRadius: BorderRadius.circular(10.r),
              child: InkWell(
                onTap: onWeightHistoryPressed,
                borderRadius: BorderRadius.circular(10.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 11.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.history,
                        size: 15.sp,
                        color: AppTheme.goldColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'تاریخچه',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
