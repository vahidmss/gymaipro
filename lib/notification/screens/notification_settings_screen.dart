import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/notification_model.dart';
import 'package:gymaipro/notification/services/notification_sync_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  NotificationSettingsModel _settings = NotificationSettingsModel();
  bool _isLoading = true;
  bool _isSaving = false;

  // Debounce timer برای جلوگیری از ذخیره مکرر
  Timer? _saveTimer;

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
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings');

      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        setState(() {
          _settings = NotificationSettingsModel(
            workoutReminders:
                (settingsMap['workout_reminders'] as bool?) ?? true,
            mealReminders: (settingsMap['meal_reminders'] as bool?) ?? true,
            weightReminders: (settingsMap['weight_reminders'] as bool?) ?? true,
            chatNotifications:
                (settingsMap['chat_notifications'] as bool?) ?? true,
            achievementNotifications:
                (settingsMap['achievement_notifications'] as bool?) ?? true,
            generalNotifications:
                (settingsMap['general_notifications'] as bool?) ?? true,
            soundEnabled: (settingsMap['sound_enabled'] as bool?) ?? true,
            vibrationEnabled:
                (settingsMap['vibration_enabled'] as bool?) ?? true,
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving || !mounted) return;

    try {
      setState(() {
        _isSaving = true;
      });

      // ذخیره در SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings',
        json.encode({
          'workout_reminders': _settings.workoutReminders,
          'meal_reminders': _settings.mealReminders,
          'weight_reminders': _settings.weightReminders,
          'chat_notifications': _settings.chatNotifications,
          'achievement_notifications': _settings.achievementNotifications,
          'general_notifications': _settings.generalNotifications,
          'sound_enabled': _settings.soundEnabled,
          'vibration_enabled': _settings.vibrationEnabled,
        }),
      );

      // همگام‌سازی با دیتابیس - با timeout کوتاه
      try {
        await NotificationSyncService.syncSettingsToDatabase().timeout(
          const Duration(seconds: 3),
        );
      } catch (syncError) {
        // اگر sync ناموفق بود، فقط log کن - اپ کرش نکنه
        debugPrint('Sync failed but app continues: $syncError');
      }
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('خطا در ذخیره تنظیمات'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveTimer = null; // Clear timer after save
        });
      }
    }
  }

  void _updateSetting(String key, bool value) {
    if (!mounted) return;

    try {
      setState(() {
        switch (key) {
          case 'workout_reminders':
            _settings = _settings.copyWith(workoutReminders: value);
          case 'meal_reminders':
            _settings = _settings.copyWith(mealReminders: value);
          case 'weight_reminders':
            _settings = _settings.copyWith(weightReminders: value);
          case 'chat_notifications':
            _settings = _settings.copyWith(chatNotifications: value);
          case 'achievement_notifications':
            _settings = _settings.copyWith(achievementNotifications: value);
          case 'general_notifications':
            _settings = _settings.copyWith(generalNotifications: value);
          case 'sound_enabled':
            _settings = _settings.copyWith(soundEnabled: value);
          case 'vibration_enabled':
            _settings = _settings.copyWith(vibrationEnabled: value);
        }
      });

      // Cancel previous timer if exists
      _saveTimer?.cancel();

      // Set new timer for debounced save
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _saveSettings();
        }
      });
    } catch (e) {
      debugPrint('Error updating setting: $e');
      // Continue without crashing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('تنظیمات نوتیفیکیشن'),
        centerTitle: true,
        actions: [
          if (_isSaving)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              ),
            ),
          if (_saveTimer != null && !_isSaving)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Icon(
                LucideIcons.check,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
              ),
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
                      // Header Card
                      _buildHeaderCard(),
                      const SizedBox(height: 20),

                      // Notification Types Section
                      _buildSectionTitle('انواع اعلان‌ها'),
                      const SizedBox(height: 12),

                      // پیام‌های خصوصی
                      _buildNotificationTypeCard(
                        icon: '💬',
                        title: 'پیام‌های خصوصی',
                        subtitle: 'اعلان پیام‌های جدید از کاربران',
                        value: _settings.chatNotifications,
                        onChanged: (value) =>
                            _updateSetting('chat_notifications', value),
                      ),
                      const SizedBox(height: 12),

                      // برنامه‌های مربی
                      _buildNotificationTypeCard(
                        icon: '📋',
                        title: 'برنامه‌های مربی',
                        subtitle: 'اعلان برنامه‌های جدید از مربی',
                        value: _settings.workoutReminders,
                        onChanged: (value) =>
                            _updateSetting('workout_reminders', value),
                      ),
                      const SizedBox(height: 12),

                      // درخواست‌های دوستی
                      _buildNotificationTypeCard(
                        icon: '👥',
                        title: 'درخواست‌های دوستی',
                        subtitle: 'اعلان درخواست دوستی جدید',
                        value: _settings.achievementNotifications,
                        onChanged: (value) =>
                            _updateSetting('achievement_notifications', value),
                      ),
                      const SizedBox(height: 12),

                      // درخواست مربی
                      _buildNotificationTypeCard(
                        icon: '🏋️',
                        title: 'درخواست مربی',
                        subtitle: 'اعلان درخواست مربیگری جدید',
                        value: _settings.mealReminders,
                        onChanged: (value) =>
                            _updateSetting('meal_reminders', value),
                      ),
                      const SizedBox(height: 12),

                      // پیام مربی
                      _buildNotificationTypeCard(
                        icon: '💼',
                        title: 'پیام مربی',
                        subtitle: 'اعلان پیام‌های جدید از مربی',
                        value: _settings.weightReminders,
                        onChanged: (value) =>
                            _updateSetting('weight_reminders', value),
                      ),
                      const SizedBox(height: 12),

                      // اعلان‌های عمومی
                      _buildNotificationTypeCard(
                        icon: '📢',
                        title: 'اعلان‌های عمومی',
                        subtitle: 'اعلان‌های مهم و عمومی سیستم',
                        value: _settings.generalNotifications,
                        onChanged: (value) =>
                            _updateSetting('general_notifications', value),
                      ),
                      const SizedBox(height: 20),

                      // Sound & Vibration Section
                      _buildSectionTitle('صدا و لرزش'),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        icon: LucideIcons.volume2,
                        title: 'صدا',
                        subtitle: 'فعال‌سازی صدای نوتیفیکیشن',
                        value: _settings.soundEnabled,
                        onChanged: (value) =>
                            _updateSetting('sound_enabled', value),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        icon: LucideIcons.vibrate,
                        title: 'لرزش',
                        subtitle: 'فعال‌سازی لرزش نوتیفیکیشن',
                        value: _settings.vibrationEnabled,
                        onChanged: (value) =>
                            _updateSetting('vibration_enabled', value),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: AppTheme.gradientDecoration,
      child: Column(
        children: [
          Icon(LucideIcons.bell, size: 48.sp, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            'تنظیمات نوتیفیکیشن',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'نوتیفیکیشن‌های خود را شخصی‌سازی کنید',
            style: TextStyle(fontSize: 16.sp, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppTheme.goldColor,
      ),
    );
  }

  Widget _buildNotificationTypeCard({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.goldColor,
            activeTrackColor: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppTheme.goldColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.goldColor,
            activeTrackColor: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
