import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/meal_plan.dart';

class ModeSelector extends StatelessWidget {
  final MealPlan? selectedPlan;
  final int? selectedPlanIndex;
  final List<MealPlan> availablePlans;
  final VoidCallback onFreeModeSelected;
  final Function(MealPlan, int) onPlanSelected;

  const ModeSelector({
    super.key,
    required this.selectedPlan,
    required this.selectedPlanIndex,
    required this.availablePlans,
    required this.onFreeModeSelected,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.settings, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('انتخاب حالت ثبت',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
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
                        ? Colors.blue[700]
                        : Colors.white.withValues(alpha: 0.1),
                    foregroundColor: selectedPlan == null
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedPlan != null
                        ? Colors.amber[700]?.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedPlan != null
                          ? Colors.amber[700]!
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedPlanIndex,
                      hint: Text(
                        'انتخاب برنامه',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      dropdownColor: const Color(0xFF2C1810),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: selectedPlan != null
                            ? Colors.amber[700]
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      items: availablePlans.asMap().entries.map((entry) {
                        final plan = entry.value;
                        final index = entry.key;
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            plan.planName,
                            style: TextStyle(
                              color: selectedPlanIndex == index
                                  ? Colors.amber[200]
                                  : Colors.white,
                              fontSize: 14,
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
