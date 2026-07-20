import 'package:flutter/material.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/screens/academy_main_screen.dart';
import 'package:gymaipro/features/coach/presentation/screens/coach_home_screen.dart';
import 'package:gymaipro/core/startup_bootstrap.dart';
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
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

  static bool get isShellActive {
    final state = _currentState;
    return state != null && state.mounted;
  }

  /// Currently selected bottom-nav tab (null when shell is not mounted).
  static int? get currentTabIndex => _currentState?._currentIndex;

  static final List<VoidCallback> _dashboardForegroundListeners = [];

  /// Called when the dashboard tab becomes active (for deferred tour invite).
  static void addDashboardForegroundListener(VoidCallback listener) {
    if (!_dashboardForegroundListeners.contains(listener)) {
      _dashboardForegroundListeners.add(listener);
    }
  }

  static void removeDashboardForegroundListener(VoidCallback listener) {
    _dashboardForegroundListeners.remove(listener);
  }

  static void _notifyDashboardForeground() {
    for (final listener in List<VoidCallback>.from(_dashboardForegroundListeners)) {
      listener();
    }
  }

  /// Notifies dashboard listeners (e.g. deferred tour invite).
  static void notifyDashboardForeground() => _notifyDashboardForeground();

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();

  /// Navigate to a specific tab in the main navigation
  static void navigateToTab(int index) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._onNavItemTapped(index);
    }
  }

  /// باشگاه من (ورزشکار / فضای شخصی مربی) — تب داخلی مثلاً ۰ = برنامه‌ها
  static void navigateToMyClub({int initialTab = 0}) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._navigateToMyClub(initialTab);
    }
  }

  /// میز کار مربی — همان اسلات تب پایین
  static void navigateToTrainerDashboard({int initialTab = 0}) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._navigateToTrainerDashboard(initialTab);
    }
  }

  /// تب اجتماعی (پیام‌ها / چت‌روم)
  static void navigateToSocial({int initialTab = 0}) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._navigateToSocial(initialTab);
    }
  }

  /// Back from social/chat hub to main menu (dashboard tab).
  static void leaveSocialTab() {
    final state = _currentState;
    if (state != null && state.mounted) {
      state.handleSocialTabBack();
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
  final Set<int> _builtTabIndices = {NavigationConstants.dashboardIndex};
  final List<int> _tabBackStack = [NavigationConstants.dashboardIndex];
  int? _pendingAcademyTabIndex;
  WorkoutMusic? _pendingAcademyMusic;
  int? _pendingMyClubTabIndex;
  int? _pendingSocialTabIndex;
  int? _pendingTrainerDashboardTabIndex;
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
    _userRole = _readCachedRole();
    MainNavigationScreen._currentState = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StartupBootstrap.schedulePostLoginLoads();
      _loadUserRole();
    });
  }

  String? _readCachedRole() {
    final cachedRole = SimpleProfileService.cachedRole;
    if (cachedRole != null) return cachedRole;
    final dashboardProfile = DashboardCacheService().getProfileData();
    return (dashboardProfile?['role'] as String?) ?? 'athlete';
  }

  @override
  void dispose() {
    if (MainNavigationScreen._currentState == this) {
      MainNavigationScreen._currentState = null;
    }
    super.dispose();
  }

  void _activateTab(int index) {
    if (index != _currentIndex) {
      _tabBackStack.remove(index);
      _tabBackStack.add(index);
    }

    setState(() {
      _builtTabIndices.add(index);
      _currentIndex = index;
    });

    if (index == NavigationConstants.dashboardIndex) {
      MainNavigationScreen._notifyDashboardForeground();
    }
  }

  void _onNavItemTapped(int index, {bool bypassDebounce = false}) {
    if (!bypassDebounce && !NavigationUtils.canNavigate()) return;
    _activateTab(index);
  }
  void _leaveCurrentTabToDashboard() {
    NavigationGuard.resetBackPress();
    _onNavItemTapped(
      NavigationConstants.dashboardIndex,
      bypassDebounce: true,
    );
  }

  Future<void> _handleBackPress() async {
    // اگر روی تب داشبورد نیستیم، به داشبورد (منوی اصلی) برگرد
    if (_currentIndex != NavigationConstants.dashboardIndex) {
      _leaveCurrentTabToDashboard();
      return;
    }

    // اگر روی تب داشبورد هستیم، از NavigationGuard استفاده کن
    await NavigationGuard.handleBackPress(context);
  }

  Future<void> _loadUserRole() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (!mounted || profile == null) return;
      final role = (profile['role'] as String?) ?? 'athlete';
      if (role == _userRole) return;
      setState(() => _userRole = role);
    } catch (e) {
      debugPrint('❌ Error loading user role: $e');
      if (mounted && _userRole == null) {
        setState(() => _userRole = 'athlete');
      }
    }
  }

  Widget _buildLazyTab(int index) {
    if (!_builtTabIndices.contains(index)) {
      return const SizedBox.shrink();
    }
    return _KeepAliveTab(
      key: ValueKey<int>(index),
      child: _buildTabContent(index),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case NavigationConstants.chatIndex:
        return const CoachHomeScreen();
      case NavigationConstants.academyIndex:
        return AcademyMainScreen(
          initialTabIndex: _pendingAcademyTabIndex,
          initialMusicToPlay: _pendingAcademyMusic,
        );
      case NavigationConstants.dashboardIndex:
        return const DashboardScreen();
      case NavigationConstants.myClubIndex:
        if (_userRole == 'trainer') {
          return TrainerDashboardScreen(
            initialTabIndex: _pendingTrainerDashboardTabIndex ?? 0,
          );
        }
        return MyClubMainScreen(initialTabIndex: _pendingMyClubTabIndex);
      case NavigationConstants.socialIndex:
        return ChatMainScreen(
          initialTabIndex: _pendingSocialTabIndex ?? 0,
          isActiveTab: _currentIndex == NavigationConstants.socialIndex,
        );
      default:
        return const SizedBox.shrink();
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

  void _navigateToMyClub(int initialTab) {
    setState(() => _pendingMyClubTabIndex = initialTab);
    _onNavItemTapped(NavigationConstants.myClubIndex);
  }

  void _navigateToSocial(int initialTab) {
    setState(() => _pendingSocialTabIndex = initialTab);
    _onNavItemTapped(NavigationConstants.socialIndex);
  }

  void _navigateToTrainerDashboard(int initialTab) {
    setState(() {
      _userRole = 'trainer';
      _pendingTrainerDashboardTabIndex = initialTab;
    });
    _onNavItemTapped(NavigationConstants.myClubIndex);
  }

  /// Called from [ChatMainScreen] when social tab handles system back.
  void handleSocialTabBack() {
    if (_currentIndex == NavigationConstants.socialIndex) {
      _leaveCurrentTabToDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hideBottomNav = _currentIndex == NavigationConstants.socialIndex;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: DecoratedBox(
        decoration: isDark
            ? const BoxDecoration()
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
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildLazyTab(NavigationConstants.chatIndex),
              _buildLazyTab(NavigationConstants.academyIndex),
              _buildLazyTab(NavigationConstants.dashboardIndex),
              _buildLazyTab(NavigationConstants.myClubIndex),
              _buildLazyTab(NavigationConstants.socialIndex),
            ],
          ),          // تب اجتماعی (لیست چت) تمام‌صفحه — بدون منوی پایین.
          bottomNavigationBar: hideBottomNav
              ? null
              : SafeArea(
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

class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child, super.key});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
