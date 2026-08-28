import 'package:flutter/material.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:gymaipro/features/session_analysis/presentation/session_analysis_screen.dart';

abstract final class SessionAnalysisNavigation {
  static Future<void> open(
    BuildContext context, {
    required SessionAnalysisSnapshot snapshot,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SessionAnalysisScreen(snapshot: snapshot),
      ),
    );
  }
}
