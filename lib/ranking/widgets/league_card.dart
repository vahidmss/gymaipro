import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_remote_image.dart';

/// کارت انتخاب لیگ با تصویر
class LeagueCard extends StatelessWidget {
  const LeagueCard({
    required this.league,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final League league;
  final bool isSelected;
  final VoidCallback onTap;

  /// مسیر تصویر لیگ در assets
  static String imagePathForLeague(League league) {
    return 'images/${league.id}.png';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.15)
                    : AppTheme.lightGradientStart.withValues(alpha: 0.6))
              : (isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.goldColor
                : (isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.goldColor.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // تصویر لیگ
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: AppRemoteImage(
                path: imagePathForLeague(league),
                width: 56.w,
                height: 56.w,
                fit: BoxFit.contain,
                errorWidget: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: Color(league.color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(league.icon, style: TextStyle(fontSize: 28.sp)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              league.nameFa,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? AppTheme.goldColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.lightTextColor),
                fontFamily: AppTheme.fontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
