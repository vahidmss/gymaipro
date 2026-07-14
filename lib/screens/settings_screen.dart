import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/theme/theme_provider.dart';
import 'package:gymaipro/utils/support_launcher.dart';
import 'package:gymaipro/widgets/comprehensive_cache_info_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _language = 'فارسی';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
        _language = prefs.getString('language') ?? 'فارسی';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }

    if (mounted) {
      _animationController.forward();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setString('language', _language);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                const Text('تنظیمات با موفقیت ذخیره شد'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                const Text('خطا در ذخیره تنظیمات'),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(context, isDark),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.goldColor,
                strokeWidth: 3,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBody(context, isDark),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: context.backgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowRight,
          color: context.textColor,
          size: 24.sp,
        ),
        onPressed: () => Navigator.pop(context),
        tooltip: 'بازگشت',
      ),
      title: Text(
        'تنظیمات',
        style: TextStyle(
          color: context.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 22.sp,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          
          // تنظیمات عمومی
          _buildSection(
            context: context,
            isDark: isDark,
            title: 'تنظیمات عمومی',
            icon: LucideIcons.settings,
            children: [
              // حالت تاریک/روشن
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _buildModernSwitchTile(
                    context: context,
                    isDark: isDark,
                    icon: themeProvider.isDarkMode
                        ? LucideIcons.moon
                        : LucideIcons.sun,
                    title: 'حالت تاریک',
                    subtitle: themeProvider.isDarkMode
                        ? 'تم تاریک فعال است'
                        : 'تم روشن فعال است',
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setTheme(value);
                      _saveSettings();
                    },
                  );
                },
              ),
              SizedBox(height: 12.h),

              // زبان
              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.languages,
                title: 'زبان',
                subtitle: _language,
                onTap: _showLanguageDialog,
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // تنظیمات نوتیفیکیشن
          _buildSection(
            context: context,
            isDark: isDark,
            title: 'اعلان‌ها',
            icon: LucideIcons.bell,
            children: [
              // فعال‌سازی نوتیفیکیشن
              _buildModernSwitchTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.bell,
                title: 'نوتیفیکیشن‌ها',
                subtitle: 'دریافت اعلان‌های برنامه',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSettings();
                },
              ),
              SizedBox(height: 12.h),

              // صدا
              _buildModernSwitchTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.volume2,
                title: 'صدای اعلان',
                subtitle: 'پخش صدا هنگام دریافت اعلان',
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                  _saveSettings();
                },
              ),
              SizedBox(height: 12.h),

              // لرزش
              _buildModernSwitchTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.vibrate,
                title: 'لرزش',
                subtitle: 'لرزش دستگاه هنگام دریافت اعلان',
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                  _saveSettings();
                },
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // تنظیمات کش
          _buildSection(
            context: context,
            isDark: isDark,
            title: 'ذخیره‌سازی',
            icon: LucideIcons.hardDrive,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0.w),
                child: const ComprehensiveCacheInfoWidget(),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // درباره اپلیکیشن
          _buildSection(
            context: context,
            isDark: isDark,
            title: 'درباره',
            icon: LucideIcons.info,
            children: [
              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.package,
                title: 'نسخه اپلیکیشن',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              SizedBox(height: 12.h),

              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.helpCircle,
                title: 'راهنما',
                subtitle: 'مشاهده راهنمای استفاده',
                onTap: () {
                  Navigator.pushNamed(context, '/help');
                },
              ),
              SizedBox(height: 12.h),

              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.shield,
                title: 'حریم خصوصی',
                subtitle: 'نحوه استفاده از داده‌هایت',
                onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
              ),
              SizedBox(height: 12.h),

              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.fileText,
                title: 'قوانین استفاده',
                subtitle: 'شرایط و مسئولیت‌ها',
                onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
              ),
              SizedBox(height: 12.h),

              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.bookOpen,
                title: 'مجوزهای متن‌باز',
                subtitle: 'پکیج‌های استفاده‌شده',
                onTap: () =>
                    Navigator.pushNamed(context, '/open-source-licenses'),
              ),
              SizedBox(height: 12.h),

              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.sparkles,
                title: 'درباره GymAI',
                subtitle: 'ماموریت و نسخه فعلی',
                onTap: () => Navigator.pushNamed(context, '/about-app'),
              ),
              SizedBox(height: 12.h),

              _buildModernListTile(
                context: context,
                isDark: isDark,
                icon: LucideIcons.messageCircle,
                title: 'ارتباط با ما',
                subtitle: SupportLauncher.supportPhone.isNotEmpty
                    ? '${SupportLauncher.supportPhone} · ${SupportLauncher.telegramDisplayHandle}'
                    : 'تماس با تیم پشتیبانی',
                onTap: () => Navigator.pushNamed(context, '/help'),
              ),
            ],
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // هدر بخش
        Padding(
          padding: EdgeInsets.only(bottom: 16.h, right: 4.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ),
        ),

        // محتوای بخش
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? context.separatorColor
                  : context.separatorColor.withValues(alpha: 0.5),
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              ...children.map((child) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                    ),
                    child: child,
                  )),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernSwitchTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // آیکون
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),

            // متن
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // سوییچ
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppTheme.goldColor,
                activeTrackColor: AppTheme.goldColor.withValues(alpha: 0.3),
                inactiveThumbColor: isDark
                    ? Colors.grey[600]
                    : Colors.grey[400],
                inactiveTrackColor: isDark
                    ? Colors.grey[800]
                    : Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // آیکون
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),

            // متن
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // فلش
            Icon(
              LucideIcons.chevronLeft,
              color: context.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }


  void _showLanguageDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                // هدر
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        LucideIcons.languages,
                        color: AppTheme.goldColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'انتخاب زبان',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // گزینه‌های زبان
                ...['فارسی', 'English', 'العربية'].map((lang) {
                  final displayName = {
                    'فارسی': 'فارسی',
                    'English': 'انگلیسی',
                    'العربية': 'عربی',
                  }[lang]!;
                  final isSelected = _language == lang;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _language = lang;
                      });
                      Navigator.pop(context);
                      _saveSettings();
                    },
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.goldColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.goldColor
                              : context.separatorColor.withValues(alpha: 0.3),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontSize: 16.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              LucideIcons.check,
                              color: AppTheme.goldColor,
                              size: 20.sp,
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                SizedBox(height: 16.h),

                // دکمه انصراف
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'انصراف',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
