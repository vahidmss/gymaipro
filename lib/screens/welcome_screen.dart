import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_remote_image.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.jumpToLastPage = false});

  final bool jumpToLastPage;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  late int _currentPage;

  final List<_WelcomePageData> _pages = [
    _WelcomePageData(
      title: 'مربی هوشمند همیشه همراه تو',
      description:
          'مربی هوشمند، همیشه کنارته\nحرکاتت رو زیر نظر بگیر، از اشتباهات جلوگیری کن و با پشتیبانی لحظه‌ای پیشرفت کن.',
      image: 'images/poster1.png',
      icon: Icons.image,
    ),
    _WelcomePageData(
      title: 'برنامه تمرینی و تغذیه شخصی‌سازی شده',
      description:
          'برنامه‌ای که فقط برای تو ساخته شده\nمربیان واقعی و هوش مصنوعی، دست به دست هم می‌دن تا بهترین برنامه رو برای بدن و هدفت طراحی کنن.',
      image: 'images/poster2.png',
      icon: Icons.schedule,
    ),
    _WelcomePageData(
      title: 'پیشرفتت رو ببین',
      description:
          'پیشرفتت رو به چشم ببین\nبا نمودارها و آمار دقیق، هر قدمی که جلو میری ثبت و بررسی میشه.',
      image: 'images/poster3.png',
      icon: Icons.trending_up,
    ),
    _WelcomePageData(
      title: 'مربیان واقعی، همیشه در دسترس',
      description:
          'مربی واقعی، انتخاب تو\nمربی‌هات رو بین بهترین‌ها انتخاب کن، رتبه‌بندی ببین و مستقیم باهاشون کار کن.',
      image: 'images/poster5.png',
      icon: Icons.people_alt,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // اگر jumpToLastPage true باشد، مستقیماً از آخرین صفحه شروع کن
    final lastPageIndex = _pages.length - 1;
    if (widget.jumpToLastPage) {
      _currentPage = lastPageIndex;
      _pageController = PageController(initialPage: lastPageIndex);
    } else {
      _currentPage = 0;
      _pageController = PageController();
    }
  }

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
                  AppTheme.darkGold.withValues(alpha: 0.1),
                  AppTheme.backgroundColor,
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),

          // Fullscreen poster background by current page
          if (_pages[_currentPage].image.contains('poster'))
            Positioned.fill(
              child: AppRemoteImage(
                path: _pages[_currentPage].image,
                fit: BoxFit.fill,
                errorWidget: const SizedBox.shrink(),
              ),
            ),
          if (_pages[_currentPage].image.contains('poster'))
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
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

              // Page indicator + CTAs
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    _PageDots(
                      controller: _pageController,
                      count: _pages.length,
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
                                  context,
                                  '/register',
                                );
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
                                  context,
                                  '/login',
                                );
                              },
                              child: Text(
                                'قبلاً ثبت‌نام کرده‌ام',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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

  Widget _buildPage(_WelcomePageData page) {
    // Poster slides: only texts; background image is rendered globally
    if (page.image.contains('poster')) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                page.title,
                style: AppTheme.headingStyle.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8.r,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: (AppTheme.bodyStyle.fontSize ?? 14) + 2,
                    height: 1.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (page.image.isNotEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.1),
                    AppTheme.cardColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.1),
                    blurRadius: 28.r,
                    spreadRadius: 6.r,
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardColor,
                ),
                child: AppRemoteImage(
                  path: page.image,
                  height: 100.h,
                  width: 100.w,
                  fit: BoxFit.contain,
                  errorWidget:
                      Icon(page.icon, size: 80.sp, color: AppTheme.goldColor),
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.1),
                    AppTheme.cardColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.1),
                    blurRadius: 28.r,
                    spreadRadius: 6.r,
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardColor,
                ),
                child: Icon(page.icon, size: 84.sp, color: AppTheme.goldColor),
              ),
            ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: AppTheme.headingStyle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: AppTheme.bodyStyle,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WelcomePageData {
  _WelcomePageData({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
  final String title;
  final String description;
  final String image;
  final IconData icon;
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.controller, required this.count});
  final PageController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    // Minimal page dots without external package to keep it simple
    return SizedBox(
      height: 12,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final page = controller.hasClients ? controller.page ?? 0.0 : 0.0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(count, (index) {
              final isActive = (page.round() == index);
              return Container(
                width: isActive ? 12 : 8,
                height: isActive ? 12 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.goldColor
                      : AppTheme.goldColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
