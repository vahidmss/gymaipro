import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// آیکون و عنوان‌های مشترک بخش جیم‌آی — کنتراست بالا و خوانایی بهتر.
class AiHubIconBadge extends StatelessWidget {
  const AiHubIconBadge({
    required this.icon,
    required this.gradientColors,
    super.key,
    this.size,
    this.iconSize,
    this.dimmed = false,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final double? size;
  final double? iconSize;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxSize = size ?? 48.w;
    final glyphSize = iconSize ?? 22.sp;
    final colors = dimmed
        ? [
            context.textSecondary.withValues(alpha: isDark ? 0.35 : 0.28),
            context.textSecondary.withValues(alpha: isDark ? 0.22 : 0.18),
          ]
        : gradientColors;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: (dimmed ? context.separatorColor : colors.last).withValues(
            alpha: dimmed ? 0.5 : (isDark ? 0.35 : 0.25),
          ),
        ),
        boxShadow: dimmed
            ? null
            : [
                BoxShadow(
                  color: colors.first.withValues(alpha: isDark ? 0.28 : 0.22),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
      ),
      child: Icon(
        icon,
        color: dimmed
            ? context.textSecondary.withValues(alpha: 0.75)
            : Colors.white,
        size: glyphSize,
      ),
    );
  }
}

class AiHubSectionTitle extends StatelessWidget {
  const AiHubSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 16.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// گرادیان آیکون بر اساس رنگ accent هر فیچر.
List<Color> aiHubAccentGradient(Color accent) {
  return [
    Color.lerp(accent, Colors.white, 0.12)!,
    Color.lerp(accent, Colors.black, 0.18)!,
  ];
}
