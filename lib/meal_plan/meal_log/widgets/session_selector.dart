import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SessionSelector extends StatelessWidget {
  const SessionSelector({
    required this.selectedPlan,
    required this.selectedSession,
    required this.onSessionSelected,
    super.key,
  });
  final MealPlan? selectedPlan;
  final int? selectedSession;
  final void Function(int) onSessionSelected;

  @override
  Widget build(BuildContext context) {
    if (selectedPlan == null) return const SizedBox.shrink();

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
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20.r,
            offset: Offset(0.w, 8.h),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0.w, 4.h),
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
                  'جلسه رژیم را انتخاب کنید',
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
          const SizedBox(height: 16),
          SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedPlan!.days.length,
              itemBuilder: (context, index) {
                final isSelected = selectedSession == index;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: () => onSessionSelected(index),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.2),
                                    const Color(
                                      0xFFB8860B,
                                    ).withValues(alpha: 0.1),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.1),
                                    const Color(
                                      0xFFB8860B,
                                    ).withValues(alpha: 0.05),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : const Color(
                                    0xFFD4AF37,
                                  ).withValues(alpha: 0.3),
                            width: 1.5.w,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 8.r,
                                    offset: Offset(0.w, 2.h),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'جلسه ${index + 1}',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFD4AF37),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
