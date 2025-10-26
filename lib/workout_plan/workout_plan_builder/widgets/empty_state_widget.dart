import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(24.w),
          constraints: const BoxConstraints(maxWidth: 400, minHeight: 200),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20.r,
                offset: Offset(0.w, 6.h),
              ),
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                blurRadius: 10.r,
                offset: Offset(0.w, 3.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4AF37).withValues(alpha: 0.1),
                      const Color(0xFFB8860B).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    width: 1.5.w,
                  ),
                ),
                child: Icon(
                  LucideIcons.dumbbell,
                  size: 48.sp,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'برنامه تمرینی خود را بسازید',
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'با انتخاب حرکات مورد نظر، برنامه ورزشی شخصی‌سازی شده خود را ایجاد کنید.',
                style: TextStyle(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
