import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/achievements/widgets/achievement_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  bool _isStatsExpanded = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // سینک دستاوردهای دعوت با تعداد رفرال از پروفایل (هر بار باز شدن صفحه)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AchievementService.instance.syncInviteAchievementsFromProfile();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: context.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
          ),
        ),
        child: DecoratedBox(
          decoration: isDark
              ? const BoxDecoration()
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightGradientStart.withValues(alpha: 0.15),
                      AppTheme.lightCardColor,
                      AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Consumer<AchievementService>(
              builder: (context, achievementService, _) {
                final categories = _getAvailableCategories(achievementService);

                if (categories.isEmpty) {
                  return Center(
                    child: Text(
                      'هیچ دستاوردی یافت نشد',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  );
                }

                // Ensure TabController is initialized with correct length
                _ensureTabController(categories.length);

                if (_tabController == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  );
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        // App Bar with Tabs
                        _buildAppBarWithTabs(
                          context,
                          achievementService,
                          isDark,
                          categories,
                          _tabController!,
                        ),
                        // Tab Bar View
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: categories.map((category) {
                              return _buildCategoryTabView(
                                context,
                                achievementService,
                                category,
                                isDark,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    // کارت آمار کلی در فوتر (expandable)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildExpandableStatsFooter(
                        context,
                        achievementService,
                        isDark,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<AchievementCategory> _getAvailableCategories(
    AchievementService service,
  ) {
    final grouped = service.achievementsByCategory;

    // ترتیب تب‌ها بر اساس درخواست کاربر:
    // 1. platform - استفاده از اپ
    // 2. social - اجتماعی
    // 3. workout - تمرین و فعالیت
    // 4. progress - پیشرفت شخصی
    final orderedCategories = [
      AchievementCategory.platform, // ⭐ استفاده از اپ
      AchievementCategory.social, // 👥 اجتماعی
      AchievementCategory.workout, // 💪 تمرین و فعالیت
      AchievementCategory.progress, // 📈 پیشرفت شخصی
    ];

    // فیلتر کردن دسته‌بندی‌هایی که دستاورد دارند
    return orderedCategories
        .where((category) => (grouped[category] ?? []).isNotEmpty)
        .toList();
  }

  Widget _buildAppBarWithTabs(
    BuildContext context,
    AchievementService service,
    bool isDark,
    List<AchievementCategory> categories,
    TabController tabController,
  ) {
    return ColoredBox(
      color: context.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header مشابه سایر صفحات (آیکون + عنوان وسط‌چین)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  // دکمه برگشت
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.arrowRight,
                      size: 20.sp,
                      color: context.textColor,
                    ),
                  ),
                  // عنوان وسط‌چین
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.trophy,
                          color: AppTheme.goldColor,
                          size: 20.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'دستاوردها',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // فضای خالی برای بالانس با دکمه برگشت
                  SizedBox(width: 48.w),
                ],
              ),
            ),
            // Tab Bar
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                margin: EdgeInsets.only(left: 8.w, right: 16.w),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: TabBar(
                  tabAlignment: TabAlignment.start,
                  controller: tabController,
                  isScrollable: categories.length > 3,
                  indicatorColor: AppTheme.goldColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppTheme.goldColor,
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.normal,
                    fontSize: 13.sp,
                  ),
                  dividerColor: Colors.transparent,
                  padding: EdgeInsets.only(
                    left: 4.w,
                    right: 0.w,
                    top: 4.h,
                    bottom: 4.h,
                  ),
                  tabs: categories.map((category) {
                    final achievements =
                        service.achievementsByCategory[category] ?? [];
                    final unlockedCount = achievements
                        .where((a) => a.isUnlocked)
                        .length;
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            category.icon,
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              category.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$unlockedCount/${achievements.length}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabView(
    BuildContext context,
    AchievementService service,
    AchievementCategory category,
    bool isDark,
  ) {
    final achievements = service.achievementsByCategory[category] ?? [];

    if (achievements.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await service.refreshFromDatabase();
          await ScoreService().loadFromDatabase();
        },
        color: AppTheme.goldColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Text(
                'هیچ دستاوردی در این دسته‌بندی وجود ندارد',
                style: TextStyle(fontSize: 14.sp, color: context.textSecondary),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await service.refreshFromDatabase();
        await ScoreService().loadFromDatabase();
      },
      color: AppTheme.goldColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: AchievementCard(
              achievement: achievements[index],
              onTap: () => _showAchievementDetail(context, achievements[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableStatsFooter(
    BuildContext context,
    AchievementService service,
    bool isDark,
  ) {
    final percentage = service.achievements.isNotEmpty
        ? (service.unlockedAchievements.length /
                  service.achievements.length *
                  100)
              .round()
        : 0;
    final progressValue = service.achievements.isNotEmpty
        ? service.unlockedAchievements.length / service.achievements.length
        : 0.0;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border(
            top: BorderSide(
              color: AppTheme.lightDividerColor.withValues(alpha: 0.6),
              width: 1.w,
            ),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _isStatsExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isStatsExpanded = expanded;
              });
            },
            tilePadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            childrenPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
            iconColor: Colors.transparent,
            collapsedIconColor: Colors.transparent,
            trailing: AnimatedRotation(
              turns: _isStatsExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                LucideIcons.chevronUp,
                color: AppTheme.goldColor,
                size: 24.sp,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            ),
            title: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.trophy,
                  size: 22.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'پیشرفت کلی دستاوردها',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTheme.fontFamily,
                          letterSpacing: 0.3,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '${service.unlockedAchievements.length}/${service.achievements.length} دستاورد • ${service.totalPoints} امتیاز',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTheme.fontFamily,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.goldColor.withValues(alpha: 0.35),
                        AppTheme.goldColor.withValues(alpha: 0.25),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                      width: 1.2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.25),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 3.h),
                      ),
                    ],
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0.5,
                      color: AppTheme.goldColor,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Column(
                children: [
                  SizedBox(height: 12.h),
                  LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8.h,
                    backgroundColor: AppTheme.lightDividerColor.withValues(
                      alpha: isDark ? 0.4 : 0.3,
                    ),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.goldColor),
                  ),
                  SizedBox(height: 20.h),
                  // آمار جمع‌بندی
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          isDark: isDark,
                          icon: LucideIcons.award,
                          value:
                              '${service.unlockedAchievements.length}/${service.achievements.length}',
                          label: 'دستاوردها',
                        ),
                      ),
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          isDark: isDark,
                          icon: LucideIcons.star,
                          value: '${service.totalPoints}',
                          label: 'امتیاز',
                        ),
                      ),
                      Expanded(
                        child: _buildCompactStatItem(
                          context,
                          isDark: isDark,
                          icon: LucideIcons.trendingUp,
                          value: '$percentage%',
                          label: 'تکمیل',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.25 : 0.18),
          ),
          child: Icon(icon, size: 18.sp, color: AppTheme.goldColor),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            fontFamily: AppTheme.fontFamily,
            letterSpacing: 0.3,
            color: context.textColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AchievementDetailSheet(achievement: achievement),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({required this.achievement});
  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnlocked = achievement.isUnlocked;

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isUnlocked
              ? Color(achievement.tier.colorValue).withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.8),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // دسته کشویی
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppTheme.lightDividerColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 20.h),
            child: Column(
              children: [
                // آیکون بزرگ
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked
                        ? Color(
                            achievement.tier.colorValue,
                          ).withValues(alpha: 0.2)
                        : (isDark
                              ? AppTheme.darkGreySeparator.withValues(
                                  alpha: 0.7,
                                )
                              : AppTheme.lightDividerColor.withValues(
                                  alpha: 0.7,
                                )),
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(fontSize: 40.sp),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // عنوان با فونت بهتر
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0.5,
                    height: 1.3,
                    color: context.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),

                // Tier Badge با استایل بهتر
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(
                          achievement.tier.colorValue,
                        ).withValues(alpha: 0.25),
                        Color(
                          achievement.tier.colorValue,
                        ).withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(
                      color: Color(
                        achievement.tier.colorValue,
                      ).withValues(alpha: 0.4),
                      width: 1.2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(
                          achievement.tier.colorValue,
                        ).withValues(alpha: 0.2),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 3.h),
                      ),
                    ],
                  ),
                  child: Text(
                    achievement.tier.displayName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTheme.fontFamily,
                      letterSpacing: 0.3,
                      color: Color(achievement.tier.colorValue),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // توضیحات با فونت بهتر
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.6,
                    letterSpacing: 0.2,
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28.h),

                // پیشرفت یا امتیاز
                if (isUnlocked)
                  _buildUnlockedInfo(context, isDark)
                else
                  _buildProgressInfo(context, isDark),

                SizedBox(height: 20.h),

                // دکمه بستن با استایل بهتر
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.onGoldColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      elevation: 4,
                      shadowColor: AppTheme.goldColor.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'بستن',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.fontFamily,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedInfo(BuildContext context, bool isDark) {
    // ممکن است دستاورد در دیتابیس unlock شده باشد ولی تاریخ ثبت نشده باشد
    // در این صورت برای جلوگیری از کرش، یک متن ساده نمایش می‌دهیم
    final unlockedAt = achievement.unlockedAt;
    final String dateStr;
    if (unlockedAt != null) {
      final jDate = Jalali.fromDateTime(unlockedAt);
      dateStr =
          '${jDate.year}/${jDate.month.toString().padLeft(2, '0')}/${jDate.day.toString().padLeft(2, '0')}';
    } else {
      dateStr = 'تاریخ نامشخص';
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(achievement.tier.colorValue).withValues(alpha: 0.25),
            Color(achievement.tier.colorValue).withValues(alpha: 0.15),
            Color(achievement.tier.colorValue).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Color(achievement.tier.colorValue).withValues(alpha: 0.3),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(achievement.tier.colorValue).withValues(alpha: 0.15),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // بخش امتیاز
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Color(
                    achievement.tier.colorValue,
                  ).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.star,
                  size: 26.sp,
                  color: Color(achievement.tier.colorValue),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                '${achievement.points}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                  letterSpacing: 0.5,
                  color: Color(achievement.tier.colorValue),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'امتیاز',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          // خط جداکننده
          Container(
            width: 1.5.w,
            height: 60.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(achievement.tier.colorValue).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // بخش تاریخ
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Color(
                    achievement.tier.colorValue,
                  ).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.checkCircle,
                  size: 26.sp,
                  color: Color(achievement.tier.colorValue),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                  letterSpacing: 0.3,
                  color: context.textColor,
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 4.h),
              Text(
                'تاریخ دریافت',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo(BuildContext context, bool isDark) {
    // جلوگیری از منفی شدن مقدار باقی‌مانده در صورت عبور از target
    final remainingRaw = achievement.targetValue - achievement.currentValue;
    final remaining = remainingRaw > 0 ? remainingRaw : 0;
    final tierColor = Color(achievement.tier.colorValue);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppTheme.darkGreySeparator.withValues(alpha: 0.4),
                  AppTheme.darkGreySeparator.withValues(alpha: 0.2),
                ]
              : [
                  AppTheme.lightDividerColor.withValues(alpha: 0.6),
                  AppTheme.lightDividerColor.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.2),
          width: 1.2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0.w, 3.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // هدر پیشرفت
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.trendingUp, size: 18.sp, color: tierColor),
                  SizedBox(width: 6.w),
                  Text(
                    'پیشرفت',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tierColor.withValues(alpha: 0.25),
                      tierColor.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${achievement.progressPercentage}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.fontFamily,
                    letterSpacing: 0.3,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // نوار پیشرفت
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                LinearProgressIndicator(
                  value: achievement.progress,
                  minHeight: 14.h,
                  backgroundColor: isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation(tierColor),
                ),
                if (achievement.progress > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [tierColor, tierColor.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // اطلاعات پیشرفت
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${achievement.currentValue} از ${achievement.targetValue} ${achievement.unit}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                ),
                textDirection: TextDirection.rtl,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'باقی‌مانده: $remaining',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                    color: tierColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
