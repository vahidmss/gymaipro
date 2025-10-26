import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/video_cache_info_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  bool _darkMode = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _language = 'فارسی';

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
        _darkMode = prefs.getBool('dark_mode') ?? true;
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
      await prefs.setBool('dark_mode', _darkMode);
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('vibration_enabled', _vibrationEnabled);
      await prefs.setString('language', _language);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تنظیمات ذخیره شد'),
            backgroundColor: AppTheme.goldColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره تنظیمات: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'تنظیمات',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('تنظیمات عمومی'),
                      const SizedBox(height: 16),

                      // حالت تاریک
                      _buildSwitchTile(
                        icon: LucideIcons.moon,
                        title: 'حالت تاریک',
                        subtitle: 'استفاده از تم تاریک',
                        value: _darkMode,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                          });
                          _saveSettings();
                        },
                      ),

                      // زبان
                      _buildListTile(
                        icon: LucideIcons.languages,
                        title: 'زبان',
                        subtitle: _language,
                        onTap: _showLanguageDialog,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('تنظیمات نوتیفیکیشن'),
                      const SizedBox(height: 16),

                      // فعال‌سازی نوتیفیکیشن
                      _buildSwitchTile(
                        icon: LucideIcons.bell,
                        title: 'نوتیفیکیشن‌ها',
                        subtitle: 'دریافت اعلان‌ها',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),

                      // صدا
                      _buildSwitchTile(
                        icon: LucideIcons.volume2,
                        title: 'صدا',
                        subtitle: 'صدای نوتیفیکیشن',
                        value: _soundEnabled,
                        onChanged: (value) {
                          setState(() {
                            _soundEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),

                      // لرزش
                      _buildSwitchTile(
                        icon: LucideIcons.vibrate,
                        title: 'لرزش',
                        subtitle: 'لرزش نوتیفیکیشن',
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _vibrationEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('تنظیمات کش'),
                      const SizedBox(height: 16),

                      // اطلاعات کش ویدیو
                      const VideoCacheInfoWidget(),
                      const SizedBox(height: 24),
                      _buildSectionHeader('درباره اپلیکیشن'),
                      const SizedBox(height: 16),

                      _buildListTile(
                        icon: LucideIcons.info,
                        title: 'نسخه',
                        subtitle: '1.0.0',
                        onTap: () {},
                      ),

                      _buildListTile(
                        icon: LucideIcons.helpCircle,
                        title: 'راهنما',
                        subtitle: 'مشاهده راهنمای استفاده',
                        onTap: () {
                          Navigator.pushNamed(context, '/help');
                        },
                      ),

                      _buildListTile(
                        icon: LucideIcons.messageCircle,
                        title: 'تماس با پشتیبانی',
                        subtitle: 'ارسال پیام به تیم پشتیبانی',
                        onTap: () {
                          // TODO: انتقال به صفحه تماس
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.goldColor,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppTheme.goldColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.goldColor,
        activeTrackColor: AppTheme.goldColor.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.goldColor, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        trailing: Icon(
          LucideIcons.chevronLeft,
          color: Colors.white70,
          size: 20.sp,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('انتخاب زبان', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('فارسی', 'فارسی'),
            _buildLanguageOption('English', 'انگلیسی'),
            _buildLanguageOption('العربية', 'عربی'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'انصراف',
              style: TextStyle(color: AppTheme.goldColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language, String displayName) {
    final isSelected = _language == language;
    return RadioListTile<String>(
      title: Text(
        displayName,
        style: TextStyle(
          color: isSelected ? AppTheme.goldColor : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      value: language,
      groupValue: _language,
      onChanged: (value) {
        setState(() {
          _language = value!;
        });
        Navigator.pop(context);
        _saveSettings();
      },
      activeColor: AppTheme.goldColor,
    );
  }
}
