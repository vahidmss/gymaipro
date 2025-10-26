import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/chat/widgets/online_status_widget.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBarWidget({
    required this.otherUserName,
    required this.otherUserRole,
    required this.otherUserAvatar,
    required this.isOtherUserOnline,
    required this.otherUserLastSeen,
    required this.onBackPressed,
    this.onPhonePressed,
    this.onVideoPressed,
    this.onMorePressed,
    super.key,
  });

  final String otherUserName;
  final String? otherUserRole;
  final String? otherUserAvatar;
  final bool isOtherUserOnline;
  final DateTime? otherUserLastSeen;
  final VoidCallback onBackPressed;
  final VoidCallback? onPhonePressed;
  final VoidCallback? onVideoPressed;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.cardColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowRight, color: AppTheme.textColor),
        onPressed: onBackPressed,
      ),
      title: Row(
        children: [
          UserAvatarWidget(
            avatarUrl: otherUserAvatar,
            size: 40,
            role: otherUserRole ?? 'athlete',
            showOnlineStatus: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUserName,
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (otherUserRole != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: otherUserRole == 'trainer'
                              ? AppTheme.goldColor.withValues(alpha: 0.2)
                              : AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          otherUserRole == 'trainer' ? 'مربی' : 'کاربر',
                          style: TextStyle(
                            color: otherUserRole == 'trainer'
                                ? AppTheme.goldColor
                                : AppTheme.primaryColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: isOtherUserOnline
                            ? AppTheme.goldColor
                            : AppTheme.bodyStyle.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    OnlineStatusWidget(
                      isOnline: isOtherUserOnline,
                      lastSeen: otherUserLastSeen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onPhonePressed != null)
          IconButton(
            icon: const Icon(LucideIcons.phone, color: AppTheme.textColor),
            onPressed: onPhonePressed,
          ),
        if (onVideoPressed != null)
          IconButton(
            icon: const Icon(LucideIcons.video, color: AppTheme.textColor),
            onPressed: onVideoPressed,
          ),
        if (onMorePressed != null)
          IconButton(
            icon: const Icon(
              LucideIcons.moreVertical,
              color: AppTheme.textColor,
            ),
            onPressed: onMorePressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
