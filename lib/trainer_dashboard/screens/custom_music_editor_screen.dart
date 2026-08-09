import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/custom_music.dart';
import 'package:gymaipro/academy/services/custom_music_service.dart';
import 'package:gymaipro/academy/services/music_upload_service.dart';
import 'package:gymaipro/academy/services/cover_upload_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/widgets/upload_progress_dialog.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه ساخت/ویرایش موزیک اختصاصی
class CustomMusicEditorScreen extends StatefulWidget {

  const CustomMusicEditorScreen({super.key, this.music});
  final CustomMusic? music;

  @override
  State<CustomMusicEditorScreen> createState() =>
      _CustomMusicEditorScreenState();
}

class _CustomMusicEditorScreenState extends State<CustomMusicEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomMusicService();
  final _uploadService = MusicUploadService();
  final _coverUploadService = CoverUploadService();
  final _picker = ImagePicker();

  // Controllers
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _singerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  // State
  String _visibility = 'private';
  bool _isLoading = false;

  File? _selectedAudio;
  XFile? _selectedImage;
  String? _uploadedAudioUrl;
  String? _uploadedImageUrl;
  int _duration = 0; // مدت زمان به ثانیه

  // Lists
  final List<String> _categories = [
    'انرژی‌بخش',
    'آرامش‌بخش',
    'متحرک',
    'کلاسیک',
    'الکترونیک',
    'راک',
    'هیپ‌هاپ',
    'پاپ',
    'سایر',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    if (widget.music == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDisplayArtist());
    }
  }

  Future<void> _loadDisplayArtist() async {
    try {
      final displayArtist = await _service.resolveArtistByCurrentUser();
      if (mounted && widget.music == null && _artistController.text.isEmpty) {
        _artistController.text = displayArtist;
      }
    } catch (_) {}
  }


  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _singerController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.music != null) {
      final m = widget.music!;
      _titleController.text = m.title;
      _artistController.text = m.artist;
      _singerController.text = m.singer ?? '';
      _descriptionController.text = m.description ?? '';
      _categoryController.text = m.category ?? '';
      _visibility = m.visibility;
      _uploadedAudioUrl = m.audioUrl;
      _uploadedImageUrl = m.coverImageUrl;
      _duration = m.duration;
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudio = File(result.files.single.path!);
          _uploadedAudioUrl = null; // Reset uploaded URL when new file selected
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در انتخاب فایل: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در انتخاب تصویر: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }


  Future<void> _saveMusic() async {
    if (!_formKey.currentState!.validate()) return;

    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);

    try {
      // آپلود تصویر کاور اگر انتخاب شده اما هنوز آپلود نشده
      String? finalImageUrl = _uploadedImageUrl;
      if (_selectedImage != null && (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty)) {
        debugPrint('CustomMusicEditor: Image selected but not uploaded, uploading to download host now...');
        
        final imageFile = File(_selectedImage!.path);
        final fileName = _selectedImage!.path.split('/').last;
        final fileSize = await imageFile.length();
        final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

        if (!mounted) return;
        UploadProgressHelper.show(
          context: context,
          title: 'در حال آپلود تصویر کاور...',
          fileName: fileName,
          statusText: 'شروع آپلود',
        );

        try {
          finalImageUrl = await _coverUploadService.uploadCover(
            imageFile,
            onProgress: (progress) {
              String statusText;
              if (progress < 0.3) {
                statusText = 'در حال ارسال فایل...';
              } else if (progress < 0.7) {
                statusText = 'در حال آپلود ($fileSizeMB MB)...';
              } else if (progress < 0.9) {
                statusText = 'در حال پردازش...';
              } else {
                statusText = 'در حال نهایی‌سازی...';
              }

              UploadProgressHelper.update(
                progress: progress,
                statusText: statusText,
              );
            },
          );
          
          debugPrint('CustomMusicEditor: Cover image uploaded to download host: $finalImageUrl');
          _uploadedImageUrl = finalImageUrl;
          UploadProgressHelper.hide();
        } catch (e) {
          UploadProgressHelper.hide();
          rethrow;
        }
      }

      // تصویر کاور اختیاری است - اگر وجود نداشت از یک تصویر پیش‌فرض استفاده می‌کنیم
      if (finalImageUrl == null || finalImageUrl.isEmpty) {
        // می‌توانید یک URL تصویر پیش‌فرض قرار دهید
        finalImageUrl = ''; // یا یک URL پیش‌فرض
      }

      // آپلود فایل موزیک اگر انتخاب شده
      String? finalAudioUrl = _uploadedAudioUrl;
      if (_selectedAudio != null) {
        // آپلود فایل جدید
        final fileName = _selectedAudio!.path.split('/').last;
        final fileSize = await _selectedAudio!.length();
        final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

        if (!mounted) return;
        UploadProgressHelper.show(
          context: context,
          title: 'در حال آپلود موزیک...',
          fileName: fileName,
          statusText: 'شروع آپلود',
        );

        try {
          finalAudioUrl = await _uploadService.uploadMusic(
            _selectedAudio!,
            onProgress: (progress) {
              String statusText;
              if (progress < 0.3) {
                statusText = 'در حال ارسال فایل...';
              } else if (progress < 0.7) {
                statusText = 'در حال آپلود ($fileSizeMB MB)...';
              } else if (progress < 0.9) {
                statusText = 'در حال پردازش...';
              } else {
                statusText = 'در حال نهایی‌سازی...';
              }

              UploadProgressHelper.update(
                progress: progress,
                statusText: statusText,
              );
            },
          );
          UploadProgressHelper.hide();
        } catch (e) {
          UploadProgressHelper.hide();
          rethrow;
        }
      }

      if (!mounted) return;
      if (finalAudioUrl == null || finalAudioUrl.isEmpty) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'لطفاً فایل موزیک را انتخاب و آپلود کنید',
          backgroundColor: AppTheme.errorColor,
        );
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        return;
      }

      if (widget.music == null) {
        // ساخت جدید
        debugPrint('CustomMusicEditor: Creating new music...');
        debugPrint('CustomMusicEditor: Cover image URL: $finalImageUrl');
        debugPrint('CustomMusicEditor: Audio URL: $finalAudioUrl');
        
        final createdMusic = await _service.createMusic(
          title: _titleController.text.trim(),
          artist: _artistController.text.trim(),
          audioUrl: finalAudioUrl,
          coverImageUrl: finalImageUrl,
          duration: _duration,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          singer: _singerController.text.trim().isEmpty
              ? null
              : _singerController.text.trim(),
          visibility: _visibility,
        );

        if (mounted) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'موزیک با موفقیت اضافه شد',
            backgroundColor: AppTheme.successColor,
          );
          Navigator.pop(context, createdMusic);
        }
      } else {
        // ویرایش
        debugPrint('CustomMusicEditor: Updating music...');
        debugPrint('CustomMusicEditor: Cover image URL: $finalImageUrl');
        debugPrint('CustomMusicEditor: Audio URL: $finalAudioUrl');
        
        final updatedMusic = await _service.updateMusic(
          musicId: widget.music!.id,
          title: _titleController.text.trim(),
          artist: _artistController.text.trim(),
          audioUrl: finalAudioUrl,
          coverImageUrl: finalImageUrl,
          duration: _duration > 0 ? _duration : null,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          singer: _singerController.text.trim().isEmpty
              ? null
              : _singerController.text.trim(),
          visibility: _visibility,
        );

        if (mounted) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'موزیک با موفقیت به‌روزرسانی شد',
            backgroundColor: AppTheme.successColor,
          );
          Navigator.pop(context, updatedMusic);
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در ذخیره موزیک: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);
    final body = isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground;
    final hasAudio = _selectedAudio != null || _uploadedAudioUrl != null;
    final hasCover = _selectedImage != null ||
        (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty);
    final nextHint = !hasAudio
        ? 'فایل موزیک را انتخاب کن'
        : (_titleController.text.trim().isEmpty ? 'عنوان را بنویس' : null);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.music == null ? 'موزیک جدید' : 'ویرایش موزیک',
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppTheme.darkCardColor : AppTheme.darkTextColor,
        elevation: 0,
        automaticallyImplyLeading: !_isLoading,
      ),
      body: _isLoading
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.goldColor),
                    SizedBox(height: 20.h),
                    Text(
                      'در حال ذخیره موزیک…',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: body,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'لطفاً صبر کن — قطع نکن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5.sp,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                children: [
                  _sectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('اطلاعات اصلی', LucideIcons.star, body),
                        SizedBox(height: 12.h),
                        _field(
                          controller: _titleController,
                          label: 'عنوان موزیک',
                          hint: 'مثال: انگیزشی صبحگاهی',
                          icon: LucideIcons.music,
                          isDark: isDark,
                          body: body,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'عنوان الزامی است'
                                  : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: 10.h),
                        _field(
                          controller: _artistController,
                          label: 'نام نمایشی (نویسنده)',
                          hint: 'به‌صورت خودکار تنظیم می‌شود',
                          icon: LucideIcons.user,
                          isDark: isDark,
                          body: body,
                          readOnly: true,
                        ),
                        SizedBox(height: 10.h),
                        _field(
                          controller: _singerController,
                          label: 'نام خواننده (اختیاری)',
                          hint: 'برای بی‌کلام خالی بگذار',
                          icon: LucideIcons.mic2,
                          isDark: isDark,
                          body: body,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _sectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('فایل و کاور', LucideIcons.disc, body),
                        SizedBox(height: 12.h),
                        _buildMediaSelector(
                          label: 'فایل موزیک',
                          icon: LucideIcons.music,
                          isDark: isDark,
                          hasFile: hasAudio,
                          onPick: _pickAudio,
                          onRemove: () {
                            WidgetSafetyUtils.safeSetState(this, () {
                              _selectedAudio = null;
                              _uploadedAudioUrl = null;
                            });
                          },
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'تصویر کاور',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: body,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        if (hasCover)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _selectedImage != null
                                  ? Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _uploadedImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppTheme.goldColor
                                            .withValues(alpha: 0.1),
                                        child: Icon(
                                          LucideIcons.image,
                                          color: AppTheme.goldColor,
                                          size: 32.sp,
                                        ),
                                      ),
                                    ),
                            ),
                          )
                        else
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(12.r),
                              child: Ink(
                                height: 96.h,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.veryDarkBackground
                                          .withValues(alpha: 0.35)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.camera,
                                      color: AppTheme.goldColor,
                                      size: 26.sp,
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      'افزودن تصویر کاور',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: body,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'اختیاری',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 11.sp,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (hasCover) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(LucideIcons.image, size: 16.sp),
                                label: const Text('تغییر'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.goldColor,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  WidgetSafetyUtils.safeSetState(this, () {
                                    _selectedImage = null;
                                    _uploadedImageUrl = null;
                                  });
                                },
                                icon: Icon(LucideIcons.trash2, size: 16.sp),
                                label: const Text('حذف'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _sectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle(
                          'مشخصات بیشتر',
                          LucideIcons.slidersHorizontal,
                          body,
                        ),
                        SizedBox(height: 12.h),
                        DropdownButtonFormField<String>(
                          initialValue: _categoryController.text.isEmpty
                              ? null
                              : _categoryController.text,
                          decoration: InputDecoration(
                            labelText: 'دسته‌بندی',
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkCardColor
                                : AppTheme.darkTextColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            prefixIcon: Icon(
                              LucideIcons.folder,
                              color: AppTheme.goldColor,
                              size: 18.sp,
                            ),
                          ),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _categoryController.text = value ?? '';
                            });
                          },
                        ),
                        SizedBox(height: 10.h),
                        _field(
                          controller: _descriptionController,
                          label: 'توضیحات (اختیاری)',
                          hint: 'توضیح کوتاه درباره موزیک',
                          icon: LucideIcons.fileText,
                          isDark: isDark,
                          body: body,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _sectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('دسترسی', LucideIcons.lock, body),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _accessPill(
                                isDark: isDark,
                                body: body,
                                label: 'خصوصی',
                                icon: LucideIcons.lock,
                                selected: _visibility == 'private',
                                onTap: () =>
                                    setState(() => _visibility = 'private'),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _accessPill(
                                isDark: isDark,
                                body: body,
                                label: 'عمومی',
                                icon: LucideIcons.globe,
                                selected: _visibility == 'public',
                                onTap: () =>
                                    setState(() => _visibility = 'public'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.music != null) ...[
                    SizedBox(height: 16.h),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteMusic,
                      icon: Icon(LucideIcons.trash2, size: 18.sp),
                      label: const Text('حذف موزیک'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Material(
              elevation: 8,
              color: isDark ? AppTheme.darkCardColor : Colors.white,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (nextHint != null) ...[
                        Text(
                          nextHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      ElevatedButton.icon(
                        onPressed: _saveMusic,
                        icon: Icon(
                          widget.music == null
                              ? LucideIcons.plus
                              : LucideIcons.save,
                          size: 20.sp,
                        ),
                        label: Text(
                          widget.music == null
                              ? 'ساخت موزیک'
                              : 'ذخیره تغییرات',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: AppTheme.veryDarkBackground,
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color body) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.goldColor, size: 18.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: body,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required bool isDark, required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
        child: child,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color body,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14.sp,
        color: body,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: isDark ? AppTheme.darkCardColor : AppTheme.darkTextColor,
        prefixIcon: Icon(icon, color: AppTheme.goldColor, size: 18.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
        ),
      ),
    );
  }

  Widget _accessPill({
    required bool isDark,
    required Color body,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.16)
                : (isDark
                    ? AppTheme.veryDarkBackground.withValues(alpha: 0.3)
                    : Colors.grey[100]),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected
                  ? AppTheme.goldColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: selected ? AppTheme.goldColor : Colors.grey,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: selected ? body : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMusic() async {
    if (widget.music == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف موزیک'),
        content: const Text('آیا از حذف این موزیک اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);

    try {
      final success = await _service.deleteMusic(widget.music!.id);
      if (mounted) {
        if (success) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'موزیک با موفقیت حذف شد',
            backgroundColor: AppTheme.successColor,
          );
          WidgetSafetyUtils.safePop(context, widget.music);
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'خطا در حذف موزیک',
            backgroundColor: AppTheme.errorColor,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
    }
  }

  Widget _buildMediaSelector({
    required String label,
    required IconData icon,
    required bool isDark,
    required bool hasFile,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final body = isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasFile
              ? AppTheme.goldColor.withValues(alpha: 0.55)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: body,
                  ),
                ),
                if (hasFile)
                  Text(
                    _selectedAudio != null
                        ? _selectedAudio!.path.split(RegExp(r'[/\\]')).last
                        : 'آپلود شده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5.sp,
                      color: AppTheme.goldColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'قبل از ذخیره لازم است',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5.sp,
                      color: isDark ? Colors.grey[400] : const Color(0xFF5A5A5A),
                    ),
                  ),
              ],
            ),
          ),
          if (hasFile)
            IconButton(
              icon: Icon(LucideIcons.trash2, color: AppTheme.errorColor, size: 18.sp),
              onPressed: onRemove,
            ),
          TextButton.icon(
            onPressed: onPick,
            icon: Icon(LucideIcons.upload, size: 16.sp),
            label: Text(hasFile ? 'تغییر' : 'انتخاب'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.goldColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog برای وارد کردن URL موزیک
class _AudioUrlDialog extends StatefulWidget {

  const _AudioUrlDialog({
    required this.onUrlEntered,
  });
  final void Function(String) onUrlEntered;

  @override
  State<_AudioUrlDialog> createState() => _AudioUrlDialogState();
}

class _AudioUrlDialogState extends State<_AudioUrlDialog> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      title: const Text(
        'وارد کردن URL موزیک',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'آدرس فایل موزیک',
            hintText: 'https://dl.gymaipro.ir/music/example.mp3',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            prefixIcon: const Icon(LucideIcons.link),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'لطفاً آدرس را وارد کنید';
            }
            if (!value.startsWith('http://') &&
                !value.startsWith('https://')) {
              return 'آدرس باید با http:// یا https:// شروع شود';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onUrlEntered(_urlController.text.trim());
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.goldColor,
            foregroundColor: Colors.black,
          ),
          child: const Text('تایید'),
        ),
      ],
    );
  }
}

