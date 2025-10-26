import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, super.key});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: message.type == ChatMessageType.user
          ? TextDirection.rtl
          : TextDirection.rtl,
      mainAxisAlignment: message.type == ChatMessageType.user
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.type == ChatMessageType.ai) ...[
          _buildAvatar(),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
            decoration: BoxDecoration(
              color: message.type == ChatMessageType.user
                  ? AppTheme.goldColor
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomLeft: message.type == ChatMessageType.user
                    ? Radius.circular(20.r)
                    : Radius.circular(4.r),
                bottomRight: message.type == ChatMessageType.user
                    ? Radius.circular(4.r)
                    : Radius.circular(20.r),
              ),
              border: Border.all(
                color: message.type == ChatMessageType.user
                    ? AppTheme.goldColor
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: message.type == ChatMessageType.user
                        ? Colors.white
                        : Colors.white,
                    fontSize: 14.sp,
                    height: 1.4.h,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: message.type == ChatMessageType.user
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (message.type == ChatMessageType.user) ...[
          const SizedBox(width: 8),
          _buildUserAvatar(),
        ],
      ],
    );
  }

  /// آواتار کاربر
  Widget _buildUserAvatar() {
    return Container(
      width: 32.w,
      height: 32.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.goldColor, AppTheme.darkGold],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 16),
    );
  }

  /// آواتار هوش مصنوعی
  Widget _buildAvatar() {
    return Container(
      width: 32.w,
      height: 32.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
    );
  }

  /// فرمت زمان
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الان';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ساعت پیش';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
