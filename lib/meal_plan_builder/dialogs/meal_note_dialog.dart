import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MealNoteDialog extends StatefulWidget {
  const MealNoteDialog({super.key, this.initialNote});
  final String? initialNote;

  @override
  State<MealNoteDialog> createState() => _MealNoteDialogState();
}

class _MealNoteDialogState extends State<MealNoteDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'یادداشت وعده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    LucideIcons.x,
                    size: 18.sp,
                    color: context.textColor.withValues(alpha: 0.55),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                hintText:
                    'مثال: انقدر آب بخور، روز آزاد است، تمرین سنگین داری...',
                hintStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkCardColor
                    : AppTheme.lightButtonBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.7),
                  ),
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textColor.withValues(
                        alpha: 0.7,
                      ),
                      side: BorderSide(
                        color: isDark
                            ? AppTheme.darkGreySeparator
                            : AppTheme.lightDividerColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'انصراف',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.onGoldColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () {
                      if (_controller.isSafe) {
                        Navigator.of(context).pop(_controller.safeText.trim());
                      }
                    },
                    child: Text(
                      'ثبت یادداشت',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
