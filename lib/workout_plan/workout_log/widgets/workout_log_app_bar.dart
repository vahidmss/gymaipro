import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WorkoutLogAppBar({
    required this.persianDate,
    required this.onBackPressed,
    required this.onDatePickerPressed,
    super.key,
  });
  final String persianDate;
  final VoidCallback onBackPressed;
  final VoidCallback onDatePickerPressed;

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
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
              offset: Offset(0.w, 4.h),
            ),
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
              blurRadius: 10.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20),
            child: Row(
              children: [
                // Back button
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD4AF37).withValues(alpha: 0.1),
                        const Color(0xFFB8860B).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      width: 1.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
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
                    onPressed: onBackPressed,
                    tooltip: 'بازگشت',
                  ),
                ),
                const SizedBox(width: 20),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ثبت تمرین',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8.r,
                              offset: Offset(0.w, 1.h),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37).withValues(alpha: 0.1),
                              const Color(0xFFB8860B).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          persianDate,
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
                const SizedBox(width: 12),
                // Calendar icon
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD4AF37).withValues(alpha: 0.1),
                        const Color(0xFFB8860B).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      width: 1.5.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
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
                    onPressed: onDatePickerPressed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
