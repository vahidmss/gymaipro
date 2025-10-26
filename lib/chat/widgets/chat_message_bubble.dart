import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 50 : 0,
        right: isMe ? 0 : 50,
        bottom: 8.h,
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Row(
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
                      color: isMe ? AppTheme.goldColor : AppTheme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.backgroundColor.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 4.r,
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
                          _buildMessageContent(),

                          // Time and status (for both; icon only for sender)
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.end,
                            children: [_buildMessageFooter()],
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

  Widget _buildMessageContent() {
    switch (message.messageType) {
      case 'text':
        return Text(
          message.message,
          style: TextStyle(color: AppTheme.textColor, fontSize: 14.sp),
        );
      case 'image':
        return _buildImageContent();
      case 'file':
        return _buildFileContent();
      case 'voice':
        return _buildVoiceContent();
      default:
        return Text(
          message.message,
          style: TextStyle(color: AppTheme.textColor, fontSize: 14.sp),
        );
    }
  }

  Widget _buildImageContent() {
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
                    color: (AppTheme.bodyStyle.color ?? AppTheme.textColor)
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    LucideIcons.image,
                    color: AppTheme.bodyStyle.color,
                    size: 40.sp,
                  ),
                );
              },
            ),
          ),
        if (message.message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.message,
            style: TextStyle(color: AppTheme.textColor, fontSize: 14.sp),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: (AppTheme.bodyStyle.color ?? AppTheme.textColor).withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.file, color: AppTheme.goldColor, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.attachmentName ?? 'فایل',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message.attachmentSize != null)
                  Text(
                    _formatFileSize(message.attachmentSize!),
                    style: TextStyle(
                      color: AppTheme.bodyStyle.color,
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

  Widget _buildVoiceContent() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: (AppTheme.bodyStyle.color ?? AppTheme.textColor).withValues(
          alpha: 0.2,
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.play, color: AppTheme.goldColor, size: 24),
          const SizedBox(width: 8),
          Text(
            'پیام صوتی',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            color: isMe
                ? AppTheme.textColor.withValues(alpha: 0.8)
                : AppTheme.bodyStyle.color,
            fontSize: 11.sp,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
            color: message.isRead
                ? AppTheme.textColor.withValues(alpha: 0.8)
                : AppTheme.bodyStyle.color,
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
