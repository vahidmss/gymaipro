import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/ai/screens/ai_progress_analysis_screen.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_hub_sections.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_orbit_menu.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_plan_purchase_sheet.dart';
import 'package:gymaipro/features/coach/view_models/coach_home_view_model.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/form_guidance_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/recovery_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/workout_program_request_navigation.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Unified coach hub — orbit menu + message + CTA + quick tools.
class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({
    this.viewModel,
    this.enforceCoachV2Gate = false,
    this.autoLoad = true,
    super.key,
  });

  final CoachHomeViewModel? viewModel;
  final bool enforceCoachV2Gate;
  final bool autoLoad;

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  late final CoachHomeViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? CoachHomeViewModel();
    final gateDisabled =
        widget.enforceCoachV2Gate && !CoachV2Config.coachV2Enabled;
    if (widget.autoLoad && !gateDisabled) {
      unawaited(_viewModel.load());
    }
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openPlanSheet(CoachHomeState state) async {
    final purchased = await showCoachPlanPurchaseSheet(
      context,
      currentPlan: state.plan,
    );
    if ((purchased ?? false) && mounted) {
      await _viewModel.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enforceCoachV2Gate && !CoachV2Config.coachV2Enabled) {
      return const _CoachDisabledScreen();
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        return GymPageScaffold(
          centerContent: true,
          title: ProductCopy.myCoachTitle,
          actions: <Widget>[
            _PlanBadgeChip(
              label: state.planLabel,
              onTap: () => unawaited(_openPlanSheet(state)),
            ),
            IconButton(
              tooltip: 'اعلان‌ها',
              onPressed: () => unawaited(
                Navigator.of(context).pushNamed('/notifications'),
              ),
              icon: Icon(
                LucideIcons.bell,
                color: context.gymTextSecondary,
                size: 22,
              ),
            ),
          ],
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(CoachHomeState state) {
    if (state.isLoading) return const _CoachHomeSkeleton();
    if (state.hasError) {
      return GymPagePadding(
        child: GymErrorState(
          message: state.errorMessage ?? 'خطا در بارگذاری مربی',
          onRetry: () => unawaited(_viewModel.refresh()),
        ),
      );
    }

    final hasWorkout = state.todayWorkout != null;
    final message = _resolveMessage(state);
    final tip = _resolveTip(state);

    return RefreshIndicator(
      color: context.gymPrimary,
      backgroundColor: context.gymCard,
      onRefresh: _viewModel.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: GymPagePadding(
              padding: const EdgeInsets.fromLTRB(
                GymSpacing.lg,
                GymSpacing.sm,
                GymSpacing.lg,
                GymSpacing.massive,
              ),
              child: Column(
                children: <Widget>[
                  CoachOrbitMenu(
                    actions: <CoachOrbitAction>[
                      CoachOrbitAction(
                        id: 'program',
                        label: ProductCopy.programOrbit,
                        icon: LucideIcons.clipboardList,
                        onTap: _openProgramRequest,
                      ),
                      CoachOrbitAction(
                        id: 'today',
                        label: ProductCopy.todayOrbit,
                        icon: LucideIcons.calendarDays,
                        onTap: _openToday,
                      ),
                      CoachOrbitAction(
                        id: 'meal',
                        label: ProductCopy.mealPlanOrbit,
                        icon: LucideIcons.utensils,
                        locked: true,
                        lockedHint: ProductCopy.mealPlanComingSoon,
                        onTap: _showMealPlanLocked,
                      ),
                      CoachOrbitAction(
                        id: 'consult',
                        label: ProductCopy.chatWithCoach,
                        icon: LucideIcons.messageCircle,
                        onTap: _openConsult,
                      ),
                    ],
                  ),
                  GymSpacing.gapXxl,
                  CoachMessageCard(message: message),
                  GymSpacing.gapLg,
                  CoachPrimaryStartButton(
                    label: hasWorkout
                        ? ProductCopy.goToTodayWorkout
                        : ProductCopy.requestWorkoutProgram,
                    icon: hasWorkout
                        ? LucideIcons.calendarDays
                        : LucideIcons.clipboardList,
                    onPressed: hasWorkout ? _openToday : _openProgramRequest,
                  ),
                  GymSpacing.gapXxl,
                  CoachStatusMonitor(recovery: state.recovery),
                  if (tip != null) ...<Widget>[
                    GymSpacing.gapLg,
                    CoachTipCard(
                      title: tip.$1,
                      body: tip.$2,
                      icon: tip.$3,
                    ),
                  ],
                  GymSpacing.gapXxl,
                  CoachGuideChips(
                    chips: <CoachGuideChip>[
                      CoachGuideChip(
                        id: 'form',
                        label: ProductCopy.askFormTip,
                        icon: LucideIcons.personStanding,
                        onTap: _askFormTip,
                      ),
                      CoachGuideChip(
                        id: 'recovery',
                        label: ProductCopy.recovery,
                        icon: LucideIcons.heartPulse,
                        onTap: _openRecovery,
                      ),
                      CoachGuideChip(
                        id: 'modify',
                        label: ProductCopy.modifyProgramTitle,
                        icon: LucideIcons.pencil,
                        onTap: _askModify,
                      ),
                    ],
                  ),
                  GymSpacing.gapXxl,
                  CoachQuickToolsRow(
                    tools: <CoachQuickTool>[
                      CoachQuickTool(
                        id: 'progress',
                        label: ProductCopy.progressAnalysis,
                        icon: LucideIcons.chartColumn,
                        onTap: _openProgress,
                      ),
                      CoachQuickTool(
                        id: 'recovery',
                        label: ProductCopy.recovery,
                        icon: LucideIcons.heartPulse,
                        onTap: _openRecovery,
                      ),
                      CoachQuickTool(
                        id: 'consult',
                        label: ProductCopy.chatWithCoach,
                        icon: LucideIcons.messageCircle,
                        onTap: _openConsult,
                      ),
                    ],
                  ),
                  const SizedBox(height: GymSpacing.massive),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveMessage(CoachHomeState state) {
    final guidance = RecoveryGuidance.fromSnapshot(state.recovery);
    if (guidance.scenario == RecoveryScenario.postSessionToday) {
      return 'جلسه امروزت ثبت شده — آفرین. الان روی ریکاوری تمرکز کن.';
    }

    final brief = ProductCopy.buildCoachBrief(state).trim();
    if (brief.isNotEmpty) {
      final firstBeat = brief.split(RegExp(r'\n\s*\n')).first.trim();
      if (firstBeat.length <= 160) return firstBeat;
      return '${firstBeat.substring(0, 157)}…';
    }
    final greeting = state.greeting.trim();
    if (greeting.isNotEmpty) {
      return greeting.split('\n').first.trim();
    }
    final workout = state.todayWorkout;
    if (workout != null) {
      return 'امروز روز ${workout.focus} است — از «تمرین امروز» وارد شو و شروع کن.';
    }
    return 'چی دوست داری؟ درخواست برنامه بده، تمرین امروزت رو ببین، یا با من مشاوره کن.';
  }

  (String, String, IconData)? _resolveTip(CoachHomeState state) {
    final guidance = RecoveryGuidance.fromSnapshot(state.recovery);

    // After today's logged session, never show pre-workout warm-up advice.
    if (guidance.scenario == RecoveryScenario.postSessionToday) {
      final hint = ProductExperienceFormatter.readinessHint(state.recovery);
      final lines = <String>[
        if (hint != null && hint.isNotEmpty) '• $hint',
        '• امشب خواب و تغذیه را جدی بگیر تا برای جلسه بعد آماده‌تر باشی.',
        if (state.recovery.fatigue >= 60)
          '• خستگی بالاست؛ فردا اگر تمرین داری با گرم‌کردن بیشتر شروع کن.',
      ];
      return (
        ProductCopy.whyThisSuggestion,
        lines.join('\n'),
        LucideIcons.circleHelp,
      );
    }

    final explain = state.explainability;
    final humanizedReasons = explain.reasons
        .map(ProductCopy.humanizeReason)
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .where((reason) => !_looksLikeStalePreWorkoutAdvice(reason, guidance))
        .toList(growable: false);

    if (humanizedReasons.isNotEmpty) {
      final body = humanizedReasons
          .take(3)
          .map((reason) => '• $reason')
          .join('\n');
      return (
        ProductCopy.whyThisSuggestion,
        body,
        LucideIcons.circleHelp,
      );
    }

    if (state.insights.isNotEmpty) {
      final insight = ProductCopy.humanizeReason(state.insights.first);
      if (insight.isNotEmpty) {
        return (
          ProductCopy.coachTipTitle,
          insight,
          LucideIcons.lightbulb,
        );
      }
    }
    if (state.memories.isNotEmpty) {
      return (
        'یادم هست',
        state.memories.first,
        LucideIcons.brain,
      );
    }

    final recovery = state.recovery;
    if (recovery.readiness > 0) {
      final hint = ProductExperienceFormatter.readinessHint(recovery);
      if (hint != null && hint.isNotEmpty) {
        return (
          ProductCopy.whyThisSuggestion,
          '• $hint',
          LucideIcons.circleHelp,
        );
      }
    }

    return (
      ProductCopy.coachTipTitle,
      ProductCopy.weeklyFocusFallback,
      LucideIcons.sparkles,
    );
  }

  bool _looksLikeStalePreWorkoutAdvice(
    String reason,
    RecoveryGuidance guidance,
  ) {
    if (guidance.scenario != RecoveryScenario.postSessionToday) return false;
    final lower = reason.toLowerCase();
    return lower.contains('ست اول') ||
        lower.contains('گرم') ||
        lower.contains('شروع کن') ||
        lower.contains('سبک‌تر') ||
        lower.contains('شدت برنامه‌ریزی') ||
        lower.contains('تمرین کردن مشکلی');
  }

  void _openProgramRequest() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(WorkoutProgramRequestNavigation.open(context));
  }

  void _openToday() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(Navigator.of(context).pushNamed('/workout-today'));
  }

  void _openConsult() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(CoachChatNavigation.open(context, quickActionId: 'ask_coach'));
  }

  void _showMealPlanLocked() {
    unawaited(HapticFeedback.selectionClick());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ProductCopy.mealPlanComingSoon,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openProgress() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AIProgressAnalysisScreen(),
        ),
      ),
    );
  }

  void _openRecovery() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(RecoveryNavigation.open(context));
  }

  void _askFormTip() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(FormGuidanceNavigation.open(context));
  }

  void _askModify() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(() async {
      final applied = await ProgramModifyNavigation.open(
        context,
        quickActionId: 'modify_program',
      );
      if ((applied ?? false) && mounted) {
        await _viewModel.refresh();
      }
    }());
  }
}

class _CoachHomeSkeleton extends StatelessWidget {
  const _CoachHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GymPagePadding(
      child: Column(
        children: <Widget>[
          GymSkeleton(variant: GymSkeletonVariant.hero),
          SizedBox(height: GymSpacing.xxl),
          GymSkeleton(variant: GymSkeletonVariant.chatBubble),
        ],
      ),
    );
  }
}

class _PlanBadgeChip extends StatelessWidget {
  const _PlanBadgeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: ActionChip(
        onPressed: onTap,
        avatar: Icon(
          LucideIcons.sparkles,
          size: 14,
          color: context.gymPrimary,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.gymTextPrimary,
          ),
        ),
        backgroundColor: context.gymPrimary.withValues(alpha: 0.12),
        side: BorderSide(
          color: context.gymPrimary.withValues(alpha: 0.35),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}

class _CoachDisabledScreen extends StatelessWidget {
  const _CoachDisabledScreen();

  @override
  Widget build(BuildContext context) {
    return const GymPageScaffold(
      body: GymEmptyState(
        title: ProductCopy.coachDisabledTitle,
        icon: GymIcons.coach,
      ),
    );
  }
}
