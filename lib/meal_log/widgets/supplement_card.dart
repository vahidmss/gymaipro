import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/logged_supplement.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SupplementCard extends StatelessWidget {
  const SupplementCard({
    required this.supplement,
    required this.index,
    super.key,
    this.isFromPlan = false,
    this.followedPlan = false,
    this.onToggleFollowedPlan,
  });
  final LoggedSupplement supplement;
  final int index;
  final bool isFromPlan;
  final bool followedPlan;
  final ValueChanged<bool?>? onToggleFollowedPlan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDrug = supplement.supplementType == 'دارو';
    final primaryColor = isDrug ? Colors.red[600]! : Colors.purple[600]!;
    final borderColor = isDrug
        ? Colors.red[700]!.withValues(alpha: isDark ? 0.4 : 0.3)
        : Colors.purple[700]!.withValues(alpha: isDark ? 0.4 : 0.3);

    return LayoutBuilder(
      builder: (context, constraints) {
        // استفاده از MediaQuery برای اندازه واقعی صفحه
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // محاسبه responsive margin و padding بر اساس اندازه واقعی
        final verticalMargin = screenWidth > 600 ? 8.0 : 6.0;
        final containerMargin = EdgeInsets.symmetric(vertical: verticalMargin);
        
        final containerPadding = screenWidth > 600 ? 24.0 : 20.0;
        final borderRadius = screenWidth > 600 ? 24.0 : 20.0;
        
        return Container(
          margin: containerMargin,
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
            color: isDark ? context.cardColor : null,
            borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 2),
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
      child: Padding(
        padding: EdgeInsets.all(containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    isDrug ? LucideIcons.pill : LucideIcons.flaskConical,
                    color: primaryColor,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${supplement.name}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${supplement.amount} ${supplement.unit}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: context.textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFromPlan) ...[
                  Checkbox(
                    value: followedPlan,
                    onChanged: onToggleFollowedPlan,
                    activeColor: primaryColor,
                  ),
                ],
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(LucideIcons.clock, color: primaryColor, size: 16.sp),
                SizedBox(width: 6.w),
                Text(
                  supplement.time ?? '',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    color: context.textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            if ((supplement.note ?? '').isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                supplement.note!,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: context.textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
        );
      },
    );
  }
}
