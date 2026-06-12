import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:gymaipro/trainer_ranking/services/certificate_service.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  bool _isUploading = false;

  static const _typeMeta = <CertificateType, ({String label, IconData icon})>{
    CertificateType.coaching: (label: 'مربیگری', icon: LucideIcons.dumbbell),
    CertificateType.championship: (label: 'قهرمانی', icon: LucideIcons.trophy),
    CertificateType.education: (label: 'تحصیلات', icon: LucideIcons.graduationCap),
    CertificateType.specialization: (label: 'تخصص', icon: LucideIcons.brain),
    CertificateType.achievement: (label: 'دستاورد', icon: LucideIcons.star),
    CertificateType.other: (label: 'سایر', icon: LucideIcons.fileBadge),
  };

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

    if (pickedFile != null && mounted) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _showFeedback({
    required String message,
    required bool isSuccess,
    String? subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isSuccess ? AppTheme.successColor : AppTheme.errorColor;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          padding: EdgeInsets.zero,
          duration: Duration(seconds: isSuccess ? 3 : 4),
          content: DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.45 : 0.35),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(
                    isSuccess ? LucideIcons.check : LucideIcons.alertCircle,
                    color: accent,
                    size: 22.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12.sp,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Future<void> _uploadCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      _showFeedback(
        message: 'تصویر مدرک انتخاب نشده',
        subtitle: 'لطفاً یک تصویر از مدرک خود انتخاب کنید',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('کاربر وارد نشده است');

      final fileName =
          '${user.id}/certificate_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await _selectedImage!.readAsBytes();

      await Supabase.instance.client.storage.from('coach_certificates').uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final imageUrl = Supabase.instance.client.storage
          .from('coach_certificates')
          .getPublicUrl(fileName);

      await CertificateService.uploadCertificate(
        title: _titleController.text.trim(),
        type: _selectedType,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      _showFeedback(
        message: 'مدرک با موفقیت آپلود شد',
        subtitle: 'پس از بررسی در پروفایل شما نمایش داده می‌شود',
        isSuccess: true,
      );
      WidgetSafetyUtils.safePop(context);
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        message: 'آپلود ناموفق بود',
        subtitle: 'لطفاً دوباره تلاش کنید',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.headerBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'آپلود مدرک',
          style: context.headerTitleStyle(fontSize: 18.sp),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            LucideIcons.arrowRight,
            color: context.textColor,
            size: 22.sp,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.separatorColor),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isUploading,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(isDark),
                SizedBox(height: 20.h),
                _buildSectionTitle('نوع مدرک'),
                SizedBox(height: 10.h),
                _buildTypeSelector(isDark),
                SizedBox(height: 20.h),
                _buildSectionTitle('عنوان مدرک'),
                SizedBox(height: 10.h),
                _buildTitleField(isDark),
                SizedBox(height: 20.h),
                _buildSectionTitle('تصویر مدرک'),
                SizedBox(height: 10.h),
                _buildImageSelector(isDark),
                SizedBox(height: 28.h),
                _buildUploadButton(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            color: AppTheme.goldColor,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'مدرک پس از بررسی در پروفایل عمومی شما نمایش داده می‌شود. تصویر باید خوانا و کامل باشد.',
              style: TextStyle(
                color: context.textColor,
                fontSize: 12.5.sp,
                height: 1.5,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.textColor,
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        fontFamily: AppTheme.fontFamily,
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: CertificateType.values.map((type) {
        final meta = _typeMeta[type]!;
        final isSelected = _selectedType == type;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedType = type),
            borderRadius: BorderRadius.circular(12.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.goldColor
                    : (isDark
                        ? context.cardColor
                        : context.cardColor),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor
                      : (isDark
                          ? context.separatorColor
                          : AppTheme.goldColor.withValues(alpha: 0.25)),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    meta.icon,
                    size: 16.sp,
                    color: isSelected
                        ? AppTheme.onGoldColor
                        : AppTheme.goldColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    meta.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.onGoldColor
                          : context.textColor,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTitleField(bool isDark) {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(
        color: context.textColor,
        fontSize: 14.sp,
        fontFamily: AppTheme.fontFamily,
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'عنوان مدرک الزامی است' : null,
      decoration: InputDecoration(
        hintText: 'مثال: گواهینامه مربیگری بدنسازی',
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: TextStyle(
          color: context.textSecondary.withValues(alpha: 0.8),
          fontSize: 13.sp,
          fontFamily: AppTheme.fontFamily,
        ),
        prefixIcon: Icon(
          LucideIcons.award,
          color: AppTheme.goldColor,
          size: 20.sp,
        ),
        filled: true,
        fillColor: context.cardColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: isDark
                ? context.separatorColor
                : AppTheme.goldColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: AppTheme.errorColor.withValues(alpha: 0.6),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      ),
    );
  }

  Widget _buildImageSelector(bool isDark) {
    final hasImage = _selectedImage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              width: double.infinity,
              height: 200.h,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: hasImage
                      ? AppTheme.goldColor
                      : (isDark
                          ? context.separatorColor
                          : AppTheme.goldColor.withValues(alpha: 0.25)),
                  width: hasImage ? 2 : 1.5,
                ),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56.w,
                          height: 56.w,
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.15 : 0.12,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.imagePlus,
                            color: AppTheme.goldColor,
                            size: 28.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'انتخاب تصویر مدرک',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'JPG یا PNG — حداکثر ۱۹۲۰×۱۰۸۰',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (hasImage) ...[
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                LucideIcons.checkCircle2,
                color: AppTheme.successColor,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'تصویر انتخاب شد',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedImage = null),
                icon: Icon(
                  LucideIcons.trash2,
                  size: 16.sp,
                  color: AppTheme.errorColor,
                ),
                label: Text(
                  'حذف',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUploadButton(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _isUploading
            ? LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.5),
                  AppTheme.darkGold.withValues(alpha: 0.5),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: _isUploading
            ? null
            : [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.25),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploading ? null : _uploadCertificate,
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            width: double.infinity,
            height: 52.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isUploading) ...[
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.onGoldColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'در حال آپلود...',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onGoldColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ] else ...[
                  Icon(
                    LucideIcons.upload,
                    size: 20.sp,
                    color: AppTheme.onGoldColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'آپلود مدرک',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onGoldColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
