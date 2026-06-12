import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/services/models/point_history.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

class MyPointsScreen extends StatefulWidget {
  const MyPointsScreen({super.key});

  @override
  State<MyPointsScreen> createState() => _MyPointsScreenState();
}

class _MyPointsScreenState extends State<MyPointsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedFilter = 'all'; // all, achievements, other

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () async {
            // بارگذاری مجدد دستاوردها از دیتابیس (پاک کردن cache)
            final achievementService = Provider.of<AchievementService>(context, listen: false);
            await achievementService.refreshFromDatabase();
            // بارگذاری مجدد امتیازات از دیتابیس
            final scoreService = Provider.of<ScoreService>(context, listen: false);
            await scoreService.loadFromDatabase();
          },
          color: AppTheme.goldColor,
          child: Consumer2<ScoreService, AchievementService>(
            builder: (context, scoreService, achievementService, _) {
              final history = scoreService.sortedHistory;
              final filteredHistory = _filterHistory(history);

              return ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // کارت امتیاز کل
                  _buildTotalPointsCard(context, scoreService, isDark),
                  SizedBox(height: 16.h),

                  // آمار کلی
                  _buildStatsSection(
                    context,
                    scoreService,
                    achievementService,
                    isDark,
                  ),
                  SizedBox(height: 16.h),

                  // فیلترها
                  _buildFilters(context, isDark),
                  SizedBox(height: 16.h),

                  // تاریخچه
                  if (filteredHistory.isEmpty)
                    _buildEmptyState(context, isDark)
                  else
                    ...filteredHistory.map((item) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildHistoryItem(context, item, isDark),
                        )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPointsCard(
    BuildContext context,
    ScoreService scoreService,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(
            alpha: isDark ? 0.3 : 0.4,
          ),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(
              alpha: isDark ? 0.1 : 0.15,
            ),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.05,
            ),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.25),
                  AppTheme.goldColor.withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1.5.w,
              ),
            ),
            child: Icon(
              LucideIcons.award,
              color: AppTheme.goldColor,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'امتیاز کل',
            style: TextStyle(
              fontSize: 13.sp,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatScore(scoreService.score),
              style: TextStyle(
                fontSize: 42.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldColor,
                fontFamily: AppTheme.fontFamily,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    ScoreService scoreService,
    AchievementService achievementService,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'دستاوردها',
              '${scoreService.unlockedAchievementsCount}',
              LucideIcons.trophy,
              isDark,
            ),
          ),
          Container(
            width: 1.5.w,
            height: 50.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.goldColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'امتیاز از دستاوردها',
              _formatScore(scoreService.achievementPoints),
              LucideIcons.star,
              isDark,
            ),
          ),
          Container(
            width: 1.5.w,
            height: 50.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.goldColor.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'کل فعالیت‌ها',
              '${scoreService.history.length}',
              LucideIcons.activity,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldColor.withValues(alpha: 0.2),
                AppTheme.goldColor.withValues(alpha: 0.15),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: AppTheme.goldColor,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: context.textColor,
            fontFamily: AppTheme.fontFamily,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: context.textSecondary,
            fontFamily: AppTheme.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, bool isDark) {
    return Row(
      children: [
        _buildFilterChip(
          context,
          'همه',
          'all',
          isDark,
        ),
        SizedBox(width: 8.w),
        _buildFilterChip(
          context,
          'دستاوردها',
          'achievements',
          isDark,
        ),
        SizedBox(width: 8.w),
        _buildFilterChip(
          context,
          'سایر',
          'other',
          isDark,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.25),
                      AppTheme.goldColor.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            color: isSelected ? null : context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.goldColor.withValues(alpha: 0.4)
                  : (isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor),
              width: isSelected ? 1.5.w : 1.w,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      blurRadius: 6.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? (isDark
                      ? AppTheme.goldColor
                      : AppTheme.lightTextColor)
                  : context.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.sp,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    PointHistory item,
    bool isDark,
  ) {
    final jDate = Jalali.fromDateTime(item.earnedAt);
    final monthNames = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    final dateStr = '${jDate.day} ${monthNames[jDate.month - 1]}';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // آیکون
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.2),
                  AppTheme.goldColor.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: Center(
              child: Text(
                item.sourceIcon,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // اطلاعات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.sourceTitle,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      LucideIcons.tag,
                      size: 14.sp,
                      color: context.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        item.source.displayName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textSecondary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      LucideIcons.calendar,
                      size: 14.sp,
                      color: context.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.textSecondary,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // امتیاز
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.25),
                  AppTheme.goldColor.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.4),
                width: 1.2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  blurRadius: 6.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.star,
                  size: 16.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  '+${item.points}',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldColor,
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.15),
                  AppTheme.goldColor.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.award,
              size: 64.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'هنوز امتیازی کسب نکرده‌اید',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'با انجام فعالیت‌ها و باز کردن دستاوردها امتیاز کسب کنید',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.textSecondary,
              fontFamily: AppTheme.fontFamily,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  List<PointHistory> _filterHistory(List<PointHistory> history) {
    switch (_selectedFilter) {
      case 'achievements':
        return history
            .where((h) => h.source == PointSource.achievement)
            .toList();
      case 'other':
        return history
            .where((h) => h.source != PointSource.achievement)
            .toList();
      default:
        return history;
    }
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}
