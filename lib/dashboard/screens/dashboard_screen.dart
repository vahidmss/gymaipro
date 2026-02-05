import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/dashboard/widgets/exercises_tabs_section.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/dashboard/widgets/chat_section.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_app_bar.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_drawer.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_loading_screen.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_welcome.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_welcome_helpers.dart';
import 'package:gymaipro/dashboard/widgets/fitness_metrics.dart';
import 'package:gymaipro/dashboard/widgets/quick_action_buttons.dart';
import 'package:gymaipro/dashboard/widgets/todays_program_section.dart';
import 'package:gymaipro/dashboard/widgets/tip_card.dart';
import 'package:gymaipro/dashboard/widgets/weight_chart.dart';
import 'package:gymaipro/dashboard/widgets/academy_section.dart';
import 'package:gymaipro/guide/data/dashboard_guide_data.dart';
import 'package:gymaipro/guide/guide.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/services/auth_state_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/app_state.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/logout_cache_clear_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/streak_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
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

    _logoutFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoutAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize cache service
    DashboardCacheService().initialize();

    _loadUserData();

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
        await startGuide(context, 'dashboard_main_tour');
      }
    } catch (e) {
      debugPrint('Error showing tour: $e');
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _logoutAnimationController?.dispose();
    super.dispose();
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
  Future<void> _updateStreakAndMembershipAchievements() async {
    try {
      final streakService = StreakService();

      // به‌روزرسانی streak
      await streakService.updateLoginStreak();

      // به‌روزرسانی دستاوردهای membership
      await streakService.updateMembershipAchievements();
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
      'role': profileData['role'] ?? 'athlete', // اضافه کردن نقش به profileData
      'latest_weight': latestWeight,
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
      'role': 'athlete', // اضافه کردن نقش پیش‌فرض
    };
  }

  Future<void> _refreshAll() async {
    // If offline, show hint and stop refresh quickly
    try {
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'اتصال اینترنت برقرار نیست. رفرش ممکن نیست',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              duration: const Duration(seconds: 2),
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

      // Use post frame callback to ensure widget is still mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
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
            SnackBar(
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
                  child: Container(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
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
                  // کارت خوشامدگویی بهبود یافته
                  WelcomeCard(
                    key: DashboardGuideData.keys['welcome_card'],
                    username: _username ?? 'کاربر عزیز',
                    welcomeMessage: DashboardWelcomeHelpers.getWelcomeMessage(),
                    welcomeIcon: DashboardWelcomeHelpers.getWelcomeIcon(),
                    profileData: _profileData,
                  ),
                  SizedBox(height: 24.h),

                  // کارت‌های BMI و معیارهای فیزیکی
                  FitnessMetrics(
                    key: DashboardGuideData.keys['fitness_metrics'],
                    profileData: _profileData,
                  ),
                  SizedBox(height: 24.h),

                  // نمودار وزن (گروه‌بندی با معیارهای فیتنس)
                  if (_profileData['id'] != null)
                    WeightChart(
                      key: DashboardGuideData.keys['weight_chart'],
                      userId: _profileData['id'] as String,
                      currentWeight: double.tryParse(
                        (_profileData['weight'] as String?) ?? '',
                      ),
                    ),
                  if (_profileData['id'] != null) SizedBox(height: 24.h),

                  // حائل شیک (جداکننده بصری)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 12.h),
                    height: 1.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.goldColor.withValues(alpha: 0.3),
                          AppTheme.goldColor.withValues(alpha: 0.5),
                          AppTheme.goldColor.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // دکمه‌های سریع: ساخت برنامه، مربیان، دستاوردها
                  QuickActionButtons(
                    key: DashboardGuideData.keys['quick_actions'],
                  ),
                  SizedBox(height: 24.h),

                  // کارت نکته (محتوای آموزشی - break point)
                  TipCard(),
                  SizedBox(height: 24.h),

                  // بخش برنامه امروز من
                  TodaysProgramSection(
                    key: DashboardGuideData.keys['todays_program'],
                  ),
                  SizedBox(height: 32.h),

                  // بخش تب‌های تمرینات و تغذیه
                  ExercisesTabsSection(
                    key: DashboardGuideData.keys['exercises_tabs'],
                  ),
                  SizedBox(height: 24.h),

                  // بخش چت با خط طلایی و دایره
                  ChatSection(key: DashboardGuideData.keys['chat_section']),
                  SizedBox(height: 24.h),

                  // بخش آکادمی
                  AcademySection(
                    key: DashboardGuideData.keys['academy_section'],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
