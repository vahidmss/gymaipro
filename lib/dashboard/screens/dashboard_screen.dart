import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/achievement_hooks.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
import 'package:gymaipro/announcements/services/in_app_announcement_service.dart';
import 'package:gymaipro/announcements/widgets/in_app_announcement_modal.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/dashboard/models/dashboard_snapshot.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_animated_section.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_app_bar.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_deferred_gate.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_welcome.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_welcome_helpers.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_stats_strip.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_feature_banners.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_quick_access.dart';
import 'package:gymaipro/dashboard/widgets/todays_program_section.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_workout_continue_strip.dart';
import 'package:gymaipro/dashboard/widgets/weekly_muscle_heatmap_section.dart';
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/services/avatar_refresh_notifier.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/streak_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
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

  // انیمیشن‌های ورود
  DashboardSnapshot? _snapshot;
  bool _isLoading = true;

  String? get _username => _snapshot?.username;
  Map<String, dynamic> get _profileData =>
      _snapshot?.profileData ?? const <String, dynamic>{};
  int _refreshKey = 0; // برای force rebuild ویجت‌های فرزند
  bool _gamificationBootstrapScheduled = false;
  bool _announcementScheduled = false;
  final InAppAnnouncementService _announcementService =
      InAppAnnouncementService();
  bool _isAnnouncementDialogVisible = false;
  final ScrollController _scrollController = ScrollController();
  late final DashboardDeferredReveal _deferredReveal;

  @override
  void initState() {
    super.initState();

    _deferredReveal = DashboardDeferredReveal(
      scrollController: _scrollController,
    )..addListener(_onDeferredRevealChanged);

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

    // Initialize cache service
    DashboardCacheService().initialize();

    _loadUserData();
    AvatarRefreshNotifier.instance.addListener(_onAvatarUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animation.safeForward();
      }
    });
  }

  void _onDeferredRevealChanged() {
    if (!mounted) return;
    // Rebuild so staggered DashboardDeferredGate sections can mount one-by-one.
    setState(() {});
  }

  @override
  void dispose() {
    _deferredReveal.dispose();
    _scrollController.dispose();
    AvatarRefreshNotifier.instance.removeListener(_onAvatarUpdated);
    _animation.dispose();
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
        _scheduleGamificationBootstrap();
        _scheduleAnnouncement();
        return;
      }

      final profileData = await SimpleProfileService.getCurrentProfile();

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

  void _scheduleGamificationBootstrap() {
    if (_gamificationBootstrapScheduled) return;
    _gamificationBootstrapScheduled = true;
    // After deferred stagger so it does not contend with heatmap paint.
    Future<void>.delayed(const Duration(milliseconds: 3500), () {
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
      final achievementService = Provider.of<AchievementService>(
        context,
        listen: false,
      );
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

      // دستاورد اولین ورود
      await AchievementHooks.unlockOnce('first_login');
      await AchievementHooks.syncOwnedPrograms();

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
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: context.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: context.backgroundColor,
          elevation: 0,
        ),
      ),
      child: DecoratedBox(
        decoration: context.pageDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const DashboardAppBar(),
          body: _isLoading
              ? const DashboardLoadingScreen()
              : KeyedSubtree(
                  // Used to force a full subtree rebuild after a "hard refresh"
                  // (e.g., when caches are cleared or user data changes)
                  key: ValueKey<int>(_refreshKey),
                  child: _buildHomeTab(),
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
              padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // هویت
                  DashboardAnimatedSection(
                    child: WelcomeCard(
                      username: _username ?? 'کاربر عزیز',
                      welcomeMessage:
                          DashboardWelcomeHelpers.getWelcomeMessage(),
                      profileData: _profileData,
                      streak: _snapshot?.loginStreak ?? 0,
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // نقطه کانونی روز
                  DashboardAnimatedSection(
                    index: 1,
                    child: const TodaysProgramSection(),
                  ),
                  SizedBox(height: 12.h),

                  // ادامه جلسه / آخرین تمرین — فقط وقتی داده شخصی هست
                  DashboardAnimatedSection(
                    index: 2,
                    child: DashboardWorkoutContinueStrip(
                      refreshToken: _refreshKey,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // اکشن دوم روز: تغذیه (سبک‌تر از Hero تمرین)
                  const DashboardAnimatedSection(
                    index: 3,
                    child: DashboardCalorieHero(),
                  ),
                  SizedBox(height: 18.h),

                  // میانبرها — نه تکرار هیرو تمرین/تغذیه
                  const DashboardAnimatedSection(
                    index: 4,
                    child: DashboardQuickAccess(),
                  ),
                  SizedBox(height: 18.h),

                  // مربی AI — کشف روی خانه؛ تب پایین برایش نیست
                  const DashboardAnimatedSection(
                    index: 5,
                    child: DashboardAiBanner(),
                  ),
                  SizedBox(height: 18.h),

                  // وضعیت بدن
                  DashboardAnimatedSection(
                    index: 6,
                    child: DashboardStatsStrip(profileData: _profileData),
                  ),
                  SizedBox(height: 20.h),

                  // پیشرفت هفته
                  DashboardDeferredGate(
                    ready: _deferredReveal.isSectionReady(
                      DashboardDeferredSection.heatmap,
                    ),
                    placeholderHeight: 160.h,
                    child: DashboardAnimatedSection(
                      index: 7,
                      child: WeeklyMuscleHeatmapSection(
                        refreshToken: _refreshKey,
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
