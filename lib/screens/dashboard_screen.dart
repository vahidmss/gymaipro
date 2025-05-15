import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/fitness_calculator.dart';
import '../screens/profile_screen.dart';

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
  int _selectedIndex = 0;
  Map<String, String> _profileData = {};

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
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final supabaseService = SupabaseService();
        final profile = await supabaseService.getProfileByAuthId();

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
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _buildBody(context),
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
                const Divider(color: Colors.white24),
                _buildDrawerItem(LucideIcons.settings, 'تنظیمات', 6),
              ],
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
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
        mainAxisAlignment: MainAxisAlignment.center,
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
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(LucideIcons.user, size: 35, color: darkGold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'GymCursor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(LucideIcons.logOut, size: 16),
            label: const Text('خروج'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: _buildAppBarTitle(),
      actions: [
        _buildNotificationButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        Hero(
          tag: 'profile_image_small',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: goldColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: goldColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: cardColor,
              child: Icon(LucideIcons.user, size: 18, color: goldColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'کاربر عزیز',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'سطح: مبتدی',
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: goldColor.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.bell, color: goldColor, size: 20),
            onPressed: () {},
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Simulate refresh
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsCards(),
            const SizedBox(height: 24),
            _buildStatisticsGrid(),
            const SizedBox(height: 24),
            _buildWeightSection(),
            const SizedBox(height: 24),
            _buildWorkoutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards() {
    final height = double.tryParse(_profileData['height'] ?? '') ?? 0;
    final weight = double.tryParse(_profileData['weight'] ?? '') ?? 0;
    final birthDateStr = _profileData['birth_date'];
    int age = 25;
    if (birthDateStr != null && birthDateStr.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateStr);
        final now = DateTime.now();
        age = now.year -
            birthDate.year -
            ((now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day))
                ? 1
                : 0);
      } catch (_) {}
    }
    // جنسیت را male فرض کن (در آینده از پروفایل بخوان)
    final isMale = true;
    // دور گردن اگر نبود مقدار پیش‌فرض قرار بده
    final neck = double.tryParse(_profileData['neck_circumference'] ?? '') ??
        (isMale ? 35 : 32);
    final waist =
        double.tryParse(_profileData['waist_circumference'] ?? '') ?? 0;
    final hip = double.tryParse(_profileData['hip_circumference'] ?? '') ?? 0;

    double bmi = 0;
    String bmiCategory = 'داده‌ای وارد نشده';
    if (height > 0 && weight > 0) {
      bmi = FitnessCalculator.calculateBMI(weight, height);
      bmiCategory = FitnessCalculator.getBMICategory(bmi);
    }

    String bodyFat = '-';
    if (waist > 0 && neck > 0 && height > 0) {
      final bodyFatVal = FitnessCalculator.calculateBodyFatPercentage(
        waist,
        neck,
        height,
        isMale,
        hip,
      );
      bodyFat = '${bodyFatVal.toStringAsFixed(1)}%';
    }

    String bmr = '-';
    if (weight > 0 && height > 0) {
      final bmrVal = FitnessCalculator.calculateBMR(
        weight,
        height,
        age,
        isMale,
      );
      bmr = bmrVal.toStringAsFixed(0);
    }

    String tdee = '-';
    if (weight > 0 && height > 0) {
      final bmrVal = FitnessCalculator.calculateBMR(
        weight,
        height,
        age,
        isMale,
      );
      final tdeeVal = FitnessCalculator.calculateTDEE(
        bmrVal,
        ActivityLevel.moderatelyActive,
      );
      tdee = tdeeVal.toStringAsFixed(0);
    }

    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMetricCard(
            'BMI',
            bmi > 0 ? bmi.toStringAsFixed(1) : '-',
            bmiCategory,
            Icons.monitor_weight,
            bmi > 0
                ? [
                    FitnessCalculator.getBMIColor(bmi),
                    FitnessCalculator.getBMIColor(bmi).withOpacity(0.7)
                  ]
                : [Colors.grey.shade300, Colors.grey],
          ),
          _buildMetricCard(
            'درصد چربی',
            bodyFat,
            'عالی',
            Icons.accessibility_new,
            [Colors.blue.shade300, Colors.blue],
          ),
          _buildMetricCard(
            'BMR',
            bmr,
            'کالری در روز',
            Icons.local_fire_department,
            [Colors.orange.shade300, Colors.orange],
          ),
          _buildMetricCard(
            'TDEE',
            tdee,
            'کالری در روز',
            Icons.trending_up,
            [Colors.purple.shade300, Colors.purple],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 100,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('تمرینات انجام شده', '48', LucideIcons.checkCircle),
        _buildStatCard('ساعات تمرین هفتگی', '12', LucideIcons.clock),
        _buildStatCard('وزن فعلی', '70.0', LucideIcons.scale),
        _buildStatCard('روزهای متوالی', '7', LucideIcons.flame),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: goldColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: goldColor, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('نمودار تغییرات وزن'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: goldColor),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: goldColor.withOpacity(0.1)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const style = TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      );
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text('${value.toInt()}', style: style),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 65,
              maxY: 75,
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 70),
                    FlSpot(1, 69.5),
                    FlSpot(2, 69.8),
                    FlSpot(3, 69.3),
                    FlSpot(4, 69.0),
                    FlSpot(5, 68.8),
                    FlSpot(6, 68.5),
                  ],
                  isCurved: true,
                  color: goldColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: goldColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: goldColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('تقسیم‌بندی تمرینات'),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: goldColor.withOpacity(0.1)),
          ),
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
                  const SizedBox(height: 8),
                  _buildWorkoutLegend('پا', darkGold, '25%'),
                  const SizedBox(height: 8),
                  _buildWorkoutLegend(
                      'پشت و بازو', goldColor.withOpacity(0.5), '25%'),
                  const SizedBox(height: 8),
                  _buildWorkoutLegend(
                      'شکم و کاردیو', darkGold.withOpacity(0.5), '20%'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

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

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: goldColor, width: 2),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
