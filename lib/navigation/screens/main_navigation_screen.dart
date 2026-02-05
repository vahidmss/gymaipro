import 'package:flutter/material.dart';
import 'package:gymaipro/academy/screens/academy_main_screen.dart';
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

  static _MainNavigationScreenState? _currentState;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();

  /// Navigate to a specific tab in the main navigation
  static void navigateToTab(int index) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._onNavItemTapped(index);
    }
  }

  /// فقط selected کردن بدون تغییر صفحه (برای راهنمایی)
  static void setSelectedIndex(int index) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._currentIndex = index;
      // بدون jumpToPage - فقط selected می‌شود
    }
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex =
      NavigationConstants.dashboardIndex; // شروع با داشبورد (دکمه مرکزی)
  late PageController _pageController;

  // GlobalKey برای المان‌های ناوبری
  final Map<int, GlobalKey> _navKeys = {
    NavigationConstants.chatIndex: GlobalKey(),
    NavigationConstants.academyIndex: GlobalKey(),
    NavigationConstants.dashboardIndex: GlobalKey(),
    NavigationConstants.roleIndex: GlobalKey(),
    NavigationConstants.profileIndex: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Set the static reference to this state
    MainNavigationScreen._currentState = this;
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Clear the static reference when state is disposed
    if (MainNavigationScreen._currentState == this) {
      MainNavigationScreen._currentState = null;
    }
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (!NavigationUtils.canNavigate()) return;

    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  Future<bool> _handleBackPress() async {
    // اگر روی تب داشبورد نیستیم، به داشبورد برو
    if (_currentIndex != NavigationConstants.dashboardIndex) {
      _onNavItemTapped(NavigationConstants.dashboardIndex);
      return false; // جلوگیری از خروج
    }

    // اگر روی تب داشبورد هستیم، از NavigationGuard استفاده کن
    return await NavigationGuard.handleBackPress(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: _handleBackPress,
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
              AcademyMainScreen(),

              // داشبورد (index 2)
              DashboardScreen(),

              // رتبه‌بندی مربیان (index 3) - برای همه نقش‌ها
              TrainerRankingScreen(),

              // پروفایل (index 4)
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: CustomBottomNavigation(
              currentIndex: _currentIndex,
              onTap: _onNavItemTapped,
              navKeys: _navKeys,
            ),
          ),
        ),
      ),
    );
  }

  // Removed legacy workout/nutrition section tabs
}
