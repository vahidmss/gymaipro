import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';

/// وضعیت رقابتی کاربر: فاصله تا رتبه بالاتر + پیشرفت تا لیگ بعد.
class UserRankCard extends StatelessWidget {
  const UserRankCard({
    required this.ranking,
    required this.displayRank,
    this.gapHint,
    this.compact = false,
    super.key,
  });

  final UserRanking ranking;
  final int displayRank;
  final String? gapHint;

  /// وقتی خودت داخل لیست هستی، تکرار رتبه کمتر شود
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final league = ranking.league;
    final next = league.nextLeague;
    final progress = league.getProgressToNextLeague(ranking.totalScore);
    final remaining = next == null
        ? 0
        : (next.minScore - ranking.totalScore).clamp(0, 999999);

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact)
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(league.icon, style: TextStyle(fontSize: 20.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'رتبه ${FormatUtils.toPersianDigits('$displayRank')} · لیگ ${league.nameFa}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                      color: context.textColor,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Text(
                  FormatUtils.toPersianDigits('${ranking.totalScore}'),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp,
                    color: AppTheme.goldColor,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  GamificationLabels.points,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            )
          else
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 18.sp, color: AppTheme.goldColor),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    gapHint ?? 'وضعیت تو در لیگ ${league.nameFa}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                      color: context.textColor,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          if (!compact && gapHint != null) ...[
            SizedBox(height: 8.h),
            Text(
              gapHint!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.goldColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
          if (next != null) ...[
            SizedBox(height: compact ? 10.h : 12.h),
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  league.nameFa,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(league.color),
                  ),
                ),
                Text(
                  remaining == 0
                      ? 'آماده صعود به ${next.nameFa}'
                      : '${FormatUtils.toPersianDigits('$remaining')} امتیاز تا ${next.nameFa}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 7.h,
                    backgroundColor: context.separatorColor,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.goldColor),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
