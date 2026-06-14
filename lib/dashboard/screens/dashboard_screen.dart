import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/services/achievement_service.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
import 'package:gymaipro/announcements/services/in_app_announcement_service.dart';
import 'package:gymaipro/announcements/widgets/in_app_announcement_modal.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_animated_section.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_app_bar.dart';
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
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/services/app_state.dart';
import 'package:gymaipro/services/auth_state_service.dart';
import 'package:gymaipro/services/avatar_refresh_notifier.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
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

  // انیمیشن logout
  AnimationController? _logoutAnimationController;
  Animation<double>? _logoutFadeAnimation;
  bool _isLoggingOut = false;

  Map<String, dynamic> _profileData = {};
  String? _username;
  String? _userRole;
  bool _isLoading = true;
  int? _walletAvailableBalance;
  int _refreshKey = 0; // برای force rebuild ویجت‌های فرزند
  final InAppAnnouncementService _announcementService =
      InAppAnnouncementService();
  bool _isAnnouncementDialogVisible = false;

  @override
  void initState() {
    super.initState();

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
        _checkAndShowTour();
      }
    });
  }

  void _registerGuides() {
    try {
      // ثبت راهنمای اصلی داشبورد
      registerGuide(context, DashboardGuideData.getDashboardGuide());
      registerGuide(context, DashboardGuideData.getProgramBuilderGuide());
      registerGuide(context, DashboardGuideData.getWeightTrackingGuide());
    } catch (e) {
      debugPrint('Error registering guides: $e');
    }
  }

  Future<void> _checkAndShowTour() async {
    try {
      final guideService = Provider.of<GuideService>(context, listen: false);

      // اگر راهنمای drawer فعاله، راهنمای داشبورد رو شروع نکن
      if (guideService.hasActiveGuide &&
          guideService.activeGuide?.id == 'drawer_guide') {
        return;
      }

      // تاخیر برای اطمینان از render شدن ویجت‌ها
      await Future<void>.delayed(const Duration(milliseconds: 800));

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
    }
  }

  @override
  void dispose() {
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
        WidgetSafetyUtils.safeSetState(this, () {
          _profileData = _buildProfileData(profileData, latestWeight);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final cacheService = DashboardCacheService();

    try {
      // بررسی کش برای profile data - اما ابتدا بررسی کنیم که متعلق به کاربر فعلی است
      final currentUser = Supabase.instance.client.auth.currentUser;
      Map<String, dynamic>? cachedProfileData = cacheService.getProfileData();

      // بررسی اینکه کش متعلق به کاربر فعلی است
      if (cachedProfileData != null && currentUser != null) {
        final cachedUserId = cachedProfileData['id']?.toString();
        if (cachedUserId != currentUser.id) {
          // کش متعلق به کاربر قبلی است - پاک می‌کنیم
          cacheService.invalidateDashboard();
          cachedProfileData = null;
        }
      }

      if (cachedProfileData != null && currentUser != null) {
        final profileData = cachedProfileData; // برای null safety
        if (mounted) {
          final role = (profileData['role'] as String?) ?? 'athlete';
          WidgetSafetyUtils.safeSetState(this, () {
            _username = _getDisplayName(profileData);
            _userRole = role;
            _profileData = profileData;
            _isLoading = false;
          });
        }
        // بارگذاری کیف پول (نیازی به کش ندارد - حساس است)
        _loadWallet();
        // به‌روزرسانی streak و دستاوردهای membership
        _updateStreakAndMembershipAchievements();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryShowAnnouncement();
        });
        return;
      }

      // بارگذاری از API
      final profileData = await SimpleProfileService.getCurrentProfile();

      // بارگذاری کیف پول کاربر
      await _loadWallet();

      if (profileData != null && mounted) {
        // بارگذاری آخرین وزن ثبت شده
        double? latestWeight;
        try {
          final profileId = (profileData['id'] ?? '').toString();
          if (profileId.isNotEmpty) {
            latestWeight = await WeeklyWeightService.getLatestWeight(profileId);
            if (latestWeight != null) {
              cacheService.setLatestWeight(latestWeight);
            }
          }
        } catch (e) {
          // Error handled silently
        }

        final builtProfileData = _buildProfileData(profileData, latestWeight);

        // ذخیره در کش
        cacheService.setProfileData(builtProfileData);

        final role = (profileData['role'] as String?) ?? 'athlete';
        WidgetSafetyUtils.safeSetState(this, () {
          _username = _getDisplayName(profileData);
          _userRole = role;
          _profileData = builtProfileData;
          _isLoading = false;
        });

        // به‌روزرسانی streak و دستاوردهای membership
        _updateStreakAndMembershipAchievements();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryShowAnnouncement();
        });
      } else {
        if (mounted) {
          SafeSetState.call(this, () {
            _isLoading = false;
            _profileData = _getDefaultProfileData();
          });
        }
      }
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
        _profileData = _getDefaultProfileData();
      });
    }
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await WalletService().getUserWallet();
      if (mounted) {
        setState(() {
          _walletAvailableBalance = wallet?.availableBalance ?? wallet?.balance;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletAvailableBalance = null;
        });
      }
    }
  }

  /// به‌روزرسانی streak و دستاوردهای membership
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

      await _refreshGamificationScores();
    } catch (e) {
      // بی‌صدا - خطا در به‌روزرسانی streak نباید روی عملکرد اصلی تاثیر بگذارد
      debugPrint('⚠️ Error updating streak and membership achievements: $e');
    }
  }

  String _getDisplayName(Map<String, dynamic> profileData) {
    final firstName = (profileData['first_name'] ?? '').toString();
    final lastName = (profileData['last_name'] ?? '').toString();
    final username = (profileData['username'] ?? '').toString();
    final phone = (profileData['phone_number'] ?? '').toString();
    final email = (profileData['email'] ?? '').toString();

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty) return username;
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email.split('@').first;
    return 'کاربر عزیز';
  }

  Map<String, dynamic> _buildProfileData(
    Map<String, dynamic> profileData,
    double? latestWeight,
  ) {
    return {
      'id': profileData['id'] ?? '',
      'first_name': profileData['first_name'] ?? '',
      'last_name': profileData['last_name'] ?? '',
      'height': profileData['height']?.toString() ?? '0',
      'weight': profileData['weight']?.toString() ?? '0',
      'arm_circumference': profileData['arm_circumference']?.toString() ?? '',
      'chest_circumference':
          profileData['chest_circumference']?.toString() ?? '',
      'waist_circumference':
          profileData['waist_circumference']?.toString() ?? '',
      'hip_circumference': profileData['hip_circumference']?.toString() ?? '',
      'experience_level': profileData['experience_level'] ?? '',
      'preferred_training_days':
          profileData['preferred_training_days']?.join(',') ?? '',
      'preferred_training_time': profileData['preferred_training_time'] ?? '',
      'fitness_goals': profileData['fitness_goals']?.join(',') ?? '',
      'medical_conditions': profileData['medical_conditions']?.join(',') ?? '',
      'dietary_preferences':
          profileData['dietary_preferences']?.join(',') ?? '',
      'birth_date': profileData['birth_date']?.toString() ?? '',
      'gender': profileData['gender'] ?? 'male',
      'activity_level': profileData['activity_level'] ?? 'moderate',
      'weight_history': (profileData['weight_history'] as List<dynamic>?) ?? [],
      'username': profileData['username'] ?? '',
      'phone_number': profileData['phone_number'] ?? '',
      'avatar_url': profileData['avatar_url'] ?? '',
      'role': profileData['role'] ?? 'athlete',
      'latest_weight': latestWeight,
      'login_streak': (profileData['login_streak'] as num?)?.toInt() ?? 0,
    };
  }

  Map<String, dynamic> _getDefaultProfileData() {
    return {
      'first_name': '',
      'last_name': '',
      'height': '0',
      'weight': '0',
      'arm_circumference': '',
      'chest_circumference': '',
      'waist_circumference': '',
      'hip_circumference': '',
      'experience_level': '',
      'preferred_training_days': '',
      'preferred_training_time': '',
      'fitness_goals': '',
      'medical_conditions': '',
      'dietary_preferences': '',
      'birth_date': '',
      'gender': 'male',
      'activity_level': 'moderate',
      'weight_history': <dynamic>[],
      'username': '',
      'phone_number': '',
      'avatar_url': '',
      'role': 'athlete',
      'login_streak': 0,
    };
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

    // Clear all caches
    try {
      FoodService().clearCache();
      ExerciseService().clearCache();
      DashboardCacheService().invalidateDashboard();
    } catch (_) {}

    // به‌روزرسانی کش اطلاعات کاربر برای هوش مصنوعی (در بک‌گراند)
    try {
      UserContextCacheService.refreshUserContextCache();
    } catch (_) {}

    // Trigger dependent notifiers/services to refresh
    try {
      final chatUnread = Provider.of<ChatUnreadNotifier>(
        context,
        listen: false,
      );
      await chatUnread.refreshUnreadCount();
    } catch (_) {}

    // بارگذاری امتیاز و ستاره‌های دستاورد از منبع واقعی
    try {
      await _refreshGamificationScores(force: true);
    } catch (_) {}

    // Reload dashboard user data and rebuild
    setState(() {
      _isLoading = true;
    });
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

      // پاک کردن تمام کش‌ها و داده‌های کاربر قبل از logout
      await LogoutCacheClearService.clearAllUserData();

      // پاک کردن AppState
      await AppState().logout();

      // خروج از Supabase
      await SupabaseService().signOut();

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
        _logoutAnimationController?.reverse();
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
                appBar: const DashboardAppBar(),
                drawer: DashboardDrawer(
                  username: _username,
                  userRole: _userRole,
                  walletBalance: _walletAvailableBalance,
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ۰. کارت خوش‌آمدگویی (با Streak داخلش) ──
                  DashboardAnimatedSection(
                    child: WelcomeCard(
                      key: DashboardGuideData.keys['welcome_card'],
                      username: _username ?? 'کاربر عزیز',
                      welcomeMessage:
                          DashboardWelcomeHelpers.getWelcomeMessage(),
                      welcomeIcon: DashboardWelcomeHelpers.getWelcomeIcon(),
                      profileData: _profileData,
                      streak:
                          (_profileData['login_streak'] as num?)?.toInt() ?? 0,
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
                      key: DashboardGuideData.keys['todays_program'],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۴. اقدامات سریع ──
                  DashboardAnimatedSection(
                    index: 4,
                    child: QuickActionButtons(
                      key: DashboardGuideData.keys['quick_actions'],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۵. هیت‌مپ عضلانی هفتگی ──
                  DashboardAnimatedSection(
                    index: 5,
                    child: WeeklyMuscleHeatmapSection(
                      refreshToken: _refreshKey,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۶. متریک‌های فیتنس ──
                  DashboardAnimatedSection(
                    index: 6,
                    child: FitnessMetrics(
                      key: DashboardGuideData.keys['fitness_metrics'],
                      profileData: _profileData,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۷. نمودار وزن ──
                  DashboardAnimatedSection(
                    index: 7,
                    child: _profileData['id'] != null
                        ? WeightChart(
                            key: DashboardGuideData.keys['weight_chart'],
                            userId: _profileData['id'] as String,
                            currentWeight: double.tryParse(
                              (_profileData['weight'] as String?) ?? '',
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  ...(_profileData['id'] != null
                      ? [SizedBox(height: 24.h)]
                      : []),

                  // ── ۸. محتوای پیشنهادی - ویدیو، مقاله، موزیک ──
                  const DashboardAnimatedSection(
                    index: 8,
                    child: DashboardHeroCarousel(),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۹. کشف جدیدها - تمرینات و تغذیه ──
                  const DashboardAnimatedSection(
                    index: 9,
                    child: DiscoverSection(),
                  ),
                  SizedBox(height: 24.h),

                  // ── ۱۰. رتبه‌بندی ──
                  const DashboardAnimatedSection(
                    index: 10,
                    child: TopRankingsSection(),
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
