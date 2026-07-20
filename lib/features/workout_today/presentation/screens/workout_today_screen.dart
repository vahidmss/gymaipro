import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/animations/stagger_column.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_route.dart';
import 'package:gymaipro/features/product_experience/navigation/workout_program_request_navigation.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_facade.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/product_experience/active_program_catalog_service.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/features/product_experience/presentation/active_program_selector_bar.dart';
import 'package:gymaipro/features/product_experience/presentation/workout_session_day_picker.dart';
import 'package:gymaipro/features/product_experience/presentation/workout_session_selection_helper.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_notes_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/exercise_timeline_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/muscle_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/quick_actions_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/start_workout_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/workout_hero_card.dart';
import 'package:gymaipro/features/workout_today/state/workout_today_state.dart';
import 'package:gymaipro/features/workout_today/view_models/workout_today_view_model.dart';

class WorkoutTodayScreen extends StatefulWidget {
  const WorkoutTodayScreen({
    this.viewModel,
    this.autoLoad = true,
    super.key,
  });

  final WorkoutTodayViewModel? viewModel;
  final bool autoLoad;

  @override
  State<WorkoutTodayScreen> createState() => _WorkoutTodayScreenState();
}

class _WorkoutTodayScreenState extends State<WorkoutTodayScreen> {
  late final WorkoutTodayViewModel _viewModel;
  late final bool _ownsViewModel;
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? WorkoutTodayViewModel();
    if (widget.autoLoad) {
      unawaited(_viewModel.load());
      unawaited(_checkDraft());
    }
  }

  Future<void> _checkDraft() async {
    try {
      final facade = LiveWorkoutFacade();
      final userId = await facade.resolveUserId();
      final draft = await LiveWorkoutSessionStore().loadDraft(userId);
      if (!mounted) return;
      if (draft == null ||
          draft.session.exercises.isEmpty ||
          !ActiveWorkoutSessionService.draftHasProgress(draft.session)) {
        setState(() => _hasDraft = false);
        return;
      }
      setState(() => _hasDraft = true);
    } on Object {
      if (!mounted) return;
      setState(() => _hasDraft = false);
    }
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return GymPageScaffold(
          title: 'تمرین امروز',
          centerContent: true,
          padding: EdgeInsets.zero,
          bottomNavigationBar: _viewModel.state.isLoaded
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    GymSpacing.lg,
                    GymSpacing.sm,
                    GymSpacing.lg,
                    GymSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      
                      GymSpacing.gapSm,
                      GymButton(
                        label: ProductCopy.startWorkout,
                        fullWidth: true,
                        icon: GymIcons.workout,
                        onPressed: _handleStart,
                      ),
                    ],
                  ),
                )
              : null,
          body: _buildBody(_viewModel.state),
        );
      },
    );
  }

  Widget _buildBody(WorkoutTodayState state) {
    switch (state.status) {
      case WorkoutTodayStatus.loading:
        return const _WorkoutTodaySkeleton();
      case WorkoutTodayStatus.error:
        return GymPagePadding(
          child: GymErrorState(
            message: state.errorMessage ?? 'خطا در بارگذاری',
            onRetry: () => unawaited(_viewModel.refresh()),
          ),
        );
      case WorkoutTodayStatus.awaitingSession:
        return GymPagePadding(
          child: Column(
            children: <Widget>[
              if (state.activeProgram != null)
                ActiveProgramSelectorBar(
                  program: state.activeProgram,
                  onProgramChanged: _handleProgramChanged,
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
                    'برای دیدن حرکات امروز و شروع تمرین، ابتدا باید مشخص کنی '
                    'کدام روز برنامه را اجرا می‌کنی. در هر روز فقط یک سشن '
                    'می‌توانی ثبت کنی.',
                icon: GymIcons.calendar,
              ),
            ],
          ),
        );
      case WorkoutTodayStatus.empty:
        return GymPagePadding(
          child: Column(
            children: <Widget>[
              if (state.activeProgram != null)
                ActiveProgramSelectorBar(
                  program: state.activeProgram,
                  onProgramChanged: _handleProgramChanged,
                ),
              GymSpacing.gapLg,
              StartWorkoutCard(
                hasWorkout: false,
                onStart: () {},
                onBuildProgram: _handleBuildProgram,
              ),
            ],
          ),
        );
      case WorkoutTodayStatus.loaded:
        final data = state.data!;
        final workout = data.workout;
        return RefreshIndicator(
          color: context.gymPrimary,
          backgroundColor: context.gymCard,
          onRefresh: () async {
            await _viewModel.refreshWithCoach();
            await _checkDraft();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: GymPagePadding(
                  padding: const EdgeInsets.fromLTRB(
                    GymSpacing.lg,
                    GymSpacing.md,
                    GymSpacing.lg,
                    GymSpacing.massive,
                  ),
                  child: GymStaggerColumn(
                    gap: GymSpacing.md,
                    children: <Widget>[
                      if (data.activeProgram != null)
                        ActiveProgramSelectorBar(
                          program: data.activeProgram,
                          onProgramChanged: _handleProgramChanged,
                        ),
                      WorkoutSessionDayPicker(
                        sessions: data.sessionContext.sessions,
                        selectedSessionDay:
                            data.sessionContext.selectedSessionDay,
                        onSessionDaySelected: _handleSessionDaySelected,
                      ),
                      if (_hasDraft) const _ResumeDraftBanner(),
                      WorkoutHeroCard(workout: workout),
                      ExerciseTimelineCard(exercises: workout.exercises),
                      MuscleCard(muscles: workout.muscleGroups),
                      CoachNotesCard(notes: workout.coachNotes),
                      WorkoutExplainabilityCard(reasons: workout.reasons),
                      QuickActionsCard(
                        actions: data.quickActions,
                        onActionTap: _handleQuickAction,
                      ),
                      const SizedBox(height: GymSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _handleProgramChanged(ActiveProgramOption option) async {
    HapticFeedback.selectionClick();
    final currentId = _viewModel.state.activeProgram?.id ??
        _viewModel.state.data?.activeProgram?.id;
    if (currentId == option.id) return;

    final evaluation = await _viewModel.evaluateProgramChange();
    if (!mounted) return;

    final confirmed = await WorkoutSessionSelectionHelper.confirmAndApply(
      context: context,
      evaluation: evaluation,
      newSessionDay: 'برنامه جدید',
      sessionGateway: _viewModel.sessionGateway,
    );
    if (!confirmed || !mounted) return;

    await _viewModel.selectProgram(option);
    await _checkDraft();
  }

  Future<void> _handleSessionDaySelected(String sessionDay) async {
    HapticFeedback.selectionClick();
    final current = _viewModel.state.data?.sessionContext.selectedSessionDay ??
        _viewModel.state.sessionContext?.selectedSessionDay;
    if (current == sessionDay) return;

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
    await _checkDraft();
  }

  void _handleQuickAction(WorkoutTodayQuickAction action) {
    HapticFeedback.selectionClick();
    unawaited(_runQuickAction(action));
  }

  Future<void> _runQuickAction(WorkoutTodayQuickAction action) async {
    final result = await _viewModel.runQuickAction(action);
    if (!mounted) return;
    final sessionDay = _viewModel.state.data?.sessionContext.selectedSessionDay ??
        _viewModel.state.sessionContext?.selectedSessionDay;

    if (ProgramModifyNavigation.isModifyAction(action.id) ||
        result.routeName == ProgramModifyRoute.routeName) {
      final applied = await ProgramModifyNavigation.open(
        context,
        initialRequest: result.previewMessage ?? result.message,
        quickActionId: action.id,
        sessionDay: sessionDay,
      );
      if ((applied ?? false) && mounted) {
        await _viewModel.load();
        await _checkDraft();
      }
      return;
    }

    await CoachChatNavigation.open(
      context,
      initialPrompt: result.previewMessage ?? result.message,
      quickActionId: action.id,
      sessionDay: sessionDay,
    );
  }

  void _handleStart() {
    HapticFeedback.mediumImpact();
    unawaited(Navigator.of(context).pushNamed('/live-workout'));
  }

  void _handleBuildProgram() {
    unawaited(WorkoutProgramRequestNavigation.open(context));
  }
}

class _ResumeDraftBanner extends StatelessWidget {
  const _ResumeDraftBanner();

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: GymCardVariant.action,
      child: Row(
        children: <Widget>[
          Icon(GymIcons.activity, color: context.gymPrimary),
          GymSpacing.gapMd,
          Expanded(
            child: Text(
              'یک جلسه نیمه‌کاره داری. می‌توانی از همان‌جا ادامه بدهی.',
              style: context.gymTextStyle(
                fontSize: 13,
                color: context.gymTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTodaySkeleton extends StatelessWidget {
  const _WorkoutTodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return const GymPagePadding(
      child: Column(
        children: <Widget>[
          GymSkeleton(variant: GymSkeletonVariant.hero),
          SizedBox(height: GymSpacing.xl),
          GymSkeleton(variant: GymSkeletonVariant.timeline),
        ],
      ),
    );
  }
}
