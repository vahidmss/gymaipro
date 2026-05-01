import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/announcements/models/in_app_announcement.dart';
import 'package:gymaipro/announcements/services/in_app_announcement_service.dart';
import 'package:gymaipro/academy/services/cover_upload_service.dart';
import 'package:gymaipro/services/coach_video_upload_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/widgets/upload_progress_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final InAppAnnouncementService _service = InAppAnnouncementService();
  bool _isLoading = true;
  List<InAppAnnouncement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.getAllAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('خطا در دریافت اطلاعیه‌ها: $e', isError: true);
    }
  }

  Future<void> _showAnnouncementForm({InAppAnnouncement? current}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _AnnouncementFormDialog(current: current),
    );
    if (result == true) {
      await _loadAnnouncements();
    }
  }

  Future<void> _deleteAnnouncement(InAppAnnouncement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف اطلاعیه'),
          content: Text('آیا از حذف "${announcement.title}" مطمئن هستید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteAnnouncement(announcement.id);
      _showMessage('اطلاعیه حذف شد');
      await _loadAnnouncements();
    } catch (e) {
      _showMessage('حذف انجام نشد: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundColor
          : AppTheme.lightBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAnnouncementForm(),
        backgroundColor: AppTheme.goldColor,
        foregroundColor: AppTheme.onGoldColor,
        icon: const Icon(LucideIcons.plus),
        label: const Text('اطلاعیه جدید'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.goldColor))
          : RefreshIndicator(
              onRefresh: _loadAnnouncements,
              child: _announcements.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 120.h),
                        Icon(
                          LucideIcons.megaphone,
                          size: 56.sp,
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.4)
                              : AppTheme.lightTextSecondary,
                        ),
                        SizedBox(height: 12.h),
                        Center(
                          child: Text(
                            'هنوز اطلاعیه‌ای ثبت نشده است',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDark
                                  ? AppTheme.darkTextColor.withValues(
                                      alpha: 0.7,
                                    )
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final item = _announcements[index];
                        return _buildCard(item, isDark);
                      },
                    ),
            ),
    );
  }

  Widget _buildCard(InAppAnnouncement item, bool isDark) {
    return Card(
      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.darkTextColor
                          : AppTheme.lightTextColor,
                    ),
                  ),
                ),
                Switch(
                  value: item.isActive,
                  onChanged: (value) async {
                    await _service.toggleActive(item.id, isActive: value);
                    await _loadAnnouncements();
                  },
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextColor.withValues(alpha: 0.8)
                    : AppTheme.lightTextSecondary,
              ),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                _chip(
                  item.mediaType == AnnouncementMediaType.image
                      ? 'تصویر'
                      : 'ویدیو',
                  isDark,
                ),
                _chip(_dismissText(item.dismissMode), isDark),
                if (item.startAt != null)
                  _chip('شروع: ${_dateText(item.startAt!)}', isDark),
                if (item.endAt != null)
                  _chip('پایان: ${_dateText(item.endAt!)}', isDark),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showAnnouncementForm(current: item),
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('ویرایش'),
                ),
                SizedBox(width: 8.w),
                OutlinedButton.icon(
                  onPressed: () => _deleteAnnouncement(item),
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
        ),
      ),
    );
  }

  String _dismissText(AnnouncementDismissMode mode) {
    switch (mode) {
      case AnnouncementDismissMode.always:
        return 'همیشه';
      case AnnouncementDismissMode.daily:
        return 'روزی یک‌بار';
      case AnnouncementDismissMode.once:
        return 'فقط یک‌بار';
    }
  }

  String _dateText(DateTime value) {
    return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
  }
}

class _AnnouncementFormDialog extends StatefulWidget {
  const _AnnouncementFormDialog({this.current});

  final InAppAnnouncement? current;

  @override
  State<_AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final _service = InAppAnnouncementService();
  final _coverUploadService = CoverUploadService();
  final _videoUploadService = CoachVideoUploadService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _ctaTextController = TextEditingController(text: 'بزن بریم');
  final _ctaValueController = TextEditingController();

  AnnouncementMediaType _mediaType = AnnouncementMediaType.image;
  AnnouncementCtaType _ctaType = AnnouncementCtaType.none;
  AnnouncementDismissMode _dismissMode = AnnouncementDismissMode.daily;
  bool _isActive = true;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _isSaving = false;
  bool _isUploadingMedia = false;
  late final List<_DeepLinkOption> _deepLinkOptions;
  String? _selectedDeepLink;

  bool get _isEditing => widget.current != null;

  @override
  void initState() {
    super.initState();
    _deepLinkOptions = _buildDefaultDeepLinks();
    final current = widget.current;
    if (current == null) return;
    _titleController.text = current.title;
    _descriptionController.text = current.description;
    _mediaUrlController.text = current.mediaUrl ?? '';
    _ctaTextController.text = current.ctaText ?? 'بزن بریم';
    _ctaValueController.text = current.ctaValue ?? '';
    _mediaType = current.mediaType;
    _ctaType = current.ctaType;
    _dismissMode = current.dismissMode;
    _isActive = current.isActive;
    _startAt = current.startAt;
    _endAt = current.endAt;
    if (_ctaType == AnnouncementCtaType.deepLink) {
      _selectedDeepLink = _ctaValueController.text.trim().isEmpty
          ? null
          : _ctaValueController.text.trim();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mediaUrlController.dispose();
    _ctaTextController.dispose();
    _ctaValueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startAt ?? now) : (_endAt ?? now);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _startAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          0,
          0,
          0,
        );
      } else {
        _endAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
          59,
        );
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      _showError('عنوان و متن الزامی است');
      return;
    }
    if (_ctaType != AnnouncementCtaType.none &&
        _ctaValueController.text.trim().isEmpty) {
      _showError('برای CTA باید لینک مقصد را وارد کنید');
      return;
    }
    if (_startAt != null && _endAt != null && _endAt!.isBefore(_startAt!)) {
      _showError('تاریخ پایان نباید قبل از شروع باشد');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = InAppAnnouncement(
        id: widget.current?.id ?? '',
        title: title,
        description: description,
        mediaType: _mediaType,
        mediaUrl: _mediaUrlController.text.trim(),
        ctaType: _ctaType,
        ctaText: _ctaTextController.text.trim(),
        ctaValue: _ctaValueController.text.trim(),
        dismissMode: _dismissMode,
        priority: widget.current?.priority ?? 0,
        isActive: _isActive,
        startAt: _startAt,
        endAt: _endAt,
        createdAt: widget.current?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await _service.updateAnnouncement(payload);
      } else {
        await _service.createAnnouncement(payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError('ذخیره انجام نشد: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<_DeepLinkOption> _buildDefaultDeepLinks() {
    return const [
      _DeepLinkOption('/main', 'خانه اصلی'),
      _DeepLinkOption('/dashboard', 'داشبورد'),
      _DeepLinkOption('/profile', 'پروفایل'),
      _DeepLinkOption('/my-club', 'باشگاه من'),
      _DeepLinkOption('/ai-programs', 'برنامه‌های هوش مصنوعی'),
      _DeepLinkOption('/program-type-selection', 'ساخت برنامه'),
      _DeepLinkOption('/workout-log', 'لاگ تمرین'),
      _DeepLinkOption('/meal-log', 'لاگ تغذیه'),
      _DeepLinkOption('/food-list', 'لیست غذاها'),
      _DeepLinkOption('/exercise-list', 'لیست تمرینات'),
      _DeepLinkOption('/trainer-ranking', 'رتبه‌بندی مربیان'),
      _DeepLinkOption('/ranking', 'رتبه‌بندی کاربران'),
      _DeepLinkOption('/notifications', 'اعلان‌ها'),
      _DeepLinkOption('/wallet', 'کیف پول'),
      _DeepLinkOption('/subscriptions', 'اشتراک‌ها'),
      _DeepLinkOption('/chat-main', 'چت اصلی'),
      _DeepLinkOption('/settings', 'تنظیمات'),
      _DeepLinkOption('/help', 'راهنما'),
    ];
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.goldColor),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadMedia() async {
    if (_isUploadingMedia) return;

    if (kIsWeb) {
      _showError('آپلود فایل از Web در این صفحه پشتیبانی نشده است');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: _mediaType == AnnouncementMediaType.video
            ? FileType.video
            : FileType.image,
        allowMultiple: false,
      );
      final selectedPath = result?.files.single.path;
      if (selectedPath == null || selectedPath.trim().isEmpty) return;

      final selectedFile = File(selectedPath);
      final fileName = selectedPath.split('/').last;
      final fileSize = await selectedFile.length();
      final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

      setState(() => _isUploadingMedia = true);
      UploadProgressHelper.show(
        context: context,
        title: _mediaType == AnnouncementMediaType.video
            ? 'در حال آپلود ویدیو...'
            : 'در حال آپلود تصویر...',
        fileName: fileName,
        progress: 0,
        statusText: 'شروع آپلود',
      );

      final uploadedUrl = _mediaType == AnnouncementMediaType.video
          ? await _videoUploadService.uploadVideo(
              selectedFile,
              uploadContext: 'announcements',
              onProgress: (progress) {
                final statusText = progress < 0.3
                    ? 'در حال ارسال فایل...'
                    : progress < 0.8
                    ? 'در حال آپلود ($fileSizeMB MB)...'
                    : 'در حال نهایی‌سازی...';
                UploadProgressHelper.update(
                  progress: progress,
                  statusText: statusText,
                );
              },
            )
          : await _coverUploadService.uploadCover(
              selectedFile,
              uploadContext: 'announcements',
              onProgress: (progress) {
                final statusText = progress < 0.3
                    ? 'در حال ارسال فایل...'
                    : progress < 0.8
                    ? 'در حال آپلود ($fileSizeMB MB)...'
                    : 'در حال نهایی‌سازی...';
                UploadProgressHelper.update(
                  progress: progress,
                  statusText: statusText,
                );
              },
            );

      _mediaUrlController.text = uploadedUrl;
      UploadProgressHelper.hide();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فایل با موفقیت روی سرور دانلود آپلود شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      UploadProgressHelper.hide();
      if (mounted) {
        _showError('خطا در آپلود فایل: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark
          ? AppTheme.darkCardColor
          : AppTheme.lightCardColor,
      title: Row(
        children: [
          Icon(LucideIcons.megaphone, color: AppTheme.goldColor),
          SizedBox(width: 8.w),
          Text(_isEditing ? 'ویرایش اطلاعیه' : 'ایجاد اطلاعیه جدید'),
        ],
      ),
      content: SizedBox(
        width: 620.w,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('محتوا', LucideIcons.fileText),
              SizedBox(height: 10.h),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان اطلاعیه',
                  hintText: 'مثال: تخفیف ویژه اشتراک',
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'متن اطلاعیه',
                  hintText: 'توضیح کوتاه و واضح درباره خبر',
                ),
                textDirection: TextDirection.rtl,
              ),
              SizedBox(height: 18.h),
              _sectionTitle('مدیا', LucideIcons.image),
              SizedBox(height: 10.h),
              DropdownButtonFormField<AnnouncementMediaType>(
                initialValue: _mediaType,
                decoration: const InputDecoration(labelText: 'نوع مدیا'),
                items: const [
                  DropdownMenuItem(
                    value: AnnouncementMediaType.image,
                    child: Text('تصویر'),
                  ),
                  DropdownMenuItem(
                    value: AnnouncementMediaType.video,
                    child: Text('ویدیو'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _mediaType = value);
                },
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _mediaUrlController,
                decoration: const InputDecoration(
                  labelText: 'لینک فایل مدیا',
                  hintText: 'پس از آپلود، این فیلد خودکار پر می‌شود',
                ),
                readOnly: true,
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isUploadingMedia ? null : _pickAndUploadMedia,
                  icon: _isUploadingMedia
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(LucideIcons.upload, size: 16),
                  label: Text(
                    _mediaType == AnnouncementMediaType.video
                        ? 'انتخاب و آپلود ویدیو'
                        : 'انتخاب و آپلود تصویر',
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              _sectionTitle('دکمه اقدام (CTA)', LucideIcons.mousePointer2),
              SizedBox(height: 10.h),
              DropdownButtonFormField<AnnouncementDismissMode>(
                initialValue: _dismissMode,
                decoration: const InputDecoration(
                  labelText: 'الگوی نمایش اطلاعیه',
                ),
                items: const [
                  DropdownMenuItem(
                    value: AnnouncementDismissMode.always,
                    child: Text('همیشه'),
                  ),
                  DropdownMenuItem(
                    value: AnnouncementDismissMode.daily,
                    child: Text('روزی یک‌بار'),
                  ),
                  DropdownMenuItem(
                    value: AnnouncementDismissMode.once,
                    child: Text('فقط یک‌بار'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _dismissMode = value);
                },
              ),
              DropdownButtonFormField<AnnouncementCtaType>(
                initialValue: _ctaType,
                decoration: const InputDecoration(labelText: 'نوع CTA'),
                items: const [
                  DropdownMenuItem(
                    value: AnnouncementCtaType.none,
                    child: Text('بدون CTA'),
                  ),
                  DropdownMenuItem(
                    value: AnnouncementCtaType.deepLink,
                    child: Text('لینک داخلی'),
                  ),
                  DropdownMenuItem(
                    value: AnnouncementCtaType.externalUrl,
                    child: Text('لینک خارجی'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _ctaType = value;
                      if (_ctaType != AnnouncementCtaType.deepLink) {
                        _selectedDeepLink = null;
                      }
                    });
                  }
                },
              ),
              if (_ctaType != AnnouncementCtaType.none) ...[
                SizedBox(height: 10.h),
                TextField(
                  controller: _ctaTextController,
                  decoration: const InputDecoration(
                    labelText: 'متن دکمه',
                    hintText: 'مثال: بزن بریم',
                  ),
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 10.h),
                if (_ctaType == AnnouncementCtaType.deepLink)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDeepLink,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'لینک داخلی آماده',
                    ),
                    items: _deepLinkOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option.route,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedDeepLink = value);
                      _ctaValueController.text = value;
                    },
                  ),
                if (_ctaType == AnnouncementCtaType.deepLink &&
                    _selectedDeepLink != null)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Text(
                      'مسیر انتخاب‌شده: ${_selectedDeepLink!}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark
                            ? AppTheme.darkTextColor.withValues(alpha: 0.75)
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                if (_ctaType == AnnouncementCtaType.deepLink)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'مسیرهای نیازمند پارامتر (مثل جزییات مقاله/کاربر) در لیست نیستند.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark
                            ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                if (_ctaType == AnnouncementCtaType.externalUrl)
                  TextField(
                    controller: _ctaValueController,
                    decoration: const InputDecoration(
                      labelText: 'لینک خارجی',
                      hintText: 'https://example.com',
                    ),
                  ),
              ],
              SizedBox(height: 18.h),
              _sectionTitle('انتشار', LucideIcons.calendarDays),
              SizedBox(height: 8.h),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('فعال باشد'),
                subtitle: const Text(
                  'فقط اطلاعیه فعال در اپ نمایش داده می‌شود',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: true),
                      child: Text(
                        _startAt == null
                            ? 'تاریخ شروع'
                            : 'شروع: ${_dateText(_startAt!)}',
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: Text(
                        _endAt == null
                            ? 'تاریخ پایان'
                            : 'پایان: ${_dateText(_endAt!)}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'ذخیره تغییرات' : 'ایجاد اطلاعیه'),
        ),
      ],
    );
  }

  String _dateText(DateTime value) {
    return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
  }
}

class _DeepLinkOption {
  const _DeepLinkOption(this.route, this.label);

  final String route;
  final String label;
}
