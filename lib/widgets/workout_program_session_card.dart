import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import 'workout_program_exercise_card.dart';

class WorkoutProgramSessionCard extends StatelessWidget {
  final WorkoutSession session;
  final List<Exercise> exercises;
  final VoidCallback onAddExercise;
  final VoidCallback onDeleteSession;
  final VoidCallback onAddSession;
  final Function(String) onRenameSession;
  final Function(int) onDeleteExercise;
  final Function(int) onMoveExerciseUp;
  final Function(int) onMoveExerciseDown;

  const WorkoutProgramSessionCard({
    Key? key,
    required this.session,
    required this.exercises,
    required this.onAddExercise,
    required this.onDeleteSession,
    required this.onRenameSession,
    required this.onDeleteExercise,
    required this.onMoveExerciseUp,
    required this.onMoveExerciseDown,
    required this.onAddSession,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF3F51B5);

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const Divider(),
          _buildExercisesList(),
          _buildActionButtons(primaryColor),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showRenameDialog(context),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    session.day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.edit, size: 14),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'حذف سشن',
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    if (session.exercises.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'هنوز تمرینی اضافه نشده است',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: session.exercises.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final exercise = session.exercises[index];
        return WorkoutProgramExerciseCard(
          exercise: exercise,
          allExercises: exercises,
          onDelete: () => onDeleteExercise(index),
          onMoveUp: index > 0 ? () => onMoveExerciseUp(index) : null,
          onMoveDown: index < session.exercises.length - 1
              ? () => onMoveExerciseDown(index)
              : null,
        );
      },
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // افزودن تمرین
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('افزودن تمرین'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onAddExercise,
            ),
          ),
          const SizedBox(width: 8),
          // افزودن سشن جدید - تغییر به دکمه با متن
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.plusCircle, size: 16),
              label: const Text('افزودن سشن جدید'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onAddSession,
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: session.day);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر نام سشن'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'نام جدید',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                onRenameSession(newName);
                Navigator.pop(context);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف سشن'),
        content: Text('آیا از حذف سشن "${session.day}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onDeleteSession();
              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
