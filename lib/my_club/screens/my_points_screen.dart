import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/achievements/screens/achievements_screen.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/services/models/point_history.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
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

  String _selectedFilter = 'all'; // all, stars, points
  bool _guideExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshData();
    });
  }

  Future<void> _refreshData({bool force = false}) async {
    final achievementService =
        Provider.of<AchievementService>(context, listen: false);
    final scoreService = Provider.of<ScoreService>(context, listen: false);

    await Future.wait<void>([
      achievementService.refreshFromDatabase(force: force),
      scoreService.loadFromDatabase(force: force),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () => _refreshData(force: true),
          color: AppTheme.goldColor,
          child: Consumer2<ScoreService, AchievementService>(
            builder: (context, scoreService, achievementService, _) {
              if (scoreService.isLoading &&
                  scoreService.activityEntries.isEmpty &&
                  scoreService.rankingScore == 0) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80.h),
                    child: const CircularProgressIndicator(
                      color: AppTheme.goldColor,
                      strokeWidth: 3,
                    ),
                  ),
                );
              }

              if (scoreService.lastLoadError != null &&
                  scoreService.activityEntries.isEmpty &&
                  scoreService.rankingScore == 0) {
                return _buildErrorState(context, isDark, scoreService);
              }

              final activityEntries = scoreService.sortedActivityEntries;
              final starEntries = _sortedStarAchievements(
                achievementService.unlockedAchievements,
              );
              final listChildren = _buildFilteredList(
                context,
                isDark,
                activityEntries: activityEntries,
                starEntries: starEntries,
              );
              final hasAnyContent =
                  activityEntries.isNotEmpty || starEntries.isNotEmpty;

              return ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _buildLegendCard(context, isDark),
                  SizedBox(height: 14.h),
                  _buildTotalPointsCard(
                    context,
                    scoreService,
                    achievementService,
                    isDark,
                  ),
                  SizedBox(height: 16.h),

                  _buildStatsSection(
                    context,
                    scoreService,
                    achievementService,
                    isDark,
                  ),
                  SizedBox(height: 16.h),

                  _buildFilters(context, isDark),
                  SizedBox(height: 16.h),

                  if (listChildren.isEmpty)
                    _buildEmptyState(
                      context,
                      isDark,
                      hasAnyContent: hasAnyContent,
                    )
                  else
                    ...listChildren,
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
    AchievementService achievementService,
    bool isDark,
  ) {
    final showStars = _selectedFilter == 'stars';
    final showPoints = _selectedFilter == 'points';
    final showBoth = _selectedFilter == 'all';

    final primaryValue = showStars
        ? achievementService.totalStars
        : scoreService.rankingScore;
    final primaryLabel = showStars
        ? '${GamificationLabels.stars} شما'
        : '${GamificationLabels.points} شما';
    final primaryIcon = showStars
        ? GamificationLabels.starsIcon
        : GamificationLabels.pointsIcon;

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
            color: AppTheme.veryDarkBackground.withValues(
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
              primaryIcon,
              color: AppTheme.goldColor,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            primaryLabel,
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
              _formatScore(primaryValue),
              style: TextStyle(
                fontSize: 42.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldColor,
                fontFamily: AppTheme.fontFamily,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          if (showBoth)
            Text(
              '${GamificationLabels.points}: ${FormatUtils.toPersianDigits('${scoreService.rankingScore}')} · ${GamificationLabels.stars}: ${FormatUtils.toPersianDigits('${achievementService.totalStars}')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: context.textSecondary,
                fontFamily: AppTheme.fontFamily,
                height: 1.4,
              ),
            )
          else if (showPoints)
            Text(
              'برای لیگ و جدول نفرات برتر — از فعالیت در اپ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: context.textSecondary,
                fontFamily: AppTheme.fontFamily,
                height: 1.4,
              ),
            )
          else
            Text(
              'از باز کردن دستاوردها — در تب دستاوردها',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: context.textSecondary,
                fontFamily: AppTheme.fontFamily,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendCard(BuildContext context, bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.goldColor.withValues(alpha: 0.22)
              : AppTheme.lightDividerColor.withValues(alpha: 0.8),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.veryDarkBackground.withValues(
              alpha: isDark ? 0.15 : 0.04,
            ),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _guideExpanded = !_guideExpanded),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16.r),
                bottom: _guideExpanded ? Radius.zero : Radius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        LucideIcons.lightbulb,
                        size: 18.sp,
                        color: AppTheme.goldColor,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'راهنما',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                    ),
                    Icon(
                      _guideExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 20.sp,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_guideExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: context.separatorColor.withValues(alpha: 0.6),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _guideItem(
                    context,
                    isDark: isDark,
                    icon: GamificationLabels.pointsIcon,
                    title: GamificationLabels.points,
                    bullets: const [
                      'با تمرین، ثبت وعده، استریک و مطالعه مقاله',
                      'در لیگ و جدول «نفرات برتر» حساب می‌شود',
                      'فیلتر «امتیاز» فقط همین بخش را نشان می‌دهد',
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _guideItem(
                    context,
                    isDark: isDark,
                    icon: GamificationLabels.starsIcon,
                    title: GamificationLabels.stars,
                    bullets: const [
                      'فقط با باز کردن دستاوردها',
                      'جمع ستاره‌ها در پروفایل دستاوردهاست',
                      'به امتیاز لیگ اضافه نمی‌شود',
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(
                        alpha: isDark ? 0.08 : 0.06,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.layers,
                          size: 16.sp,
                          color: AppTheme.goldColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'فیلتر بالای لیست: «همه» هر دو را با هم، «${GamificationLabels.stars}» یا «${GamificationLabels.points}» جداگانه',
                            style: TextStyle(
                              fontSize: 11.sp,
                              height: 1.5,
                              color: context.textSecondary,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guideItem(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required List<String> bullets,
  }) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(icon, size: 18.sp, color: AppTheme.goldColor),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textColor,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
              SizedBox(height: 6.h),
              ...bullets.map(
                (line) => Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 6.h, left: 6.w),
                        child: Container(
                          width: 4.w,
                          height: 4.w,
                          decoration: const BoxDecoration(
                            color: AppTheme.goldColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 11.sp,
                            height: 1.45,
                            color: context.textSecondary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: AppTheme.veryDarkBackground.withValues(alpha: isDark ? 0.2 : 0.05),
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
              'دستاورد باز',
              FormatUtils.toPersianDigits(
                '${achievementService.unlockedAchievements.length}',
              ),
              GamificationLabels.achievementsIcon,
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
              '${GamificationLabels.stars} جمع‌شده',
              FormatUtils.toPersianDigits(
                '${achievementService.totalStars}',
              ),
              GamificationLabels.starsIcon,
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
              'فعالیت در اپ',
              FormatUtils.toPersianDigits('${scoreService.rankingScore}'),
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
            fontSize: 18.sp,
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
          GamificationLabels.stars,
          'stars',
          isDark,
        ),
        SizedBox(width: 8.w),
        _buildFilterChip(
          context,
          GamificationLabels.points,
          'points',
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
    final isActivitySummary =
        item.sourceId != null && item.sourceId!.startsWith('ranking_');
    final dateStr = isActivitySummary
        ? 'جمع‌بندی'
        : '${jDate.day} ${monthNames[jDate.month - 1]}';

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
            color: AppTheme.veryDarkBackground.withValues(alpha: isDark ? 0.2 : 0.05),
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
                style: TextStyle(fontSize: 18.sp),
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                if (item.description != null &&
                    item.description!.trim().isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    item.description!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      GamificationLabels.pointsIcon,
                      size: 16.sp,
                      color: AppTheme.goldColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '+${FormatUtils.toPersianDigits('${item.points}')} ${GamificationLabels.points}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Achievement> _sortedStarAchievements(List<Achievement> unlocked) {
    final sorted = List<Achievement>.from(unlocked);
    sorted.sort((a, b) {
      final aDate = a.unlockedAt;
      final bDate = b.unlockedAt;
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return a.title.compareTo(b.title);
    });
    return sorted;
  }

  List<Widget> _buildFilteredList(
    BuildContext context,
    bool isDark, {
    required List<PointHistory> activityEntries,
    required List<Achievement> starEntries,
  }) {
    final widgets = <Widget>[];

    void addSectionTitle(String title) {
      if (widgets.isNotEmpty) {
        widgets.add(SizedBox(height: 8.h));
      }
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: 10.h, right: 4.w),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: context.textSecondary,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      );
    }

    switch (_selectedFilter) {
      case 'stars':
        for (final a in starEntries) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildStarHistoryItem(context, a, isDark),
            ),
          );
        }
        return widgets;
      case 'points':
        for (final item in activityEntries) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildHistoryItem(context, item, isDark),
            ),
          );
        }
        return widgets;
      default:
        if (starEntries.isNotEmpty) {
          addSectionTitle(GamificationLabels.stars);
          for (final a in starEntries) {
            widgets.add(
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildStarHistoryItem(context, a, isDark),
              ),
            );
          }
        }
        if (activityEntries.isNotEmpty) {
          addSectionTitle(GamificationLabels.points);
          for (final item in activityEntries) {
            widgets.add(
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildHistoryItem(context, item, isDark),
              ),
            );
          }
        }
        return widgets;
    }
  }

  Widget _buildStarHistoryItem(
    BuildContext context,
    Achievement achievement,
    bool isDark,
  ) {
    final unlockedAt = achievement.unlockedAt;
    String dateStr = '—';
    if (unlockedAt != null) {
      final jDate = Jalali.fromDateTime(unlockedAt);
      const monthNames = [
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
      dateStr = '${jDate.day} ${monthNames[jDate.month - 1]}';
    }

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
            color: AppTheme.veryDarkBackground.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
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
                achievement.icon,
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                if (achievement.description.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    achievement.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      GamificationLabels.achievementsIcon,
                      size: 14.sp,
                      color: context.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'دستاورد',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      LucideIcons.calendar,
                      size: 14.sp,
                      color: context.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  GamificationLabels.starsIcon,
                  size: 16.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  '+${FormatUtils.toPersianDigits('${achievement.stars}')} ${GamificationLabels.stars}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark, {
    required bool hasAnyContent,
  }) {
    final isFilteredEmpty = hasAnyContent;
    final isStarsFilter = _selectedFilter == 'stars';
    final isPointsFilter = _selectedFilter == 'points';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFilteredEmpty
                ? LucideIcons.filter
                : (isStarsFilter
                    ? GamificationLabels.starsIcon
                    : GamificationLabels.pointsIcon),
            size: 56.sp,
            color: AppTheme.goldColor.withValues(alpha: 0.75),
          ),
          SizedBox(height: 20.h),
          Text(
            isFilteredEmpty
                ? 'موردی در این فیلتر نیست'
                : isStarsFilter
                    ? 'هنوز ${GamificationLabels.stars} نگرفته‌اید'
                    : isPointsFilter
                        ? 'هنوز ${GamificationLabels.points} فعالیتی ندارید'
                        : 'هنوز ${GamificationLabels.stars} یا ${GamificationLabels.points} ندارید',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isFilteredEmpty
                ? 'فیلتر دیگری انتخاب کنید یا «همه» را بزنید'
                : isStarsFilter
                    ? 'با باز کردن دستاوردها ${GamificationLabels.stars} می‌گیرید'
                    : 'با تمرین، ثبت وعده، استریک و مطالعه در اپ ${GamificationLabels.points} می‌گیرید',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.textSecondary,
              fontFamily: AppTheme.fontFamily,
              height: 1.6,
            ),
          ),
          if (!isFilteredEmpty && (isStarsFilter || _selectedFilter == 'all')) ...[
            SizedBox(height: 20.h),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AchievementsScreen(),
                  ),
                );
              },
              icon: Icon(
                LucideIcons.trophy,
                size: 18.sp,
                color: AppTheme.goldColor,
              ),
              label: Text(
                'مشاهده دستاوردها',
                style: TextStyle(
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    bool isDark,
    ScoreService scoreService,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48.sp,
              color: AppTheme.errorColor,
            ),
            SizedBox(height: 16.h),
            Text(
              scoreService.lastLoadError ?? 'خطا در بارگذاری',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: () => _refreshData(force: true),
              icon: const Icon(LucideIcons.refreshCw, color: AppTheme.goldColor),
              label: const Text(
                'تلاش مجدد',
                style: TextStyle(
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    return FormatUtils.formatAmount(score);
  }
}
