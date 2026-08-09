import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/services/meal_insight_engine.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// افزودن سریع + پیام کوتاه غیرتکراری (اگر باشد).
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
    final showSuggestions = insight.suggestions.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(top: 6.h, bottom: 2.h),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: MealLogColors.sectionBackground(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: MealLogColors.chipBorder(context, selected: false),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showMessage)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Icon(_toneIcon(insight.tone), color: accent, size: 15.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    insight.cardMessage,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: MealLogColors.primaryText(context),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (insight.streakDays > 1) ...[
                  SizedBox(width: 6.w),
                  _StreakBadge(days: insight.streakDays),
                ],
              ],
            ),
          if (showSuggestions) ...[
            if (showMessage) SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  'افزودن سریع',
                  style: MealLogTypography.caption(
                    context,
                    fontWeight: FontWeight.w800,
                  ).copyWith(fontSize: 11.sp),
                  textDirection: TextDirection.rtl,
                ),
                const Spacer(),
                if (!showMessage && insight.streakDays > 1)
                  _StreakBadge(days: insight.streakDays),
              ],
            ),
            SizedBox(height: 8.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: insight.suggestions.map((s) {
                  return Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: ActionChip(
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
                        size: 13.sp,
                        color: MealLogColors.accent(context),
                      ),
                      backgroundColor: MealLogColors.chipFill(
                        context,
                        selected: false,
                      ),
                      side: BorderSide(
                        color: MealLogColors.chipBorder(
                          context,
                          selected: false,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: onSuggestionTap == null
                          ? null
                          : () => onSuggestionTap!(s),
                    ),
                  );
                }).toList(),
              ),
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
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
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
          Icon(LucideIcons.flame, size: 11.sp, color: accent),
          SizedBox(width: 3.w),
          Text(
            MealLogUtils.convertToPersianNumbers('$days'),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: MealLogColors.primaryText(context),
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
