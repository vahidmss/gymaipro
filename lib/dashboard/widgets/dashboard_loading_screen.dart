import 'package:flutter/material.dart';
import 'package:gymaipro/widgets/app_loading_widget.dart';

class DashboardLoadingScreen extends StatelessWidget {
  const DashboardLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingWidget(message: 'در حال بارگیری اطلاعات...');
  }
}
