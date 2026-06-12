import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/navigation/widgets/navigation_chrome_bar.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({
    required this.controller,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    required this.isSending,
    this.onEmojiPressed,
    this.useSafeArea = true,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final VoidCallback onAttachmentPressed;
  final bool isSending;
  final VoidCallback? onEmojiPressed;
  final bool useSafeArea;

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant MessageInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
      _hasText = widget.controller.text.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (!mounted) return;
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final innerWell = NavigationChromeBar.innerWellColor(context);
    final sendEnabled = !widget.isSending && widget.controller.isSafe && _hasText;

    return SafeArea(
      top: false,
      bottom: widget.useSafeArea,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: innerWell,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: isDark ? 0.14 : 0.18),
                ),
              ),
              child: IconButton(
                icon: const Icon(LucideIcons.plus, color: AppTheme.goldColor),
                onPressed: widget.onAttachmentPressed,
                splashRadius: 20.r,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.04 : 0.7),
                      innerWell.withValues(alpha: isDark ? 0.95 : 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.45),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                      blurRadius: 10.r,
                      offset: Offset(0, 2.h),
                    ),
                    if (_hasText)
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.12),
                        blurRadius: 16.r,
                        offset: Offset(0, 4.h),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
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
                                  fontSize: 14.sp,
                                  height: 1.35,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'یک پیام بنویس...',
                                  hintStyle: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: context.textSecondary.withValues(alpha: 0.9),
                                    fontSize: 13.sp,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 11.h,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  fillColor: Colors.transparent,
                                  filled: true,
                                ),
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.newline,
                                cursorColor: AppTheme.goldColor,
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (widget.onEmojiPressed != null)
                        IconButton(
                          icon: Icon(
                            LucideIcons.smile,
                            color: context.textSecondary,
                            size: 19.sp,
                          ),
                          onPressed: widget.onEmojiPressed,
                          splashRadius: 18.r,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                gradient: sendEnabled
                    ? LinearGradient(colors: context.goldGradientColors)
                    : null,
                color: sendEnabled ? null : innerWell,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: sendEnabled
                      ? Colors.transparent
                      : context.separatorColor.withValues(alpha: 0.45),
                ),
                boxShadow: sendEnabled
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.32),
                          blurRadius: 12.r,
                          offset: Offset(0, 3.h),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                icon: widget.isSending
                    ? SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.onGoldColor,
                        ),
                      )
                    : Icon(
                        _hasText ? LucideIcons.send : LucideIcons.mic,
                        color: sendEnabled
                            ? AppTheme.onGoldColor
                            : context.textSecondary.withValues(alpha: 0.8),
                        size: 19.sp,
                    ),
                onPressed: sendEnabled ? widget.onSendPressed : null,
                splashRadius: 20.r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
