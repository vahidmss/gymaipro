import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/achievements/screens/achievements_screen.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/ranking/models/league.dart';
import 'package:gymaipro/ranking/models/user_ranking.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/services/models/point_history.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// هاب امتیاز واحد: فعالیت + بونوس دستاورد → لیگ.
class MyPointsScreen extends StatefulWidget {
  const MyPointsScreen({super.key});

  @override
  State<MyPointsScreen> createState() => _MyPointsScreenState();
}

class _MyPointsScreenState extends State<MyPointsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  UserRanking? _ranking;

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
      RankingService().getCurrentUserRanking().then((r) {
        if (mounted) setState(() => _ranking = r);
      }),
    ]);
  }

  League get _league {
    final id = _ranking?.currentLeague ?? 'bronze';
    return League.all.firstWhere((l) => l.id == id, orElse: () => League.bronze);
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
                return _errorState(context, scoreService);
              }

              final activityEntries = scoreService.sortedActivityEntries;
              final unlocked = List<Achievement>.from(
                achievementService.unlockedAchievements,
              )..sort(
                  (a, b) => (b.unlockedAt ?? DateTime(2000))
                      .compareTo(a.unlockedAt ?? DateTime(2000)),
                );

              return ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _heroCard(
                    context,
                    isDark: isDark,
                    score: scoreService.rankingScore,
                    unlockedCount: achievementService.unlockedAchievements.length,
                    totalCount: achievementService.achievements.length,
                  ),
                  SizedBox(height: 16.h),
                  _sectionTitle(context, 'منابع امتیاز'),
                  SizedBox(height: 8.h),
                  if (activityEntries.isEmpty)
                    _emptyHint(
                      context,
                      'با ثبت تمرین و وعده غذایی امتیاز می‌گیری',
                    )
                  else
                    ...activityEntries.map(
                      (e) => _activityTile(context, isDark, e),
                    ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(child: _sectionTitle(context, 'دستاوردهای بازشده')),
                      TextButton(
                        onPressed: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AchievementsScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'همه',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: AppTheme.goldColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  if (unlocked.isEmpty)
                    _emptyHint(
                      context,
                      'دستاورد باز کن تا امتیاز بیشتری بگیری',
                    )
                  else
                    ...unlocked.take(8).map(
                          (a) => _achievementTile(context, isDark, a),
                        ),
                  SizedBox(height: 24.h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _heroCard(
    BuildContext context, {
    required bool isDark,
    required int score,
    required int unlockedCount,
    required int totalCount,
  }) {
    final rank = _ranking?.globalRank;
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(GamificationLabels.pointsIcon, color: AppTheme.goldColor, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'امتیاز شما',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                  color: context.textColor,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
                icon: Icon(GamificationLabels.rankingIcon, size: 16.sp),
                label: Text(
                  GamificationLabels.ranking,
                  style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 12.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            FormatUtils.toPersianDigits('$score'),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 36.sp,
              color: AppTheme.goldColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            [
              'لیگ ${_league.nameFa}',
              if (rank != null && rank > 0)
                'رتبه ${FormatUtils.toPersianDigits('$rank')}',
              '$unlockedCount از $totalCount دستاورد',
            ].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontWeight: FontWeight.w700,
        fontSize: 15.sp,
        color: context.textColor,
      ),
    );
  }

  Widget _emptyHint(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13.sp,
          color: context.textSecondary,
        ),
      ),
    );
  }

  Widget _activityTile(BuildContext context, bool isDark, PointHistory entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(entry.sourceIcon, style: TextStyle(fontSize: 20.sp)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.sourceTitle,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: context.textColor,
                  ),
                ),
                if (entry.description != null)
                  Text(
                    entry.description!,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '+${FormatUtils.toPersianDigits('${entry.points}')}',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              color: AppTheme.goldColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementTile(
    BuildContext context,
    bool isDark,
    Achievement achievement,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(achievement.icon, style: TextStyle(fontSize: 20.sp)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              achievement.title,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: context.textColor,
              ),
            ),
          ),
          Text(
            '+${FormatUtils.toPersianDigits('${achievement.points}')} ${GamificationLabels.points}',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
              color: AppTheme.goldColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, ScoreService scoreService) {
    return ListView(
      padding: EdgeInsets.all(24.w),
      children: [
        SizedBox(height: 80.h),
        Icon(LucideIcons.wifiOff, size: 40.sp, color: context.textSecondary),
        SizedBox(height: 12.h),
        Text(
          scoreService.lastLoadError ?? 'خطا در بارگذاری',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14.sp,
            color: context.textSecondary,
          ),
        ),
        SizedBox(height: 16.h),
        Center(
          child: TextButton(
            onPressed: () => _refreshData(force: true),
            child: const Text('تلاش مجدد'),
          ),
        ),
      ],
    );
  }
}
