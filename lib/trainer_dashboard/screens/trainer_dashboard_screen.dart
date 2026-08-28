import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/screens/trainer_channel_manage_screen.dart';
import 'package:gymaipro/trainer_dashboard/screens/client_management/client_management_screen.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_activities_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_content_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_finance_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_profile_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_requests_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_services_tab.dart';
import 'package:gymaipro/trainer_dashboard/trainer_desk_tabs.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, TrainerDeskTabs.last);
    _tabController = TabController(
      length: TrainerDeskTabs.count,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      SafeSetState.call(this, () {});
    });
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
            title: Text(
              'میز کار مربی',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TrainerChannelManageScreen(),
                    ),
                  );
                },
                icon: Icon(
                  LucideIcons.radio,
                  color: isDark ? AppTheme.goldColor : context.textColor,
                  size: 22.sp,
                ),
                tooltip: 'کانال من',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(58.h),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.18)
                      : context.textColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.24)
                        : context.separatorColor,
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
                  fontSize: 12.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
                padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 6.h),
                tabs: [
                  _deskTab(LucideIcons.users, 'شاگردان'),
                  _deskTab(LucideIcons.inbox, 'درخواست‌ها'),
                  _deskTab(LucideIcons.library, 'محتوا'),
                  _deskTab(LucideIcons.tags, 'خدمات'),
                  _deskTab(LucideIcons.wallet, 'مالی'),
                  _deskTab(LucideIcons.listChecks, 'فعالیت‌ها'),
                  _deskTab(LucideIcons.userRound, 'پروفایل'),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            physics: WebInteraction.tabBarViewPhysics,
            children: const [
              ClientManagementScreen(embedded: true),
              TrainerRequestsTab(),
              TrainerContentTab(),
              TrainerServicesTab(),
              TrainerFinanceTab(),
              TrainerActivitiesTab(),
              TrainerProfileTab(),
            ],
          ),
        ),
      ),
    );
  }

  Tab _deskTab(IconData icon, String label) {
    return Tab(
      height: 46.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17.sp),
          SizedBox(width: 6.w),
          Text(label, maxLines: 1, overflow: TextOverflow.fade),
        ],
      ),
    );
  }
}
