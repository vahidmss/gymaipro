import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/ai/screens/ai_progress_analysis_screen.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/features/live_workout/presentation/cards/live_workout_cards.dart';
import 'package:gymaipro/features/live_workout/presentation/widgets/live_workout_session_progress.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/navigation/form_guidance_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/product_experience/presentation/active_program_selector_bar.dart';
import 'package:gymaipro/features/product_experience/presentation/workout_session_day_picker.dart';
import 'package:gymaipro/features/product_experience/presentation/workout_session_selection_helper.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/live_workout/view_models/live_workout_view_model.dart';
import 'package:gymaipro/workout_log/widgets/exercise_card.dart';

class LiveWorkoutScreen extends StatefulWidget {
  const LiveWorkoutScreen({this.viewModel, this.autoLoad = true, super.key});

  final LiveWorkoutViewModel? viewModel;
  final bool autoLoad;

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  late final LiveWorkoutViewModel _viewModel;
  late final bool _ownsViewModel;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? LiveWorkoutViewModel();
    if (widget.autoLoad) {
      unawaited(_viewModel.load());
    }
  }

  Future<void> _onProgramChanged(ActiveProgramOption option) async {
    await ActiveProgramCatalogService().activateProgram(option.id);
    await _viewModel.refresh();
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    _viewModel.flushPendingSetSaves();
  }

  void _toggleExerciseCollapse(String exerciseKey) {
    _dismissKeyboard();
    _viewModel.toggleExerciseCollapse(exerciseKey);
  }

  void _navigateToExerciseTutorial(int exerciseId) {
    _dismissKeyboard();
    final exercise = _viewModel.exerciseDetails[exerciseId];
    if (exercise == null || !mounted) return;
    unawaited(
      Navigator.pushNamed(
        context,
        '/exercise-detail',
        arguments: <String, Object>{'exercise': exercise},
      ),
    );
  }

  Future<void> _openQuickAction(String actionId) async {
    final sessionDay = _viewModel.state.sessionContext?.selectedSessionDay;
    if (ProgramModifyNavigation.isModifyAction(actionId)) {
      final applied = await ProgramModifyNavigation.open(
        context,
        quickActionId: actionId,
        sessionDay: sessionDay,
        initialRequest: switch (actionId) {
          'replace_exercise' || 'replace' =>
            'یک حرکت این جلسه را نمی‌توانم بزنم؛ جایگزین مناسب بده و روی برنامه اعمال کن',
          _ =>
            'برنامه‌ام را اصلاح کن: اگر لازم است حرکت عوض شود، ست کم/زیاد شود، یا جلسه سبک‌تر/سنگین‌تر شود.',
        },
      );
      if ((applied ?? false) && mounted) {
        await _viewModel.load();
      }
      return;
    }

    if (FormGuidanceNavigation.isFormAction(actionId)) {
      final current = _viewModel.state.currentExercise;
      await FormGuidanceNavigation.open(
        context,
        sessionDay: sessionDay,
        catalogExerciseId: current?.exerciseId,
      );
      return;
    }

    final prompt = switch (actionId) {
      'recovery' =>
        'با توجه به ریکاوری من، برای اجرای همین جلسه چه شدت و رویکردی مناسب‌تر است؟',
      'ask_coach' => 'درباره همین جلسه تمرینی یک سوال دارم.',
      _ => ProductExperienceFormatter.promptForQuickAction(actionId),
    };
    await CoachChatNavigation.open(
      context,
      quickActionId: actionId,
      initialPrompt: prompt,
      sessionDay: sessionDay,
    );
  }

  Future<void> _showCoachHelpSheet() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  ProductCopy.coachHelp,
                  style: context.gymTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                ..._LiveWorkoutQuickActions.actionIds.map((id) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${ProductCopy.quickActionEmoji(id)} '
                      '${ProductCopy.defaultQuickChipLabel(id, id)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      unawaited(_openQuickAction(id));
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        return GymPageScaffold(
          title: ProductCopy.workoutSession,
          centerContent: true,
          padding: EdgeInsets.zero,
          actions: state.isLoaded
              ? <Widget>[
                  IconButton(
                    tooltip: ProductCopy.coachHelp,
                    onPressed: () => unawaited(_showCoachHelpSheet()),
                    icon: Icon(GymIcons.coach, color: context.gymPrimary),
                  ),
                ]
              : null,
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(LiveWorkoutState state) {
    switch (state.status) {
      case LiveWorkoutStatus.loading:
        return const _LiveWorkoutSkeleton();
      case LiveWorkoutStatus.awaitingSession:
        return GymPagePadding(
          child: Column(
            children: <Widget>[
              if (state.activeProgram != null)
                ActiveProgramSelectorBar(
                  program: state.activeProgram,
                  onProgramChanged: _onProgramChanged,
                ),
              GymSpacing.gapLg,
              if (state.sessionContext != null)
                WorkoutSessionDayPicker(
                  sessions: state.sessionContext!.sessions,
                  selectedSessionDay: state.sessionContext!.selectedSessionDay,
                  onSessionDaySelected: _handleSessionDaySelected,
                ),
              GymSpacing.gapLg,
              const GymEmptyState(
                title: 'یک روز از برنامه را انتخاب کن',
                message:
                    'برای شروع ثبت ست‌ها، ابتدا روز برنامه را انتخاب کن. '
                    'اگر امروز ستی ثبت کرده باشی، با تغییر روز آن داده‌ها پاک می‌شود.',
                icon: GymIcons.calendar,
              ),
            ],
          ),
        );
      case LiveWorkoutStatus.empty:
        return const GymPagePadding(
          child: GymEmptyState(
            title: 'برای امروز تمرینی فعال نیست',
            message: 'جلسه تمرین برای امروز پیدا نشد.',
            icon: GymIcons.calendar,
          ),
        );
      case LiveWorkoutStatus.error:
        return GymPagePadding(
          child: GymErrorState(
            title: 'خطا در بارگذاری تمرین',
            message: state.errorMessage ?? ProductCopy.coachLoadFailed,
            onRetry: () => unawaited(_viewModel.refresh()),
          ),
        );
      case LiveWorkoutStatus.sessionCompleted:
        final summary = state.completionSummary;
        if (summary == null) {
          return const GymPagePadding(
            child: GymEmptyState(
              title: 'تمرین ثبت شد',
              message: 'جلسه امروز ذخیره شد.',
              icon: GymIcons.success,
            ),
          );
        }
        return GymPagePadding(
          child: LiveWorkoutCompletionCard(summary: summary),
        );
      case LiveWorkoutStatus.loaded:
        final session = state.session!;
        if (session.exercises.isEmpty) {
          return const GymPagePadding(
            child: GymEmptyState(
              title: 'جلسه تمرین نامعتبر است',
              message: 'حرکتی برای ثبت پیدا نشد.',
              icon: GymIcons.workout,
            ),
          );
        }

        final tip = state.coachTips
            .map(ProductExperienceFormatter.humanizeReason)
            .firstWhere((item) => item.trim().isNotEmpty, orElse: () => '');

        return TapRegion(
          onTapOutside: (_) => _dismissKeyboard(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _LiveExecutionHeader(
                    programTitle: state.activeProgram?.title,
                    sessionDay: state.sessionContext?.selectedSessionDay,
                    focus: session.focus,
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: LiveWorkoutSessionProgress(
                    session: session,
                    savedSets: _viewModel.savedSetsCount,
                    totalSets: _viewModel.totalSetsCount,
                  ),
                ),
                if (state.completionSummary != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: LiveWorkoutCompletionCard(
                      summary: state.completionSummary!,
                      onOpenAnalysis: () {
                        HapticFeedback.selectionClick();
                        unawaited(
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const AIProgressAnalysisScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (tip.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: _LiveCoachTipLine(tip: tip),
                  ),
                ...List.generate(_viewModel.displayExercises.length, (index) {
                  final exercise = _viewModel.displayExercises[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: RepaintBoundary(
                      child: ExerciseCard(
                        exercise: exercise,
                        exerciseDetails: _viewModel.exerciseDetails,
                        exerciseControllers: _viewModel.exerciseControllers,
                        exerciseFocusNodes: _viewModel.exerciseFocusNodes,
                        setSavedStatus: _viewModel.setSavedStatus,
                        collapsedExercises: _viewModel.collapsedExercises,
                        exerciseCoachFeedback: _viewModel.exerciseCoachFeedback,
                        compact: true,
                        onToggleCollapse: _toggleExerciseCollapse,
                        onNavigateToTutorial: _navigateToExerciseTutorial,
                        onSaveSet: _viewModel.saveSet,
                        onDismissKeyboard: _dismissKeyboard,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
    }
  }

  Future<void> _handleSessionDaySelected(String sessionDay) async {
    unawaited(HapticFeedback.selectionClick());
    final current = _viewModel.state.sessionContext?.selectedSessionDay;
    if (current == sessionDay) return;

    _dismissKeyboard();
    final evaluation = await _viewModel.evaluateSessionChange(sessionDay);
    if (!mounted) return;

    final confirmed = await WorkoutSessionSelectionHelper.confirmAndApply(
      context: context,
      evaluation: evaluation,
      newSessionDay: sessionDay,
      sessionGateway: _viewModel.sessionGateway,
    );
    if (!confirmed || !mounted) return;

    await _viewModel.selectSession(sessionDay);
  }
}

/// Read-only context — program/day changes belong on Workout Today.
class _LiveExecutionHeader extends StatelessWidget {
  const _LiveExecutionHeader({
    required this.programTitle,
    required this.sessionDay,
    required this.focus,
  });

  final String? programTitle;
  final String? sessionDay;
  final String focus;

  @override
  Widget build(BuildContext context) {
    final dayLabel = (sessionDay != null && sessionDay!.isNotEmpty)
        ? sessionDay!
        : focus;
    final program = (programTitle != null && programTitle!.trim().isNotEmpty)
        ? programTitle!.trim()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            GymChip(
              label: ProductCopy.liveSessionInProgress,
              variant: GymChipVariant.filled,
            ),
            GymSpacing.gapSm,
            Expanded(
              child: Text(
                dayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.gymTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (program != null) ...[
          SizedBox(height: 6.h),
          Text(
            program,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.gymTextStyle(
              fontSize: 12,
              color: context.gymTextSecondary,
            ),
          ),
        ],
        SizedBox(height: 8.h),
        Text(
          ProductCopy.liveSessionModeHint,
          style: context.gymTextStyle(
            fontSize: 12,
            color: context.gymTextSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LiveCoachTipLine extends StatelessWidget {
  const _LiveCoachTipLine({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.compact,
      padding: const EdgeInsets.symmetric(
        horizontal: GymSpacing.md,
        vertical: GymSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(GymIcons.success, size: 16, color: context.gymPrimary),
          GymSpacing.gapSm,
          Expanded(
            child: Text(
              tip,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.gymTextStyle(
                fontSize: 12,
                color: context.gymTextSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveWorkoutQuickActions {
  const _LiveWorkoutQuickActions._();

  static const List<String> actionIds = <String>[
    'form',
    'modify_workout',
    'recovery',
    'ask_coach',
  ];
}

class _LiveWorkoutSkeleton extends StatelessWidget {
  const _LiveWorkoutSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GymPagePadding(
      child: Column(
        children: <Widget>[
          GymSkeleton(variant: GymSkeletonVariant.hero),
          SizedBox(height: GymSpacing.lg),
          GymSkeleton(variant: GymSkeletonVariant.card),
          SizedBox(height: GymSpacing.lg),
          GymSkeleton(variant: GymSkeletonVariant.card),
          SizedBox(height: GymSpacing.lg),
          GymSkeleton(variant: GymSkeletonVariant.timeline),
        ],
      ),
    );
  }
}
