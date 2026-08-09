import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/screens/academy_main_screen.dart';
import 'package:gymaipro/chat/screens/chat_main_screen.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/core/startup_bootstrap.dart';
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/my_club/my_club_main_screen.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/navigation_guard.dart';
import 'package:gymaipro/navigation/screens/more_screen.dart';
import 'package:gymaipro/navigation/utils/navigation_utils.dart';
import 'package:gymaipro/navigation/widgets/custom_bottom_navigation.dart';
import 'package:gymaipro/navigation/widgets/plus_action_sheet.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_dashboard_screen.dart';
import 'package:provider/provider.dart';

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

  /// Called when the dashboard tab becomes active.
  static void addDashboardForegroundListener(VoidCallback listener) {
    if (!_dashboardForegroundListeners.contains(listener)) {
      _dashboardForegroundListeners.add(listener);
    }
  }

  static void removeDashboardForegroundListener(VoidCallback listener) {
    _dashboardForegroundListeners.remove(listener);
  }

  static void _notifyDashboardForeground() {
    for (final listener in List<VoidCallback>.from(
      _dashboardForegroundListeners,
    )) {
      listener();
    }
  }

  /// Notifies dashboard listeners.
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

  /// باشگاه من / تب تمرین (ورزشکار) — تب داخلی مثلاً ۰ = برنامه‌ها
  static void navigateToMyClub({int initialTab = 0}) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._navigateToMyClub(initialTab);
    }
  }

  /// میز کار مربی — همان اسلات hub
  static void navigateToTrainerDashboard({int initialTab = 0}) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._navigateToTrainerDashboard(initialTab);
    }
  }

  /// پیام‌ها: برای مربی تب؛ برای ورزشکار push تمام‌صفحه
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

  /// Back from باشگاه من hub: pop overlay if pushed, else go home tab.
  static void leaveMyClubTab() {
    final state = _currentState;
    if (state != null && state.mounted) {
      state.handleMyClubTabBack();
    }
  }

  /// آکادمی به‌صورت صفحهٔ push (دیگر تب پایین نیست)
  static void openAcademy({int? initialTabIndex, WorkoutMusic? music}) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._openAcademy(initialTabIndex: initialTabIndex, music: music);
      return;
    }
    final nav = rootNavigator;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => AcademyMainScreen(
          initialTabIndex: initialTabIndex,
          initialMusicToPlay: music,
        ),
      ),
    );
  }

  /// رفتن به آکادمی با تب موزیک و پخش یک موزیک خاص
  static void navigateToAcademyWithMusic(WorkoutMusic music) {
    openAcademy(initialTabIndex: 1, music: music);
  }

  /// فقط selected کردن بدون تغییر صفحه
  static void setSelectedIndex(int index) {
    final state = _currentState;
    if (state != null && state.mounted) {
      state._currentIndex = index;
    }
  }

  /// Reload tabs/role after an in-place account switch (debug switcher).
  static Future<bool> reloadAfterAccountSwitch() async {
    final state = _currentState;
    if (state == null || !state.mounted) return false;
    await state._reloadAfterAccountSwitch();
    return true;
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = NavigationConstants.homeIndex;
  final Set<int> _builtTabIndices = {NavigationConstants.homeIndex};
  final List<int> _tabBackStack = [NavigationConstants.homeIndex];
  int? _pendingMyClubTabIndex;
  int? _pendingSocialTabIndex;
  int? _pendingTrainerDashboardTabIndex;
  String? _userRole;
  int _accountEpoch = 0;

  final Map<int, GlobalKey> _navKeys = {
    NavigationConstants.homeIndex: GlobalKey(),
    NavigationConstants.hubIndex: GlobalKey(),
    NavigationConstants.roleTabIndex: GlobalKey(),
    NavigationConstants.moreIndex: GlobalKey(),
  };

  bool get _isTrainer => _userRole == 'trainer';

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

    final leftMessages = _currentIndex == NavigationConstants.roleTabIndex &&
        index != NavigationConstants.roleTabIndex;

    setState(() {
      _builtTabIndices.add(index);
      _currentIndex = index;
    });

    if (index == NavigationConstants.homeIndex) {
      MainNavigationScreen._notifyDashboardForeground();
    }

    // After leaving messages, refresh badge — important when push is unreliable.
    if (leftMessages) {
      try {
        final unread = Provider.of<ChatUnreadNotifier>(context, listen: false);
        unawaited(unread.refreshUnreadCount());
      } catch (_) {}
    }
  }

  void _onNavItemTapped(int index, {bool bypassDebounce = false}) {
    if (!bypassDebounce && !NavigationUtils.canNavigate()) return;
    _activateTab(index);
  }

  void _leaveCurrentTabToHome() {
    NavigationGuard.resetBackPress();
    _onNavItemTapped(NavigationConstants.homeIndex, bypassDebounce: true);
  }

  Future<void> _handleBackPress() async {
    if (_currentIndex != NavigationConstants.homeIndex) {
      _leaveCurrentTabToHome();
      return;
    }
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

  Future<void> _reloadAfterAccountSwitch() async {
    SimpleProfileService.invalidateCache();
    StartupBootstrap.resetOnLogout();
    if (!mounted) return;

    setState(() {
      _accountEpoch++;
      _userRole = null;
      _builtTabIndices
        ..clear()
        ..add(NavigationConstants.homeIndex);
      _currentIndex = NavigationConstants.homeIndex;
      _tabBackStack
        ..clear()
        ..add(NavigationConstants.homeIndex);
      _pendingMyClubTabIndex = null;
      _pendingSocialTabIndex = null;
      _pendingTrainerDashboardTabIndex = null;
    });

    StartupBootstrap.schedulePostLoginLoads();
    await _loadUserRole();
    if (!mounted) return;
    MainNavigationScreen.notifyDashboardForeground();
  }

  Widget _buildLazyTab(int index) {
    if (!_builtTabIndices.contains(index)) {
      return const SizedBox.shrink();
    }
    return _KeepAliveTab(
      key: ValueKey<String>('tab_${index}_$_accountEpoch'),
      child: _buildTabContent(index),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case NavigationConstants.homeIndex:
        return const DashboardScreen();
      case NavigationConstants.hubIndex:
        if (_isTrainer) {
          return TrainerDashboardScreen(
            initialTabIndex: _pendingTrainerDashboardTabIndex ?? 0,
          );
        }
        return MyClubMainScreen(initialTabIndex: _pendingMyClubTabIndex);
      case NavigationConstants.roleTabIndex:
        return ChatMainScreen(
          initialTabIndex: _pendingSocialTabIndex ?? 0,
          isActiveTab: _currentIndex == NavigationConstants.roleTabIndex,
        );
      case NavigationConstants.moreIndex:
        return const MoreScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _openAcademy({int? initialTabIndex, WorkoutMusic? music}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcademyMainScreen(
          initialTabIndex: initialTabIndex,
          initialMusicToPlay: music,
        ),
      ),
    );
  }

  void _navigateToMyClub(int initialTab) {
    if (_isTrainer) {
      // Trainers don't have MyClub as hub — open as overlay route if needed
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MyClubMainScreen(initialTabIndex: initialTab),
        ),
      );
      return;
    }
    setState(() => _pendingMyClubTabIndex = initialTab);
    _onNavItemTapped(NavigationConstants.hubIndex);
  }

  void _navigateToSocial(int initialTab) {
    setState(() => _pendingSocialTabIndex = initialTab);
    _onNavItemTapped(NavigationConstants.roleTabIndex);
  }

  void _navigateToTrainerDashboard(int initialTab) {
    setState(() {
      _userRole = 'trainer';
      _pendingTrainerDashboardTabIndex = initialTab;
    });
    _onNavItemTapped(NavigationConstants.hubIndex);
  }

  void handleSocialTabBack() {
    if (_currentIndex == NavigationConstants.roleTabIndex) {
      _leaveCurrentTabToHome();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _leaveCurrentTabToHome();
    }
  }

  void handleMyClubTabBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _leaveCurrentTabToHome();
  }

  Future<void> _onPlusTap() async {
    if (!NavigationUtils.canNavigate()) return;
    await showPlusActionSheet(context, userRole: _userRole);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hideBottomNav = _currentIndex == NavigationConstants.roleTabIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBackgroundColor
              : AppTheme.lightBackgroundColor,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _buildLazyTab(NavigationConstants.homeIndex),
              _buildLazyTab(NavigationConstants.hubIndex),
              _buildLazyTab(NavigationConstants.roleTabIndex),
              _buildLazyTab(NavigationConstants.moreIndex),
            ],
          ),
          bottomNavigationBar: hideBottomNav
              ? null
              : CustomBottomNavigation(
                  currentIndex: _currentIndex,
                  onTap: _onNavItemTapped,
                  onPlusTap: () => unawaited(_onPlusTap()),
                  navKeys: _navKeys,
                  userRole: _userRole,
                ),
        ),
      ),
    );
  }
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
