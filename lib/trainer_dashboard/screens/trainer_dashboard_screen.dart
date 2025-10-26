import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/client_management/client_management_screen.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_activities_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_profile_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_requests_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_services_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_stats_tab.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'میز کار مربی',
          style: GoogleFonts.vazirmatn(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: Colors.grey[400],
          labelStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(LucideIcons.users, size: 20), text: 'شاگردان'),
            Tab(icon: Icon(LucideIcons.inbox, size: 20), text: 'درخواست‌ها'),
            Tab(icon: Icon(LucideIcons.user, size: 20), text: 'پروفایل'),
            Tab(icon: Icon(LucideIcons.wallet, size: 20), text: 'خدمات'),
            Tab(icon: Icon(LucideIcons.barChart3, size: 20), text: 'آمار'),
            Tab(
              icon: Icon(LucideIcons.listChecks, size: 20),
              text: 'فعالیت‌ها',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ClientManagementScreen(embedded: true),
          TrainerRequestsTab(),
          TrainerProfileTab(),
          TrainerServicesTab(),
          TrainerStatsTab(),
          TrainerActivitiesTab(),
        ],
      ),
    );
  }
}
