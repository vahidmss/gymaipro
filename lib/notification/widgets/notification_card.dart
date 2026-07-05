import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification, super.key,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  final NotificationItem notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final Future<bool> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = !notification.isRead;
    final typeColor = _getNotificationColor(context, notification.type);

    final card = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? context.cardColor.withValues(alpha: 0.95)
                  : typeColor.withValues(alpha: 0.05))
              : context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isUnread
                ? typeColor.withValues(alpha: isDark ? 0.4 : 0.3)
                : (isDark
                    ? context.separatorColor
                    : context.separatorColor.withValues(alpha: 0.5)),
            width: isUnread ? 1.5.w : 1.w,
          ),
          boxShadow: [
            if (isUnread)
              BoxShadow(
                color: typeColor.withValues(alpha: 0.15),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 4.r,
              offset: Offset(0.w, 1.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: onTap,
            splashColor: typeColor.withValues(alpha: 0.1),
            highlightColor: typeColor.withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // Minimal icon indicator
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: typeColor,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: TextDirection.rtl,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                  color: context.textColor,
                                  fontSize: 13.sp,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            if (isUnread)
                              Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: typeColor.withValues(alpha: 0.5),
                                      blurRadius: 4.r,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          notification.message,
                          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                            color: context.textSecondary,
                            fontSize: 11.5.sp,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          textDirection: TextDirection.rtl,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 11.sp,
                              color: context.textSecondary.withValues(alpha: 0.7),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              notification.timeAgo,
                              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                color: context.textSecondary.withValues(alpha: 0.7),
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (notification.isHighPriority) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Icon(
                                      LucideIcons.alertCircle,
                                      size: 10.sp,
                                      color: AppTheme.errorColor,
                                    ),
                                    SizedBox(width: 3.w),
                                    Text(
                                      'مهم',
                                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                                        color: AppTheme.errorColor,
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isUnread && onMarkAsRead != null) ...[
                    SizedBox(width: 8.w),
                    InkWell(
                      borderRadius: BorderRadius.circular(999.r),
                      onTap: onMarkAsRead,
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: typeColor.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          LucideIcons.check,
                          size: 14.sp,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ],
                  if (!WebInteraction.allowSwipeToDismiss &&
                      onDelete != null) ...[
                    SizedBox(width: 8.w),
                    InkWell(
                      borderRadius: BorderRadius.circular(999.r),
                      onTap: () async {
                        final confirmed = await _showDeleteConfirmation(context);
                        if (confirmed) await onDelete!();
                      },
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.errorColor.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 14.sp,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

    if (!WebInteraction.allowSwipeToDismiss) {
      return card;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Icon(
          LucideIcons.trash2,
          color: AppTheme.errorColor,
          size: 20.sp,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: AppTheme.goldColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Icon(
          LucideIcons.check,
          color: AppTheme.goldColor,
          size: 20.sp,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!notification.isRead) {
            onMarkAsRead?.call();
          }
          return false;
        }
        final confirmed = await _showDeleteConfirmation(context);
        if (!confirmed) return false;
        if (onDelete != null) {
          return onDelete!();
        }
        return false;
      },
      onDismissed: (_) {},
      child: card,
    );
  }

  Color _getNotificationColor(BuildContext context, NotificationType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case NotificationType.welcome:
        return AppTheme.goldColor;
      case NotificationType.workout:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case NotificationType.reminder:
        return isDark ? const Color(0xFFFF9800) : const Color(0xFFF57C00);
      case NotificationType.achievement:
        return isDark ? const Color(0xFF9C27B0) : const Color(0xFF7B1FA2);
      case NotificationType.message:
        return isDark ? const Color(0xFF2196F3) : const Color(0xFF1976D2);
      case NotificationType.payment:
        return isDark ? const Color(0xFFFFC107) : const Color(0xFFF9A825);
      case NotificationType.system:
        return isDark
            ? AppTheme.darkTextColor.withValues(alpha: 0.6)
            : context.textSecondary;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return LucideIcons.userPlus;
      case NotificationType.workout:
        return LucideIcons.dumbbell;
      case NotificationType.reminder:
        return LucideIcons.clock;
      case NotificationType.achievement:
        return LucideIcons.trophy;
      case NotificationType.message:
        return LucideIcons.messageCircle;
      case NotificationType.payment:
        return LucideIcons.creditCard;
      case NotificationType.system:
        return LucideIcons.settings;
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        title: Text(
          'حذف اعلان',
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این اعلان را حذف کنید؟',
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
            fontSize: 13.sp,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'انصراف',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}
