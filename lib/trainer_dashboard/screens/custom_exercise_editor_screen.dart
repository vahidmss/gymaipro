import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحه ساخت/ویرایش تمرین اختصاصی
class CustomExerciseEditorScreen extends StatefulWidget {
  final CustomExercise? exercise;

  const CustomExerciseEditorScreen({super.key, this.exercise});

  @override
  State<CustomExerciseEditorScreen> createState() =>
      _CustomExerciseEditorScreenState();
}

class _CustomExerciseEditorScreenState
    extends State<CustomExerciseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomExerciseService();
  final _picker = ImagePicker();

  // Controllers
  final _titleController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailedDescriptionController = TextEditingController();
  final _secondaryMusclesController = TextEditingController();
  final _tipsControllers = <TextEditingController>[];

  // State
  String _mainMuscle = 'سینه';
  String _difficulty = 'متوسط';
  String _equipment = 'بدون تجهیزات';
  String _exerciseType = 'قدرتی';
  String _visibility = 'private';
  bool _sharedWithClients = true;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  XFile? _selectedVideo;
  XFile? _selectedImage;
  String? _uploadedVideoUrl;
  String? _uploadedImageUrl;

  // Lists
  final List<String> _muscleGroups = [
    'سینه',
    'پشت',
    'شانه',
    'پا',
    'بازو',
    'شکم',
    'سرینی',
    'ساعد',
    'کاردیو',
    'کل بدن',
  ];

  final List<String> _difficulties = ['آسان', 'متوسط', 'سخت', 'حرفه‌ای'];
  final List<String> _equipments = [
    'بدون تجهیزات',
    'هالتر',
    'دمبل',
    'دستگاه',
    'کابل',
    'کتل‌بل',
    'کش',
  ];

  final List<String> _exerciseTypes = [
    'قدرتی',
    'کاردیو',
    'کششی',
    'تعادلی',
    'انعطاف‌پذیری',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.exercise != null) {
      final ex = widget.exercise!;
      _titleController.text = ex.title;
      _nameController.text = ex.name;
      _descriptionController.text = ex.description ?? '';
      _detailedDescriptionController.text = ex.detailedDescription ?? '';
      _secondaryMusclesController.text = ex.secondaryMuscles;
      _mainMuscle = ex.mainMuscle;
      _difficulty = ex.difficulty;
      _equipment = ex.equipment;
      _exerciseType = ex.exerciseType;
      _visibility = ex.visibility;
      _sharedWithClients = ex.sharedWithClients;
      _uploadedVideoUrl = ex.videoUrl;
      _uploadedImageUrl = ex.imageUrl;

      // Tips
      _tipsControllers.clear();
      for (final tip in ex.tips) {
        _tipsControllers.add(TextEditingController(text: tip));
      }
      if (_tipsControllers.isEmpty) {
        _tipsControllers.add(TextEditingController());
      }
    } else {
      _tipsControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _detailedDescriptionController.dispose();
    _secondaryMusclesController.dispose();
    for (final controller in _tipsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.exercise == null ? 'تمرین جدید' : 'ویرایش تمرین',
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
                  CircularProgressIndicator(
                    value: _uploadProgress,
                    color: AppTheme.goldColor,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'در حال آپلود... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // اطلاعات اصلی
                    _buildSectionTitle('اطلاعات اصلی', isDark),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _titleController,
                      label: 'عنوان تمرین',
                      hint: 'مثال: پرس سینه با هالتر',
                      icon: LucideIcons.type,
                      isDark: isDark,
                      validator: (v) => v?.isEmpty ?? true ? 'عنوان الزامی است' : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _nameController,
                      label: 'نام تمرین',
                      hint: 'مثال: Bench Press',
                      icon: LucideIcons.tag,
                      isDark: isDark,
                      validator: (v) => v?.isEmpty ?? true ? 'نام الزامی است' : null,
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('جزئیات تمرین', isDark),
                    SizedBox(height: 12.h),

                    // عضله اصلی
                    _buildDropdown(
                      label: 'عضله اصلی',
                      value: _mainMuscle,
                      items: _muscleGroups,
                      icon: LucideIcons.target,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _mainMuscle = v!),
                    ),
                    SizedBox(height: 12.h),

                    // عضلات فرعی
                    _buildTextField(
                      controller: _secondaryMusclesController,
                      label: 'عضلات فرعی (با کاما جدا کنید)',
                      hint: 'مثال: سرشانه، پشت بازو',
                      icon: LucideIcons.activity,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12.h),

                    // سطح دشواری
                    _buildDropdown(
                      label: 'سطح دشواری',
                      value: _difficulty,
                      items: _difficulties,
                      icon: LucideIcons.gauge,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                    SizedBox(height: 12.h),

                    // تجهیزات
                    _buildDropdown(
                      label: 'تجهیزات',
                      value: _equipment,
                      items: _equipments,
                      icon: LucideIcons.dumbbell,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _equipment = v!),
                    ),
                    SizedBox(height: 12.h),

                    // نوع تمرین
                    _buildDropdown(
                      label: 'نوع تمرین',
                      value: _exerciseType,
                      items: _exerciseTypes,
                      icon: LucideIcons.layers,
                      isDark: isDark,
                      onChanged: (v) => setState(() => _exerciseType = v!),
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('توضیحات', isDark),
                    SizedBox(height: 12.h),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'توضیحات کوتاه',
                      hint: 'توضیح مختصر درباره تمرین',
                      icon: LucideIcons.fileText,
                      isDark: isDark,
                      maxLines: 3,
                    ),
                    SizedBox(height: 12.h),

                    _buildTextField(
                      controller: _detailedDescriptionController,
                      label: 'توضیحات تکمیلی',
                      hint: 'توضیحات کامل و جزئیات تمرین',
                      icon: LucideIcons.bookOpen,
                      isDark: isDark,
                      maxLines: 5,
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('نکات تمرین', isDark),
                    SizedBox(height: 12.h),

                    ...List.generate(_tipsControllers.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _tipsControllers[index],
                                label: 'نکته ${index + 1}',
                                hint: 'نکته مهم درباره تمرین',
                                icon: LucideIcons.lightbulb,
                                isDark: isDark,
                              ),
                            ),
                            if (_tipsControllers.length > 1)
                              IconButton(
                                icon: Icon(
                                  LucideIcons.trash2,
                                  color: Colors.red,
                                  size: 20.sp,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _tipsControllers[index].dispose();
                                    _tipsControllers.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),

                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _tipsControllers.add(TextEditingController());
                        });
                      },
                      icon: Icon(LucideIcons.plus, size: 18.sp),
                      label: const Text('افزودن نکته'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.goldColor,
                      ),
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('رسانه', isDark),
                    SizedBox(height: 12.h),

                    // ویدیو
                    _buildMediaSelector(
                      label: 'ویدیو تمرین',
                      icon: LucideIcons.video,
                      isDark: isDark,
                      hasFile: _selectedVideo != null || _uploadedVideoUrl != null,
                      onPick: _pickVideo,
                      onRemove: () {
                        setState(() {
                          _selectedVideo = null;
                          _uploadedVideoUrl = null;
                        });
                      },
                    ),
                    SizedBox(height: 12.h),

                    // تصویر
                    _buildMediaSelector(
                      label: 'تصویر تمرین',
                      icon: LucideIcons.image,
                      isDark: isDark,
                      hasFile: _selectedImage != null || _uploadedImageUrl != null,
                      onPick: _pickImage,
                      onRemove: () {
                        setState(() {
                          _selectedImage = null;
                          _uploadedImageUrl = null;
                        });
                      },
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('تنظیمات دسترسی', isDark),
                    SizedBox(height: 12.h),

                    // Visibility
                    _buildRadioGroup(
                      label: 'دسترسی',
                      value: _visibility,
                      options: [
                        {'value': 'private', 'label': 'خصوصی (فقط من و شاگردانم)'},
                        {'value': 'public', 'label': 'عمومی (در دسترس همه)'},
                      ],
                      isDark: isDark,
                      onChanged: (v) => setState(() => _visibility = v),
                    ),
                    SizedBox(height: 12.h),

                    // Shared with clients
                    if (_visibility == 'private')
                      SwitchListTile(
                        title: const Text('اشتراک با شاگردان'),
                        subtitle: const Text('شاگردان می‌توانند این تمرین را ببینند'),
                        value: _sharedWithClients,
                        onChanged: (v) => setState(() => _sharedWithClients = v),
                        activeColor: AppTheme.goldColor,
                      ),

                    SizedBox(height: 32.h),

                    // دکمه‌های ذخیره و حذف
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveExercise,
                      icon: Icon(
                        widget.exercise == null
                            ? LucideIcons.plus
                            : LucideIcons.save,
                        size: 20.sp,
                      ),
                      label: Text(
                        widget.exercise == null ? 'ساخت تمرین' : 'ذخیره تغییرات',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),

                    if (widget.exercise != null) ...[
                      SizedBox(height: 12.h),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _deleteExercise,
                        icon: Icon(LucideIcons.trash2, size: 20.sp),
                        label: const Text('حذف تمرین'),
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
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppTheme.goldColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.goldColor),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppTheme.goldColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.goldColor),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
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
                    'فایل انتخاب شده',
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

  Widget _buildRadioGroup({
    required String label,
    required String value,
    required List<Map<String, String>> options,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
        ),
      ),
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
          SizedBox(height: 12.h),
          ...options.map((option) {
            return RadioListTile<String>(
              title: Text(option['label']!),
              value: option['value']!,
              groupValue: value,
              onChanged: (v) => onChanged(v!),
              activeColor: AppTheme.goldColor,
            );
          }),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        WidgetSafetyUtils.safeSetState(this, () {
          _selectedVideo = video;
          _uploadedVideoUrl = null;
        });
      }
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در انتخاب ویدیو: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        WidgetSafetyUtils.safeSetState(this, () {
          _selectedImage = image;
          _uploadedImageUrl = null;
        });
      }
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در انتخاب تصویر: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);

    try {
      // آپلود ویدیو
      String? videoUrl = _uploadedVideoUrl;
      if (_selectedVideo != null) {
        videoUrl = await _service.uploadVideo(
          _selectedVideo!,
          onProgress: (progress) {
            WidgetSafetyUtils.safeSetState(this, () => _uploadProgress = progress);
          },
        );
      }

      // آپلود تصویر (به Supabase Storage)
      String? imageUrl = _uploadedImageUrl;
      if (_selectedImage != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final fileName =
              '${user.id}/exercise_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final fileBytes = await _selectedImage!.readAsBytes();

          await Supabase.instance.client.storage
              .from('exercise_images')
              .uploadBinary(
                fileName,
                fileBytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );

          imageUrl = Supabase.instance.client.storage
              .from('exercise_images')
              .getPublicUrl(fileName);
        }
      }

      // جمع‌آوری نکات
      final tips = _tipsControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      CustomExercise? result;

      if (widget.exercise == null) {
        // ساخت جدید
        result = await _service.createExercise(
          title: _titleController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          detailedDescription:
              _detailedDescriptionController.text.trim().isEmpty
                  ? null
                  : _detailedDescriptionController.text.trim(),
          mainMuscle: _mainMuscle,
          secondaryMuscles: _secondaryMusclesController.text.trim(),
          difficulty: _difficulty,
          equipment: _equipment,
          exerciseType: _exerciseType,
          videoUrl: videoUrl,
          imageUrl: imageUrl,
          tips: tips,
          visibility: _visibility,
          sharedWithClients: _sharedWithClients,
        );
      } else {
        // ویرایش
        result = await _service.updateExercise(
          widget.exercise!.id,
          title: _titleController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          detailedDescription:
              _detailedDescriptionController.text.trim().isEmpty
                  ? null
                  : _detailedDescriptionController.text.trim(),
          mainMuscle: _mainMuscle,
          secondaryMuscles: _secondaryMusclesController.text.trim(),
          difficulty: _difficulty,
          equipment: _equipment,
          exerciseType: _exerciseType,
          videoUrl: videoUrl,
          imageUrl: imageUrl,
          tips: tips,
          visibility: _visibility,
          sharedWithClients: _sharedWithClients,
        );
      }

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          widget.exercise == null
              ? 'تمرین با موفقیت ساخته شد'
              : 'تمرین با موفقیت به‌روزرسانی شد',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context, result);
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
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _deleteExercise() async {
    if (widget.exercise == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف تمرین'),
        content: const Text('آیا از حذف این تمرین اطمینان دارید؟'),
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
      final success = await _service.deleteExercise(widget.exercise!.id);
      if (mounted) {
        if (success) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'تمرین با موفقیت حذف شد',
            backgroundColor: Colors.green,
          );
          Navigator.pop(context, widget.exercise);
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'خطا در حذف تمرین',
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
}

