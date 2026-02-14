import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MessageInputWidget extends StatefulWidget {
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
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(12.w),
        color: context.cardColor,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Attachments
            DecoratedBox(
              decoration: BoxDecoration(
                // فقط پس‌زمینه‌ی ملایم؛ بدون Border تا کنار کادر ورودی دوتا خط دیده نشود
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: IconButton(
                icon: Icon(LucideIcons.plus, color: AppTheme.goldColor),
                onPressed: widget.onAttachmentPressed,
              ),
            ),
            SizedBox(width: 8.w),
            // Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.2 : 0.3,
                    ),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: widget.controller.isSafe
                          ? TextField(
                              controller: widget.controller,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: context.textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'پیام خود را بنویسید...',
                                hintStyle: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: context.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.newline,
                              onSubmitted: (_) {
                                if (widget.controller.isSafe) {
                                  widget.onSendPressed();
                                }
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    // Quick actions
                    if (widget.onEmojiPressed != null)
                      IconButton(
                        icon: Icon(
                          LucideIcons.smile,
                          color: context.textSecondary,
                          size: 20.sp,
                        ),
                        onPressed: widget.onEmojiPressed,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Send button
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: context.goldGradientColors),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: IconButton(
                icon: widget.isSending
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          color: AppTheme.onGoldColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        LucideIcons.send,
                        color: AppTheme.onGoldColor,
                        size: 20.sp,
                      ),
                onPressed: widget.isSending || !widget.controller.isSafe
                    ? null
                    : widget.onSendPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
