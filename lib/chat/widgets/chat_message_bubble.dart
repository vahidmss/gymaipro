import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/models/message_send_status.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/utils/chat_attachment_actions.dart';
import 'package:gymaipro/chat/widgets/chat_voice_message.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.isMe,
    super.key,
    this.onLongPress,
    this.sendStatus,
    this.onRetryFailed,
    this.isGrouped = false,
  });
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final MessageSendStatus? sendStatus;
  final VoidCallback? onRetryFailed;
  final bool isGrouped;

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

    // پیام‌های عادی — Align + maxWidth (بدون IntrinsicWidth که overflow می‌دهد)
    final maxBubble = MediaQuery.sizeOf(context).width * 0.78;
    final isMediaBubble = message.isVoice ||
        message.isImage ||
        message.isFile ||
        message.messageType == 'video';

    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 56.w : 0,
        right: isMe ? 0 : 56.w,
        bottom: isGrouped ? 2.h : 6.h,
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubble),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                message.isImage
                    ? 3.w
                    : (message.isVoice || message.isFile ? 8.w : 12.w),
                message.isImage
                    ? 3.h
                    : (message.isVoice ? 6.h : 8.h),
                message.isImage
                    ? 3.w
                    : (message.isVoice || message.isFile ? 8.w : 12.w),
                message.isImage
                    ? 4.h
                    : (message.isVoice ? 4.h : 6.h),
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(colors: context.goldGradientColors)
                    : null,
                color: isMe ? null : context.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(
                    isMe ? 16.r : (isGrouped ? 16.r : 4.r),
                  ),
                  bottomRight: Radius.circular(
                    isMe ? (isGrouped ? 16.r : 4.r) : 16.r,
                  ),
                ),
                border: isMe
                    ? null
                    : Border.all(
                        color: AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.16 : 0.22,
                        ),
                      ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isMediaBubble
                          ? SizedBox(
                              width: constraints.maxWidth,
                              child: _buildMessageContent(context),
                            )
                          : _buildMessageContent(context),
                      SizedBox(height: message.isVoice ? 2.h : 4.h),
                      Align(
                        alignment: isMe
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: _buildMessageFooter(context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
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
      case 'video':
        return _buildVideoContent(context);
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
    final url = message.attachmentUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (url != null && url.isNotEmpty)
          GestureDetector(
            onTap: () => ChatAttachmentActions.open(context, message),
            child: Hero(
              tag: 'chat_img_${message.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: GymaiNetworkImage(
                  imageUrl: url,
                  width: double.infinity,
                  height: 180.h,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: double.infinity,
                    height: 180.h,
                    color: context.textSecondary.withValues(alpha: 0.3),
                    child: Icon(
                      LucideIcons.image,
                      color: context.textSecondary,
                      size: 40.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (message.message.isNotEmpty) ...[
          SizedBox(height: 6.h),
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
    final fg = isMe ? AppTheme.onGoldColor : context.textColor;
    final muted = isMe
        ? AppTheme.onGoldColor.withValues(alpha: 0.75)
        : context.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ChatAttachmentActions.open(context, message),
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.black.withValues(alpha: 0.18)
                      : AppTheme.goldColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  LucideIcons.file,
                  color: isMe ? AppTheme.onGoldColor : AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.attachmentName ?? 'فایل',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: fg,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      message.attachmentSize != null
                          ? '${_formatFileSize(message.attachmentSize!)} · ضربه برای باز کردن'
                          : 'ضربه برای باز کردن',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: muted,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.externalLink,
                size: 16.sp,
                color: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final fg = isMe ? AppTheme.onGoldColor : context.textColor;
    final muted = isMe
        ? AppTheme.onGoldColor.withValues(alpha: 0.75)
        : context.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ChatAttachmentActions.open(context, message),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          height: 160.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: isMe ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMe
                      ? Colors.black.withValues(alpha: 0.35)
                      : AppTheme.goldColor,
                ),
                child: Icon(
                  LucideIcons.play,
                  color: isMe ? Colors.white : AppTheme.onGoldColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message.attachmentName ?? 'ویدیو',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: fg,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'ضربه برای پخش',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: muted,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceContent(BuildContext context) {
    final url = message.attachmentUrl;
    if (url == null || url.isEmpty) {
      return Text(
        'پیام صوتی',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: isMe ? AppTheme.onGoldColor : context.textColor,
          fontSize: 13.sp,
        ),
      );
    }

    return ChatVoiceMessage(
      url: url,
      isMe: isMe,
      durationSeconds: message.durationSeconds,
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
          _buildSendStatusIcon(),
        ],
      ],
    );
  }

  Widget _buildSendStatusIcon() {
    if (sendStatus == MessageSendStatus.sending) {
      return SizedBox(
        width: 12.w,
        height: 12.h,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.onGoldColor.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    if (sendStatus == MessageSendStatus.failed) {
      return GestureDetector(
        onTap: onRetryFailed,
        behavior: HitTestBehavior.opaque,
        child: Icon(
          LucideIcons.alertCircle,
          color: Colors.red.shade200,
          size: 14.sp,
        ),
      );
    }

    // Read = double tick, brighter; sent = single tick, softer.
    if (message.isRead) {
      return Icon(
        LucideIcons.checkCheck,
        color: const Color(0xFFE8F5E9),
        size: 14.sp,
      );
    }

    return Icon(
      LucideIcons.check,
      color: AppTheme.onGoldColor.withValues(alpha: 0.55),
      size: 14.sp,
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
