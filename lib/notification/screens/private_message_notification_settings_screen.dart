import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/services/private_message_notification_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// صفحه تنظیمات نوتیفیکیشن پیام‌های شخصی
/// قابلیت‌های پیشرفته:
/// - تنظیمات تفکیک شده برای مربیان و ورزشکاران
/// - مدیریت ساعات سکوت
/// - تنظیمات بر اساس نوع پیام
/// - پیش‌نمایش تنظیمات
class PrivateMessageNotificationSettingsScreen extends StatefulWidget {
  const PrivateMessageNotificationSettingsScreen({super.key});

  @override
  State<PrivateMessageNotificationSettingsScreen> createState() =>
      _PrivateMessageNotificationSettingsScreenState();
}

class _PrivateMessageNotificationSettingsScreenState
    extends State<PrivateMessageNotificationSettingsScreen> {
  final PrivateMessageNotificationService _notificationService =
      PrivateMessageNotificationService();

  PrivateMessageNotificationSettings _settings =
      const PrivateMessageNotificationSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      _settings = _notificationService.getCurrentSettings();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings(
    PrivateMessageNotificationSettings newSettings,
  ) async {
    setState(() => _settings = newSettings);
    await _notificationService.updateSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تنظیمات نوتیفیکیشن پیام‌ها'),
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات نوتیفیکیشن پیام‌ها'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildMainToggle(),
          const SizedBox(height: 24),
          _buildUserTypeSection(),
          const SizedBox(height: 24),
          _buildMessageTypeSection(),
          const SizedBox(height: 24),
          _buildQuietHoursSection(),
          const SizedBox(height: 24),
          _buildAdvancedSection(),
          const SizedBox(height: 24),
          _buildPreviewSection(),
        ],
      ),
    );
  }

  Widget _buildMainToggle() {
    return Card(
      color: AppTheme.cardColor,
      child: SwitchListTile(
        title: const Text(
          'نوتیفیکیشن پیام‌های شخصی',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _settings.enabled
              ? 'فعال - دریافت نوتیفیکیشن برای پیام‌های جدید'
              : 'غیرفعال - هیچ نوتیفیکیشنی دریافت نمی‌کنید',
        ),
        value: _settings.enabled,
        onChanged: (value) {
          _updateSettings(_settings.copyWith(enabled: value));
        },
        activeThumbColor: AppTheme.goldColor,
      ),
    );
  }

  Widget _buildUserTypeSection() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نوتیفیکیشن بر اساس نوع کاربر',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('از مربیان'),
              subtitle: const Text('دریافت نوتیفیکیشن از مربیان'),
              value: _settings.notifyFromTrainers,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(notifyFromTrainers: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
            SwitchListTile(
              title: const Text('از ورزشکاران'),
              subtitle: const Text('دریافت نوتیفیکیشن از ورزشکاران'),
              value: _settings.notifyFromAthletes,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(notifyFromAthletes: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTypeSection() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نوتیفیکیشن بر اساس نوع پیام',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('پیام‌های متنی'),
              subtitle: const Text('💬'),
              value: _settings.notifyTextMessages,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(notifyTextMessages: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
            SwitchListTile(
              title: const Text('تصاویر'),
              subtitle: const Text('📷'),
              value: _settings.notifyImageMessages,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(notifyImageMessages: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
            SwitchListTile(
              title: const Text('فایل‌ها'),
              subtitle: const Text('📎'),
              value: _settings.notifyFileMessages,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(notifyFileMessages: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
            SwitchListTile(
              title: const Text('پیام‌های صوتی'),
              subtitle: const Text('🎤'),
              value: _settings.notifyVoiceMessages,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(notifyVoiceMessages: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ساعات سکوت',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('ساعت شروع'),
              subtitle: Text(
                _settings.quietStartTime != null
                    ? _settings.quietStartTime!.format(context)
                    : 'تنظیم نشده',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _settings.enabled ? _selectQuietStartTime : null,
            ),
            ListTile(
              title: const Text('ساعت پایان'),
              subtitle: Text(
                _settings.quietEndTime != null
                    ? _settings.quietEndTime!.format(context)
                    : 'تنظیم نشده',
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _settings.enabled ? _selectQuietEndTime : null,
            ),
            if (_settings.quietStartTime != null &&
                _settings.quietEndTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'در این ساعات نوتیفیکیشن دریافت نمی‌کنید',
                  style: TextStyle(
                    color: AppTheme.textColor.withValues(alpha: 0.1),
                    fontSize: 12.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تنظیمات پیشرفته',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('گروه‌بندی نوتیفیکیشن‌ها'),
              subtitle: const Text('ترکیب نوتیفیکیشن‌های متعدد از یک مکالمه'),
              value: _settings.groupNotifications,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(groupNotifications: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
            SwitchListTile(
              title: const Text('نمایش پیش‌نمایش'),
              subtitle: const Text('نمایش محتوای پیام در نوتیفیکیشن'),
              value: _settings.showPreview,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(_settings.copyWith(showPreview: value));
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
            SwitchListTile(
              title: const Text('صدا'),
              subtitle: const Text('صدای نوتیفیکیشن'),
              value: _settings.soundEnabled,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(_settings.copyWith(soundEnabled: value));
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
            SwitchListTile(
              title: const Text('لرزش'),
              subtitle: const Text('لرزش نوتیفیکیشن'),
              value: _settings.vibrationEnabled,
              onChanged: _settings.enabled
                  ? (value) {
                      _updateSettings(
                        _settings.copyWith(vibrationEnabled: value),
                      );
                    }
                  : null,
              activeThumbColor: AppTheme.goldColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'پیش‌نمایش تنظیمات',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPreviewItem(
              'وضعیت کلی',
              _settings.enabled ? 'فعال' : 'غیرفعال',
            ),
            _buildPreviewItem(
              'از مربیان',
              _settings.notifyFromTrainers ? 'بله' : 'خیر',
            ),
            _buildPreviewItem(
              'از ورزشکاران',
              _settings.notifyFromAthletes ? 'بله' : 'خیر',
            ),
            _buildPreviewItem(
              'پیام‌های متنی',
              _settings.notifyTextMessages ? 'بله' : 'خیر',
            ),
            _buildPreviewItem(
              'تصاویر',
              _settings.notifyImageMessages ? 'بله' : 'خیر',
            ),
            _buildPreviewItem(
              'فایل‌ها',
              _settings.notifyFileMessages ? 'بله' : 'خیر',
            ),
            _buildPreviewItem(
              'پیام‌های صوتی',
              _settings.notifyVoiceMessages ? 'بله' : 'خیر',
            ),
            if (_settings.quietStartTime != null &&
                _settings.quietEndTime != null)
              _buildPreviewItem(
                'ساعات سکوت',
                '${_settings.quietStartTime!.format(context)} - ${_settings.quietEndTime!.format(context)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.goldColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectQuietStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _settings.quietStartTime ?? const TimeOfDay(hour: 22, minute: 0),
    );

    if (picked != null) {
      _updateSettings(_settings.copyWith(quietStartTime: picked));
    }
  }

  Future<void> _selectQuietEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _settings.quietEndTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      _updateSettings(_settings.copyWith(quietEndTime: picked));
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('راهنمای تنظیمات'),
        content: const SingleChildScrollView(
          child: Text(
            '• نوتیفیکیشن پیام‌های شخصی: کنترل کلی دریافت نوتیفیکیشن‌ها\n\n'
            '• نوع کاربر: انتخاب دریافت نوتیفیکیشن از مربیان یا ورزشکاران\n\n'
            '• نوع پیام: انتخاب نوع پیام‌هایی که برای آن‌ها نوتیفیکیشن دریافت می‌کنید\n\n'
            '• ساعات سکوت: تعیین ساعاتی که نوتیفیکیشن دریافت نمی‌کنید\n\n'
            '• گروه‌بندی: ترکیب نوتیفیکیشن‌های متعدد از یک مکالمه\n\n'
            '• پیش‌نمایش: نمایش محتوای پیام در نوتیفیکیشن',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }
}
