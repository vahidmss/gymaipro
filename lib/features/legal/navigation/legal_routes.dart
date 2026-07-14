import 'package:flutter/material.dart';
import 'package:gymaipro/features/legal/legal_copy.dart';
import 'package:gymaipro/features/legal/presentation/legal_document_screen.dart';

abstract final class LegalRoutes {
  static const String privacy = '/privacy-policy';
  static const String terms = '/terms-of-service';
  static const String about = '/about-app';
  static const String licenses = '/open-source-licenses';

  static Route<dynamic> build(RouteSettings settings) {
    return switch (settings.name) {
      privacy => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LegalDocumentScreen(
          title: LegalCopy.privacyTitle,
          body: LegalCopy.privacyBody,
        ),
      ),
      terms => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LegalDocumentScreen(
          title: LegalCopy.termsTitle,
          body: LegalCopy.termsBody,
        ),
      ),
      about => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const LegalDocumentScreen(
          title: LegalCopy.aboutTitle,
          body: LegalCopy.aboutBody,
        ),
      ),
      licenses => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const OpenSourceLicensesScreen(),
      ),
      _ => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SizedBox.shrink(),
      ),
    };
  }
}
