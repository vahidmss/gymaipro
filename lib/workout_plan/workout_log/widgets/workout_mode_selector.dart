import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../workout_plan_builder/models/workout_program.dart';

class WorkoutModeSelector extends StatelessWidget {
  final WorkoutProgram? selectedProgram;
  final int? selectedProgramIndex;
  final List<WorkoutProgram> availablePrograms;
  final Function(WorkoutProgram, int) onProgramSelected;
  final bool isDisabled;

  const WorkoutModeSelector({
    Key? key,
    required this.selectedProgram,
    required this.selectedProgramIndex,
    required this.availablePrograms,
    required this.onProgramSelected,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
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
                Icon(LucideIcons.dumbbell, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('انتخاب برنامه تمرینی',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: selectedProgram != null
                    ? Colors.amber[700]?.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selectedProgram != null
                      ? Colors.amber[700]!
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedProgramIndex,
                  hint: Text(
                    'برنامه مورد نظر را انتخاب کنید',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14),
                  ),
                  dropdownColor: const Color(0xFF2C1810),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: selectedProgram != null
                        ? Colors.amber[700]
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  isExpanded: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  items: availablePrograms.asMap().entries.map((entry) {
                    final program = entry.value;
                    final index = entry.key;
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        program.name,
                        style: TextStyle(
                          color: selectedProgramIndex == index
                              ? Colors.amber[200]
                              : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: isDisabled
                      ? null
                      : (index) {
                          if (index != null) {
                            onProgramSelected(availablePrograms[index], index);
                          }
                        },
                  disabledHint: selectedProgram != null
                      ? Text(selectedProgram!.name,
                          style: TextStyle(
                              color: Colors.amber[200]?.withValues(alpha: 0.7),
                              fontSize: 14))
                      : Text('برنامه‌ای انتخاب نشده',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
