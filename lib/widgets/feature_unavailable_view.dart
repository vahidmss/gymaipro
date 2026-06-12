import 'package:flutter/material.dart';
import 'package:gymaipro/widgets/app_status_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FeatureUnavailableView extends StatelessWidget {
  const FeatureUnavailableView({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppStatusCard(
      icon: LucideIcons.shieldAlert,
      title: title,
      description: description,
    );
  }
}
