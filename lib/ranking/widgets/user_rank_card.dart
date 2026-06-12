import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/widgets/league_badge.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// کارت رتبه کاربر زیر لیست Leaderboard — طراحی دارک/لایت
class UserRankCard extends StatelessWidget {
  const UserRankCard({
    required this.ranking,
    required this.leagueId,
    super.key,
  });

  final UserRanking ranking;
  final String leagueId;

  @override
  Widget build(BuildContext context) {
    final league = ranking.league;
    final progress = league.getProgressToNextLeague(ranking.totalScore);
    final nextLeague = league.nextLeague;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.12),
            AppTheme.goldColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              LeagueBadge(league: league, size: 36),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رتبه شما',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          '#${ranking.leagueRank ?? '?'}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'در لیگ ${league.nameFa}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.sp,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (nextLeague != null) ...[
            SizedBox(height: 18.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  league.nameFa,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  nextLeague.nameFa,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10.h,
                backgroundColor: context.textSecondary.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.goldColor,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${(nextLeague.minScore - ranking.totalScore).clamp(0, 999999).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} امتیاز تا ${nextLeague.nameFa}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                color: context.textSecondary,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.star, color: AppTheme.goldColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'امتیاز کل: ${ranking.totalScore.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
