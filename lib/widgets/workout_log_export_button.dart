import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_log.dart';
import '../services/workout_log_service.dart';

class WorkoutLogExportButton extends StatelessWidget {
  final String userId;
  final WorkoutLogFilter? filter;

  const WorkoutLogExportButton({
    Key? key,
    required this.userId,
    this.filter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.file_download),
      label: const Text('Export Data'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      onPressed: () => _exportData(context),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final workoutLogService = WorkoutLogService();
      final logs = await workoutLogService.getWorkoutLogsForAnalytics(
        userId,
        filter: filter,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (logs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No workout logs to export')),
        );
        return;
      }

      // Create JSON string
      final jsonString = jsonEncode(logs);

      // Get temp directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/workout_logs.json';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Show success message with file path
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout log exported to: $filePath'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data: $e')),
      );
    }
  }
}
