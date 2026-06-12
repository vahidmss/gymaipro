import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class PlanNameCardMealPlanBuilder extends StatelessWidget {
  const PlanNameCardMealPlanBuilder({
    required this.controller,
    this.readOnly = false,
    super.key,
  });

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: DecoratedBox(
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
                  ? AppTheme.veryDarkBackground.withValues(alpha: 0.5)
                  : AppTheme.lightTextColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            color: isDark ? AppTheme.goldColor : AppTheme.veryDarkBackground,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'نام برنامه رژیمی خود را وارد کنید...',
            hintStyle: TextStyle(
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.6)
                  : AppTheme.veryDarkBackground.withValues(alpha: 0.5),
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            labelText: 'نام برنامه',
            labelStyle: TextStyle(
              color: isDark ? AppTheme.goldColor : AppTheme.veryDarkBackground,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 16.h,
            ),
          ),
        ),
      ),
    );
  }
}

