import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
import 'package:gymaipro/announcements/services/in_app_announcement_service.dart';
import 'package:gymaipro/announcements/widgets/in_app_announcement_modal.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/dashboard/models/dashboard_snapshot.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_animated_section.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_app_bar.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_deferred_gate.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_drawer.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_hero_carousel.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_stories_section.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_welcome.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_welcome_helpers.dart';
import 'package:gymaipro/dashboard/widgets/discover_section.dart';
import 'package:gymaipro/dashboard/widgets/fitness_metrics.dart';
import 'package:gymaipro/dashboard/widgets/quick_action_buttons.dart';
import 'package:gymaipro/dashboard/widgets/tip_card.dart';
import 'package:gymaipro/dashboard/widgets/todays_program_section.dart';
import 'package:gymaipro/dashboard/widgets/top_rankings_section.dart';
import 'package:gymaipro/dashboard/widgets/weekly_muscle_heatmap_section.dart';
import 'package:gymaipro/dashboard/widgets/weight_chart.dart';
import 'package:gymaipro/guide/guide.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/services/app_state.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/services/avatar_refresh_notifier.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/streak_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/store/widgets/store_teaser_banner.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, GlobalKey> _guideKeys = {
    'welcome_card': GlobalKey(debugLabel: 'dashboard_welcome_card'),
    'fitness_metrics': GlobalKey(debugLabel: 'dashboard_fitness_metrics'),
    'weight_chart': GlobalKey(debugLabel: 'dashboard_weight_chart'),
    'quick_actions': GlobalKey(debugLabel: 'dashboard_quick_actions'),
    'todays_program': GlobalKey(debugLabel: 'dashboard_todays_program'),
    'exercises_tabs': GlobalKey(debugLabel: 'dashboard_exercises_tabs'),
    'drawer_menu': GlobalKey(debugLabel: 'dashboard_drawer_menu'),
  };

  // انیمیشن logout
  AnimationController? _logoutAnimationController;
  Animation<double>? _logoutFadeAnimation;
  bool _isLoggingOut = false;

  DashboardSnapshot? _snapshot;
  bool _isLoading = true;

  String? get _username => _snapshot?.username;
  String? get _userRole => _snapshot?.userRole;
  Map<String, dynamic> get _profileData =>
      _snapshot?.profileData ?? const <String, dynamic>{};
  final ValueNotifier<int?> _walletAvailableBalance = ValueNotifier<int?>(null);
  int _refreshKey = 0; // برای force rebuild ویجت‌های فرزند
  bool _gamificationBootstrapScheduled = false;
  bool _announcementScheduled = false;
  final InAppAnnouncementService _announcementService =
      InAppAnnouncementService();
  bool _isAnnouncementDialogVisible = false;
  final ScrollController _scrollController = ScrollController();
  late final DashboardDeferredReveal _deferredReveal;
  bool _dashboardTourCheckRunning = false;
  late final VoidCallback _dashboardForegroundListener;

  @override
  void initState() {
    super.initState();

    _deferredReveal = DashboardDeferredReveal(scrollController: _scrollController)
      ..addListener(_onDeferredRevealChanged);

    // Main animations
    _animation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.w, 0.3.h),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOut));

    // Logout animation
    _logoutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoutFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoutAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize cache service
    DashboardCacheService().initialize();

    _loadUserData();
    AvatarRefreshNotifier.instance.addListener(_onAvatarUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animation.safeForward();
        _registerGuides();
        _scheduleDashboardTourCheck();
      }
    });

    _dashboardForegroundListener = _scheduleDashboardTourCheck;
    MainNavigationScreen.addDashboardForegroundListener(
      _dashboardForegroundListener,
    );
  }

  void _scheduleDashboardTourCheck() {
    if (_dashboardTourCheckRunning) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_checkAndShowTour());
    });
  }

  void _onDeferredRevealChanged() {
    if (!mounted) return;
    // Rebuild so staggered DashboardDeferredGate sections can mount one-by-one.
    setState(() {});
  }

  void _registerGuides() {
    try {
      // ثبت راهنمای اصلی داشبورد
      registerGuide(context, DashboardGuideData.getDashboardGuide(keyOverrides: _guideKeys));
      registerGuide(context, DashboardGuideData.getProgramBuilderGuide());
      registerGuide(
        context,
        DashboardGuideData.getWeightTrackingGuide(keyOverrides: _guideKeys),
      );
    } catch (e) {
      debugPrint('Error registering guides: $e');
    }
  }

  Future<void> _checkAndShowTour() async {
    if (_dashboardTourCheckRunning) return;
    _dashboardTourCheckRunning = true;
    try {
      final guideService = Provider.of<GuideService>(context, listen: false);

      // اگر راهنمای drawer فعاله، راهنمای داشبورد رو شروع نکن
      if (guideService.hasActiveGuide &&
          guideService.activeGuide?.id == 'drawer_guide') {
        return;
      }

      // تاخیر برای اطمینان از render شدن ویجت‌ها
      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (!mounted || !_isDashboardForegroundForTour()) return;

      final profileComplete = await RouteService.isCurrentUserProfileComplete();
      if (!mounted || !profileComplete || !_isDashboardForegroundForTour()) {
        return;
      }

      // سکشن‌های پایین برای تور راهنما باید mount شده باشند
      _deferredReveal.forceReveal();

      // نمایش راهنمای اصلی داشبورد اگر هنوز نشون داده نشده
      if (mounted && guideService.shouldShowGuide('dashboard_main_tour')) {
        await offerGuideTourIfEligible(
          context,
          guideId: 'dashboard_main_tour',
          title: 'یه تور کوتاه از داشبورد بریم؟',
          description:
              'می‌تونم قدم‌به‌قدم بخش‌های مهم این صفحه رو بهت نشون بدم؛ '
              'هر وقت خواستی از منو هم می‌تونی دوباره تور رو شروع کنی.',
        );
      }
    } catch (e) {
      debugPrint('Error showing tour: $e');
    } finally {
      _dashboardTourCheckRunning = false;
    }
  }

  /// تور فقط وقتی نشان داده شود که shell داشبورد جلویی باشد
  /// (بدون صفحهٔ ثبت‌نام/لودینگ روی استک).
  bool _isDashboardForegroundForTour() {
    if (!MainNavigationScreen.isShellActive) return false;
    if (MainNavigationScreen.currentTabIndex !=
        NavigationConstants.dashboardIndex) {
      return false;
    }

    final nav = rootNavigator;
    if (nav == null || nav.canPop()) return false;

    return true;
  }

  @override
  void dispose() {
    MainNavigationScreen.removeDashboardForegroundListener(
      _dashboardForegroundListener,
    );
    _deferredReveal.dispose();
    _scrollController.dispose();
    _walletAvailableBalance.dispose();
    AvatarRefreshNotifier.instance.removeListener(_onAvatarUpdated);
    _animation.dispose();
    _logoutAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _onAvatarUpdated() async {
    try {
      final profileData = await SimpleProfileService.getCurrentProfile();
      if (profileData != null && mounted) {
        final latestWeight = await WeeklyWeightService.getLatestWeight(
          (profileData['id'] ?? '').toString(),
        );
        final snapshot = DashboardSnapshot.fromRaw(
          profileData,
          latestWeight: latestWeight,
        );
        DashboardCacheService().setSnapshot(snapshot);
        WidgetSafetyUtils.safeSetState(this, () {
          _snapshot = snapshot;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final cacheService = DashboardCacheService();

    try {
      // Shell snapshot from cache — validate it belongs to the current user.
      final currentUser = Supabase.instance.client.auth.currentUser;
      var cachedSnapshot = cacheService.getSnapshot();

      if (cachedSnapshot != null && currentUser != null) {
        final cachedUserId = cachedSnapshot.userId;
        if (cachedUserId != currentUser.id) {
          cacheService.invalidateDashboard();
          cachedSnapshot = null;
        } else if (cachedSnapshot.username == 'کاربر عزیز') {
          // Incomplete cache (e.g. before profile completion) — refetch.
          cacheService.invalidateDashboard();
          cachedSnapshot = null;
          SimpleProfileService.invalidateCache();
        }
      }

      if (cachedSnapshot != null && currentUser != null) {
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () {
            _snapshot = cachedSnapshot;
            _isLoading = false;
          });
        }
        unawaited(_loadWallet());
        _scheduleGamificationBootstrap();
        _scheduleDashboardTourCheck();
        _scheduleAnnouncement();
        return;
      }

      final profileData = await SimpleProfileService.getCurrentProfile();

      // Wallet is drawer-only — do not block shell paint.
      unawaited(_loadWallet());

      if (profileData != null && mounted) {
        double? latestWeight;
        try {
          final profileId = (profileData['id'] ?? '').toString();
          if (profileId.isNotEmpty) {
            latestWeight = await WeeklyWeightService.getLatestWeight(profileId);
          }
        } catch (e) {
          // Error handled silently
        }

        final snapshot = DashboardSnapshot.fromRaw(
          profileData,
          latestWeight: latestWeight,
        );
        cacheService.setSnapshot(snapshot);

        WidgetSafetyUtils.safeSetState(this, () {
          _snapshot = snapshot;
          _isLoading = false;
        });

        _scheduleDashboardTourCheck();
        _scheduleGamificationBootstrap();
        _scheduleAnnouncement();
      } else {
        if (mounted) {
          SafeSetState.call(this, () {
            _isLoading = false;
            _snapshot = DashboardSnapshot.empty();
          });
        }
      }
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _snapshot = DashboardSnapshot.empty();
      });
    }
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await WalletService().getUserWallet();
      if (mounted) {
        // Drawer-only: avoid setState on the whole dashboard scaffold.
        _walletAvailableBalance.value =
            wallet?.availableBalance ?? wallet?.balance;
      }
    } catch (e) {
      if (mounted) {
        _walletAvailableBalance.value = null;
      }
    }
  }

  void _scheduleGamificationBootstrap() {
    if (_gamificationBootstrapScheduled) return;
    _gamificationBootstrapScheduled = true;
    // After deferred stagger wave (~2.2s + ~600ms) so it does not contend
    // with heatmap / chart / discover network + paint.
    Future<void>.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      unawaited(_updateStreakAndMembershipAchievements());
    });
  }

  void _scheduleAnnouncement() {
    if (_announcementScheduled) return;
    _announcementScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 4500), () {
      if (!mounted) return;
      unawaited(_tryShowAnnouncement());
    });
  }

  Future<void> _refreshGamificationScores({bool force = false}) async {
    if (!mounted) return;
    try {
      final achievementService =
          Provider.of<AchievementService>(context, listen: false);
      final scoreService = Provider.of<ScoreService>(context, listen: false);
      await Future.wait<void>([
        achievementService.refreshFromDatabase(force: force),
        scoreService.loadFromDatabase(force: force),
      ]);
    } catch (e) {
      debugPrint('⚠️ Error refreshing gamification scores: $e');
    }
  }

  Future<void> _updateStreakAndMembershipAchievements() async {
    try {
      final streakService = StreakService();

      // به‌روزرسانی streak
      await streakService.updateLoginStreak();

      // به‌روزرسانی دستاوردهای membership
      await streakService.updateMembershipAchievements();

      await _refreshGamificationScores(force: true);
    } catch (e) {
      // بی‌صدا - خطا در به‌روزرسانی streak نباید روی عملکرد اصلی تاثیر بگذارد
      debugPrint('⚠️ Error updating streak and membership achievements: $e');
    }
  }

  Future<void> _refreshAll() async {
    // If offline, show hint and stop refresh quickly
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'اتصال اینترنت برقرار نیست. رفرش ممکن نیست',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    } catch (_) {
      return;
    }

    if (!mounted) return;

    _deferredReveal.forceReveal();

    // Clear all caches
    try {
      FoodService().clearCache();
      unawaited(ExerciseService().clearCache());
      DashboardCacheService().invalidateDashboard();
    } catch (_) {}

    // به‌روزرسانی کش اطلاعات کاربر برای هوش مصنوعی (در بک‌گراند)
    try {
      unawaited(UserContextCacheService.refreshUserContextCache());
    } catch (_) {}

    // Trigger dependent notifiers/services to refresh
    try {
      final chatUnread = Provider.of<ChatUnreadNotifier>(
        context,
        listen: false,
      );
      await chatUnread.refreshUnreadCount();
    } catch (_) {}

    if (!mounted) return;
    try {
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notifProvider.attachForCurrentUser();
      await notifProvider.refreshUnreadCount();
    } catch (_) {}

    // بارگذاری امتیاز و ستاره‌های دستاورد از منبع واقعی
    try {
      await _refreshGamificationScores(force: true);
    } catch (_) {}

    // Reload dashboard user data and rebuild child sections
    await _loadUserData();

    // Force rebuild of child widgets by updating refresh key
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  Future<void> _signOut() async {
    if (_isLoggingOut) return; // جلوگیری از چند بار اجرا شدن

    try {
      // شروع انیمیشن logout
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoggingOut = true;
      });

      // اجرای انیمیشن fade out
      await _logoutAnimationController?.forward();

      // کمی تاخیر برای نمایش انیمیشن
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // پاک کردن تمام کش‌ها قبل از signOut — با id کاربر فعلی
      final loggingOutUserId =
          Supabase.instance.client.auth.currentUser?.id;
      await LogoutCacheClearService.clearAllUserData(
        previousUserId: loggingOutUserId,
      );

      // پاک کردن AppState
      await AppState().logout();

      // خروج از Supabase و پاک‌سازی نشست (signOut داخل clearAuthState انجام می‌شود)
      await AuthStateService().clearAuthState();
      // User signed out successfully

      // Navigate to welcome screen after logout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/welcome', (route) => false);
          } catch (e) {
            debugPrint('Error in dashboard navigation: $e');
          }
        }
      });
    } catch (e) {
      // Error during sign out handled silently
      // برگرداندن انیمیشن در صورت خطا
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoggingOut = false;
        });
        unawaited(_logoutAnimationController?.reverse());
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'خطا در خروج از حساب کاربری',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _tryShowAnnouncement() async {
    if (!mounted || _isAnnouncementDialogVisible) return;
    try {
      final announcement = await _announcementService
          .getTopActiveAnnouncement();
      if (announcement == null) return;
      final shouldShow = await _announcementService.shouldShowAnnouncement(
        announcement,
      );
      if (!shouldShow || !mounted) return;

      _isAnnouncementDialogVisible = true;
      await _announcementService.markAnnouncementShown(announcement.id);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return InAppAnnouncementModal(
            announcement: announcement,
            onDismiss: () async {
              await _announcementService.markAnnouncementDismissed(
                announcement.id,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            onCtaTap: () async {
              await _announcementService.markAnnouncementClicked(
                announcement.id,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing in-app announcement: $e');
    } finally {
      _isAnnouncementDialogVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FeatureTourWidget(
      guideId: 'dashboard_main_tour', // فقط راهنمای داشبورد رو نمایش بده
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: context.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: context.backgroundColor,
            elevation: 0,
          ),
        ),
        child: DecoratedBox(
          decoration: isDark
              ? const BoxDecoration()
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
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: DashboardAppBar(drawerMenuKey: _guideKeys['drawer_menu']),
                drawer: DashboardDrawer(
                  username: _username,
                  userRole: _userRole,
                  walletBalanceListenable: _walletAvailableBalance,
                  onSignOut: _signOut,
                ),
                body: _isLoading
                    ? const DashboardLoadingScreen()
                    : KeyedSubtree(
                        // Used to force a full subtree rebuild after a "hard refresh"
                        // (e.g., when caches are cleared or user data changes)
                        key: ValueKey<int>(_refreshKey),
                        child: _buildHomeTab(),
                      ),
              ),
              // Overlay انیمیشن logout
              if (_isLoggingOut && _logoutFadeAnimation != null)
                FadeTransition(
                  opacity: _logoutFadeAnimation!,
                  child: ColoredBox(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.goldColor,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'در حال خروج...',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await _refreshAll();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: WebInteraction.alwaysScrollableListPhysics,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ۰. کارت خوش‌آمدگویی (با Streak داخلش) ──
                  DashboardAnimatedSection(
                    child: WelcomeCard(
                      key: _guideKeys['welcome_card'],
                      username: _username ?? 'کاربر عزیز',
                      welcomeMessage:
                          DashboardWelcomeHelpers.getWelcomeMessage(),
                      welcomeIcon: DashboardWelcomeHelpers.getWelcomeIcon(),
                      profileData: _profileData,
                      streak: _snapshot?.loginStreak ?? 0,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // ── ۱. داستان‌های امروز - زیر کارت خوش‌آمدگویی ──
                  const DashboardAnimatedSection(
                    index: 1,
                    child: DashboardStoriesSection(),
                  ),
                  SizedBox(height: 20.h),

                  // ── ۲. نکته روز ──
                  const DashboardAnimatedSection(index: 2, child: TipCard()),
                  SizedBox(height: 20.h),

                  // ── ۳. برنامه امروز - اولویت اصلی کاربر ──
                  DashboardAnimatedSection(
                    index: 3,
                    child: TodaysProgramSection(
                      key: _guideKeys['todays_program'],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۴. اقدامات سریع ──
                  DashboardAnimatedSection(
                    index: 4,
                    child: QuickActionButtons(
                      key: _guideKeys['quick_actions'],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۴.۵ بنر فروشگاه (teaser) ──
                  const DashboardAnimatedSection(
                    index: 5,
                    child: StoreTeaserBanner(),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۵. هیت‌مپ عضلانی هفتگی ──
                  DashboardDeferredGate(
                    ready: _deferredReveal.isSectionReady(
                      DashboardDeferredSection.heatmap,
                    ),
                    placeholderHeight: 160.h,
                    child: DashboardAnimatedSection(
                      index: 5,
                      child: WeeklyMuscleHeatmapSection(
                        refreshToken: _refreshKey,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۶. متریک‌های فیتنس ──
                  DashboardDeferredGate(
                    ready: _deferredReveal.isSectionReady(
                      DashboardDeferredSection.metrics,
                    ),
                    placeholderHeight: 100.h,
                    child: DashboardAnimatedSection(
                      index: 6,
                      child: FitnessMetrics(
                        key: _guideKeys['fitness_metrics'],
                        profileData: _profileData,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۷. نمودار وزن ──
                  DashboardDeferredGate(
                    ready: _deferredReveal.isSectionReady(
                      DashboardDeferredSection.chart,
                    ),
                    placeholderHeight: 200.h,
                    child: DashboardAnimatedSection(
                      index: 7,
                      child: _profileData['id'] != null
                          ? WeightChart(
                              key: _guideKeys['weight_chart'],
                              userId: _profileData['id'] as String,
                              currentWeight: double.tryParse(
                                (_profileData['weight'] as String?) ?? '',
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  ...(_profileData['id'] != null
                      ? [SizedBox(height: 24.h)]
                      : []),

                  // ── ۸. محتوای پیشنهادی - ویدیو، مقاله، موزیک ──
                  DashboardDeferredGate(
                    ready: _deferredReveal.isSectionReady(
                      DashboardDeferredSection.hero,
                    ),
                    placeholderHeight: 180.h,
                    child: const DashboardAnimatedSection(
                      index: 8,
                      child: DashboardHeroCarousel(),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۹. کشف جدیدها - تمرینات و تغذیه ──
                  DashboardDeferredGate(
                    ready: _deferredReveal.isSectionReady(
                      DashboardDeferredSection.discover,
                    ),
                    placeholderHeight: 220.h,
                    child: DashboardAnimatedSection(
                      index: 9,
                      child: DiscoverSection(refreshToken: _refreshKey),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۱۰. رتبه‌بندی ──
                  DashboardDeferredGate(
                    ready: _deferredReveal.isSectionReady(
                      DashboardDeferredSection.rankings,
                    ),
                    placeholderHeight: 180.h,
                    child: const DashboardAnimatedSection(
                      index: 10,
                      child: TopRankingsSection(),
                    ),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
