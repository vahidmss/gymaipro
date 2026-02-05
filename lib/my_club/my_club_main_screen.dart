import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/my_club/my_programs_screen.dart';
import 'package:gymaipro/my_club/screens/friendship_search_screen.dart';
import 'package:gymaipro/my_club/screens/my_friends_screen.dart';
import 'package:gymaipro/my_club/screens/my_points_screen.dart';
import 'package:gymaipro/my_club/screens/my_trainers_screen.dart';
import 'package:gymaipro/my_club/screens/my_wallet_screen.dart';
import 'package:gymaipro/my_club/screens/confidential_user_info_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyClubMainScreen extends StatefulWidget {
  const MyClubMainScreen({super.key});

  @override
  State<MyClubMainScreen> createState() => _MyClubMainScreenState();
}

class _MyClubMainScreenState extends State<MyClubMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      SafeSetState.call(this, () {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final initialTab = args?['initialTab'] as int? ?? 0;
      if (initialTab != 0 && initialTab < _tabController.length) {
        _tabController.animateTo(initialTab);
      }
      _isInitialized = true;
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
            title: Text(
              'باشگاه من',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(60.h),
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
                    fontSize: 8.sp,
                    letterSpacing: 0.1,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.4,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 8.sp,
                    letterSpacing: 0.05,
                    fontFamily: AppTheme.fontFamily,
                    height: 1.4,
                  ),
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                  tabs: [
                    Tab(
                      icon: Icon(LucideIcons.dumbbell, size: 15.sp),
                      text: 'برنامه‌ها',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.userCheck, size: 15.sp),
                      text: 'مربی‌ها',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.users, size: 15.sp),
                      text: 'دوستان',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.award, size: 15.sp),
                      text: 'امتیازات',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.wallet, size: 15.sp),
                      text: 'مالی',
                      height: 44.h,
                    ),
                    Tab(
                      icon: Icon(LucideIcons.shield, size: 15.sp),
                      text: 'اطلاعات محرمانه',
                      height: 44.h,
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              MyProgramsScreen(),
              MyTrainersScreen(),
              MyFriendsScreen(),
              MyPointsScreen(),
              MyWalletScreen(),
              ConfidentialUserInfoScreen(embedded: true),
            ],
          ),
          floatingActionButton: _tabController.index == 2
              ? FloatingActionButton(
                  onPressed: () {
                    WidgetSafetyUtils.safeNavigate(
                      context,
                      () => const FriendshipSearchScreen(),
                    );
                  },
                  backgroundColor: AppTheme.goldColor,
                  child: Icon(LucideIcons.search, color: AppTheme.onGoldColor),
                )
              : null,
        ),
      ),
    );
  }
}
