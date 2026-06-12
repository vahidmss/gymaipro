import 'package:flutter/material.dart';
// دیالوگ یادداشت وعده (MealNoteDialog) مخصوص meal plan
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
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.goldGradientColors[0].withValues(alpha: 0.15),
                    context.cardColor,
                    context.goldGradientColors[1].withValues(alpha: 0.1),
                  ],
                ),
          color: isDark ? context.backgroundColor : null,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.messageSquare,
                  color: AppTheme.goldColor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'یادداشت وعده',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontSize: 14.sp,
              ),
              decoration: InputDecoration(
                hintText:
                    'مثال: انقدر آب بخور، روز آزاد است، تمرین سنگین داری...',
                hintStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.5)
                      : context.textColor.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.3 : 0.5,
                    ),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.3 : 0.5,
                    ),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.goldColor, width: 2.w),
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.1)
                    : AppTheme.goldColor.withValues(alpha: 0.05),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldColor,
                      side: BorderSide(
                        color: AppTheme.goldColor.withValues(
                          alpha: isDark ? 0.5 : 0.7,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'انصراف',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.onGoldColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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
