import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_plan/meal_log/dialogs/persian_food_log_date_picker_dialog.dart';
import 'package:gymaipro/meal_plan/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MealLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MealLogAppBar({
    required this.selectedDate,
    required this.onSave,
    required this.onDateSelected,
    super.key,
    this.onSync,
  });
  final DateTime selectedDate;
  final VoidCallback? onSave;
  final void Function(DateTime) onDateSelected;
  final VoidCallback? onSync;

  @override
  Size get preferredSize => Size.fromHeight(120.h);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Row(
            children: [
              // Back button
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFD4AF37).withValues(alpha: 0.10),
                      const Color(0xFFB8860B).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.30),
                    width: 1.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.20),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.arrowRight,
                    color: const Color(0xFFD4AF37),
                    size: 22.sp,
                  ),
                  onPressed: () => NavigationService.safePop(context),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ثبت تغذیه',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD4AF37).withValues(alpha: 0.10),
                            const Color(0xFFB8860B).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        MealLogUtils.getPersianFormattedDate(selectedDate),
                        style: TextStyle(
                          color: const Color(0xFFD4AF37),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Save button
              // حذف کامل دکمه سیو
              // Sync button
              // حذف کامل دکمه سینک
              const SizedBox(width: 8),
              // Calendar icon
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFD4AF37).withValues(alpha: 0.10),
                      const Color(0xFFB8860B).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.30),
                    width: 1.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.20),
                      blurRadius: 8.r,
                      offset: Offset(0.w, 2.h),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    LucideIcons.calendar,
                    color: const Color(0xFFD4AF37),
                    size: 22.sp,
                  ),
                  tooltip: 'انتخاب تاریخ',
                  onPressed: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => PersianFoodLogDatePickerDialog(
                        selectedDate: selectedDate,
                        onDateSelected: onDateSelected,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
