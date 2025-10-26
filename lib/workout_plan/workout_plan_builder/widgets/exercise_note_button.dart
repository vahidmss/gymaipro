import 'package:flutter/material.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/dialogs/exercise_note_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExerciseNoteButton extends StatelessWidget {
  const ExerciseNoteButton({
    required this.note,
    required this.onNoteChanged,
    super.key,
    this.iconSize = 18,
    this.color,
  });
  final String? note;
  final ValueChanged<String?> onNoteChanged;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        LucideIcons.messageCircle,
        color: note?.isNotEmpty ?? false
            ? (color ?? Colors.amber[700])
            : Colors.grey[400],
        size: iconSize,
      ),
      tooltip: note?.isNotEmpty ?? false ? 'ویرایش یادداشت' : 'افزودن یادداشت',
      onPressed: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) => ExerciseNoteDialog(initialNote: note),
        );
        if (result != null) onNoteChanged(result);
      },
    );
  }
}
