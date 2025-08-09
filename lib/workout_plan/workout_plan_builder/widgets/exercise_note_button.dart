import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../dialogs/exercise_note_dialog.dart';

class ExerciseNoteButton extends StatelessWidget {
  final String? note;
  final ValueChanged<String?> onNoteChanged;
  final double iconSize;
  final Color? color;

  const ExerciseNoteButton({
    Key? key,
    required this.note,
    required this.onNoteChanged,
    this.iconSize = 18,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        LucideIcons.messageCircle,
        color: note?.isNotEmpty == true
            ? (color ?? Colors.amber[700])
            : Colors.grey[400],
        size: iconSize,
      ),
      tooltip: note?.isNotEmpty == true ? 'ویرایش یادداشت' : 'افزودن یادداشت',
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
