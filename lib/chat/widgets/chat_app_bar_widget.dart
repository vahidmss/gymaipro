import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/widgets/online_status_widget.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
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
      backgroundColor: context.cardColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowRight, color: context.textColor),
        onPressed: onBackPressed,
      ),
      title: Row(
        textDirection: TextDirection.rtl,
        children: [
          UserAvatarWidget(
            avatarUrl: otherUserAvatar,
            size: 40,
            role: otherUserRole ?? 'athlete',
            showOnlineStatus: false,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        otherUserName,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (otherUserRole != null) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          // Use a gradient only for trainers (where we expect multiple colors),
                          // and fall back to a solid color for other roles to avoid
                          // the "colors list must have at least two colors" assertion.
                          gradient: otherUserRole == 'trainer'
                              ? LinearGradient(
                                  colors: context.goldGradientColors
                                      .map((c) => c.withValues(alpha: 0.2))
                                      .toList(),
                                )
                              : null,
                          color: otherUserRole == 'trainer'
                              ? null
                              : AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          otherUserRole == 'trainer' ? 'مربی' : 'کاربر',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
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
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: isOtherUserOnline
                            ? AppTheme.goldColor
                            : context.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
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
            icon: Icon(LucideIcons.phone, color: context.textColor),
            onPressed: onPhonePressed,
          ),
        if (onVideoPressed != null)
          IconButton(
            icon: Icon(LucideIcons.video, color: context.textColor),
            onPressed: onVideoPressed,
          ),
        if (onMorePressed != null)
          IconButton(
            icon: Icon(LucideIcons.moreVertical, color: context.textColor),
            onPressed: onMorePressed,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
