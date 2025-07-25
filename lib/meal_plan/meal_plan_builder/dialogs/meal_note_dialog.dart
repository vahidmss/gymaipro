// دیالوگ یادداشت وعده (MealNoteDialog) مخصوص meal plan
import 'package:flutter/material.dart';

class MealNoteDialog extends StatefulWidget {
  final String? initialNote;
  const MealNoteDialog({Key? key, this.initialNote}) : super(key: key);

  @override
  State<MealNoteDialog> createState() => _MealNoteDialogState();
}

class _MealNoteDialogState extends State<MealNoteDialog> {
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
                const Icon(Icons.sticky_note_2, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'یادداشت وعده',
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
              decoration: InputDecoration(
                hintText: 'یادداشت خود را وارد کنید...',
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
