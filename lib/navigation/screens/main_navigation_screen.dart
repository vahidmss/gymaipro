import 'package:flutter/material.dart';
import 'package:gymaipro/academy/screens/articles_list_screen.dart';
import 'package:gymaipro/ai/screens/ai_hub_screen.dart';
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/navigation_guard.dart';
import 'package:gymaipro/navigation/utils/navigation_utils.dart';
import 'package:gymaipro/navigation/widgets/custom_bottom_navigation.dart';
import 'package:gymaipro/profile/screens/profile_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex =
      NavigationConstants.dashboardIndex; // شروع با داشبورد (دکمه مرکزی)
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (!NavigationUtils.canNavigate()) return;

    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => NavigationGuard.handleBackPress(context),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: const [
            // AI Hub (index 0)
            AIHubScreen(),

            // آکادمی (index 1)
            ArticlesListScreen(),

            // داشبورد (index 2)
            DashboardScreen(),

            // رتبه‌بندی مربیان (index 3) - برای همه نقش‌ها
            TrainerRankingScreen(),

            // پروفایل (index 4)
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onNavItemTapped,
        ),
      ),
    );
  }

  // Removed legacy workout/nutrition section tabs
}
