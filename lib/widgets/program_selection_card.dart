import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

class ProgramSelectionCard extends StatelessWidget {
  const ProgramSelectionCard({
    required this.programs,
    required this.selectedProgram,
    required this.selectedSession,
    required this.onProgramChanged,
    required this.onSessionChanged,
    super.key,
  });
  final List<WorkoutProgram> programs;
  final WorkoutProgram? selectedProgram;
  final WorkoutSession? selectedSession;
  final void Function(WorkoutProgram?) onProgramChanged;
  final void Function(WorkoutSession?) onSessionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildProgramDropdown(context),
          const SizedBox(height: 12),
          _buildSessionDropdown(context),
        ],
      ),
    );
  }

  Widget _buildProgramDropdown(BuildContext context) {
    return DropdownButtonFormField<WorkoutProgram>(
      initialValue: selectedProgram,
      decoration: _buildDropdownDecoration(context, 'برنامه تمرینی'),
      dropdownColor: context.cardColor,
      style: TextStyle(color: context.textColor),
      items: programs
          .map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text(p.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onProgramChanged,
    );
  }

  Widget _buildSessionDropdown(BuildContext context) {
    return DropdownButtonFormField<WorkoutSession>(
      initialValue: selectedSession,
      decoration: _buildDropdownDecoration(context, 'جلسه'),
      dropdownColor: context.cardColor,
      style: TextStyle(color: context.textColor),
      items:
          selectedProgram?.sessions
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.day, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList() ??
          [],
      onChanged: onSessionChanged,
    );
  }

  InputDecoration _buildDropdownDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.textColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AppTheme.goldColor),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8),
    );
  }
}
