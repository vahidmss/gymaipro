import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileImageWidgets {
  static Widget buildImageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppTheme.goldColor, size: 32.sp),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget buildDefaultAvatar() {
    return Builder(
      builder: (context) {
        return Container(
          width: 130.w,
          height: 130.h,
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.user,
                size: 48.sp,
                color: AppTheme.goldColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              Text(
                'تصویر پروفایل',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor.withValues(alpha: 0.6),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> pickImageFromSource(
    ImageSource source,
    BuildContext context,
    void Function(File) onImageSelected,
  ) async {
    Navigator.pop(context); // بستن bottom sheet

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (image != null) {
        // Crop the image
        // Crop the image to circle
        final croppedFile = await _cropImage(image.path, context);

        if (croppedFile != null) {
          onImageSelected(File(croppedFile.path));

          // Auto-save در صفحه پروفایل انجام می‌شود؛ اینجا پیام راهنما لازم نیست
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در انتخاب تصویر: $e',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
              ),
            ),
            backgroundColor: context.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        );
      }
    }
  }

  static Future<CroppedFile?> _cropImage(
    String imagePath,
    BuildContext context,
  ) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        maxWidth: 1024,
        maxHeight: 1024,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'برش تصویر پروفایل',
            toolbarColor: const Color(0xFF000000),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            backgroundColor: const Color(0xFF000000),
            activeControlsWidgetColor: const Color(0xFFD4AF37),
            // تنظیمات برای ظاهر دایره‌ای مثل اینستاگرام
            cropFrameColor: const Color(0xFFD4AF37),
            dimmedLayerColor: const Color(0xFF000000).withValues(alpha: 0.1),
            statusBarColor: const Color(0xFF000000),
            // شکل دایره‌ای
            cropStyle: CropStyle.circle,
            cropFrameStrokeWidth: 2,
            showCropGrid: false, // حذف grid برای ظاهر تمیزتر
            lockAspectRatio: true,
            hideBottomControls: true, // حذف کنترل‌های پایین
            initAspectRatio: CropAspectRatioPreset.square,
          ),
          IOSUiSettings(
            title: 'برش تصویر پروفایل',
            doneButtonTitle: 'تایید',
            cancelButtonTitle: 'انصراف',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            hidesNavigationBar: false,
          ),
          WebUiSettings(context: context),
        ],
      );

      return croppedFile;
    } catch (e) {
      debugPrint('خطا در برش تصویر: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در برش تصویر: $e',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
              ),
            ),
            backgroundColor: context.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.errorColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        );
      }
      return null;
    }
  }

  static void showImagePickerBottomSheet(
    BuildContext context,
    void Function(ImageSource) onSourceSelected,
    VoidCallback onRemoveImage,
    bool hasImage,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'انتخاب تصویر پروفایل',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: buildImageOption(
                      icon: LucideIcons.camera,
                      title: 'دوربین',
                      onTap: () => onSourceSelected(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildImageOption(
                      icon: LucideIcons.image,
                      title: 'گالری',
                      onTap: () => onSourceSelected(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (hasImage) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRemoveImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: const Icon(LucideIcons.trash2),
                    label: Text(
                      'حذف تصویر',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static void showRemoveImageDialog(
    BuildContext context,
    VoidCallback onConfirmRemove,
  ) {
    // بستن bottom sheet
    Navigator.pop(context);

    // نمایش دیالوگ تایید
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(
                alpha: isDark ? 0.3 : 0.5,
              ),
              width: 1.5,
            ),
          ),
          title: Text(
            'حذف تصویر پروفایل',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'آیا مطمئن هستید که می‌خواهید تصویر پروفایل را حذف کنید؟',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'انصراف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // بستن دیالوگ
                Navigator.pop(dialogContext);
                // اجرای callback
                onConfirmRemove();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'حذف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
