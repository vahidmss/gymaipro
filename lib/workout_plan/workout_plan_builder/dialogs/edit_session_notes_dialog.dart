import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EditSessionNotesDialog extends StatefulWidget {
  const EditSessionNotesDialog({
    required this.sessionName,
    required this.onSave,
    super.key,
    this.initialNotes,
  });
  final String sessionName;
  final String? initialNotes;
  final Function(String) onSave;

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
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // هدر
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      LucideIcons.fileText,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'توضیحات ${widget.sessionName}',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'نکات و توضیحات تکمیلی روز تمرینی',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                  ),
                ],
              ),
            ),

            // محتوا
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // راهنمای استفاده
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.goldColor.withValues(alpha: 0.1),
                            AppTheme.goldColor.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              LucideIcons.lightbulb,
                              color: AppTheme.goldColor,
                              size: 18.sp,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نکات مهم',
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.goldColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'اهداف روز، نکات تمرینی، یا توضیحات خاص را اینجا بنویسید',
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 11.sp,
                                    color: AppTheme.textColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // فیلد متن
                    Row(
                      children: [
                        Icon(
                          LucideIcons.edit3,
                          color: AppTheme.goldColor,
                          size: 16.sp,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'توضیحات و نکات',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppTheme.goldColor.withValues(alpha: 0.2),
                            width: 1.5.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.1),
                              blurRadius: 8.r,
                              offset: Offset(0.w, 2.h),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.vazirmatn(
                            fontSize: 14.sp,
                            color: AppTheme.textColor,
                            height: 1.5.h,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'مثال: تمرکز بر فرم صحیح، استراحت 2 دقیقه بین ست‌ها، گرم کردن قبل از شروع...',
                            hintStyle: GoogleFonts.vazirmatn(
                              fontSize: 12.sp,
                              color: AppTheme.textColor.withValues(alpha: 0.4),
                              height: 1.5.h,
                            ),
                            filled: true,
                            fillColor: AppTheme.cardColor.withValues(
                              alpha: 0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide(
                                color: AppTheme.goldColor,
                                width: 2.w,
                              ),
                            ),
                            contentPadding: EdgeInsets.all(20.w),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // دکمه‌های عملیات
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textColor.withValues(
                                alpha: 0.7,
                              ),
                              side: BorderSide(
                                color: AppTheme.textColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(LucideIcons.x, size: 16),
                            label: Text(
                              'انصراف',
                              style: GoogleFonts.vazirmatn(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveNotes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.goldColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: AppTheme.goldColor.withValues(
                                alpha: 0.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: _isSaving
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(LucideIcons.check, size: 16),
                            label: Text(
                              _isSaving ? 'در حال ذخیره...' : 'ذخیره',
                              style: GoogleFonts.vazirmatn(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
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
          ],
        ),
      ),
    );
  }

  Future<void> _saveNotes() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // شبیه‌سازی ذخیره
      await Future.delayed(const Duration(milliseconds: 500));

      widget.onSave(_notesController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'توضیحات با موفقیت ذخیره شد',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: AppTheme.goldColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
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
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
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
