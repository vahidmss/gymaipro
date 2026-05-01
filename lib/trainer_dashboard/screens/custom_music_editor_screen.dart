import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه ساخت/ویرایش موزیک اختصاصی
class CustomMusicEditorScreen extends StatefulWidget {
  final CustomMusic? music;

  const CustomMusicEditorScreen({super.key, this.music});

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
  double _uploadProgress = 0.0;

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
        allowMultiple: false,
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
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _uploadAudio() async {
    if (_selectedAudio == null) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'لطفاً ابتدا فایل موزیک را انتخاب کنید',
        backgroundColor: Colors.red,
      );
      return;
    }

    final fileName = _selectedAudio!.path.split('/').last;
    final fileSize = await _selectedAudio!.length();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    // نمایش دیالوگ آپلود
    UploadProgressHelper.show(
      context: context,
      title: 'در حال آپلود موزیک...',
      fileName: fileName,
      progress: 0.0,
      statusText: 'شروع آپلود',
    );

    try {
      _uploadedAudioUrl = await _uploadService.uploadMusic(
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

      // تخمین مدت زمان (می‌توانید از یک کتابخانه برای خواندن metadata استفاده کنید)
      // فعلاً 0 می‌گذاریم و بعداً می‌تواند از metadata فایل خوانده شود
      _duration = 0;

      UploadProgressHelper.hide();

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'موزیک با موفقیت آپلود شد',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      UploadProgressHelper.hide();
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در آپلود موزیک: $e',
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
        );
      }
    }
  }


  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      debugPrint('CustomMusicEditor: _uploadImage - No image selected');
      return;
    }

    final fileName = _selectedImage!.path.split('/').last;
    final imageFile = File(_selectedImage!.path);
    final fileSize = await imageFile.length();
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    // نمایش دیالوگ آپلود
    UploadProgressHelper.show(
      context: context,
      title: 'در حال آپلود تصویر کاور...',
      fileName: fileName,
      progress: 0.0,
      statusText: 'شروع آپلود',
    );

    try {
      debugPrint('CustomMusicEditor: Starting cover image upload to download host...');
      
      _uploadedImageUrl = await _coverUploadService.uploadCover(
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

      debugPrint('CustomMusicEditor: Cover image uploaded successfully');
      debugPrint('CustomMusicEditor: Image URL: $_uploadedImageUrl');

      UploadProgressHelper.hide();

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'تصویر با موفقیت آپلود شد',
          backgroundColor: Colors.green,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('CustomMusicEditor: Error uploading image: $e');
      debugPrint('CustomMusicEditor: Stack trace: $stackTrace');
      
      UploadProgressHelper.hide();
      
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در آپلود تصویر: $e',
          backgroundColor: Colors.red,
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

        UploadProgressHelper.show(
          context: context,
          title: 'در حال آپلود تصویر کاور...',
          fileName: fileName,
          progress: 0.0,
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

        UploadProgressHelper.show(
          context: context,
          title: 'در حال آپلود موزیک...',
          fileName: fileName,
          progress: 0.0,
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

      if (finalAudioUrl == null || finalAudioUrl.isEmpty) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'لطفاً فایل موزیک را انتخاب و آپلود کنید',
          backgroundColor: Colors.red,
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
          coverImageUrl: finalImageUrl ?? '',
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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.green,
          );
          Navigator.pop(context, updatedMusic);
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در ذخیره موزیک: $e',
          backgroundColor: Colors.red,
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.music == null ? 'موزیک جدید' : 'ویرایش موزیک',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _uploadProgress > 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: _uploadProgress),
                  SizedBox(height: 16.h),
                  Text(
                    'در حال آپلود... ${(_uploadProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  // عنوان
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان موزیک',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(LucideIcons.music),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفاً عنوان موزیک را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // هنرمند (ادمین: GymAI، مربی: نام و نام‌خانوادگی — به‌صورت خودکار ذخیره می‌شود)
                  TextFormField(
                    controller: _artistController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'نام نمایشی (نویسنده)',
                      helperText: 'ادمین: GymAI | مربی: نام شما. به‌صورت خودکار تنظیم می‌شود.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(LucideIcons.user),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // نام خواننده (اختیاری — برای موزیک بی‌کلام خالی بگذارید)
                  TextFormField(
                    controller: _singerController,
                    decoration: InputDecoration(
                      labelText: 'نام خواننده (اختیاری)',
                      helperText: 'برای موزیک بی‌کلام خالی بگذارید',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(LucideIcons.mic2),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // دسته‌بندی
                  DropdownButtonFormField<String>(
                    value: _categoryController.text.isEmpty
                        ? null
                        : _categoryController.text,
                    decoration: InputDecoration(
                      labelText: 'دسته‌بندی',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(LucideIcons.folder),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryController.text = value ?? '';
                      });
                    },
                  ),
                  SizedBox(height: 16.h),

                  // توضیحات
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'توضیحات (اختیاری)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      prefixIcon: const Icon(LucideIcons.fileText),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16.h),


                  // فایل موزیک
                  _buildMediaSelector(
                    label: 'فایل موزیک',
                    icon: LucideIcons.music,
                    isDark: isDark,
                    hasFile: _selectedAudio != null || _uploadedAudioUrl != null,
                    onPick: _pickAudio,
                    onRemove: () {
                      WidgetSafetyUtils.safeSetState(this, () {
                        _selectedAudio = null;
                        _uploadedAudioUrl = null;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),

                  // تصویر کاور
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تصویر کاور',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          if (_selectedImage != null || _uploadedImageUrl != null)
                            Container(
                              height: 150.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                image: DecorationImage(
                                  image: _selectedImage != null
                                      ? FileImage(File(_selectedImage!.path))
                                      : NetworkImage(_uploadedImageUrl!)
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          SizedBox(height: 8.h),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(LucideIcons.image),
                            label: const Text('انتخاب تصویر'),
                          ),
                          if (_selectedImage != null || _uploadedImageUrl != null)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  WidgetSafetyUtils.safeSetState(this, () {
                                    _selectedImage = null;
                                    _uploadedImageUrl = null;
                                  });
                                },
                                icon: const Icon(LucideIcons.trash2),
                                label: const Text('حذف تصویر'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Visibility
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'دسترسی',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          RadioListTile<String>(
                            title: const Text('خصوصی'),
                            subtitle: const Text('فقط شما می‌توانید ببینید'),
                            value: 'private',
                            groupValue: _visibility,
                            onChanged: (value) {
                              setState(() {
                                _visibility = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('عمومی'),
                            subtitle: const Text(
                              'همه می‌توانند ببینند (نیاز به تایید دارد)',
                            ),
                            value: 'public',
                            groupValue: _visibility,
                            onChanged: (value) {
                              setState(() {
                                _visibility = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // دکمه ذخیره
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMusic,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.music == null ? 'ذخیره موزیک' : 'به‌روزرسانی',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  if (widget.music != null) ...[
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteMusic,
                      icon: Icon(LucideIcons.trash2, size: 20.sp),
                      label: const Text('حذف موزیک'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                    ),
                  ],
                ],
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            backgroundColor: Colors.green,
          );
          WidgetSafetyUtils.safePop(context, widget.music);
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'خطا در حذف موزیک',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: Colors.red,
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
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasFile
              ? AppTheme.goldColor
              : AppTheme.goldColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (hasFile)
                  Text(
                    _selectedAudio != null
                        ? 'فایل انتخاب شده: ${_selectedAudio!.path.split('/').last}'
                        : 'آپلود شده ✓',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      color: AppTheme.goldColor,
                    ),
                  ),
              ],
            ),
          ),
          if (hasFile)
            IconButton(
              icon: Icon(LucideIcons.trash2, color: Colors.red),
              onPressed: onRemove,
            ),
          TextButton.icon(
            onPressed: onPick,
            icon: Icon(LucideIcons.upload, size: 18.sp),
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
  final void Function(String) onUrlEntered;

  const _AudioUrlDialog({
    required this.onUrlEntered,
  });

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
      title: Text(
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

