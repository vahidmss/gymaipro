import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/animations/stagger_column.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/coach_notes_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/exercise_timeline_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/muscle_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/quick_actions_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/start_workout_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/workout_hero_card.dart';
import 'package:gymaipro/features/workout_today/presentation/cards/workout_summary_card.dart';
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

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? WorkoutTodayViewModel();
    if (widget.autoLoad) {
      unawaited(_viewModel.load());
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
          centerContent: true,
          padding: EdgeInsets.zero,
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
      case WorkoutTodayStatus.empty:
        return GymPagePadding(
          child: StartWorkoutCard(
            hasWorkout: false,
            onStart: () {},
            onBuildProgram: _handleBuildProgram,
          ),
        );
      case WorkoutTodayStatus.loaded:
        final data = state.data!;
        final workout = data.workout;
        return RefreshIndicator(
          color: GymColors.textPrimary,
          backgroundColor: GymColors.surface,
          onRefresh: _viewModel.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: GymPagePadding(
                  padding: GymSpacing.page,
                  child: GymStaggerColumn(
                    gap: GymSpacing.xxl,
                    children: <Widget>[
                      WorkoutHeroCard(
                        workout: workout,
                        onStart: _handleStart,
                      ),
                      WorkoutRecoveryRingCard(percent: workout.recoveryPercent),
                      WorkoutSummaryCard(workout: workout),
                      MuscleCard(muscles: workout.muscleGroups),
                      ExerciseTimelineCard(exercises: workout.exercises),
                      CoachNotesCard(notes: workout.coachNotes),
                      WorkoutExplainabilityCard(reasons: workout.reasons),
                      QuickActionsCard(
                        actions: data.quickActions,
                        onActionTap: _handleQuickAction,
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
  }

  void _handleQuickAction(WorkoutTodayQuickAction action) {
    HapticFeedback.selectionClick();
    if (action.routeName == '/workout-today') return;
    if (action.id == 'review' || action.id == 'modify' || action.id == 'replace') {
      unawaited(_runQuickAction(action));
      return;
    }
    unawaited(Navigator.of(context).pushNamed(action.routeName));
  }

  Future<void> _runQuickAction(WorkoutTodayQuickAction action) async {
    final result = await _viewModel.runQuickAction(action);
    if (!mounted) return;
    if (result.routeName != null &&
        result.routeName!.isNotEmpty &&
        action.id != 'review' &&
        action.id != 'modify' &&
        action.id != 'replace') {
      await Navigator.of(context).pushNamed(result.routeName!);
    }
  }

  void _handleStart() {
    HapticFeedback.mediumImpact();
    unawaited(Navigator.of(context).pushNamed('/live-workout'));
  }

  void _handleBuildProgram() {
    unawaited(
      CoachChatNavigation.open(context, quickActionId: 'build_program'),
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
          SizedBox(height: GymSpacing.xxl),
          GymSkeleton(variant: GymSkeletonVariant.card),
          SizedBox(height: GymSpacing.xxl),
          GymSkeleton(variant: GymSkeletonVariant.timeline),
        ],
      ),
    );
  }
}
