import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/fitness_metrics.dart';
import 'package:gymaipro/widgets/dashboard_welcome.dart';
import 'package:gymaipro/widgets/dashboard_nav.dart';
import 'package:gymaipro/widgets/dashboard_workout.dart';
import 'package:gymaipro/widgets/dashboard_analytics.dart';
import 'package:gymaipro/widgets/dashboard_profile.dart';
import 'package:gymaipro/widgets/quick_actions_section.dart' as quick_actions;
import 'package:gymaipro/widgets/latest_items_section.dart';
import 'package:gymaipro/widgets/meal_planning_section.dart';
import 'package:gymaipro/widgets/weight_height_display.dart';
import 'package:gymaipro/widgets/chat_notification_badge.dart';
import 'package:gymaipro/widgets/trainers_chat_section.dart';
import 'package:gymaipro/widgets/chat_widget.dart';
import 'package:gymaipro/widgets/public_chat_widget.dart';
import 'package:gymaipro/widgets/chat_tabs_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
  bool _isLoading = true;

  // Bottom Navigation
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    // Main animations
    _animation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animation, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final supabase = SupabaseService();
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        final profile = await supabase.getProfileByAuthId();

        if (profile != null && mounted) {
          setState(() {
            _username =
                profile.firstName ?? profile.phoneNumber ?? 'کاربر عزیز';
            _profileData = {
              'height': profile.height?.toString() ?? '',
              'weight': profile.weight?.toString() ?? '',
              'arm_circumference': profile.armCircumference?.toString() ?? '',
              'chest_circumference':
                  profile.chestCircumference?.toString() ?? '',
              'waist_circumference':
                  profile.waistCircumference?.toString() ?? '',
              'hip_circumference': profile.hipCircumference?.toString() ?? '',
              'experience_level': profile.experienceLevel ?? '',
              'preferred_training_days':
                  profile.preferredTrainingDays?.join(',') ?? '',
              'preferred_training_time': profile.preferredTrainingTime ?? '',
              'fitness_goals': profile.fitnessGoals?.join(',') ?? '',
              'medical_conditions': profile.medicalConditions?.join(',') ?? '',
              'dietary_preferences':
                  profile.dietaryPreferences?.join(',') ?? '',
              'birth_date': profile.birthDate?.toString() ?? '',
              'gender': profile.gender ?? 'male',
              'weight_history': profile.weightHistory ?? [],
              'username': profile.phoneNumber,
              'phone_number': profile.phoneNumber ?? '',
            };
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService().signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در خروج از حساب کاربری')),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  double _getDailyProgress() {
    // Simple progress calculation - can be enhanced
    return 0.7; // 70% progress
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
        body: _isLoading
            ? _buildLoadingScreen()
            : PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _buildHomeTab(),
                  _buildWorkoutsTab(),
                  _buildAnalyticsTab(),
                  _buildProfileTab(),
                ],
              ),
        bottomNavigationBar: DashboardBottomNav(
          currentIndex: _currentIndex,
          onTabTapped: _onTabTapped,
        ),
        floatingActionButton: DashboardFAB(
          onWorkoutLog: () => Navigator.pushNamed(context, '/workout-log'),
          onNewProgram: () =>
              Navigator.pushNamed(context, '/workout-program-builder'),
          onTrainers: () => Navigator.pushNamed(context, '/trainers'),
          onChat: () => Navigator.pushNamed(context, '/conversations'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          const SizedBox(height: 16),
          Text(
            'در حال بارگیری اطلاعات...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
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
              await _loadUserData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WelcomeCard(
                    username: _username ?? 'کاربر عزیز',
                    welcomeMessage: _getWelcomeMessage(),
                    welcomeIcon: _getWelcomeIcon(),
                    dailyProgressBar:
                        DailyProgressBar(progress: _getDailyProgress()),
                  ),
                  const SizedBox(height: 20),
                  WeightHeightDisplay(
                    weight: '${_profileData['weight'] ?? '0'} کیلوگرم',
                    height: '${_profileData['height'] ?? '0'} سانتی‌متر',
                  ),
                  const SizedBox(height: 20),
                  const ChatTabsWidget(),
                  const SizedBox(height: 20),
                  const quick_actions.QuickActionsSection(),
                  const SizedBox(height: 20),
                  const LatestItemsSection(),
                  const SizedBox(height: 20),
                  const MealPlanningSection(),
                  const SizedBox(height: 20),
                  FitnessMetrics(profileData: _profileData),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TodayWorkoutSection(workoutItems: _buildWorkoutItems()),
            const SizedBox(height: 20),
            WorkoutSplitSection(splitItems: _buildSplitItems()),
            const SizedBox(height: 20),
            QuickActionsSection(actionButtons: _buildQuickActionButtons()),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsCardsSection(analyticsCards: _buildAnalyticsCards()),
            const SizedBox(height: 20),
            ProgressChartsSection(progressBars: _buildProgressBars()),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(
              username: _username ?? 'کاربر عزیز',
              phoneNumber: _profileData['phone_number'] ?? '',
              onEditProfile: () => Navigator.pushNamed(context, '/profile'),
            ),
            const SizedBox(height: 20),
            ProfileStats(statItems: _buildProfileStatItems()),
            const SizedBox(height: 20),
            ProfileActions(actionItems: _buildProfileActionItems()),
          ],
        ),
      ),
    );
  }

  // Helper methods for building widget lists

  List<Widget> _buildWorkoutItems() {
    return [
      WorkoutItem(
        title: 'تمرین امروز',
        subtitle: 'پرس سینه - 3 ست',
        icon: LucideIcons.dumbbell,
        onTap: () {},
      ),
    ];
  }

  List<Widget> _buildSplitItems() {
    return [
      SplitItem(
        day: 'شنبه',
        workout: 'سینه و پشت بازو',
        isCompleted: true,
        onTap: () {},
      ),
      SplitItem(
        day: 'یکشنبه',
        workout: 'پشت و جلو بازو',
        isCompleted: false,
        onTap: () {},
      ),
    ];
  }

  List<Widget> _buildQuickActionButtons() {
    return [
      QuickActionButton(
        title: 'ثبت تمرین',
        icon: LucideIcons.plus,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/workout-log'),
      ),
      QuickActionButton(
        title: 'برنامه جدید',
        icon: LucideIcons.clipboardList,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/workout-program-builder'),
      ),
      QuickActionButton(
        title: 'آموزش حرکات',
        icon: LucideIcons.bookOpen,
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, '/exercise-list'),
      ),
      QuickActionButton(
        title: 'خوراکی‌ها',
        icon: LucideIcons.utensils,
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/food-list'),
      ),
    ];
  }

  List<Widget> _buildAnalyticsCards() {
    return [
      const AnalyticsCard(
        title: 'تمرینات این هفته',
        value: '5',
        subtitle: 'از 7 روز',
        icon: LucideIcons.calendar,
        color: Colors.blue,
      ),
      const AnalyticsCard(
        title: 'وزن کل',
        value: '1250',
        subtitle: 'کیلوگرم',
        icon: LucideIcons.dumbbell,
        color: Colors.green,
      ),
      const AnalyticsCard(
        title: 'زمان تمرین',
        value: '45',
        subtitle: 'دقیقه',
        icon: LucideIcons.clock,
        color: Colors.orange,
      ),
      const AnalyticsCard(
        title: 'کالری سوزانده',
        value: '320',
        subtitle: 'کالری',
        icon: LucideIcons.flame,
        color: Colors.red,
      ),
    ];
  }

  List<Widget> _buildProgressBars() {
    return [
      const ProgressBar(
        label: 'پرس سینه',
        progress: 0.8,
        value: '80 کیلوگرم',
        color: Colors.blue,
      ),
      const ProgressBar(
        label: 'اسکوات',
        progress: 0.6,
        value: '100 کیلوگرم',
        color: Colors.green,
      ),
      const ProgressBar(
        label: 'ددلیفت',
        progress: 0.9,
        value: '120 کیلوگرم',
        color: Colors.orange,
      ),
    ];
  }

  List<Widget> _buildProfileStatItems() {
    return [
      const ProfileStatItem(
        label: 'تعداد تمرینات',
        value: '24',
        icon: LucideIcons.dumbbell,
        color: Colors.blue,
      ),
      const ProfileStatItem(
        label: 'روزهای تمرین',
        value: '12',
        icon: LucideIcons.calendar,
        color: Colors.green,
      ),
      const ProfileStatItem(
        label: 'زمان کل',
        value: '18 ساعت',
        icon: LucideIcons.clock,
        color: Colors.orange,
      ),
    ];
  }

  List<Widget> _buildProfileActionItems() {
    return [
      ProfileActionItem(
        title: 'ویرایش پروفایل',
        subtitle: 'تغییر اطلاعات شخصی',
        icon: LucideIcons.edit,
        onTap: () => Navigator.pushNamed(context, '/profile'),
      ),
      ProfileActionItem(
        title: 'تنظیمات',
        subtitle: 'تنظیمات اپلیکیشن',
        icon: LucideIcons.settings,
        onTap: () {},
      ),
      ProfileActionItem(
        title: 'خروج',
        subtitle: 'خروج از حساب کاربری',
        icon: LucideIcons.logOut,
        color: Colors.red,
        onTap: _signOut,
      ),
    ];
  }
}
