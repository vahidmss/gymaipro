import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../constants/navigation_constants.dart';
import '../utils/navigation_utils.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../chat/screens/chat_main_screen.dart';
import '../../screens/profile_screen.dart';
import '../../theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex =
      NavigationConstants.dashboardIndex; // شروع با داشبورد (دکمه مرکزی)
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (!NavigationUtils.canNavigate()) return;

    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: NavigationConstants.pageTransitionDuration,
      curve: NavigationConstants.pageTransitionCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          // چت (index 0)
          const ChatMainScreen(),

          // تمرین (index 1)
          _buildWorkoutSection(),

          // داشبورد (index 2)
          const DashboardScreen(),

          // تغذیه (index 3)
          _buildNutritionSection(),

          // پروفایل (index 4)
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  Widget _buildWorkoutSection() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          NavigationConstants.workoutLabel,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // کارت ساخت برنامه تمرینی
            NavigationUtils.createActionCard(
              title: NavigationConstants
                  .workoutActions['program_builder']!['title'] as String,
              subtitle: NavigationConstants
                  .workoutActions['program_builder']!['subtitle'] as String,
              icon: NavigationConstants
                  .workoutActions['program_builder']!['icon'] as IconData,
              color: NavigationConstants.actionCardColors['workout_program']!,
              onTap: () => NavigationUtils.safeNavigateTo(
                context,
                NavigationConstants.workoutActions['program_builder']!['route']
                    as String,
              ),
            ),
            const SizedBox(height: NavigationConstants.actionCardSpacing),

            // کارت ثبت برنامه تمرینی
            NavigationUtils.createActionCard(
              title: NavigationConstants.workoutActions['workout_log']!['title']
                  as String,
              subtitle: NavigationConstants
                  .workoutActions['workout_log']!['subtitle'] as String,
              icon: NavigationConstants.workoutActions['workout_log']!['icon']
                  as IconData,
              color: NavigationConstants.actionCardColors['workout_log']!,
              onTap: () => NavigationUtils.safeNavigateTo(
                context,
                NavigationConstants.workoutActions['workout_log']!['route']
                    as String,
              ),
            ),
            const SizedBox(height: NavigationConstants.actionCardSpacing),

            // کارت لیست تمرینات
            NavigationUtils.createActionCard(
              title: NavigationConstants
                  .workoutActions['exercise_list']!['title'] as String,
              subtitle: NavigationConstants
                  .workoutActions['exercise_list']!['subtitle'] as String,
              icon: NavigationConstants.workoutActions['exercise_list']!['icon']
                  as IconData,
              color: NavigationConstants.actionCardColors['exercise_list']!,
              onTap: () => NavigationUtils.safeNavigateTo(
                context,
                NavigationConstants.workoutActions['exercise_list']!['route']
                    as String,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSection() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          NavigationConstants.nutritionLabel,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // کارت ساخت برنامه غذایی
            NavigationUtils.createActionCard(
              title: NavigationConstants
                  .nutritionActions['meal_plan_builder']!['title'] as String,
              subtitle: NavigationConstants
                  .nutritionActions['meal_plan_builder']!['subtitle'] as String,
              icon: NavigationConstants
                  .nutritionActions['meal_plan_builder']!['icon'] as IconData,
              color: NavigationConstants.actionCardColors['meal_plan']!,
              onTap: () => NavigationUtils.safeNavigateTo(
                context,
                NavigationConstants
                    .nutritionActions['meal_plan_builder']!['route'] as String,
              ),
            ),
            const SizedBox(height: NavigationConstants.actionCardSpacing),

            // کارت ثبت برنامه غذایی
            NavigationUtils.createActionCard(
              title: NavigationConstants.nutritionActions['meal_log']!['title']
                  as String,
              subtitle: NavigationConstants
                  .nutritionActions['meal_log']!['subtitle'] as String,
              icon: NavigationConstants.nutritionActions['meal_log']!['icon']
                  as IconData,
              color: NavigationConstants.actionCardColors['meal_log']!,
              onTap: () => NavigationUtils.safeNavigateTo(
                context,
                NavigationConstants.nutritionActions['meal_log']!['route']
                    as String,
              ),
            ),
            const SizedBox(height: NavigationConstants.actionCardSpacing),

            // کارت لیست غذاها
            NavigationUtils.createActionCard(
              title: NavigationConstants.nutritionActions['food_list']!['title']
                  as String,
              subtitle: NavigationConstants
                  .nutritionActions['food_list']!['subtitle'] as String,
              icon: NavigationConstants.nutritionActions['food_list']!['icon']
                  as IconData,
              color: NavigationConstants.actionCardColors['food_list']!,
              onTap: () => NavigationUtils.safeNavigateTo(
                context,
                NavigationConstants.nutritionActions['food_list']!['route']
                    as String,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
