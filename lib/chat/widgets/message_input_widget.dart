import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MessageInputWidget extends StatelessWidget {
  const MessageInputWidget({
    required this.controller,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    required this.isSending,
    this.onEmojiPressed,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final VoidCallback onAttachmentPressed;
  final bool isSending;
  final VoidCallback? onEmojiPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachments
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.plus, color: AppTheme.goldColor),
                onPressed: onAttachmentPressed,
              ),
            ),
            const SizedBox(width: 8),
            // Input
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppTheme.textColor.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(color: AppTheme.textColor),
                        decoration: InputDecoration(
                          hintText: 'پیام خود را بنویسید...',
                          hintStyle: TextStyle(color: AppTheme.bodyStyle.color),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => onSendPressed(),
                      ),
                    ),
                    // Quick actions
                    if (onEmojiPressed != null)
                      IconButton(
                        icon: Icon(
                          LucideIcons.smile,
                          color: AppTheme.bodyStyle.color,
                          size: 20.sp,
                        ),
                        onPressed: onEmojiPressed,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.goldColor,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: IconButton(
                icon: isSending
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          color: AppTheme.textColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        LucideIcons.send,
                        color: AppTheme.textColor,
                        size: 20.sp,
                      ),
                onPressed: isSending ? null : onSendPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
