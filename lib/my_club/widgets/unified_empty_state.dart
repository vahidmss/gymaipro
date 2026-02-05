import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// ویجت یکپارچه برای نمایش وضعیت خالی در بخش باشگاه من
/// طراحی حرفه‌ای و سازگار با تم لایت و دارک
class UnifiedEmptyState extends StatelessWidget {
  const UnifiedEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.actionText,
    this.onAction,
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // آیکون با دکوریشن حرفه‌ای
            Container(
              width: 90.w,
              height: 90.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppTheme.goldColor.withValues(alpha: 0.2),
                          AppTheme.goldColor.withValues(alpha: 0.1),
                        ]
                      : [
                          AppTheme.lightGradientStart.withValues(alpha: 0.3),
                          AppTheme.lightGradientEnd.withValues(alpha: 0.15),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15),
                    blurRadius: 20.r,
                    spreadRadius: 2,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 40.sp,
                    color: AppTheme.goldColor.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // عنوان
            Text(
              title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: context.textColor,
                fontFamily: AppTheme.fontFamily,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            // توضیحات
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: context.textSecondary,
                  fontFamily: AppTheme.fontFamily,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // دکمه اختیاری
            if (actionText != null && onAction != null) ...[
              SizedBox(height: 28.h),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.goldColor,
                      AppTheme.darkGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(
                    actionIcon ?? LucideIcons.plus,
                    size: 20.sp,
                  ),
                  label: Text(
                    actionText!,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.onGoldColor,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: 28.w,
                      vertical: 14.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

