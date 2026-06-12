import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditSessionNotesDialog extends StatefulWidget {
  const EditSessionNotesDialog({
    required this.sessionName,
    required this.onSave,
    super.key,
    this.initialNotes,
  });
  final String sessionName;
  final String? initialNotes;
  final void Function(String) onSave;

  @override
  State<EditSessionNotesDialog> createState() => _EditSessionNotesDialogState();
}

class _EditSessionNotesDialogState extends State<EditSessionNotesDialog> {
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.4),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // هدر ساده
              Row(
                children: [
                  Text(
                    'توضیحات ${widget.sessionName}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.goldColor : context.textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.x,
                      color: isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.7)
                          : context.textColor.withValues(alpha: 0.7),
                      size: 20.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // فیلد متن
              Container(
                height: 180.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCardColor
                      : context.cardColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                child: TextField(
                  controller: _notesController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'توضیحات و نکات...',
                    hintStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                      color: isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.5)
                          : context.textColor.withValues(alpha: 0.5),
                    ),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppTheme.goldColor,
                        width: 1.5.w,
                      ),
                    ),
                    contentPadding: EdgeInsets.all(12.w),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // دکمه‌ها
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.8)
                            : context.textColor.withValues(alpha: 0.7),
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.3)
                              : AppTheme.lightDividerColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'انصراف',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNotes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: AppTheme.onGoldColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: CircularProgressIndicator(
                                color: AppTheme.onGoldColor,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'ذخیره',
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
      ),
    );
  }

  Future<void> _saveNotes() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));

      widget.onSave(_notesController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'توضیحات با موفقیت ذخیره شد',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
              ),
            ),
            backgroundColor: AppTheme.goldColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ذخیره توضیحات: $e',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
