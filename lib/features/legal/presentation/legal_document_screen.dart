import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Scrollable legal/about document screen.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GymPageScaffold(
      title: title,
      centerContent: true,
      body: GymPagePadding(
        child: SingleChildScrollView(
          child: Text(
            body,
            style: GymTypography.body.copyWith(
              fontSize: 15,
              height: 1.8,
              color: GymTypography.body.color,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class OpenSourceLicensesScreen extends StatelessWidget {
  const OpenSourceLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GymPageScaffold(
      title: 'مجوزهای متن‌باز',
      centerContent: true,
      body: const GymPagePadding(
        child: _LicenseList(),
      ),
    );
  }
}

class _LicenseList extends StatelessWidget {
  const _LicenseList();

  @override
  Widget build(BuildContext context) {
    return LicensePage(
      applicationName: 'GymAI',
      applicationVersion: '1.0.0',
      applicationLegalese: '© GymAI',
    );
  }
}
