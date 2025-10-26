import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/profile/widgets/profile_image_widgets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({
    required this.profileData,
    required this.avatarFile,
    required this.isLoading,
    required this.isEditing,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onCancelPressed,
    required this.onImageTap,
    super.key,
  });
  final Map<String, dynamic> profileData;
  final File? avatarFile;
  final bool isLoading;
  final bool isEditing;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // تصویر پروفایل
        Stack(
          children: [
            GestureDetector(
              onTap: onImageTap,
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldColor, width: 3),
                ),
                child: ClipOval(
                  child: avatarFile != null
                      ? Image.file(
                          avatarFile!,
                          fit: BoxFit.cover,
                          width: 120.w,
                          height: 120.h,
                        )
                      : (profileData['avatar_url'] != null &&
                            profileData['avatar_url'].toString().isNotEmpty)
                      ? Image.network(
                          profileData['avatar_url'] as String,
                          fit: BoxFit.cover,
                          width: 120.w,
                          height: 120.h,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return ColoredBox(
                              color: const Color(0xFF2A2A2A),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return ProfileImageWidgets.buildDefaultAvatar();
                          },
                        )
                      : ProfileImageWidgets.buildDefaultAvatar(),
                ),
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // نام و نام خانوادگی
        Text(
          '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
              .trim(),
          style: GoogleFonts.vazirmatn(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),

        // نام کاربری
        if (profileData['username'] != null) ...[
          const SizedBox(height: 4),
          Text(
            '@${profileData['username']}',
            style: GoogleFonts.vazirmatn(color: Colors.grey, fontSize: 16),
          ),
        ],
        const SizedBox(height: 20),

        // دکمه‌های عملیات
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!isEditing) ...[
              ElevatedButton.icon(
                onPressed: onEditPressed,
                icon: const Icon(LucideIcons.edit),
                label: Text('ویرایش پروفایل', style: GoogleFonts.vazirmatn()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: onSavePressed,
                icon: const Icon(LucideIcons.save),
                label: Text('ذخیره', style: GoogleFonts.vazirmatn()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onCancelPressed,
                icon: const Icon(LucideIcons.x),
                label: Text('انصراف', style: GoogleFonts.vazirmatn()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
