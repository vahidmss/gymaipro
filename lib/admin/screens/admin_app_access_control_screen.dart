import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/app_access_control_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdminAppAccessControlScreen extends StatefulWidget {
  const AdminAppAccessControlScreen({super.key});

  @override
  State<AdminAppAccessControlScreen> createState() =>
      _AdminAppAccessControlScreenState();
}

class _AdminAppAccessControlScreenState
    extends State<AdminAppAccessControlScreen> {
  final AppAccessControlService _service = AppAccessControlService.instance;
  final TextEditingController _maintenanceMessageController =
      TextEditingController();
  final TextEditingController _minVersionController = TextEditingController();
  final TextEditingController _latestVersionController = TextEditingController();
  final TextEditingController _updateUrlController = TextEditingController();
  final TextEditingController _aiChatMessageController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  AppAccessConfig _config = AppAccessConfig.defaults();
  List<AppAccessAuditLog> _auditLogs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _maintenanceMessageController.dispose();
    _minVersionController.dispose();
    _latestVersionController.dispose();
    _updateUrlController.dispose();
    _aiChatMessageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final config = await _service.getConfig(forceRefresh: true);
    final logs = await _service.getAuditLogs();
    if (!mounted) return;
    setState(() {
      _config = config;
      _maintenanceMessageController.text = config.maintenanceMessage;
      _minVersionController.text = config.minSupportedVersion;
      _latestVersionController.text = config.latestVersion;
      _updateUrlController.text = config.updateUrl;
      _aiChatMessageController.text = config.aiChatUnavailableMessage;
      _auditLogs = logs;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final success = await _service.upsertConfig(
      _config.copyWith(
        maintenanceMessage: _maintenanceMessageController.text.trim(),
        minSupportedVersion: _minVersionController.text.trim(),
        latestVersion: _latestVersionController.text.trim(),
        updateUrl: _updateUrlController.text.trim(),
        aiChatUnavailableMessage: _aiChatMessageController.text.trim(),
      ),
    );
    if (!mounted) return;
    if (success) {
      _auditLogs = await _service.getAuditLogs();
      if (!mounted) return;
    }
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'تنظیمات با موفقیت ذخیره شد' : 'خطا در ذخیره تنظیمات'),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedLogs = [..._auditLogs]..sort((a, b) {
      final aMs = a.changedAt?.millisecondsSinceEpoch ?? 0;
      final bMs = b.changedAt?.millisecondsSinceEpoch ?? 0;
      return bMs.compareTo(aMs);
    });
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.goldColor,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSectionTitle('کنترل سراسری اپ', LucideIcons.shield),
          SwitchListTile(
            value: _config.maintenanceMode,
            activeThumbColor: AppTheme.goldColor,
            title: const Text('حالت تعمیرات'),
            subtitle: const Text('کاربران عادی وارد بخش اصلی اپ نمی‌شوند'),
            onChanged: (v) => setState(() {
              _config = _config.copyWith(maintenanceMode: v);
            }),
          ),
          DropdownButtonFormField<String>(
            initialValue: _config.maintenanceScope,
            decoration: const InputDecoration(labelText: 'دامنه تعمیرات'),
            items: const [
              DropdownMenuItem(
                value: 'all_non_admin',
                child: Text('همه کاربران (به‌جز ادمین)'),
              ),
              DropdownMenuItem(
                value: 'athlete_only',
                child: Text('فقط ورزشکارها'),
              ),
              DropdownMenuItem(
                value: 'trainer_only',
                child: Text('فقط مربی‌ها'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _config = _config.copyWith(maintenanceScope: value);
              });
            },
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _maintenanceMessageController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'پیام حالت تعمیرات',
              hintText: 'مثال: در حال بروزرسانی سرور هستیم...',
            ),
          ),
          SizedBox(height: 14.h),
          SwitchListTile(
            value: _config.forceUpdate,
            activeThumbColor: AppTheme.goldColor,
            title: const Text('اجبار به آپدیت'),
            subtitle: const Text('کاربران نسخه پایین‌تر باید آپدیت کنند'),
            onChanged: (v) => setState(() {
              _config = _config.copyWith(forceUpdate: v);
            }),
          ),
          TextField(
            controller: _minVersionController,
            decoration: const InputDecoration(
              labelText: 'حداقل نسخه مجاز',
              hintText: 'مثال: 1.2.0',
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _latestVersionController,
            decoration: const InputDecoration(
              labelText: 'آخرین نسخه منتشر شده',
              hintText: 'مثال: 1.4.0',
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _updateUrlController,
            decoration: const InputDecoration(
              labelText: 'لینک APK بروزرسانی',
              hintText: 'لینک مستقیم APK (Supabase Storage / Drive)',
              helperText:
                  'APK را روی سرور خودتان آپلود کنید و لینک مستقیم دانلود را اینجا بگذارید. '
                  'با تغییر latest_version، اپ به‌صورت خودکار آپدیت را پیشنهاد می‌دهد.',
            ),
          ),
          SizedBox(height: 20.h),
          _buildSectionTitle('فیچر فلگ‌ها', LucideIcons.toggleLeft),
          _toggle('AI Hub', _config.aiHubEnabled, (v) {
            setState(() => _config = _config.copyWith(aiHubEnabled: v));
          }),
          _toggle('آکادمی', _config.academyEnabled, (v) {
            setState(() => _config = _config.copyWith(academyEnabled: v));
          }),
          _toggle('باشگاه من', _config.myClubEnabled, (v) {
            setState(() => _config = _config.copyWith(myClubEnabled: v));
          }),
          _toggle('اجتماعی', _config.socialEnabled, (v) {
            setState(() => _config = _config.copyWith(socialEnabled: v));
          }),
          _toggle('چت خصوصی', _config.privateChatEnabled, (v) {
            setState(() => _config = _config.copyWith(privateChatEnabled: v));
          }),
          _toggle('چت عمومی', _config.publicChatEnabled, (v) {
            setState(() => _config = _config.copyWith(publicChatEnabled: v));
          }),
          SizedBox(height: 14.h),
          _buildSectionTitle('چت هوش مصنوعی (GPT)', LucideIcons.messageCircle),
          _toggle('چت GPT فعال', _config.aiChatEnabled, (v) {
            setState(() => _config = _config.copyWith(aiChatEnabled: v));
          }),
          TextField(
            controller: _aiChatMessageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'پیام وقتی چت GPT غیرفعال است',
              hintText: 'فعلاً چت با هوش مصنوعی در دسترس نیست!',
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: 16.h),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: isDark ? AppTheme.veryDarkBackground : AppTheme.darkTextColor,
              padding: EdgeInsets.symmetric(vertical: 13.h),
            ),
            icon: _isSaving
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save),
            label: Text(_isSaving ? 'در حال ذخیره...' : 'ذخیره تنظیمات'),
          ),
          SizedBox(height: 20.h),
          _buildSectionTitle('تاریخچه تغییرات', LucideIcons.history),
          if (sortedLogs.isEmpty)
            Text(
              'هنوز تغییری ثبت نشده است.',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                    : AppTheme.lightTextSecondary,
              ),
            ),
          for (final log in sortedLogs)
            Card(
              margin: EdgeInsets.only(bottom: 10.h),
              child: ListTile(
                title: Text(
                  log.summary,
                  style: TextStyle(fontSize: 12.sp),
                ),
                subtitle: Text(
                  '${log.adminName} • ${_formatRelativeDateTime(log.changedAt)} • ${_formatDateTime(log.changedAt)}',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'نامشخص';
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y/$m/$d - $hh:$mm';
  }

  String _formatRelativeDateTime(DateTime? date) {
    if (date == null) return 'نامشخص';
    final nowUtc = DateTime.now().toUtc();
    final d = nowUtc.difference(date.toUtc());
    if (d.isNegative) return 'همین الان';
    if (d.inSeconds < 60) return 'همین الان';
    if (d.inMinutes < 60) return '${d.inMinutes} دقیقه پیش';
    if (d.inHours < 24) return '${d.inHours} ساعت پیش';
    if (d.inDays == 1) return 'دیروز';
    if (d.inDays < 7) return '${d.inDays} روز پیش';
    return '${(d.inDays / 7).floor()} هفته پیش';
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.goldColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      activeThumbColor: AppTheme.goldColor,
      title: Text(title),
      onChanged: onChanged,
    );
  }
}
