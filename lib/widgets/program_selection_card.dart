import 'package:flutter/material.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import '../theme/app_theme.dart';

class ProgramSelectionCard extends StatelessWidget {
  final List<WorkoutProgram> programs;
  final WorkoutProgram? selectedProgram;
  final WorkoutSession? selectedSession;
  final Function(WorkoutProgram?) onProgramChanged;
  final Function(WorkoutSession?) onSessionChanged;

  const ProgramSelectionCard({
    Key? key,
    required this.programs,
    required this.selectedProgram,
    required this.selectedSession,
    required this.onProgramChanged,
    required this.onSessionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildProgramDropdown(),
          const SizedBox(height: 12),
          _buildSessionDropdown(),
        ],
      ),
    );
  }

  Widget _buildProgramDropdown() {
    return DropdownButtonFormField<WorkoutProgram>(
      value: selectedProgram,
      decoration: _buildDropdownDecoration('برنامه تمرینی'),
      dropdownColor: AppTheme.cardColor,
      style: const TextStyle(color: Colors.white),
      items: programs
          .map((p) => DropdownMenuItem(
                value: p,
                child: Text(p.name, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onProgramChanged,
    );
  }

  Widget _buildSessionDropdown() {
    return DropdownButtonFormField<WorkoutSession>(
      value: selectedSession,
      decoration: _buildDropdownDecoration('جلسه'),
      dropdownColor: AppTheme.cardColor,
      style: const TextStyle(color: Colors.white),
      items: selectedProgram?.sessions
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.day, overflow: TextOverflow.ellipsis),
                  ))
              .toList() ??
          [],
      onChanged: onSessionChanged,
    );
  }

  InputDecoration _buildDropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.goldColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.goldColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
