import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/session_analysis/application/session_analysis_narrative_service.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_snapshot.dart';
import 'package:gymaipro/features/session_analysis/presentation/widgets/session_analysis_sections.dart';

/// Standalone route kept for deep-links/tests.
/// Preferred product path: embed [SessionAnalysisBody] on the same day screen.
class SessionAnalysisScreen extends StatelessWidget {
  const SessionAnalysisScreen({
    required this.snapshot,
    this.narrativeService,
    this.onResumeEditing,
    super.key,
  });

  final SessionAnalysisSnapshot snapshot;
  final SessionAnalysisNarrativeService? narrativeService;
  final VoidCallback? onResumeEditing;

  @override
  Widget build(BuildContext context) {
    return GymPageScaffold(
      title: ProductCopy.sessionAnalysisTitle,
      body: GymPagePadding(
        child: ListView(
          children: <Widget>[
            SessionAnalysisBody(
              snapshot: snapshot,
              narrativeService: narrativeService,
              onResumeEditing: onResumeEditing ??
                  () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
