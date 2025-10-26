import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({
    required this.selectedPlan,
    required this.selectedPlanIndex,
    required this.availablePlans,
    required this.onFreeModeSelected,
    required this.onPlanSelected,
    super.key,
  });
  final MealPlan? selectedPlan;
  final int? selectedPlanIndex;
  final List<MealPlan> availablePlans;
  final VoidCallback onFreeModeSelected;
  final void Function(MealPlan, int) onPlanSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.settings,
                color: const Color(0xFFD4AF37),
                size: 20.sp,
              ),
              const SizedBox(width: 8),
              Text(
                'انتخاب حالت ثبت',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Free mode button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedPlan == null
                        ? const Color(0xFFD4AF37)
                        : Colors.white.withValues(alpha: 0.06),
                    foregroundColor: selectedPlan == null
                        ? const Color(0xFF1A1A1A)
                        : Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onFreeModeSelected,
                  child: const Text('ثبت آزاد', style: TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              // Plan mode button
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selectedPlan != null
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: selectedPlan != null
                          ? const Color(0xFFD4AF37)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedPlanIndex,
                      hint: Text(
                        'انتخاب برنامه',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14.sp,
                        ),
                      ),
                      dropdownColor: const Color(0xFF1A1A1A),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: selectedPlan != null
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      items: availablePlans.asMap().entries.map((entry) {
                        final plan = entry.value;
                        final index = entry.key;
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            plan.planName,
                            style: TextStyle(
                              color: selectedPlanIndex == index
                                  ? const Color(0xFFD4AF37)
                                  : Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (index) {
                        if (index != null) {
                          onPlanSelected(availablePlans[index], index);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
