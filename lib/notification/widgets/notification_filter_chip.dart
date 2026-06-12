import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class NotificationFilterChip extends StatelessWidget {
  const NotificationFilterChip({
    required this.label, required this.isSelected, super.key,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor,
                    AppTheme.darkGold,
                  ],
                )
              : null,
          color: isSelected ? null : context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.goldColor
                : AppTheme.goldColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5.w : 1.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0.w, 2.h),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? AppTheme.onGoldColor : AppTheme.goldColor,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: isSelected
                    ? AppTheme.onGoldColor
                    : context.textColor,
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

