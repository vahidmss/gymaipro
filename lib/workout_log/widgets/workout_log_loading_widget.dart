import 'package:flutter/material.dart';
import 'package:gymaipro/widgets/app_loading_widget.dart';

/// ویجت بارگذاری لاگ تمرین — از ویجت مشترک استفاده می‌کند
class WorkoutLogLoadingWidget extends StatelessWidget {
  const WorkoutLogLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingWidget();
  }
}
