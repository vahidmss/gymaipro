import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, super.key});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.type == ChatMessageType.user;
    
    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 50.w : 0,
        right: isUser ? 0 : 50.w,
        bottom: 8.h,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          // آواتار کاربر (قبل از پیام - سمت راست)
          if (isUser) ...[
            _buildUserAvatar(),
            SizedBox(width: 8.w),
          ],
          // پیام
          Flexible(
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: context.goldGradientColors,
                          )
                        : null,
                    color: isUser ? null : context.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                      bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
                      bottomRight: Radius.circular(isUser ? 4.r : 20.r),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppTheme.goldColor.withValues(
                              alpha: isDark ? 0.2 : 0.3,
                            ),
                            width: 1.w,
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
                        // محتوای پیام
                        Text(
                          message.content,
                          style: GoogleFonts.vazirmatn(
                            color: isUser
                                ? AppTheme.onGoldColor
                                : context.textColor,
                            fontSize: 14.sp,
                            height: 1.4.h,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        // زمان
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: GoogleFonts.vazirmatn(
                                color: isUser
                                    ? AppTheme.onGoldColor.withValues(alpha: 0.8)
                                    : context.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          // آواتار AI (بعد از پیام - سمت چپ)
          if (!isUser) ...[
            SizedBox(width: 8.w),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  /// آواتار کاربر
  Widget _buildUserAvatar() {
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.goldColor, AppTheme.darkGold],
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 18),
    );
  }

  /// آواتار هوش مصنوعی
  Widget _buildAvatar() {
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.goldColor, AppTheme.darkGold],
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
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
