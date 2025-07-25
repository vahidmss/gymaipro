import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../models/meal_plan.dart';

class SessionSelector extends StatelessWidget {
  final MealPlan? selectedPlan;
  final int? selectedSession;
  final Function(int) onSessionSelected;

  const SessionSelector({
    Key? key,
    required this.selectedPlan,
    required this.selectedSession,
    required this.onSessionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedPlan == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendar, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text('جلسه ${selectedPlan!.planName}',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedPlan!.days.length,
              itemBuilder: (context, index) {
                final isSelected = selectedSession == index;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.amber[700]
                          : Colors.white.withOpacity(0.1),
                      foregroundColor: isSelected
                          ? Colors.black
                          : Colors.white.withOpacity(0.7),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => onSessionSelected(index),
                    child: Text('جلسه ${index + 1}'),
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
