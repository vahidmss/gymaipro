import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    required this.avatarUrl,
    super.key,
    this.size = 56,
    this.isOnline = false,
    this.role = 'athlete',
    this.showOnlineStatus = true,
  });

  final String? avatarUrl;
  final double size;
  final bool isOnline;
  final String role;
  final bool showOnlineStatus;

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(role);
    final icon = _getAvatarIcon(role);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size.w,
          height: size.h,
          decoration: BoxDecoration(
            color: avatarColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular((size / 2).r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular((size / 2).r),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl!,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    placeholderFadeInDuration: Duration.zero,
                    errorWidget: (context, url, error) =>
                        Icon(icon, color: avatarColor, size: (size / 2).sp),
                  )
                : Icon(icon, color: avatarColor, size: (size / 2).sp),
          ),
        ),
        if (showOnlineStatus && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: (size * 0.3).w,
              height: (size * 0.3).h,
              decoration: BoxDecoration(
                color: AppTheme.goldColor,
                borderRadius: BorderRadius.circular((size * 0.15).r),
                border: Border.all(color: AppTheme.backgroundColor, width: 2.w),
              ),
            ),
          ),
      ],
    );
  }

  Color _getAvatarColor(String role) {
    switch (role.toLowerCase()) {
      case 'trainer':
        return AppTheme.goldColor;
      case 'athlete':
        return AppTheme.primaryColor;
      case 'admin':
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getAvatarIcon(String role) {
    switch (role.toLowerCase()) {
      case 'trainer':
        return LucideIcons.userCheck;
      case 'athlete':
        return LucideIcons.user;
      case 'admin':
        return LucideIcons.shield;
      default:
        return LucideIcons.user;
    }
  }
}
