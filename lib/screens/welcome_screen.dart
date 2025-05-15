import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomePageData> _pages = [
    WelcomePageData(
      title: 'به GymAI خوش آمدید',
      description: 'دستیار هوشمند تمرینات ورزشی شما',
      image: 'assets/images/welcome1.png',
      icon: Icons.fitness_center,
    ),
    WelcomePageData(
      title: 'برنامه تمرینی شخصی‌سازی شده',
      description:
          'با استفاده از هوش مصنوعی، برنامه تمرینی مخصوص شما را طراحی می‌کنیم',
      image: 'assets/images/welcome2.png',
      icon: Icons.schedule,
    ),
    WelcomePageData(
      title: 'پیشرفت خود را دنبال کنید',
      description: 'با نمودارها و آمارهای دقیق، پیشرفت خود را مشاهده کنید',
      image: 'assets/images/welcome3.png',
      icon: Icons.trending_up,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppTheme.darkGold.withOpacity(0.1),
                  AppTheme.backgroundColor,
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: WormEffect(
                        dotColor: AppTheme.goldColor.withOpacity(0.3),
                        activeDotColor: AppTheme.goldColor,
                        dotHeight: 10,
                        dotWidth: 10,
                        spacing: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_currentPage == _pages.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            ElevatedButton(
                              style: AppTheme.primaryButtonStyle,
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/register');
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('شروع کنید'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              style: AppTheme.secondaryButtonStyle,
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                              child: const Text('قبلاً ثبت‌نام کرده‌ام'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(WelcomePageData page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: AppTheme.goldColor,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: AppTheme.headingStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: AppTheme.bodyStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class WelcomePageData {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  WelcomePageData({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}
