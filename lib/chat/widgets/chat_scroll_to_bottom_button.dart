import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Compact jump-to-latest control shown when the user scrolls up in a reverse chat list.
class ChatScrollToBottomButton extends StatelessWidget {
  const ChatScrollToBottomButton({
    required this.onPressed,
    this.unreadHint = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool unreadHint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22.r),
        child: Ink(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: context.cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.chevronDown,
                color: AppTheme.goldColor,
                size: 22.sp,
              ),
              if (unreadHint)
                Positioned(
                  top: 8.h,
                  right: 10.w,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: AppTheme.goldColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
