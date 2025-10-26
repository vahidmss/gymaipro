import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/widgets/academy_preview_section.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/chat/widgets/chat_tabs_widget.dart';
import 'package:gymaipro/dashboard/widgets/dashboard_welcome.dart';
import 'package:gymaipro/dashboard/widgets/fitness_metrics.dart';
import 'package:gymaipro/dashboard/widgets/latest_items_section.dart';
import 'package:gymaipro/dashboard/widgets/quick_shortcuts_grid.dart';
import 'package:gymaipro/dashboard/widgets/weight_chart.dart';
import 'package:gymaipro/meal_plan/meal_log/screens/meal_log_screen.dart';
import 'package:gymaipro/notification/screens/notification_settings_screen.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/screens/help_screen.dart';
import 'package:gymaipro/screens/settings_screen.dart';
import 'package:gymaipro/services/auth_state_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_dashboard_screen.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
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

  Map<String, dynamic> _profileData = {};
  String? _username;
  String? _userRole;
  bool _isLoading = true;
  int? _walletAvailableBalance;

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

    _loadUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animation.forward();
      }
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      print('=== DASHBOARD: Loading user data ===');

      // تست کامل احراز هویت
      print('=== DASHBOARD: Testing authentication status ===');

      // 1. بررسی وضعیت لاگین
      final authService = AuthStateService();
      final isLoggedIn = await authService.isLoggedIn();
      print('=== DASHBOARD: Is user logged in: $isLoggedIn ===');

      // 2. بررسی Supabase session
      final currentSession = Supabase.instance.client.auth.currentSession;
      print(
        '=== DASHBOARD: Supabase session: ${currentSession != null ? "exists" : "null"} ===',
      );
      if (currentSession != null) {
        print('=== DASHBOARD: Session user ID: ${currentSession.user.id} ===');
        print(
          '=== DASHBOARD: Session access token: ${currentSession.accessToken.substring(0, 10)}... ===',
        );
      }

      // 4. بررسی current user
      final currentUser = Supabase.instance.client.auth.currentUser;
      print('=== DASHBOARD: Current user: ${currentUser?.id ?? "null"} ===');

      // 5. تست دسترسی به داده‌های کاربر
      if (currentUser != null) {
        print('=== DASHBOARD: Testing user data access ===');
        try {
          // تست دسترسی به profiles table
          final testProfile = await Supabase.instance.client
              .from('profiles')
              .select('id, username, phone_number')
              .eq('id', currentUser.id)
              .maybeSingle();

          if (testProfile != null) {
            print(
              '=== DASHBOARD: Profile access successful: ${testProfile['username']} ===',
            );
          } else {
            print('=== DASHBOARD: Profile access failed: No profile found ===');
          }
        } catch (e) {
          print('=== DASHBOARD: Profile access error: $e ===');
        }
      }

      // استفاده از SimpleProfileService بجای ProfileService
      final profileData = await SimpleProfileService.getCurrentProfile();

      // بارگذاری کیف پول کاربر برای نمایش بالانس در هدر
      try {
        final wallet = await WalletService().getUserWallet();
        _walletAvailableBalance = wallet?.availableBalance ?? wallet?.balance;
      } catch (e) {
        _walletAvailableBalance = null;
      }

      if (profileData != null && mounted) {
        print('Dashboard profile loaded: ${profileData['username']}');
        print('Dashboard first_name: ${profileData['first_name']}');
        print('Dashboard last_name: ${profileData['last_name']}');
        print('Dashboard weight: ${profileData['weight']}');

        // بارگذاری آخرین وزن ثبت شده (اگر user ID موجود باشد)
        double? latestWeight;
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            latestWeight = await WeeklyWeightService.getLatestWeight(user.id);
          }
        } catch (e) {
          print('Error loading latest weight: $e');
        }

        setState(() {
          final String nameFromProfile = (profileData['username'] ?? '')
              .toString();
          final String firstName = (profileData['first_name'] ?? '').toString();
          final String lastName = (profileData['last_name'] ?? '').toString();
          final String phone = (profileData['phone_number'] ?? '').toString();
          final String email = (profileData['email'] ?? '').toString();

          String displayName = 'کاربر عزیز';
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            displayName = fullName;
          } else if (nameFromProfile.isNotEmpty) {
            displayName = nameFromProfile;
          } else if (phone.isNotEmpty) {
            displayName = phone;
          } else if (email.isNotEmpty) {
            displayName = email.split('@').first;
          }

          _username = displayName;
          _userRole = (profileData['role'] as String?) ?? 'athlete';
          _profileData = {
            'id': profileData['id'] ?? '',
            'first_name': profileData['first_name'] ?? '',
            'last_name': profileData['last_name'] ?? '',
            'height': profileData['height']?.toString() ?? '0',
            'weight': profileData['weight']?.toString() ?? '0',
            'arm_circumference':
                profileData['arm_circumference']?.toString() ?? '',
            'chest_circumference':
                profileData['chest_circumference']?.toString() ?? '',
            'waist_circumference':
                profileData['waist_circumference']?.toString() ?? '',
            'hip_circumference':
                profileData['hip_circumference']?.toString() ?? '',
            'experience_level': profileData['experience_level'] ?? '',
            'preferred_training_days':
                profileData['preferred_training_days']?.join(',') ?? '',
            'preferred_training_time':
                profileData['preferred_training_time'] ?? '',
            'fitness_goals': profileData['fitness_goals']?.join(',') ?? '',
            'medical_conditions':
                profileData['medical_conditions']?.join(',') ?? '',
            'dietary_preferences':
                profileData['dietary_preferences']?.join(',') ?? '',
            'birth_date': profileData['birth_date']?.toString() ?? '',
            'gender': profileData['gender'] ?? 'male',
            'weight_history':
                (profileData['weight_history'] as List<dynamic>?) ?? [],
            'username': profileData['username'] ?? '',
            'phone_number': profileData['phone_number'] ?? '',
            'avatar_url': profileData['avatar_url'] ?? '',
            'latest_weight': latestWeight,
          };
          _isLoading = false;
        });

        print('Dashboard data loaded successfully');
      } else {
        print('No profile data found for dashboard');
        if (mounted) {
          SafeSetState.call(this, () {
            _isLoading = false;
            _profileData = {
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
              'weight_history': <dynamic>[],
              'username': '',
              'phone_number': '',
              'avatar_url': '',
            };
          });
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      SafeSetState.call(this, () {
        _isLoading = false;
        _profileData = {
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
          'weight_history': <dynamic>[],
          'username': '',
          'phone_number': '',
          'avatar_url': '',
        };
      });
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
              content: Text('اتصال اینترنت برقرار نیست. رفرش ممکن نیست'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    } catch (_) {
      return;
    }

    // Clear caches that affect dashboard content
    try {
      FoodService().clearCache();
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
    await _loadUserData();
  }

  Future<void> _signOut() async {
    try {
      // خروج از Supabase
      await SupabaseService().signOut();

      await AuthStateService().clearAuthState();
      print('User signed out successfully');

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
      print('Error during sign out: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در خروج از حساب کاربری')),
          );
        }
      });
    }
  }

  // Helper methods for welcome card
  String _getWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صبح بخیر';
    if (hour < 17) return 'ظهر بخیر';
    if (hour < 20) return 'عصر بخیر';
    return 'شب بخیر';
  }

  IconData _getWelcomeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return LucideIcons.sun;
    if (hour < 17) return LucideIcons.sun;
    if (hour < 20) return LucideIcons.sunset;
    return LucideIcons.moon;
  }

  String _getSafeInitial() {
    if (_username == null || _username!.isEmpty) {
      return 'U';
    }
    return _username!.substring(0, 1).toUpperCase();
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Column(
          children: [
            // Header with gradient and modern design
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF2A2A2A),
                    Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                ),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    blurRadius: 20.r,
                    offset: Offset(0.w, 4.h),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // User profile section
                  Row(
                    children: [
                      // Avatar with enhanced styling
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 2.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8.r,
                              offset: Offset(0.w, 2.h),
                            ),
                          ],
                        ),
                        child: FutureBuilder<dynamic>(
                          future: Supabase.instance.client
                              .from('profiles')
                              .select('avatar_url')
                              .eq(
                                'id',
                                Supabase.instance.client.auth.currentUser?.id ??
                                    '',
                              )
                              .maybeSingle(),
                          builder: (context, snapshot) {
                            final avatarUrl = (snapshot.data != null)
                                ? (snapshot.data['avatar_url'] as String?)
                                : null;
                            if (avatarUrl != null && avatarUrl.isNotEmpty) {
                              return CircleAvatar(
                                radius: ResponsiveValue(
                                  context,
                                  defaultValue: 28.r,
                                  conditionalValues: [
                                    Condition.smallerThan(
                                      name: MOBILE,
                                      value: 24.r,
                                    ),
                                    Condition.largerThan(
                                      name: TABLET,
                                      value: 32.r,
                                    ),
                                  ],
                                ).value,
                                backgroundImage: NetworkImage(avatarUrl),
                                backgroundColor: Colors.transparent,
                              );
                            }
                            return CircleAvatar(
                              radius: ResponsiveValue(
                                context,
                                defaultValue: 28.r,
                                conditionalValues: [
                                  Condition.smallerThan(
                                    name: MOBILE,
                                    value: 24.r,
                                  ),
                                  Condition.largerThan(
                                    name: TABLET,
                                    value: 32.r,
                                  ),
                                ],
                              ).value,
                              backgroundColor: const Color(0xFFD4AF37),
                              child: Text(
                                _getSafeInitial(),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveValue(
                                    context,
                                    defaultValue: 18.sp,
                                    conditionalValues: [
                                      Condition.smallerThan(
                                        name: MOBILE,
                                        value: 16.sp,
                                      ),
                                      Condition.largerThan(
                                        name: TABLET,
                                        value: 20.sp,
                                      ),
                                    ],
                                  ).value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username ?? 'کاربر عزیز',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: ResponsiveValue(
                                  context,
                                  defaultValue: 18.sp,
                                  conditionalValues: [
                                    Condition.smallerThan(
                                      name: MOBILE,
                                      value: 16.sp,
                                    ),
                                    Condition.largerThan(
                                      name: TABLET,
                                      value: 20.sp,
                                    ),
                                  ],
                                ).value,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: _userRole == 'trainer'
                                    ? const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.2)
                                    : const Color(
                                        0xFF4CAF50,
                                      ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: _userRole == 'trainer'
                                      ? const Color(0xFFD4AF37)
                                      : const Color(0xFF4CAF50),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _userRole == 'trainer'
                                        ? LucideIcons.crown
                                        : LucideIcons.user,
                                    color: _userRole == 'trainer'
                                        ? const Color(0xFFD4AF37)
                                        : const Color(0xFF4CAF50),
                                    size: ResponsiveValue(
                                      context,
                                      defaultValue: 14.sp,
                                      conditionalValues: [
                                        Condition.smallerThan(
                                          name: MOBILE,
                                          value: 12.sp,
                                        ),
                                        Condition.largerThan(
                                          name: TABLET,
                                          value: 16.sp,
                                        ),
                                      ],
                                    ).value,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _userRole == 'trainer' ? 'مربی' : 'ورزشکار',
                                    style: TextStyle(
                                      color: _userRole == 'trainer'
                                          ? const Color(0xFFD4AF37)
                                          : const Color(0xFF4CAF50),
                                      fontSize: ResponsiveValue(
                                        context,
                                        defaultValue: 12.sp,
                                        conditionalValues: [
                                          Condition.smallerThan(
                                            name: MOBILE,
                                            value: 10.sp,
                                          ),
                                          Condition.largerThan(
                                            name: TABLET,
                                            value: 14.sp,
                                          ),
                                        ],
                                      ).value,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Wallet section with enhanced design
                      InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () => Navigator.pushNamed(context, '/wallet'),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8.r,
                                offset: Offset(0.w, 2.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.wallet,
                                color: Colors.black,
                                size: ResponsiveValue(
                                  context,
                                  defaultValue: 16.sp,
                                  conditionalValues: [
                                    Condition.smallerThan(
                                      name: MOBILE,
                                      value: 14.sp,
                                    ),
                                    Condition.largerThan(
                                      name: TABLET,
                                      value: 18.sp,
                                    ),
                                  ],
                                ).value,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                _walletAvailableBalance != null
                                    ? PaymentConstants.formatAmount(
                                        _walletAvailableBalance!,
                                      )
                                    : 'کیف پول',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: ResponsiveValue(
                                    context,
                                    defaultValue: 12.sp,
                                    conditionalValues: [
                                      Condition.smallerThan(
                                        name: MOBILE,
                                        value: 10.sp,
                                      ),
                                      Condition.largerThan(
                                        name: TABLET,
                                        value: 14.sp,
                                      ),
                                    ],
                                  ).value,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // Menu Items with enhanced design
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                children: [
                  // My Club moved from dashboard body to drawer
                  _buildMenuItem(
                    icon: LucideIcons.users,
                    title: 'باشگاه من',
                    subtitle: 'مربی‌ها، دوستان و برنامه‌ها',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/my-club');
                    },
                  ),

                  SizedBox(height: 8.h),

                  // Trainer Dashboard Section (with lock for non-trainers)
                  _buildMenuItem(
                    icon: LucideIcons.users,
                    title: 'میز کار مربی',
                    subtitle: 'مدیریت شاگردان و آمار',
                    isLocked: _userRole != 'trainer',
                    onTap: _userRole == 'trainer'
                        ? () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    const TrainerDashboardScreen(),
                              ),
                            );
                          }
                        : null,
                  ),

                  SizedBox(height: 8.h),

                  // Notification Settings
                  _buildMenuItem(
                    icon: LucideIcons.bell,
                    title: 'تنظیمات اعلان‌ها',
                    subtitle: 'مدیریت نوتیفیکیشن‌ها',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 8.h),

                  // General Settings
                  _buildMenuItem(
                    icon: LucideIcons.settings,
                    title: 'تنظیمات عمومی',
                    subtitle: 'تنظیمات اپلیکیشن',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 8.h),

                  // Help
                  _buildMenuItem(
                    icon: LucideIcons.helpCircle,
                    title: 'راهنما',
                    subtitle: 'آموزش استفاده از اپلیکیشن',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const HelpScreen(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Logout with enhanced styling
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          LucideIcons.logOut,
                          color: Colors.red,
                          size: ResponsiveValue(
                            context,
                            defaultValue: 20.sp,
                            conditionalValues: [
                              Condition.smallerThan(name: MOBILE, value: 18.sp),
                              Condition.largerThan(name: TABLET, value: 22.sp),
                            ],
                          ).value,
                        ),
                      ),
                      title: Text(
                        'خروج از حساب',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveValue(
                            context,
                            defaultValue: 16.sp,
                            conditionalValues: [
                              Condition.smallerThan(name: MOBILE, value: 14.sp),
                              Condition.largerThan(name: TABLET, value: 18.sp),
                            ],
                          ).value,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _signOut();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.grey.withValues(alpha: 0.1)
            : const Color(0xFF1A1A1A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isLocked
              ? Colors.grey.withValues(alpha: 0.3)
              : const Color(0xFFD4AF37).withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.grey.withValues(alpha: 0.2)
                : const Color(0xFFD4AF37).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isLocked
                  ? Colors.grey.withValues(alpha: 0.5)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.5),
            ),
          ),
          child: Icon(
            isLocked ? LucideIcons.lock : icon,
            color: isLocked ? Colors.grey : const Color(0xFFD4AF37),
            size: ResponsiveValue(
              context,
              defaultValue: 20.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 18.sp),
                Condition.largerThan(name: TABLET, value: 22.sp),
              ],
            ).value,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLocked ? Colors.grey : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveValue(
              context,
              defaultValue: 16.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 14.sp),
                Condition.largerThan(name: TABLET, value: 18.sp),
              ],
            ).value,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isLocked
                ? Colors.grey.withValues(alpha: 0.7)
                : Colors.white70,
            fontSize: ResponsiveValue(
              context,
              defaultValue: 12.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 10.sp),
                Condition.largerThan(name: TABLET, value: 14.sp),
              ],
            ).value,
          ),
        ),
        trailing: isLocked
            ? Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  LucideIcons.lock,
                  color: Colors.grey,
                  size: ResponsiveValue(
                    context,
                    defaultValue: 14.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 12.sp),
                      Condition.largerThan(name: TABLET, value: 16.sp),
                    ],
                  ).value,
                ),
              )
            : Icon(
                LucideIcons.chevronLeft,
                color: const Color(0xFFD4AF37),
                size: ResponsiveValue(
                  context,
                  defaultValue: 16.sp,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 14.sp),
                    Condition.largerThan(name: TABLET, value: 18.sp),
                  ],
                ).value,
              ),
        onTap: isLocked ? null : onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Colors.black,
                  size: ResponsiveValue(
                    context,
                    defaultValue: 20.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 18.sp),
                      Condition.largerThan(name: TABLET, value: 22.sp),
                    ],
                  ).value,
                ),
                SizedBox(width: 6.w),
                Text(
                  'GYMAI',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveValue(
                      context,
                      defaultValue: 16.sp,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 14.sp),
                        Condition.largerThan(name: TABLET, value: 18.sp),
                      ],
                    ).value,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                LucideIcons.menu,
                color: AppTheme.goldColor,
                size: ResponsiveValue(
                  context,
                  defaultValue: 24.sp,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 22.sp),
                    Condition.largerThan(name: TABLET, value: 26.sp),
                  ],
                ).value,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        drawer: _buildDrawer(),
        body: _isLoading ? _buildLoadingScreen() : _buildHomeTab(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppTheme.goldColor,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'در حال بارگیری اطلاعات...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: ResponsiveValue(
                context,
                defaultValue: 14.sp,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 12.sp),
                  Condition.largerThan(name: TABLET, value: 16.sp),
                ],
              ).value,
            ),
          ),
        ],
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      kToolbarHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // کارت خوشامدگویی بهبود یافته
                    WelcomeCard(
                      username: _username ?? 'کاربر عزیز',
                      welcomeMessage: _getWelcomeMessage(),
                      welcomeIcon: _getWelcomeIcon(),
                      profileData: _profileData,
                    ),
                    SizedBox(height: 20.h),

                    // کارت‌های BMI و معیارهای فیزیکی
                    FitnessMetrics(profileData: _profileData),
                    SizedBox(height: 20.h),

                    // نمودار وزن
                    if (_profileData['id'] != null)
                      WeightChart(
                        userId: _profileData['id'] as String,
                        currentWeight: double.tryParse(
                          (_profileData['weight'] as String?) ?? '',
                        ),
                      ),
                    SizedBox(height: 20.h),

                    // ناوبری جمع‌وجور: گرید گلس‌مورفیسم میانبرها
                    QuickShortcutsGrid(
                      title: 'میانبرها',
                      items: [
                        QuickShortcutItem(
                          title: 'ثبت تمرین',
                          subtitle: 'افزودن تمرین روزانه',
                          icon: LucideIcons.plus,
                          onTap: () =>
                              Navigator.pushNamed(context, '/workout-log'),
                          gradient: [
                            const Color(0xFF1F2A38),
                            const Color(0xFF2C3E50),
                          ],
                        ),
                        QuickShortcutItem(
                          title: 'ثبت رژیم غذایی',
                          subtitle: 'غذاهای امروز را ثبت کن',
                          icon: LucideIcons.calendar,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const FoodLogScreen(),
                            ),
                          ),
                          gradient: [
                            const Color(0xFF8E4B10),
                            const Color(0xFFE67E22),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // آیکون کیف پول در هدر اضافه شد؛ کارت‌ها حذف شدند
                    SizedBox(height: 20.h),

                    const LatestItemsSection(),
                    SizedBox(height: 20.h),

                    // آکادمی جیم‌آی: پیش‌نمایش افقی + دکمه مشاهده همه
                    const AcademyPreviewSection(),
                    SizedBox(height: 20.h),

                    // چت را به پایین منتقل کردیم
                    const ChatTabsWidget(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
