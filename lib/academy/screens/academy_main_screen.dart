import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/screens/articles_list_screen.dart';
import 'package:gymaipro/academy/screens/legends_list_screen.dart';
import 'package:gymaipro/academy/screens/music_list_screen.dart';
import 'package:gymaipro/academy/screens/motivational_videos_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AcademyMainScreen extends StatefulWidget {
  const AcademyMainScreen({super.key});

  @override
  State<AcademyMainScreen> createState() => _AcademyMainScreenState();
}

class _AcademyMainScreenState extends State<AcademyMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      child: Container(
        decoration: isDark
            ? null
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
          appBar: AppBar(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'آکادمی',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(56.h),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? context.backgroundColor
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : AppTheme.goldColor.withValues(alpha: 0.08),
                      blurRadius: 12.r,
                      offset: Offset(0, -2.h),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.transparent
                          : AppTheme.goldColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor.withValues(alpha: 0.25),
                              AppTheme.goldColor.withValues(alpha: 0.15),
                            ],
                          )
                        : null,
                    color: isDark
                        ? null
                        : context.textColor.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.2)
                            : context.textColor.withValues(alpha: 0.1),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 6.h,
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: isDark ? AppTheme.goldColor : context.textColor,
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5.sp,
                    letterSpacing: 0.1,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 9.5.sp,
                    letterSpacing: 0.05,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                  tabs: [
                    Tab(
                      icon: Icon(LucideIcons.bookOpen, size: 14.sp),
                      text: 'مقالات',
                      height: 40.h,
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                    ),
                    Tab(
                      icon: Icon(LucideIcons.music, size: 14.sp),
                      text: 'موزیک',
                      height: 40.h,
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                    ),
                    Tab(
                      icon: Icon(LucideIcons.video, size: 14.sp),
                      text: 'ویدیو',
                      height: 40.h,
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                    ),
                    Tab(
                      icon: Icon(LucideIcons.trophy, size: 14.sp),
                      text: 'اساطیر',
                      height: 40.h,
                      iconMargin: EdgeInsets.only(bottom: 4.h),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              ArticlesListScreen(),
              MusicListScreen(),
              MotivationalVideosScreen(),
              LegendsListScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
