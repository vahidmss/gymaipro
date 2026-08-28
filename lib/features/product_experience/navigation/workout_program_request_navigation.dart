import 'package:flutter/material.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_program_request/presentation/screens/workout_program_gap_fill_screen.dart';
import 'package:gymaipro/features/workout_program_request/presentation/widgets/workout_program_existing_guide_sheet.dart';
import 'package:gymaipro/features/workout_today/navigation/workout_today_route.dart';
import 'package:gymaipro/utils/auth_helper.dart';

/// Opens the adaptive program-request flow (gap-fill + Coach generator).
///
/// Q&A is free to enter. Payment is requested only when the user taps Build.
/// If the user already has a Coach AI program, we guide them elsewhere instead
/// of repeating the same request questionnaire.
abstract final class WorkoutProgramRequestNavigation {
  const WorkoutProgramRequestNavigation._();

  /// Named route used for post-payment redirects back to the builder.
  static const String routeName = '/workout-program-request';

  /// Bumped when Zibal returns and the builder is already on the stack.
  static final ValueNotifier<int> paymentReturnTick = ValueNotifier<int>(0);

  /// Opens gap-fill, or a guidance sheet when an AI program already exists.
  ///
  /// Set [forceBuilder] after payment return / explicit "build new" confirm.
  static Future<T?> open<T extends Object?>(
    BuildContext context, {
    bool forceBuilder = false,
  }) async {
    final userId = await AuthHelper.getCurrentUserId();
    if (!context.mounted) return null;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ورود به ساخت برنامه، اول وارد حساب شو.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    if (!forceBuilder) {
      final redirected = await _guideIfAiProgramExists(context);
      if (redirected || !context.mounted) return null;
    }

    return _openBuilder<T>(context);
  }

  /// Ensures the gap-fill screen is on top after an external payment return.
  ///
  /// Safe to call when a builder is already visible — avoids stacking duplicates.
  /// Always opens the builder (user just paid mid-flow).
  static Future<void> openAfterPayment(BuildContext context) async {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    var builderAlreadyOpen = false;
    navigator.popUntil((route) {
      final name = route.settings.name ?? '';
      if (name == routeName) {
        builderAlreadyOpen = true;
        return true;
      }
      // Drop not-found / deeplink shim leftovers.
      if (name == '/payment-deeplink-shim' ||
          name.contains('coach-plan') ||
          name.contains('coach_plan')) {
        return false;
      }
      return route.isFirst;
    });

    paymentReturnTick.value++;
    if (builderAlreadyOpen || !context.mounted) return;
    await open(context, forceBuilder: true);
  }

  static Future<T?> _openBuilder<T extends Object?>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: const RouteSettings(name: routeName),
        builder: (_) => const WorkoutProgramGapFillScreen(),
      ),
    );
  }

  /// Returns true when the request flow was handled (user guided away / dismissed).
  static Future<bool> _guideIfAiProgramExists(BuildContext context) async {
    final catalog = ActiveProgramCatalogService();
    final aiPrograms = await catalog.listAiWorkoutPrograms();
    if (!context.mounted) return true;
    if (aiPrograms.isEmpty) return false;

    final activeAi = await catalog.getActiveAiProgramOption();
    if (!context.mounted) return true;

    final action = await showWorkoutProgramExistingGuideSheet(
      context,
      activeAiProgram: activeAi,
      aiProgramCount: aiPrograms.length,
    );
    if (!context.mounted) return true;

    switch (action) {
      case WorkoutProgramExistingAction.modify:
        if (activeAi == null) {
          final selected = await _activateAiProgramIfNeeded(
            context,
            catalog,
            aiPrograms,
          );
          if (!context.mounted) return true;
          if (selected == null) return true;
        }
        if (!context.mounted) return true;
        await ProgramModifyNavigation.open(
          context,
          quickActionId: 'modify_program',
        );
        return true;
      case WorkoutProgramExistingAction.today:
        if (activeAi == null) {
          final selected = await _activateAiProgramIfNeeded(
            context,
            catalog,
            aiPrograms,
          );
          if (!context.mounted || selected == null) return true;
        }
        if (!context.mounted) return true;
        await Navigator.of(context).pushNamed(WorkoutTodayRoute.routeName);
        return true;
      case WorkoutProgramExistingAction.programs:
        await Navigator.of(context).pushNamed('/ai-programs');
        return true;
      case WorkoutProgramExistingAction.buildNew:
        final confirmed = await _confirmBuildNew(context);
        if (!context.mounted) return true;
        if (confirmed) {
          await _openBuilder(context);
        }
        return true;
      case WorkoutProgramExistingAction.dismiss:
      case null:
        return true;
    }
  }

  static Future<ActiveProgramOption?> _activateAiProgramIfNeeded(
    BuildContext context,
    ActiveProgramCatalogService catalog,
    List<ActiveProgramOption> aiPrograms,
  ) async {
    if (aiPrograms.isEmpty) return null;
    if (aiPrograms.length == 1) {
      final only = aiPrograms.first;
      await catalog.activateProgram(only.id);
      return only;
    }

    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'اول برنامه هوش مصنوعی فعال را از لیست برنامه‌ها انتخاب کن.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await Navigator.of(context).pushNamed('/ai-programs');
    return null;
  }

  static Future<bool> _confirmBuildNew(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(ProductCopy.existingAiProgramBuildNewConfirmTitle),
        content: const Text(ProductCopy.existingAiProgramBuildNewConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('بساز'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
