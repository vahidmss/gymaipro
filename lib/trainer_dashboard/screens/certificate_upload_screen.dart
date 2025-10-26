import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CertificateUploadScreen extends StatefulWidget {
  const CertificateUploadScreen({super.key});

  @override
  State<CertificateUploadScreen> createState() =>
      _CertificateUploadScreenState();
}

class _CertificateUploadScreenState extends State<CertificateUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  CertificateType _selectedType = CertificateType.coaching;
  File? _selectedImage;
  bool _isLoading = false;

  final List<CertificateType> _certificateTypes = CertificateType.values;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً تصویر مدرک را انتخاب کنید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('کاربر وارد نشده است');

      // آپلود تصویر
      final fileName =
          '${user.id}/certificate_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await _selectedImage!.readAsBytes();

      // آپلود با تنظیمات ساده
      await Supabase.instance.client.storage
          .from('coach_certificates')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('coach_certificates')
          .getPublicUrl(fileName);

      // ذخیره اطلاعات مدرک در دیتابیس
      await CertificateService.uploadCertificate(
        title: _titleController.text.trim(),
        type: _selectedType,
        imageUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مدرک با موفقیت آپلود شد و در انتظار تایید است'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در آپلود مدرک: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'آپلود مدرک',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // انتخاب نوع مدرک
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // عنوان مدرک
              _buildTextField(
                controller: _titleController,
                label: 'عنوان مدرک',
                hint: 'مثال: گواهینامه مربیگری بدنسازی',
                icon: LucideIcons.award,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'عنوان مدرک الزامی است' : null,
              ),
              const SizedBox(height: 20),

              // انتخاب تصویر
              _buildImageSelector(),
              const SizedBox(height: 24),

              // دکمه آپلود
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadCertificate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Icon(LucideIcons.upload),
                  label: Text(_isLoading ? 'در حال آپلود...' : 'آپلود مدرک'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع مدرک',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _certificateTypes.map((type) {
            final isSelected = _selectedType == type;
            return InkWell(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.goldColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.goldColor
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == CertificateType.coaching
                          ? Icons.sports_martial_arts
                          : type == CertificateType.championship
                          ? Icons.emoji_events
                          : type == CertificateType.education
                          ? Icons.school
                          : type == CertificateType.specialization
                          ? Icons.psychology
                          : type == CertificateType.achievement
                          ? Icons.star
                          : Icons.card_membership,
                      color: isSelected ? Colors.black : AppTheme.goldColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      type == CertificateType.coaching
                          ? 'مربیگری'
                          : type == CertificateType.championship
                          ? 'قهرمانی'
                          : type == CertificateType.education
                          ? 'تحصیلات'
                          : type == CertificateType.specialization
                          ? 'تخصص'
                          : type == CertificateType.achievement
                          ? 'دستاورد'
                          : 'سایر',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppTheme.goldColor, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppTheme.goldColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تصویر مدرک',
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _selectedImage != null
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.image,
                        color: AppTheme.goldColor,
                        size: 48.sp,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'تصویر مدرک را انتخاب کنید',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'فرمت‌های پشتیبانی شده: JPG, PNG',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.checkCircle, color: Colors.green, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'تصویر انتخاب شده',
                style: GoogleFonts.vazirmatn(
                  color: Colors.green,
                  fontSize: 12.sp,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selectedImage = null),
                child: Text(
                  'حذف',
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
