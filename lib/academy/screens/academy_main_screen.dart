import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/screens/articles_list_screen.dart';
import 'package:gymaipro/academy/screens/legends_list_screen.dart';
import 'package:gymaipro/academy/screens/music_list_screen.dart';
import 'package:gymaipro/academy/screens/motivational_videos_screen.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AcademyMainScreen extends StatefulWidget {
  const AcademyMainScreen({
    super.key,
    this.initialTabIndex,
    this.initialMusicToPlay,
  });

  /// تب اولیه (۰=مقالات، ۱=موزیک، ۲=ویدیو، ۳=اساطیر) - برای ناوبری از کاروسل
  final int? initialTabIndex;

  /// موزیکی که باید بعد از ورود پخش شود
  final WorkoutMusic? initialMusicToPlay;

  @override
  State<AcademyMainScreen> createState() => _AcademyMainScreenState();
}

class _AcademyMainScreenState extends State<AcademyMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WorkoutMusic? _initialMusicToPlay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _applyInitialParams(widget.initialTabIndex, widget.initialMusicToPlay);
  }

  @override
  void didUpdateWidget(covariant AcademyMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex ||
        widget.initialMusicToPlay != oldWidget.initialMusicToPlay) {
      _applyInitialParams(widget.initialTabIndex, widget.initialMusicToPlay);
    }
  }

  void _applyInitialParams(int? tabIndex, WorkoutMusic? music) {
    if (music != null) _initialMusicToPlay = music;
    if (tabIndex != null && tabIndex >= 0 && tabIndex < 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != tabIndex) {
          _tabController.animateTo(tabIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
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
        decoration: context.pageDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'بازگشت',
              icon: Icon(LucideIcons.arrowRight, color: context.textColor),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              'آکادمی',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 19.sp,
                color: context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(54.h),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppTheme.goldColor.withValues(alpha: 0.1),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.28),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 4.h,
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: isDark ? AppTheme.goldColor : context.textColor,
                    unselectedLabelColor: context.textSecondary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                      fontFamily: AppTheme.fontFamily,
                      height: 1.2,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                      fontFamily: AppTheme.fontFamily,
                      height: 1.2,
                    ),
                    tabAlignment: TabAlignment.fill,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    tabs: [
                      Tab(
                        icon: Icon(LucideIcons.bookOpen, size: 16.sp),
                        text: 'مقالات',
                        height: 44.h,
                        iconMargin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Tab(
                        icon: Icon(LucideIcons.music, size: 16.sp),
                        text: 'موزیک',
                        height: 44.h,
                        iconMargin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Tab(
                        icon: Icon(LucideIcons.video, size: 16.sp),
                        text: 'ویدیو',
                        height: 44.h,
                        iconMargin: EdgeInsets.only(bottom: 3.h),
                      ),
                      Tab(
                        icon: Icon(LucideIcons.trophy, size: 16.sp),
                        text: 'اساطیر',
                        height: 44.h,
                        iconMargin: EdgeInsets.only(bottom: 3.h),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: WebInteraction.tabBarViewPhysics,
            children: [
              const ArticlesListScreen(),
              MusicListScreen(initialMusicToPlay: _initialMusicToPlay),
              const MotivationalVideosScreen(),
              const LegendsListScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
