import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NoActivePlanCard extends StatelessWidget {
  const NoActivePlanCard({
    required this.onOpenMyPrograms,
    required this.onCreatePlan,
    super.key,
  });
  final VoidCallback onOpenMyPrograms;
  final VoidCallback onCreatePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      const Color(0xFFB8860B).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    width: 1.5.w,
                  ),
                ),
                child: Icon(
                  LucideIcons.utensils,
                  color: const Color(0xFFD4AF37),
                  size: 20.sp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'برنامه‌ی غذایی فعالی ندارید',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'از بین برنامه‌ها یکی را فعال کنید یا یک برنامه جدید بسازید.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.1),
              fontSize: 13.sp,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // My Programs
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      width: 1.5.w,
                    ),
                    foregroundColor: const Color(0xFFD4AF37),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: onOpenMyPrograms,
                  icon: const Icon(LucideIcons.folder),
                  label: const Text('برنامه‌های من'),
                ),
              ),
              const SizedBox(width: 12),
              // Get from AI (coming soon)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1A1A1A),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('به زودی')));
                  },
                  icon: const Icon(LucideIcons.sparkles),
                  label: const Text('دریافت از هوش مصنوعی'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
