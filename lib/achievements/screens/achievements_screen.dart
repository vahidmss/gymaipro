import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/achievements/widgets/achievement_card.dart';
import 'package:gymaipro/core/gamification_labels.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AchievementService.instance.syncInviteAchievementsFromProfile());
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _ensureTabController(int length) {
    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
  }

  List<AchievementCategory> _categories(AchievementService service) {
    final grouped = service.achievementsByCategory;
    const order = [
      AchievementCategory.platform,
      AchievementCategory.workout,
      AchievementCategory.nutrition,
      AchievementCategory.social,
      AchievementCategory.progress,
    ];
    return order.where((c) => (grouped[c] ?? []).isNotEmpty).toList();
  }

  List<Achievement> _sorted(List<Achievement> list) {
    final copy = List<Achievement>.from(list);
    copy.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
      return a.title.compareTo(b.title);
    });
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: context.pageDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Consumer2<AchievementService, ScoreService>(
            builder: (context, service, scoreService, _) {
              final categories = _categories(service);
              if (categories.isEmpty) {
                return Center(
                  child: Text(
                    'هیچ دستاوردی یافت نشد',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 15.sp,
                      color: context.textSecondary,
                    ),
                  ),
                );
              }

              _ensureTabController(categories.length);
              final tabController = _tabController!;
              final unlocked = service.unlockedAchievements.length;
              final total = service.achievements.length;
              final pct = total == 0 ? 0 : ((unlocked / total) * 100).round();

              return Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: _Header(
                      unlocked: unlocked,
                      total: total,
                      points: service.totalUnlockedRewardPoints,
                      leagueScore: scoreService.rankingScore,
                      percent: pct,
                      onOpenRanking: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
                    child: _CategoryTabs(
                      controller: tabController,
                      categories: categories,
                      service: service,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: tabController,
                      children: categories.map((category) {
                        final items = _sorted(
                          service.achievementsByCategory[category] ?? [],
                        );
                        return RefreshIndicator(
                          color: AppTheme.goldColor,
                          onRefresh: () async {
                            await service.refreshFromDatabase(force: true);
                            await scoreService.loadFromDatabase(force: true);
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => SizedBox(height: 10.h),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return AchievementCard(
                                achievement: item,
                                onTap: () => _showDetail(context, item),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Achievement achievement) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        final unlocked = achievement.isUnlocked;
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.separatorColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  height: 1.5,
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    GamificationLabels.pointsIcon,
                    size: 16.sp,
                    color: AppTheme.goldColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    unlocked
                        ? '+${FormatUtils.toPersianDigits('${achievement.points}')} امتیاز گرفتی'
                        : 'پاداش: +${FormatUtils.toPersianDigits('${achievement.points}')} امتیاز',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ],
              ),
              if (!unlocked) ...[
                SizedBox(height: 14.h),
                Text(
                  '${FormatUtils.toPersianDigits('${achievement.currentValue}')} از ${FormatUtils.toPersianDigits('${achievement.targetValue}')} ${achievement.unit}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    color: context.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    minHeight: 6.h,
                    backgroundColor: context.separatorColor,
                    valueColor: AlwaysStoppedAnimation(
                      Color(achievement.tier.colorValue),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.unlocked,
    required this.total,
    required this.points,
    required this.leagueScore,
    required this.percent,
    required this.onOpenRanking,
  });

  final int unlocked;
  final int total;
  final int points;
  final int leagueScore;
  final int percent;
  final VoidCallback onOpenRanking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 0),
      child: Column(
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  LucideIcons.arrowRight,
                  size: 20.sp,
                  color: context.textColor,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      GamificationLabels.achievementsIcon,
                      color: AppTheme.goldColor,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      GamificationLabels.achievements,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 17.sp,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: GamificationLabels.ranking,
                onPressed: onOpenRanking,
                icon: Icon(
                  GamificationLabels.rankingIcon,
                  size: 20.sp,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: context.separatorColor),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${FormatUtils.toPersianDigits('$unlocked')} از ${FormatUtils.toPersianDigits('$total')} باز شده',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'از دستاوردها: ${FormatUtils.toPersianDigits('$points')} · امتیاز کل: ${FormatUtils.toPersianDigits('$leagueScore')}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.5.sp,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${FormatUtils.toPersianDigits('$percent')}٪',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.controller,
    required this.categories,
    required this.service,
  });

  final TabController controller;
  final List<AchievementCategory> categories;
  final AchievementService service;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: categories.length > 3,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.goldColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.goldColor,
        unselectedLabelColor: context.textSecondary,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 12.sp,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 12.sp,
        ),
        tabs: categories.map((category) {
          final list = service.achievementsByCategory[category] ?? [];
          final done = list.where((a) => a.isUnlocked).length;
          return Tab(
            height: 44.h,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                Icon(category.lucideIcon, size: 14.sp),
                SizedBox(width: 5.w),
                Text(category.displayName),
                SizedBox(width: 5.w),
                Text(
                  '${FormatUtils.toPersianDigits('$done')}/${FormatUtils.toPersianDigits('${list.length}')}',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
