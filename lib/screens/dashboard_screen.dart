import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../screens/profile_screen.dart';
import '../widgets/weight_chart.dart';
import '../widgets/fitness_metrics.dart';
import '../widgets/stats_grid.dart';
import '../widgets/achievements_section.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String? _username;
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedIndex = 0;
  Map<String, dynamic> _profileData = {};
  final SupabaseService _supabaseService = SupabaseService();

  // رنگ‌های اصلی برنامه با گرادیان‌های جدید
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controller.value = 0.0;

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _loadUserData().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    });
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .listen((data) {
            if (data.isNotEmpty) {
              _loadUserData();
            }
          });
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await _supabaseService.getProfileByAuthId();

        if (profile != null && mounted) {
          setState(() {
            _username = profile.firstName ?? 'کاربر';
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
              'gender': profile.gender ?? 'male', // اضافه کردن جنسیت
              'weight_history': profile.weightHistory ?? [],
              'username': profile
                  .phoneNumber, // استفاده از شماره تلفن به عنوان نام کاربری پیش‌فرض
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        drawer: _buildDrawer(context),
        appBar: _buildAppBar(context),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: goldColor,
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
              )
            : SafeArea(
                child: FadeTransition(
                  opacity: _animation,
                  child: _buildBody(context),
                ),
              ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(LucideIcons.layoutDashboard, 'داشبورد', 0),
                _buildDrawerItem(LucideIcons.user, 'پروفایل من', 1),
                _buildDrawerItem(LucideIcons.dumbbell, 'برنامه تمرینی من', 2),
                _buildDrawerItem(
                    LucideIcons.clipboardList, 'ثبت تمرین امروز', 3),
                _buildDrawerItem(LucideIcons.lineChart, 'نمودار پیشرفت', 4),
                _buildDrawerItem(
                    LucideIcons.messageCircle, 'مشاوره با مربی', 5),

                // Divider before settings
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: Colors.white24, height: 1),
                ),

                _buildDrawerItem(LucideIcons.settings, 'تنظیمات', 6),
                _buildDrawerItem(
                    LucideIcons.helpCircle, 'راهنما و پشتیبانی', 7),
              ],
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            darkGold,
            goldColor,
            accentColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'profile_image',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: goldColor.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(LucideIcons.user, size: 40, color: darkGold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _username ?? 'کاربر عزیز',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _profileData['experience_level'] ?? 'مبتدی',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? goldColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isSelected ? Border.all(color: goldColor.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? goldColor : Colors.white70,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? goldColor : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
          if (index == 1) {
            // Profile
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        selected: isSelected,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'نسخه 1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _signOut,
            icon: const Icon(LucideIcons.logOut, size: 16),
            label: const Text('خروج'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
              foregroundColor: Colors.red.shade300,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: goldColor.withOpacity(0.3)),
            ),
            child: const Icon(
              LucideIcons.dumbbell,
              color: goldColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'GYMAI',
            style: TextStyle(
              color: goldColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(LucideIcons.search, color: goldColor, size: 20),
          onPressed: () {},
        ),
        // Notification button
        _buildNotificationButton(),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.bell, color: goldColor, size: 20),
          onPressed: () {},
        ),
        Positioned(
          right: 8,
          top: 10,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: backgroundColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card - بخش خوشامدگویی
            _buildWelcomeCard(),
            const SizedBox(height: 16),

            // Fitness metrics - نشانگرهای تناسب اندام
            FitnessMetrics(profileData: _profileData),
            const SizedBox(height: 16),

            // Achievements + Stats in a row - دستاوردها و آمارها در یک ردیف
            _buildAchievementsAndStats(),
            const SizedBox(height: 16),

            // Weight chart - نمودار وزن
            WeightChart(
              profileData: _profileData,
              onWeightAdded: _loadUserData,
            ),
            const SizedBox(height: 16),

            // Today's workout + workout distribution - تمرین امروز و نمودار توزیع تمرینات
            _buildTodayWorkoutSection(),
            const SizedBox(height: 16),

            // Workout split - تقسیم‌بندی تمرینات
            _buildWorkoutSplit(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // کارت خوشامدگویی با پیشرفت روزانه
  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            darkGold.withOpacity(0.8),
            goldColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سلام ${_username ?? 'کاربر'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'امروز برای تمرین آماده‌ای؟',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getTodayPersianDate(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          LucideIcons.activity,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'پیشرفت امروز',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('ثبت تمرین'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: goldColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ترکیب دستاوردها و آمارها در یک بخش
  Widget _buildAchievementsAndStats() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats in a smaller column
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: goldColor.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title for stats
                  _buildSectionTitleSmall('آمار من'),
                  const SizedBox(height: 12),
                  // Stats content
                  _buildStatsContent(),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Achievements in a larger column
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: goldColor.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title for achievements
                  _buildSectionTitleSmall('دستاوردهای من'),
                  const SizedBox(height: 12),
                  // Achievements content
                  SizedBox(
                    height: 130,
                    child: AchievementsSection(profileData: _profileData),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Compact stats content
  Widget _buildStatsContent() {
    final height = double.tryParse(_profileData['height'] ?? '') ?? 0;
    final weight = double.tryParse(_profileData['weight'] ?? '') ?? 0;

    return Column(
      children: [
        _buildSingleStat('قد', '$height cm', LucideIcons.arrowUpDown),
        const Divider(height: 16, color: Colors.white10),
        _buildSingleStat('وزن', '$weight kg', LucideIcons.scale),
        const Divider(height: 16, color: Colors.white10),
        _buildSingleStat('تمرین‌های انجام شده', '28', LucideIcons.check),
        const Divider(height: 16, color: Colors.white10),
        _buildSingleStat('روزهای متوالی', '5', LucideIcons.flame),
      ],
    );
  }

  // Single stat item
  Widget _buildSingleStat(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: goldColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: goldColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ایجاد بخش تمرین امروز
  Widget _buildTodayWorkoutSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitleSmall('تمرین امروز'),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.arrowRight, size: 16),
                  label: const Text('مشاهده همه'),
                  style: TextButton.styleFrom(
                    foregroundColor: goldColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),

          // List of exercises
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Colors.white10,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              return _buildExerciseItem(
                ['پرس سینه', 'اسکات', 'زیربغل سیم کش'][index],
                [
                  '4 ست × 12 تکرار',
                  '4 ست × 10 تکرار',
                  '3 ست × 15 تکرار'
                ][index],
                [
                  LucideIcons.dumbbell,
                  LucideIcons.dumbbell,
                  LucideIcons.dumbbell
                ][index],
              );
            },
          ),

          // View all button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.clipboardList, size: 16),
                label: const Text('مشاهده کامل برنامه'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor.withOpacity(0.2),
                  foregroundColor: goldColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: goldColor.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تمرین تکی
  Widget _buildExerciseItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: goldColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: goldColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
      trailing:
          const Icon(LucideIcons.checkCircle, color: Colors.green, size: 18),
      dense: true,
    );
  }

  // Section title - smaller version
  Widget _buildSectionTitleSmall(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: const BoxDecoration(
            color: goldColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // تقسیم‌بندی تمرینات
  Widget _buildWorkoutSplit() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitleSmall('تقسیم‌بندی تمرینات'),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 35,
                      sections: [
                        PieChartSectionData(
                          color: goldColor,
                          value: 30,
                          title: '30%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: darkGold,
                          value: 25,
                          title: '25%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: goldColor.withOpacity(0.5),
                          value: 25,
                          title: '25%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          color: darkGold.withOpacity(0.5),
                          value: 20,
                          title: '20%',
                          radius: 45,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWorkoutLegend('سینه و سرشانه', goldColor, '30%'),
                    const SizedBox(height: 12),
                    _buildWorkoutLegend('پا', darkGold, '25%'),
                    const SizedBox(height: 12),
                    _buildWorkoutLegend(
                        'پشت و بازو', goldColor.withOpacity(0.5), '25%'),
                    const SizedBox(height: 12),
                    _buildWorkoutLegend(
                        'شکم و کاردیو', darkGold.withOpacity(0.5), '20%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دریافت تاریخ فارسی
  String _getTodayPersianDate() {
    // در یک برنامه واقعی، باید از کتابخانه‌های تبدیل تاریخ شمسی استفاده شود
    // اینجا برای نمونه یک تاریخ ثابت برمی‌گردانیم

    // ماه‌های شمسی
    final persianMonths = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];

    // اعداد فارسی
    final persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    // تبدیل عدد به فارسی
    String toPersianNumber(int n) {
      if (n == 0) return persianDigits[0];
      String result = '';
      while (n > 0) {
        result = persianDigits[n % 10] + result;
        n ~/= 10;
      }
      return result;
    }

    // تاریخ امروز
    final now = DateTime.now();

    // در دنیای واقعی اینجا باید تبدیل به تاریخ شمسی انجام شود
    // اما به عنوان مثال، ما فقط یک مقدار ثابت برمی‌گردانیم
    final day = toPersianNumber(now.day);
    final month = persianMonths[now.month - 1];
    final year = toPersianNumber(1403); // سال شمسی فرضی معادل

    return '$day $month $year';
  }

  // Workout legend with better style
  Widget _buildWorkoutLegend(String title, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          percentage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
