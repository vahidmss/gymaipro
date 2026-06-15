import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan_builder/dialogs/edit_session_notes_dialog.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DaySelector extends StatelessWidget {
  const DaySelector({
    required this.selectedDay,
    required this.onDayChanged,
    super.key,
    this.currentSession,
    this.onNotesChanged,
  });
  final int selectedDay;
  final ValueChanged<int> onDayChanged;
  final WorkoutSession? currentSession;
  final void Function(String)? onNotesChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysFa = [
      'روز ۱',
      'روز ۲',
      'روز ۳',
      'روز ۴',
      'روز ۵',
      'روز ۶',
      'روز ۷',
    ];

    return Column(
      children: [
        // انتخابگر روزها
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
          child: DecoratedBox(
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
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.3 : 0.5,
                ),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.15 : 0.35,
                  ),
                  blurRadius: 16.r,
                  offset: Offset(0.w, 6.h),
                  spreadRadius: 1.r,
                ),
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : AppTheme.lightTextColor.withValues(alpha: 0.08),
                  blurRadius: 8.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            child: Container(
              height: 60.h,
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 8.h,
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, idx) {
                  final isSelected = selectedDay == idx;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onDayChanged(idx),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.goldColor
                                  : (isDark
                                      ? AppTheme.goldColor.withValues(alpha: 0.1)
                                      : AppTheme.goldColor.withValues(
                                          alpha: 0.08,
                                        )),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.goldColor
                                    : AppTheme.goldColor.withValues(
                                        alpha: isDark ? 0.3 : 0.4,
                                      ),
                                width: isSelected ? 1.5.w : 1.w,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.goldColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8.r,
                                        offset: Offset(0.w, 2.h),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              daysFa[idx],
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isSelected
                                    ? AppTheme.onGoldColor
                                    : (isDark
                                        ? AppTheme.goldColor
                                        : Colors.black),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // دکمه ویرایش توضیحات روز
        if (currentSession != null && onNotesChanged != null)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _showEditNotesDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    currentSession!.notes != null &&
                        currentSession!.notes!.isNotEmpty
                    ? AppTheme.goldColor
                    : AppTheme.goldColor.withValues(alpha: 0.7),
                side: BorderSide(
                  color:
                      currentSession!.notes != null &&
                          currentSession!.notes!.isNotEmpty
                      ? AppTheme.goldColor
                      : AppTheme.goldColor.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
              ),
              icon: Icon(
                currentSession!.notes != null &&
                        currentSession!.notes!.isNotEmpty
                    ? LucideIcons.fileText
                    : LucideIcons.plus,
                size: 16.sp,
              ),
              label: Text(
                currentSession!.notes != null &&
                        currentSession!.notes!.isNotEmpty
                    ? 'ویرایش توضیحات'
                    : 'اضافه کردن توضیحات',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showEditNotesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => EditSessionNotesDialog(
        sessionName: currentSession?.day ?? 'روز ${selectedDay + 1}',
        initialNotes: currentSession?.notes,
        onSave: (notes) {
          if (onNotesChanged != null) {
            onNotesChanged!(notes);
          }
        },
      ),
    );
  }
}
