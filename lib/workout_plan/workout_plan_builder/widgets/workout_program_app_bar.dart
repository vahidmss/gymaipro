import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WorkoutProgramAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const WorkoutProgramAppBar({
    required this.isSaving,
    required this.onSave,
    required this.onMenuPressed,
    super.key,
    this.programId,
  });
  final String? programId;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onMenuPressed;

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
              textDirection: TextDirection.rtl,
              children: [
                // Back button (leftmost)
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
                    onPressed: () => NavigationService.safePop(context),
                    tooltip: 'بازگشت',
                  ),
                ),
                const SizedBox(width: 20),
                // Title (center)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          programId != null
                              ? 'ویرایش برنامه تمرینی'
                              : 'ایجاد برنامه تمرینی',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4AF37).withValues(alpha: 0.1),
                                const Color(0xFFB8860B).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'طراحی و مدیریت جلسات تمرینی',
                            style: TextStyle(
                              color: const Color(0xFFD4AF37),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Save button
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
                    icon: isSaving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD4AF37),
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.save,
                            color: const Color(0xFFD4AF37),
                            size: 22.sp,
                          ),
                    onPressed: isSaving ? null : onSave,
                    tooltip: 'ذخیره',
                  ),
                ),
                const SizedBox(width: 12),
                // Menu button
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
                      LucideIcons.menu,
                      color: const Color(0xFFD4AF37),
                      size: 22.sp,
                    ),
                    onPressed: onMenuPressed,
                    tooltip: 'برنامه‌های ذخیره‌شده',
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
