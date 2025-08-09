// Flutter imports
import 'package:flutter/material.dart';
import 'package:gymaipro/trainer_dashboard/screens/client_management/client_management_screen.dart';

// Third-party imports
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// App imports
import 'package:gymaipro/services/supabase_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';

// Dashboard widgets - using barrel export
import '../widgets/dashboard_widgets.dart';

// Other widgets
import 'package:gymaipro/widgets/chat_tabs_widget.dart';

// Screen imports
import '../../meal_plan/meal_plan_builder/screens/meal_plan_builder_screen.dart';
import '../../meal_plan/meal_log/screens/meal_log_screen.dart';

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
  String? _userRole;
  bool _isLoading = true;

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
            _userRole = profile.role;
            _profileData = {
              'first_name': profile.firstName ?? '',
              'last_name': profile.lastName ?? '',
              'height': profile.height?.toString() ?? '0',
              'weight': profile.weight?.toString() ?? '0',
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
          SafeSetState.call(this, () {
            _isLoading = false;
            // اطمینان از اینکه _profileData همیشه مقدار داشته باشد
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
              'weight_history': [],
              'username': '',
              'phone_number': '',
            };
          });
        }
      } else if (mounted) {
        SafeSetState.call(this, () {
          _isLoading = false;
          // اطمینان از اینکه _profileData همیشه مقدار داشته باشد
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
            'weight_history': [],
            'username': '',
            'phone_number': '',
          };
        });
      }
    } catch (e) {
      // Error handled silently - user will see loading state
      SafeSetState.call(this, () {
        _isLoading = false;
        // اطمینان از اینکه _profileData همیشه مقدار داشته باشد
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
          'weight_history': [],
          'username': '',
          'phone_number': '',
        };
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService().signOut();

      // Use post frame callback to ensure widget is still mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      });
    } catch (e) {
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
      backgroundColor: AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.goldColor,
                    child: Text(
                      _getSafeInitial(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username ?? 'کاربر عزیز',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _userRole == 'trainer' ? 'مربی' : 'ورزشکار',
                          style: const TextStyle(
                            color: AppTheme.goldColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  // داشبورد مربی (فقط برای مربیان)
                  if (_userRole == 'trainer') ...[
                    ListTile(
                      leading: const Icon(
                        LucideIcons.users,
                        color: AppTheme.goldColor,
                      ),
                      title: const Text(
                        'داشبورد مربی',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'مدیریت شاگردان',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        Navigator.pop(context); // بستن drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ClientManagementScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24),
                  ],

                  // سایر آیتم‌های منو
                  ListTile(
                    leading: const Icon(
                      LucideIcons.settings,
                      color: AppTheme.goldColor,
                    ),
                    title: const Text(
                      'تنظیمات',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: انتقال به صفحه تنظیمات
                    },
                  ),

                  ListTile(
                    leading: const Icon(
                      LucideIcons.helpCircle,
                      color: AppTheme.goldColor,
                    ),
                    title: const Text(
                      'راهنما',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: انتقال به صفحه راهنما
                    },
                  ),

                  const Divider(color: Colors.white24),

                  ListTile(
                    leading: const Icon(
                      LucideIcons.logOut,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'خروج',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor,
                  AppTheme.darkGold,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Colors.black,
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'GYMAI',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                LucideIcons.menu,
                color: AppTheme.goldColor,
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
                  // کارت خوشامدگویی بهبود یافته
                  WelcomeCard(
                    username: _username ?? 'کاربر عزیز',
                    welcomeMessage: _getWelcomeMessage(),
                    welcomeIcon: _getWelcomeIcon(),
                    profileData: _profileData,
                  ),
                  const SizedBox(height: 20),

                  // کارت‌های BMI و معیارهای فیزیکی
                  FitnessMetrics(profileData: _profileData),
                  const SizedBox(height: 20),

                  // نمودار وزن
                  if (Supabase.instance.client.auth.currentUser?.id != null)
                    WeightChart(
                      userId: Supabase.instance.client.auth.currentUser!.id,
                      currentWeight:
                          double.tryParse(_profileData['weight'] ?? ''),
                    ),
                  const SizedBox(height: 20),

                  // جابجایی: ناوبری بخش‌ها (تمرین و غذا)
                  SectionNavCarousel(
                    title: 'تمرین',
                    items: [
                      SectionCardItem(
                        title: 'ثبت تمرین',
                        subtitle: 'افزودن تمرین روزانه',
                        icon: LucideIcons.plus,
                        onTap: () =>
                            Navigator.pushNamed(context, '/workout-log'),
                        gradientColors: const [
                          Color(0xFF2C3E50),
                          Color(0xFF34495E)
                        ],
                      ),
                      SectionCardItem(
                        title: 'برنامه تمرینی',
                        subtitle: 'ساخت یا مشاهده برنامه',
                        icon: LucideIcons.clipboardList,
                        onTap: () => Navigator.pushNamed(
                            context, '/workout-program-builder'),
                        gradientColors: const [
                          Color(0xFF8E44AD),
                          Color(0xFF9B59B6)
                        ],
                      ),
                      SectionCardItem(
                        title: 'آموزش حرکات',
                        subtitle: 'لیست حرکات و ویدیوها',
                        icon: LucideIcons.bookOpen,
                        onTap: () =>
                            Navigator.pushNamed(context, '/exercise-list'),
                        gradientColors: const [
                          Color(0xFF2980B9),
                          Color(0xFF3498DB)
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SectionNavCarousel(
                    title: 'غذا',
                    items: [
                      SectionCardItem(
                        title: 'ثبت رژیم روزانه',
                        subtitle: 'غذاهای امروز را ثبت کن',
                        icon: LucideIcons.calendar,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const FoodLogScreen()),
                        ),
                        gradientColors: const [
                          Color(0xFFE67E22),
                          Color(0xFFF39C12)
                        ],
                      ),
                      SectionCardItem(
                        title: 'برنامه غذایی',
                        subtitle: 'ایجاد یا ویرایش پلن',
                        icon: LucideIcons.utensils,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const MealPlanBuilderScreen()),
                        ),
                        gradientColors: const [
                          Color(0xFF27AE60),
                          Color(0xFF2ECC71)
                        ],
                      ),
                      SectionCardItem(
                        title: 'بانک خوراکی‌ها',
                        subtitle: 'اطلاعات کامل غذا ها ',
                        icon: LucideIcons.search,
                        onTap: () => Navigator.pushNamed(context, '/food-list'),
                        gradientColors: const [
                          Color(0xFFE74C3C),
                          Color(0xFFC0392B)
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const LatestItemsSection(),
                  const SizedBox(height: 20),

                  // چت را به پایین منتقل کردیم
                  const ChatTabsWidget(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // removed old workous/profile tabs (dashboard is a single-page layout now)

  // Widget _buildClientsTab() => const ClientManagementScreen();

  // Widget _buildProfileTab() { ... }

  // Helper methods for building widget lists

  // List<Widget> _buildWorkoutItems() { ... }

  // List<Widget> _buildSplitItems() { ... }

  // List<Widget> _buildQuickActionButtons() { ... }

  // List<Widget> _buildProgressBars() { ... }

  // List<Widget> _buildProfileStatItems() { ... }

  // List<Widget> _buildProfileActionItems() { ... }
}
