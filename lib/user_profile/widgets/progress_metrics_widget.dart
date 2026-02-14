import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/utils/score_help_texts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Widget برای نمایش جزئیات امتیازات (Progress Metrics)
class ProgressMetricsWidget extends StatelessWidget {
  const ProgressMetricsWidget({
    required this.breakdown,
    super.key,
  });

  final RankingScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                size: 18.sp,
                color: AppTheme.goldColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'جزئیات امتیازات',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildProgressMetric(
            context,
            'فعالیت روزانه',
            breakdown.dailyActivitiesScore,
            RankingScoreBreakdown.maxDailyActivitiesScore,
            LucideIcons.activity,
            const Color(0xFF00BCD4),
            'امتیاز ۳۰ روز گذشته',
            ScoreHelpTexts.dailyActivities,
          ),
          SizedBox(height: 16.h),
          _buildProgressMetric(
            context,
            'روزهای فعال',
            breakdown.activeDaysScore,
            RankingScoreBreakdown.maxActiveDaysScore,
            LucideIcons.calendarCheck,
            const Color(0xFF9C27B0),
            '${breakdown.activeDays} روز فعال',
            ScoreHelpTexts.activeDays,
          ),
          SizedBox(height: 16.h),
          _buildProgressMetric(
            context,
            'تمرینات',
            breakdown.totalWorkoutsScore,
            RankingScoreBreakdown.maxTotalWorkoutsScore,
            LucideIcons.dumbbell,
            const Color(0xFF4CAF50),
            '${breakdown.totalWorkouts} جلسه',
            ScoreHelpTexts.workouts,
          ),
          SizedBox(height: 16.h),
          _buildProgressMetric(
            context,
            'وعده‌های غذایی',
            breakdown.totalMealsScore,
            RankingScoreBreakdown.maxTotalMealsScore,
            LucideIcons.utensils,
            const Color(0xFF2196F3),
            '${breakdown.totalMeals} وعده',
            ScoreHelpTexts.meals,
          ),
          SizedBox(height: 16.h),
          _buildProgressMetric(
            context,
            'مطالعه مقالات',
            breakdown.articlesReadScore,
            RankingScoreBreakdown.maxArticlesReadScore,
            LucideIcons.bookOpen,
            const Color(0xFFFF9800),
            '${breakdown.articlesReadCount} مقاله',
            ScoreHelpTexts.articlesRead,
          ),
        ],
      ),
    );
  }

  void _showScoreHelp(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(fontFamily: AppTheme.fontFamily)),
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

  Widget _buildProgressMetric(
    BuildContext context,
    String label,
    int score,
    int maxScore,
    IconData icon,
    Color color,
    String subtitle,
    String helpBody,
  ) {
    final progress = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, size: 14.sp, color: color),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          icon: Icon(
                            LucideIcons.helpCircle,
                            size: 16.sp,
                            color: context.textSecondary,
                          ),
                          onPressed: () =>
                              _showScoreHelp(context, label, helpBody),
                          tooltip: 'راهنما',
                        ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '$score / $maxScore',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8.h,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
