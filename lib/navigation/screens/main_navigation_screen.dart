import 'package:flutter/material.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/screens/academy_main_screen.dart';
import 'package:gymaipro/ai/screens/ai_hub_screen.dart';
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/navigation/navigation_guard.dart';
import 'package:gymaipro/navigation/utils/navigation_utils.dart';
import 'package:gymaipro/navigation/widgets/custom_bottom_navigation.dart';
import 'package:gymaipro/chat/screens/chat_main_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/my_club/my_club_main_screen.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_dashboard_screen.dart';

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

  /// رفتن به آکادمی با تب موزیک و پخش یک موزیک خاص (مثل لمس از کاروسل)
  static void navigateToAcademyWithMusic(WorkoutMusic music) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._navigateToAcademyWithMusic(music);
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
  int? _pendingAcademyTabIndex;
  WorkoutMusic? _pendingAcademyMusic;
  String? _userRole; // نقش کاربر: 'athlete' یا 'trainer'

  // GlobalKey برای المان‌های ناوبری
  final Map<int, GlobalKey> _navKeys = {
    NavigationConstants.chatIndex: GlobalKey(),
    NavigationConstants.academyIndex: GlobalKey(),
    NavigationConstants.dashboardIndex: GlobalKey(),
    NavigationConstants.myClubIndex: GlobalKey(),
    NavigationConstants.socialIndex: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Set the static reference to this state
    MainNavigationScreen._currentState = this;
    // بارگذاری دستاوردها و امتیاز کاربر فعلی از دیتابیس (بعد از لاگین یا ورود به اپ)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SimpleProfileService.invalidateCache();
      AchievementService.instance.refreshFromDatabase();
      ScoreService().loadFromDatabase();
      _loadUserRole();
    });
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

  Future<void> _loadUserRole() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (mounted && profile != null) {
        setState(() {
          _userRole = (profile['role'] as String?) ?? 'athlete';
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading user role: $e');
      if (mounted) {
        setState(() {
          _userRole = 'athlete'; // پیش‌فرض
        });
      }
    }
  }

  void _navigateToAcademyWithMusic(WorkoutMusic music) {
    setState(() {
      _pendingAcademyTabIndex = 1; // موزیک
      _pendingAcademyMusic = music;
    });
    _onNavItemTapped(NavigationConstants.academyIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _pendingAcademyTabIndex = null;
          _pendingAcademyMusic = null;
        });
      }
    });
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
                // بالا پررنگ‌تر (نوار ساعت خوانا) → پایین روشن
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFDDD0B8),
                    const Color(0xFFEDE4D4),
                    AppTheme.lightCardColor,
                    AppTheme.lightGradientEnd.withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.08, 0.22, 1.0],
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
            children: [
              // AI Hub (index 0)
              const AIHubScreen(),

              // آکادمی (index 1)
              AcademyMainScreen(
                initialTabIndex: _pendingAcademyTabIndex,
                initialMusicToPlay: _pendingAcademyMusic,
              ),

              // داشبورد (index 2)
              DashboardScreen(),

              // باشگاه من / داشبورد مربی (index 3) - بر اساس نقش کاربر
              _userRole == 'trainer'
                  ? const TrainerDashboardScreen()
                  : const MyClubMainScreen(),

              // اجتماعی / چت‌ها (index 4) - گفتگوها، چت عمومی، مربیان
              const ChatMainScreen(),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: CustomBottomNavigation(
              currentIndex: _currentIndex,
              onTap: _onNavItemTapped,
              navKeys: _navKeys,
              userRole: _userRole,
            ),
          ),
        ),
      ),
    );
  }

  // Removed legacy workout/nutrition section tabs
}
