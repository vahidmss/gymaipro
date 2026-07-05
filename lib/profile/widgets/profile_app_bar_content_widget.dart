import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/widgets/profile_image_widgets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ویجت محتوای AppBar پروفایل
class ProfileAppBarContentWidget extends StatelessWidget {
  const ProfileAppBarContentWidget({
    required this.profileData,
    required this.avatarPreviewBytes,
    required this.isLoading,
    required this.isEditing,
    required this.onImageTap,
    super.key,
  });

  final Map<String, dynamic> profileData;
  final Uint8List? avatarPreviewBytes;
  final bool isLoading;
  final bool isEditing;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        avatarPreviewBytes != null ||
        (profileData.containsKey('avatar_url') &&
            profileData['avatar_url'] != null &&
            profileData['avatar_url'] is String &&
            (profileData['avatar_url'] as String).isNotEmpty);

    return Container(
      padding: EdgeInsets.only(top: 60.h, left: 20.w, right: 20.w, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: isEditing ? onImageTap : null,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withAlpha(50),
                        blurRadius: 15.r,
                        spreadRadius: 3.r,
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 8.r,
                        spreadRadius: 1.r,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? avatarPreviewBytes != null
                              ? Image.memory(
                                  avatarPreviewBytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ProfileImageWidgets.buildDefaultAvatar();
                                  },
                                )
                              : GymaiNetworkImage(
                                  imageUrl: profileData['avatar_url'] as String,
                                  errorWidget:
                                      ProfileImageWidgets.buildDefaultAvatar(),
                                )
                        : ProfileImageWidgets.buildDefaultAvatar(),
                  ),
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.backgroundColor.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                ),
              if (isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onImageTap,
                    child: Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.cardColor,
                          width: 2.5.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6.r,
                            offset: Offset(0.w, 2.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        color: AppTheme.onGoldColor,
                        size: 16.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'
                .trim(),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (profileData['username'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${profileData['username']}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}
