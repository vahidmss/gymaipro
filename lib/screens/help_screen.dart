import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/support_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        _animationController.safeForward();
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
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
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
        color: context.cardColor,
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
    final phone = SupportLauncher.supportPhone;
    final telegram = SupportLauncher.telegramDisplayHandle;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
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
            'ارتباط با ما',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'برای گزارش باگ، پیشنهاد یا سوال با ما در تماس باشید',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildContactRow(
              icon: LucideIcons.phone,
              label: phone,
              onTap: () => SupportLauncher.openPhone(context),
            ),
          ],
          if (telegram.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildContactRow(
              icon: LucideIcons.send,
              label: 'تلگرام $telegram',
              onTap: () => SupportLauncher.openTelegram(context),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => SupportLauncher.openBestContact(context),
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

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.goldColor, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronLeft,
                color: Colors.white.withValues(alpha: 0.5),
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
