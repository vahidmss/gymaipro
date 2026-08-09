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
    this.sessions,
    this.currentSession,
    this.onNotesChanged,
  });
  final int selectedDay;
  final ValueChanged<int> onDayChanged;
  final List<WorkoutSession>? sessions;
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
    final hasNotes =
        currentSession?.notes != null && currentSession!.notes!.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
          child: SizedBox(
            height: 44.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, idx) {
                final isSelected = selectedDay == idx;
                final exerciseCount = (sessions != null && idx < sessions!.length)
                    ? sessions![idx].exercises.length
                    : 0;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Material(
                    color: isSelected
                        ? AppTheme.goldColor
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(14.r),
                    child: InkWell(
                      onTap: () => onDayChanged(idx),
                      borderRadius: BorderRadius.circular(14.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 11.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.goldColor
                                : AppTheme.goldColor.withValues(
                                    alpha: isDark ? 0.2 : 0.28,
                                  ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              daysFa[idx],
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isSelected
                                    ? AppTheme.onGoldColor
                                    : (isDark
                                          ? AppTheme.goldColor
                                          : context.textColor),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13.sp,
                              ),
                            ),
                            if (exerciseCount > 0) ...[
                              SizedBox(width: 5.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.onGoldColor.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppTheme.goldColor.withValues(
                                          alpha: 0.12,
                                        ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '$exerciseCount',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.onGoldColor
                                        : AppTheme.goldColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (currentSession != null && onNotesChanged != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showEditNotesDialog(context),
                style: TextButton.styleFrom(
                  foregroundColor: hasNotes
                      ? AppTheme.goldColor
                      : AppTheme.goldColor.withValues(alpha: 0.7),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  hasNotes ? LucideIcons.fileText : LucideIcons.plus,
                  size: 14.sp,
                ),
                label: Text(
                  hasNotes ? 'ویرایش توضیحات روز' : 'توضیحات روز',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
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
