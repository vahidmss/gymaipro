import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/utils/score_help_texts.dart';
import 'package:gymaipro/ranking/widgets/league_badge.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// بخش رتبه‌بندی و تفکیک امتیاز در پروفایل (ورزشکار) — با پراگرس بار شیک
class ProfileRankingSection extends StatelessWidget {
  const ProfileRankingSection({
    required this.ranking,
    required this.breakdown,
    this.isOwnProfile = true,
    this.onViewLeaderboard,
    super.key,
  });

  final UserRanking? ranking;
  final RankingScoreBreakdown? breakdown;
  final bool isOwnProfile;
  final VoidCallback? onViewLeaderboard;

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ranking == null && breakdown == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final league = ranking != null
        ? League.getLeagueByScore(ranking!.totalScore)
        : (breakdown != null
              ? League.getLeagueByScore(breakdown!.totalScore)
              : null);
    if (league == null) return const SizedBox.shrink();

    final totalScore = ranking?.totalScore ?? breakdown?.totalScore ?? 0;
    final progress = league.getProgressToNextLeague(totalScore);
    final nextLeague = league.nextLeague;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color(league.color).withValues(alpha: 0.18),
                  context.backgroundColor,
                ]
              : [
                  Color(league.color).withValues(alpha: 0.12),
                  context.cardColor,
                  Color(league.color).withValues(alpha: 0.06),
                ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Color(league.color).withValues(alpha: isDark ? 0.5 : 0.6),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(league.color).withValues(alpha: isDark ? 0.2 : 0.3),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
            spreadRadius: 1.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // هدر: لیگ، رتبه، امتیاز کل
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
            child: Row(
              children: [
                LeagueBadge(league: league, size: 44),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwnProfile ? 'رتبه من' : 'رتبه',
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
                            '#${ranking?.leagueRank ?? '?'}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Color(league.color),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'در لیگ ${league.nameFa}',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 15.sp,
                              color: context.textColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.star,
                            color: Color(league.color),
                            size: 18.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${_formatNumber(totalScore)} امتیاز',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
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
          ),
          // پراگرس به لیگ بعدی
          if (nextLeague != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        league.nameFa,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.sp,
                          color: Color(league.color),
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
                      backgroundColor: context.textSecondary.withValues(
                        alpha: 0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(league.color),
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    nextLeague.maxScore == null
                        ? 'در بالاترین لیگ'
                        : '${_formatNumber((nextLeague.minScore - totalScore).clamp(0, 999999))} امتیاز تا ${nextLeague.nameFa}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
          // تفکیک امتیاز: چطور این امتیاز رو گرفتم؟
          if (breakdown != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.pieChart,
                    color: Color(league.color),
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isOwnProfile
                        ? 'چطور این امتیاز رو گرفتم؟'
                        : 'چطور این امتیاز رو گرفته؟',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: Column(
                children: [
                  _buildProgressRow(
                    context,
                    icon: LucideIcons.flame,
                    label: 'زنجیره فعلی',
                    value: breakdown!.currentStreak,
                    sub: 'روز',
                    score: breakdown!.currentStreakScore,
                    maxScore: RankingScoreBreakdown.maxCurrentStreakScore,
                    color: league.color,
                    helpBody: ScoreHelpTexts.currentStreak,
                  ),
                  SizedBox(height: 12.h),
                  _buildProgressRow(
                    context,
                    icon: LucideIcons.trophy,
                    label: 'طولانی‌ترین زنجیره',
                    value: breakdown!.longestStreak,
                    sub: 'روز',
                    score: breakdown!.longestStreakScore,
                    maxScore: RankingScoreBreakdown.maxLongestStreakScore,
                    color: league.color,
                    helpBody: ScoreHelpTexts.longestStreak,
                  ),
                  SizedBox(height: 12.h),
                  _buildProgressRow(
                    context,
                    icon: LucideIcons.calendarCheck,
                    label: 'روزهای فعال (۳۰ روز)',
                    value: breakdown!.activeDays,
                    sub: 'روز',
                    score: breakdown!.activeDaysScore,
                    maxScore: RankingScoreBreakdown.maxActiveDaysScore,
                    color: league.color,
                    helpBody: ScoreHelpTexts.activeDays,
                  ),
                  SizedBox(height: 12.h),
                  _buildProgressRow(
                    context,
                    icon: LucideIcons.dumbbell,
                    label: 'تمرینات ثبت‌شده',
                    value: breakdown!.totalWorkouts,
                    sub: 'تمرین',
                    score: breakdown!.totalWorkoutsScore,
                    maxScore: RankingScoreBreakdown.maxTotalWorkoutsScore,
                    color: league.color,
                    helpBody: ScoreHelpTexts.workouts,
                  ),
                  SizedBox(height: 12.h),
                  _buildProgressRow(
                    context,
                    icon: LucideIcons.utensilsCrossed,
                    label: 'وعده‌های ثبت‌شده',
                    value: breakdown!.totalMeals,
                    sub: 'وعده',
                    score: breakdown!.totalMealsScore,
                    maxScore: RankingScoreBreakdown.maxTotalMealsScore,
                    color: league.color,
                    helpBody: ScoreHelpTexts.meals,
                  ),
                  SizedBox(height: 12.h),
                  _buildProgressRow(
                    context,
                    icon: LucideIcons.activity,
                    label: 'فعالیت روزانه (۳۰ روز)',
                    value: breakdown!.dailyActivitiesScore,
                    sub: 'امتیاز',
                    score: breakdown!.dailyActivitiesScore,
                    maxScore: RankingScoreBreakdown.maxDailyActivitiesScore,
                    color: league.color,
                    helpBody: ScoreHelpTexts.dailyActivities,
                  ),
                  SizedBox(height: 12.h),
                  _buildProgressRow(
                    context,
                    icon: LucideIcons.bookOpen,
                    label: 'مطالعه مقالات',
                    value: breakdown!.articlesReadCount,
                    sub: 'مقاله',
                    score: breakdown!.articlesReadScore,
                    maxScore: RankingScoreBreakdown.maxArticlesReadScore,
                    color: league.color,
                    helpBody: ScoreHelpTexts.articlesRead,
                  ),
                ],
              ),
            ),
            if (isOwnProfile && onViewLeaderboard != null) ...[
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewLeaderboard,
                    icon: Icon(
                      LucideIcons.trophy,
                      size: 18.sp,
                      color: Color(league.color),
                    ),
                    label: Text(
                      'مشاهده جدول رتبه‌بندی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(league.color),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Color(league.color).withValues(alpha: 0.7),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              SizedBox(height: 20.h),
          ],
        ],
      ),
    );
  }

  static void _showHelp(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: AppTheme.fontFamily)),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required String sub,
    required int score,
    required int maxScore,
    required int color,
    String? helpBody,
  }) {
    final progress = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: Color(color), size: 16.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (helpBody != null && helpBody.isNotEmpty) ...[
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: () => _showHelp(context, label, helpBody),
                      child: Icon(
                        LucideIcons.helpCircle,
                        size: 14.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '$value $sub · ${_formatNumber(score)} امتیاز',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: context.textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8.h,
            backgroundColor: context.textSecondary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(Color(color)),
          ),
        ),
      ],
    );
  }
}
