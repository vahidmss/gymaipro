import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/widgets/auth_gradient_background.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_remote_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.jumpToLastPage = false});

  final bool jumpToLastPage;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  late int _currentPage;

  final List<_WelcomePageData> _pages = const [
    _WelcomePageData(
      title: 'مربی هوشمند همیشه همراه تو',
      description:
          'حرکاتت را زیر نظر بگیر، از اشتباهات جلوگیری کن و با پشتیبانی لحظه‌ای پیشرفت کن.',
      image: 'images/poster1.jpg',
      alignment: Alignment(0, -0.15),
    ),
    _WelcomePageData(
      title: 'برنامه تمرینی و تغذیه شخصی',
      description:
          'مربیان واقعی و هوش مصنوعی با هم بهترین برنامه را برای بدن و هدفت می‌سازند.',
      image: 'images/poster2.jpg',
    ),
    _WelcomePageData(
      title: 'پیشرفتت را ببین',
      description:
          'با نمودارها و آمار دقیق، هر قدمی که جلو می‌روی ثبت و بررسی می‌شود.',
      image: 'images/poster3.jpg',
    ),
    _WelcomePageData(
      title: 'مربیان واقعی، همیشه در دسترس',
      description:
          'از بین بهترین‌ها انتخاب کن، رتبه‌بندی ببین و مستقیم با مربی کار کن.',
      image: 'images/poster5.jpg',
      // گوشی گرافیکی سمت راست را از مرکز کادر دور کن
      alignment: Alignment(-0.4, -0.12),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final lastPageIndex = _pages.length - 1;
    if (widget.jumpToLastPage) {
      _currentPage = lastPageIndex;
      _pageController = PageController(initialPage: lastPageIndex);
    } else {
      _currentPage = 0;
      _pageController = PageController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheAround(_currentPage);
    });
  }

  void _precacheAround(int index) {
    for (final i in {index, index + 1}) {
      if (i < 0 || i >= _pages.length) continue;
      precacheImage(AssetImage(_pages[i].image), context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _precacheAround(index);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final p = _pages[index];
              return AppRemoteImage(
                path: p.image,
                fit: BoxFit.cover,
                alignment: p.alignment,
                errorWidget: ColoredBox(color: context.backgroundColor),
              );
            },
          ),

          // اسکریم پایین قوی — متن/CTA روی ناحیهٔ تاریک
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22000000),
                    Color(0x00000000),
                    Color(0x99000000),
                    Color(0xE6000000),
                  ],
                  stops: [0.0, 0.28, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // یک ستون واحد تا دات روی متن نیفتد
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 18.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 18.h),
                    _PageDots(
                      controller: _pageController,
                      count: _pages.length,
                      index: _currentPage,
                    ),
                    SizedBox(height: 18.h),
                    if (isLast) ...[
                      AuthPrimaryButton(
                        label: 'شروع کنید',
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Text(
                            'قبلاً ثبت‌نام کرده‌ام',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: FilledButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: AppTheme.onGoldColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ادامه',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(LucideIcons.chevronLeft, size: 18.sp),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePageData {
  const _WelcomePageData({
    required this.title,
    required this.description,
    required this.image,
    this.alignment = Alignment.center,
  });
  final String title;
  final String description;
  final String image;
  final Alignment alignment;
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.controller,
    required this.count,
    required this.index,
  });
  final PageController controller;
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final page = controller.hasClients
              ? (controller.page ?? index.toDouble())
              : index.toDouble();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(count, (i) {
              final active = (page - i).abs() < 0.5;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.goldColor
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
