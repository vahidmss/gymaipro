import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _helpSections = [
    {
      'title': 'شروع کار',
      'icon': LucideIcons.play,
      'items': [
        'نحوه ثبت‌نام و ورود به اپلیکیشن',
        'آشنایی با رابط کاربری',
        'تنظیمات اولیه پروفایل',
      ],
    },
    {
      'title': 'تمرینات',
      'icon': LucideIcons.dumbbell,
      'items': [
        'مشاهده لیست تمرینات',
        'جستجو و فیلتر تمرینات',
        'ساخت برنامه تمرینی',
        'ثبت تمرینات انجام شده',
      ],
    },
    {
      'title': 'تغذیه',
      'icon': LucideIcons.apple,
      'items': [
        'مشاهده لیست غذاها',
        'ساخت برنامه غذایی',
        'ثبت وعده‌های غذایی',
        'محاسبه کالری و درشت‌مغذی‌ها',
      ],
    },
    {
      'title': 'چت و ارتباط',
      'icon': LucideIcons.messageCircle,
      'items': ['ارتباط با مربی', 'ارسال پیام', 'دریافت راهنمایی'],
    },
    {
      'title': 'تنظیمات',
      'icon': LucideIcons.settings,
      'items': [
        'تنظیمات نوتیفیکیشن',
        'تنظیمات کش ویدیو',
        'تغییر زبان',
        'تنظیمات حریم خصوصی',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.3.h), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'راهنما',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldColor.withValues(alpha: 0.1),
                        AppTheme.goldColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.helpCircle,
                        color: AppTheme.goldColor,
                        size: 32.sp,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'راهنمای استفاده از GymAI Pro',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'آموزش کامل استفاده از تمام ویژگی‌های اپلیکیشن',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Help sections
                ..._helpSections.map(_buildHelpSection),
                const SizedBox(height: 24),

                // Contact support
                _buildContactSupport(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(Map<String, dynamic> section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        leading: Icon(
          section['icon'] as IconData?,
          color: AppTheme.goldColor,
          size: 24.sp,
        ),
        title: Text(
          section['title'] as String,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppTheme.goldColor,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
            child: Column(
              children: (section['items'] as List<String>)
                  .map(_buildHelpItem)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            margin: EdgeInsets.only(top: 8.h, left: 8),
            decoration: const BoxDecoration(
              color: AppTheme.goldColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                height: 1.5.h,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: AppTheme.goldColor,
            size: 32.sp,
          ),
          const SizedBox(height: 16),
          Text(
            'نیاز به کمک بیشتری دارید؟',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'با تیم پشتیبانی ما در ارتباط باشید',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: انتقال به صفحه تماس با پشتیبانی
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('به زودی در دسترس خواهد بود'),
                    backgroundColor: AppTheme.goldColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.messageSquare, size: 18),
              label: const Text('تماس با پشتیبانی'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.goldColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
