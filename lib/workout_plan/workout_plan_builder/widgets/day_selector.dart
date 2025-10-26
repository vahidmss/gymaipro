import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/dialogs/edit_session_notes_dialog.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  final Function(String)? onNotesChanged;

  @override
  Widget build(BuildContext context) {
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
        Container(
          height: 60.h,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, idx) {
              final isSelected = selectedDay == idx;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ChoiceChip(
                    label: Text(
                      daysFa[idx],
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFFD4AF37).withValues(alpha: 0.8),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) onDayChanged(idx);
                    },
                    selectedColor: const Color(0xFFD4AF37),
                    backgroundColor: const Color(0xFF0A0A0A),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      width: 1.5.w,
                    ),
                    elevation: isSelected ? 6 : 2,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              );
            },
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
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  void _showEditNotesDialog(BuildContext context) {
    showDialog(
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
