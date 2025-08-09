import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExerciseNoteDialog extends StatefulWidget {
  final String? initialNote;
  const ExerciseNoteDialog({Key? key, this.initialNote}) : super(key: key);

  @override
  State<ExerciseNoteDialog> createState() => _ExerciseNoteDialogState();
}

class _ExerciseNoteDialogState extends State<ExerciseNoteDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1310),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.messageCircle,
                    color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'یادداشت حرکت',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.amber),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 2,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'یادداشت خود را وارد کنید... (مثلاً: وزن را کم کنید)',
                hintStyle: const TextStyle(color: Colors.amberAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.1),
              ),
              style: const TextStyle(color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(_controller.text.trim());
                    },
                    child: const Text('ثبت یادداشت'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[200],
                      side: const BorderSide(color: Colors.amber),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('انصراف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
