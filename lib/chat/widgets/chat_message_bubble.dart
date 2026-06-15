import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.isMe,
    super.key,
    this.onLongPress,
  });
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdminWarning = message.messageType == 'admin_warning';

    // اگر پیام هشدار ادمین است، آن را در وسط نمایش بده
    if (isAdminWarning) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50.withValues(alpha: isDark ? 0.2 : 1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.orange,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0.w, 2.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // آیکون و عنوان ادمین
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        LucideIcons.shield,
                        color: Colors.orange.shade700,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'پیام مدیریتی',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: Colors.orange.shade700,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // محتوای پیام
                  Text(
                    message.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // زمان
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.orange.shade600.withValues(alpha: 0.7),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // پیام‌های عادی
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 50.w : 0,
        right: isMe ? 0 : 50.w,
        bottom: 8.h,
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMe
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            // پیام
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? LinearGradient(colors: context.goldGradientColors)
                          : null,
                      color: isMe ? null : context.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                        bottomLeft: Radius.circular(isMe ? 20.r : 4.r),
                        bottomRight: Radius.circular(isMe ? 4.r : 20.r),
                      ),
                      border: isMe
                          ? null
                          : Border.all(
                              color: AppTheme.goldColor.withValues(
                                alpha: isDark ? 0.2 : 0.3,
                              ),
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(
                            alpha: isDark ? 0.1 : 0.15,
                          ),
                          blurRadius: 6.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
                    ),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Message content
                          _buildMessageContent(context),

                          // Time and status (for both; icon only for sender)
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.end,
                            children: [_buildMessageFooter(context)],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case 'text':
        return Text(
          message.message,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isMe ? AppTheme.onGoldColor : context.textColor,
            fontSize: 14.sp,
          ),
        );
      case 'image':
        return _buildImageContent(context);
      case 'file':
        return _buildFileContent(context);
      case 'voice':
        return _buildVoiceContent(context);
      default:
        return Text(
          message.message,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isMe ? AppTheme.onGoldColor : context.textColor,
            fontSize: 14.sp,
          ),
        );
    }
  }

  Widget _buildImageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachmentUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.network(
              message.attachmentUrl!,
              width: 200.w,
              height: 150.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200.w,
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: context.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    LucideIcons.image,
                    color: context.textSecondary,
                    size: 40.sp,
                  ),
                );
              },
            ),
          ),
        if (message.message.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            message.message,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isMe ? AppTheme.onGoldColor : context.textColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.textSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.file, color: AppTheme.goldColor, size: 24.sp),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.attachmentName ?? 'فایل',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isMe ? AppTheme.onGoldColor : context.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message.attachmentSize != null)
                  Text(
                    _formatFileSize(message.attachmentSize!),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.textSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.play, color: AppTheme.goldColor, size: 24.sp),
          SizedBox(width: 8.w),
          Text(
            'پیام صوتی',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isMe ? AppTheme.onGoldColor : context.textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isMe
                ? AppTheme.onGoldColor.withValues(alpha: 0.8)
                : context.textSecondary,
            fontSize: 11.sp,
          ),
        ),
        if (isMe) ...[
          SizedBox(width: 4.w),
          Icon(
            message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
            color: message.isRead
                ? AppTheme.onGoldColor.withValues(alpha: 0.8)
                : AppTheme.onGoldColor.withValues(alpha: 0.6),
            size: 14.sp,
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    // همیشه فقط HH:mm نمایش بده و زمان را به لوکال دستگاه تبدیل کن
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
