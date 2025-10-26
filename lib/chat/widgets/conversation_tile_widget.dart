import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ConversationTileWidget extends StatelessWidget {
  const ConversationTileWidget({
    required this.conversation,
    required this.currentUserId,
    required this.avatarUrl,
    required this.userRole,
    super.key,
    this.onTap,
    this.onLongPress,
  });

  final ChatConversation conversation;
  final String currentUserId;
  final String? avatarUrl;
  final String? userRole;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final otherUserName = conversation.getOtherUserName(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = conversation.hasUnreadForUser(currentUserId);
    final timeString = _formatLastMessageTime(conversation.lastMessageDateTime);

    return Column(
      key: ValueKey(conversation.id),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasUnread
                  ? AppTheme.goldColor.withValues(alpha: 0.3)
                  : AppTheme.backgroundColor,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.backgroundColor.withValues(alpha: 0.06),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Material(
            color: AppTheme.backgroundColor,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    // آواتار
                    UserAvatarWidget(
                      avatarUrl: avatarUrl,
                      role: userRole ?? 'athlete',
                    ),
                    const SizedBox(width: 16),

                    // محتوا
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
                                    color: hasUnread
                                        ? AppTheme.textColor
                                        : AppTheme.textColor.withValues(
                                            alpha: 0.9,
                                          ),
                                    fontSize: 16.sp,
                                    fontWeight: hasUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeString,
                                style: TextStyle(
                                  color: AppTheme.bodyStyle.color,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (userRole != null) ...[
                                UserRoleBadge(
                                  role: userRole!,
                                  fontSize: 10.sp,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  conversation.lastMessageText ?? 'بدون پیام',
                                  style: TextStyle(
                                    color: hasUnread
                                        ? AppTheme.textColor.withValues(
                                            alpha: 0.95,
                                          )
                                        : AppTheme.textColor.withValues(
                                            alpha: 0.65,
                                          ),
                                    fontSize: 13.sp,
                                    fontWeight: hasUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasUnread)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(
                                      color: AppTheme.textColor,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatLastMessageTime(DateTime dateTime) {
    // تبدیل تاریخ میلادی به شمسی و نمایش به صورت «روز ماه» مثل «20 مهر»
    final Jalali j = Jalali.fromDateTime(dateTime);
    final f = j.formatter;
    return '${f.d} ${f.mN}';
  }
}
