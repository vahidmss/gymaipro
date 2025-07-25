import 'package:flutter/material.dart';
import '../models/workout_program.dart';

class ConfirmDeleteProgramDialog extends StatelessWidget {
  final WorkoutProgram program;
  final Future<void> Function() onDelete;

  const ConfirmDeleteProgramDialog({
    Key? key,
    required this.program,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('حذف برنامه'),
      content: Text('آیا از حذف برنامه "${program.name}" اطمینان دارید؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(context); // بستن دیالوگ تایید
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('در حال حذف برنامه...'),
                  ],
                ),
              ),
            );
            try {
              await onDelete();
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context); // بستن لودینگ
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('برنامه با موفقیت حذف شد')),
                );
              }
            } catch (error) {
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context); // بستن لودینگ
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطا در حذف برنامه: $error'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          },
          child: const Text('حذف'),
        ),
      ],
    );
  }
}
