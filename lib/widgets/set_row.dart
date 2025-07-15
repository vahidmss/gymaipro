import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_program_log.dart';
import '../theme/app_theme.dart';

class SetRow extends StatelessWidget {
  final NormalExercise exercise;
  final int setIdx;
  final bool isLogged;
  final ExerciseSetLog? lastLog;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final VoidCallback onSave;
  final String setPlannedValue;

  const SetRow({
    Key? key,
    required this.exercise,
    required this.setIdx,
    required this.isLogged,
    this.lastLog,
    required this.repsController,
    required this.weightController,
    required this.onSave,
    required this.setPlannedValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLogged
            ? Colors.green.withValues(alpha: 0.1)
            : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLogged
              ? Colors.green.withValues(alpha: 0.3)
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildSetNumber(),
          const SizedBox(width: 12),
          Expanded(child: _buildRepsInput()),
          const SizedBox(width: 8),
          Expanded(child: _buildWeightInput()),
          const SizedBox(width: 8),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSetNumber() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            isLogged ? Colors.green : AppTheme.goldColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Text(
        '${setIdx + 1}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isLogged ? Colors.white : AppTheme.goldColor,
        ),
      ),
    );
  }

  Widget _buildRepsInput() {
    return TextField(
      controller: repsController,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.goldColor),
        ),
        labelText: exercise.style == ExerciseStyle.setsReps ? 'تکرار' : 'ثانیه',
        labelStyle: const TextStyle(color: AppTheme.goldColor),
        hintText: setPlannedValue,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        suffixIcon: lastLog != null ? _buildHistoryButton() : null,
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildWeightInput() {
    return TextField(
      controller: weightController,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.goldColor),
        ),
        labelText: 'وزن',
        labelStyle: const TextStyle(color: AppTheme.goldColor),
        hintText: lastLog?.weight?.toString() ?? '',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        suffixIcon:
            lastLog?.weight != null ? _buildWeightHistoryButton() : null,
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildHistoryButton() {
    return IconButton(
      icon:
          const Icon(LucideIcons.history, size: 16, color: AppTheme.goldColor),
      onPressed: () {
        final value = exercise.style == ExerciseStyle.setsReps
            ? lastLog?.reps?.toString() ?? ''
            : lastLog?.seconds?.toString() ?? '';
        repsController.text = value;
      },
    );
  }

  Widget _buildWeightHistoryButton() {
    return IconButton(
      icon:
          const Icon(LucideIcons.history, size: 16, color: AppTheme.goldColor),
      onPressed: () {
        weightController.text = lastLog?.weight?.toString() ?? '';
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        color: isLogged ? Colors.green : AppTheme.goldColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onSave,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              isLogged ? LucideIcons.check : LucideIcons.save,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
