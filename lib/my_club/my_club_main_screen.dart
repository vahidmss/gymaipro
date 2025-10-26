import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/my_club/my_programs_screen.dart';
import 'package:gymaipro/my_club/screens/friendship_search_screen.dart';
import 'package:gymaipro/my_club/screens/my_club_overview_screen.dart';
import 'package:gymaipro/my_club/screens/my_friends_screen.dart';
import 'package:gymaipro/my_club/screens/my_trainers_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyClubMainScreen extends StatefulWidget {
  const MyClubMainScreen({super.key});

  @override
  State<MyClubMainScreen> createState() => _MyClubMainScreenState();
}

class _MyClubMainScreenState extends State<MyClubMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          'باشگاه من',
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
            Tab(icon: Icon(LucideIcons.home, size: 20), text: 'خانه'),
            Tab(icon: Icon(LucideIcons.dumbbell, size: 20), text: 'برنامه‌ها'),
            Tab(icon: Icon(LucideIcons.userCheck, size: 20), text: 'مربی‌ها'),
            Tab(icon: Icon(LucideIcons.users, size: 20), text: 'دوستان'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MyClubOverviewScreen(),
          MyProgramsScreen(),
          MyTrainersScreen(),
          MyFriendsScreen(),
        ],
      ),
      floatingActionButton: _tabController.index == 3
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const FriendshipSearchScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.goldColor,
              child: const Icon(LucideIcons.search, color: Colors.black),
            )
          : null,
    );
  }
}
