import 'package:flutter/material.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/guide/data/dashboard_guide_data.dart';
import 'package:gymaipro/guide/data/drawer_guide_data.dart';
import 'package:gymaipro/guide/services/guide_service.dart';
import 'package:gymaipro/guide/widgets/feature_tour_widget.dart';
import 'package:gymaipro/meal_log/data/meal_log_guide_data.dart';
import 'package:provider/provider.dart';

/// تورهای قابل اجرا از صفحه راهنما
class AppTourInfo {
  const AppTourInfo({
    required this.guideId,
    required this.title,
    required this.description,
    required this.stepCount,
    required this.icon,
    required this.launchTarget,
    this.showOnce = true,
  });

  final String guideId;
  final String title;
  final String description;
  final int stepCount;
  final IconData icon;
  final AppTourLaunchTarget launchTarget;
  final bool showOnce;
}

enum AppTourLaunchTarget {
  dashboard,
  drawer,
  mealLog,
}

List<AppTourInfo> buildAppToursCatalog() {
  final dashboard = DashboardGuideData.getDashboardGuide();
  final drawer = DrawerGuideData.getDrawerGuide();
  final mealLog = MealLogGuideData.getMealLogGuide();
  final weightTracking = DashboardGuideData.getWeightTrackingGuide();

  return [
    AppTourInfo(
      guideId: dashboard.id,
      title: dashboard.name,
      description: dashboard.description ?? 'بخش‌های اصلی صفحه خانه',
      stepCount: dashboard.stepCount,
      icon: Icons.dashboard_outlined,
      launchTarget: AppTourLaunchTarget.dashboard,
    ),
    AppTourInfo(
      guideId: drawer.id,
      title: drawer.name,
      description: drawer.description ?? 'آیتم‌های منوی کناری',
      stepCount: drawer.stepCount,
      icon: Icons.menu,
      launchTarget: AppTourLaunchTarget.drawer,
    ),
    AppTourInfo(
      guideId: mealLog.id,
      title: mealLog.name,
      description: mealLog.description ?? 'کالری‌شمار و ثبت وعده',
      stepCount: mealLog.stepCount,
      icon: Icons.restaurant_outlined,
      launchTarget: AppTourLaunchTarget.mealLog,
    ),
    AppTourInfo(
      guideId: weightTracking.id,
      title: weightTracking.name,
      description: weightTracking.description ?? 'ثبت وزن روی نمودار داشبورد',
      stepCount: weightTracking.stepCount,
      icon: Icons.monitor_weight_outlined,
      launchTarget: AppTourLaunchTarget.dashboard,
      showOnce: false,
    ),
  ];
}

void registerAllAppGuides(BuildContext context) {
  registerGuide(context, DashboardGuideData.getDashboardGuide());
  registerGuide(context, DrawerGuideData.getDrawerGuide());
  registerGuide(context, MealLogGuideData.getMealLogGuide());
  registerGuide(context, DashboardGuideData.getWeightTrackingGuide());
}

Future<void> forceStartGuide(BuildContext context, String guideId) async {
  final guideService = Provider.of<GuideService>(context, listen: false);
  if (guideService.getGuide(guideId) == null) {
    debugPrint('⚠️ Tour not registered: $guideId');
    return;
  }
  await Future<void>.delayed(const Duration(milliseconds: 700));
  if (!context.mounted) return;
  await guideService.startGuide(guideId);
}

Future<void> launchAppTourFromHelp(
  BuildContext context,
  AppTourInfo tour,
) async {
  registerAllAppGuides(context);
  final guideService = Provider.of<GuideService>(context, listen: false);
  await guideService.resetGuide(tour.guideId);

  if (!context.mounted) return;
  Navigator.pop(context);

  await Future<void>.delayed(const Duration(milliseconds: 200));

  switch (tour.launchTarget) {
    case AppTourLaunchTarget.dashboard:
      guideService.setPendingForcedGuide(tour.guideId);
      openMainDashboard();
    case AppTourLaunchTarget.drawer:
      guideService.setPendingForcedGuide(tour.guideId, openDrawer: true);
      openMainDashboard();
    case AppTourLaunchTarget.mealLog:
      guideService.setPendingForcedGuide(tour.guideId);
      await appNavigatorKey.currentState?.pushNamed('/meal-log');
  }
}

Future<bool> runPendingForcedGuideOnDashboard(BuildContext context) async {
  final guideService = Provider.of<GuideService>(context, listen: false);
  final peek = guideService.peekPendingForcedGuide();
  if (peek == null) return false;

  if (peek == 'drawer_guide' && guideService.pendingOpenDrawer) {
    try {
      Scaffold.of(context).openDrawer();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      debugPrint('Could not open drawer for tour: $e');
    }
    return true;
  }

  final pending = guideService.consumePendingForcedGuide();
  if (pending == null || !context.mounted) return false;

  await Future<void>.delayed(const Duration(milliseconds: 500));
  if (!context.mounted) return false;
  await forceStartGuide(context, pending.$1);
  return true;
}

Future<bool> runPendingForcedGuideIfAny(BuildContext context) async {
  final guideService = Provider.of<GuideService>(context, listen: false);
  final pending = guideService.consumePendingForcedGuide();
  if (pending == null || !context.mounted) return false;
  await Future<void>.delayed(const Duration(milliseconds: 800));
  if (!context.mounted) return false;
  await forceStartGuide(context, pending.$1);
  return true;
}

Future<bool> runPendingForcedGuideOnDrawer(BuildContext context) async {
  final guideService = Provider.of<GuideService>(context, listen: false);
  final pending = guideService.consumePendingForcedGuide();
  if (pending == null || !context.mounted) return false;
  await Future<void>.delayed(const Duration(milliseconds: 400));
  if (!context.mounted) return false;
  await forceStartGuide(context, pending.$1);
  return true;
}
