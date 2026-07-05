import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/services/meal_insight_engine.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
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

    final accent = _toneColor(context, insight.tone);
    final showMessage = insight.cardMessage.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: MealLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accent.withValues(
            alpha: MealLogColors.isDark(context) ? 0.55 : 0.65,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
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
                      color: MealLogColors.primaryText(context),
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
                  style: MealLogTypography.caption(
                    context,
                    fontWeight: FontWeight.w800,
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
                      color: MealLogColors.primaryText(context),
                    ),
                  ),
                  avatar: Icon(
                    LucideIcons.plus,
                    size: 14.sp,
                    color: MealLogColors.accent(context),
                  ),
                  backgroundColor: MealLogColors.chipFill(
                    context,
                    selected: false,
                  ),
                  side: BorderSide(
                    color: MealLogColors.chipBorder(context, selected: false),
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

  static Color _toneColor(BuildContext context, MealInsightTone tone) {
    switch (tone) {
      case MealInsightTone.success:
        return MealLogColors.successText(context);
      case MealInsightTone.warning:
        return MealLogColors.errorText(context);
      case MealInsightTone.tip:
      case MealInsightTone.info:
        return MealLogColors.accent(context);
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
    final accent = MealLogColors.accent(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: MealLogColors.chipFill(context, selected: true),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: MealLogColors.chipBorder(context, selected: true),
        ),
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
              color: MealLogColors.primaryText(context),
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
