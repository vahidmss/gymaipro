import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/services/meal_insight_engine.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MealInsightCard extends StatelessWidget {
  const MealInsightCard({
    required this.insight,
    this.onSuggestionTap,
    super.key,
  });

  final MealInsightResult insight;
  final void Function(MealFoodSuggestion suggestion)? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    if (!insight.shouldShowInsightCard) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _toneColor(insight.tone, isDark);
    final showMessage = insight.cardMessage.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withValues(alpha: isDark ? 0.55 : 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showMessage)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Icon(_toneIcon(insight.tone), color: accent, size: 18.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    insight.cardMessage,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                if (insight.streakDays > 1) ...[
                  SizedBox(width: 8.w),
                  _StreakBadge(days: insight.streakDays),
                ],
              ],
            ),
          if (insight.suggestions.isNotEmpty) ...[
            if (showMessage) SizedBox(height: 10.h),
            if (!showMessage)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text(
                  'افزودن سریع',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              textDirection: TextDirection.rtl,
              children: insight.suggestions.map((s) {
                return ActionChip(
                  label: Text(
                    s.label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                  avatar: Icon(
                    LucideIcons.plus,
                    size: 14.sp,
                    color: isDark ? AppTheme.goldColor : AppTheme.darkGold,
                  ),
                  backgroundColor: context.backgroundColor,
                  side: BorderSide(
                    color: (isDark ? AppTheme.goldColor : AppTheme.darkGold)
                        .withValues(alpha: 0.45),
                  ),
                  onPressed: onSuggestionTap == null
                      ? null
                      : () => onSuggestionTap!(s),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static Color _toneColor(MealInsightTone tone, bool isDark) {
    switch (tone) {
      case MealInsightTone.success:
        return isDark
            ? const Color(0xFF81C784)
            : AppTheme.proteinColor;
      case MealInsightTone.warning:
        return isDark
            ? const Color(0xFFFF8A80)
            : const Color(0xFFB71C1C);
      case MealInsightTone.tip:
      case MealInsightTone.info:
        return isDark ? AppTheme.goldColor : AppTheme.darkGold;
    }
  }

  static IconData _toneIcon(MealInsightTone tone) {
    switch (tone) {
      case MealInsightTone.success:
        return LucideIcons.checkCircle;
      case MealInsightTone.warning:
        return LucideIcons.alertTriangle;
      case MealInsightTone.tip:
        return LucideIcons.sparkles;
      case MealInsightTone.info:
        return LucideIcons.lightbulb;
    }
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.goldColor : AppTheme.darkGold;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flame, size: 12.sp, color: accent),
          SizedBox(width: 3.w),
          Text(
            '$days',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
