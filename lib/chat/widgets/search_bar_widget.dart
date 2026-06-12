import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    required this.controller,
    required this.onChanged,
    this.hintText = 'جستجو...',
    this.onClearPressed,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onClearPressed;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.05 : 0.08),
            blurRadius: 8,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: widget.controller.isSafe
          ? TextField(
              controller: widget.controller,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: context.textSecondary,
                  size: 20.sp,
                ),
                suffixIcon: widget.controller.safeText.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          color: context.textSecondary,
                          size: 18.sp,
                        ),
                        onPressed: () {
                          if (widget.controller.isSafe) {
                            widget.controller.safeClear();
                            widget.onChanged('');
                            widget.onClearPressed?.call();
                          }
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: widget.onChanged,
            )
          : const SizedBox.shrink(),
    );
  }
}
