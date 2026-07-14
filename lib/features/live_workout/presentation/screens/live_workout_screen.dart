import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/animations/stagger_column.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/features/live_workout/presentation/cards/live_workout_cards.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_state.dart';
import 'package:gymaipro/features/live_workout/view_models/live_workout_view_model.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class LiveWorkoutScreen extends StatefulWidget {
  const LiveWorkoutScreen({
    this.viewModel,
    this.autoLoad = true,
    super.key,
  });

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
        final state = _viewModel.state;
        return GymPageScaffold(
          title: ProductCopy.workoutSession,
          centerContent: true,
          padding: EdgeInsets.zero,
          bottomNavigationBar: state.isLoaded
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
                      if (state.rest.active)
                        Padding(
                          padding: const EdgeInsets.only(bottom: GymSpacing.sm),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: GymButton(
                                  label: 'رد کردن استراحت',
                                  variant: GymButtonVariant.secondary,
                                  onPressed: _viewModel.skipRest,
                                ),
                              ),
                              GymSpacing.gapSm,
                              Expanded(
                                child: GymButton(
                                  label: state.rest.paused
                                      ? 'ادامه تایمر'
                                      : 'توقف تایمر',
                                  variant: GymButtonVariant.secondary,
                                  onPressed: state.rest.paused
                                      ? _viewModel.resumeRest
                                      : _viewModel.pauseRest,
                                ),
                              ),
                            ],
                          ),
                        ),
                      GymButton(
                        label: ProductCopy.localizePrimaryAction(
                          state.primaryButtonLabel,
                        ),
                        fullWidth: true,
                        icon: GymIcons.workout,
                        loading: _viewModel.isCompleting,
                        onPressed: _viewModel.isCompleting
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                _viewModel.completePrimaryAction();
                              },
                      ),
                    ],
                  ),
                )
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
        return GymPagePadding(
          child: summary == null
              ? const GymEmptyState(
                  title: 'تمرین تمام شد',
                  message: 'خلاصه جلسه در دسترس نیست.',
                  icon: GymIcons.success,
                )
              : SingleChildScrollView(
                  child: LiveWorkoutCompletionCard(summary: summary),
                ),
        );
      case LiveWorkoutStatus.loaded:
        final session = state.session!;
        final exercise = state.currentExercise;
        if (exercise == null) {
          return const GymPagePadding(
            child: GymEmptyState(
              title: 'جلسه تمرین نامعتبر است',
              message: 'حرکتی برای ثبت پیدا نشد.',
              icon: GymIcons.workout,
            ),
          );
        }
        final upcoming = state.upcomingExercise;
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: GymPagePadding(
                padding: GymSpacing.page,
                child: GymStaggerColumn(
                  gap: GymSpacing.lg,
                  children: <Widget>[
                    LiveWorkoutHeroCard(session: session),
                    LiveWorkoutProgressCard(state: state),
                    CurrentExerciseCard(
                      exercise: exercise,
                      currentSet: state.currentSet,
                    ),
                    SetTrackerCard(
                      state: state,
                      onSetTap: _viewModel.toggleSet,
                      onSetChanged: _viewModel.updateCurrentSet,
                    ),
                    RestTimerCard(
                      rest: state.rest,
                      onPause: _viewModel.pauseRest,
                      onResume: _viewModel.resumeRest,
                      onSkip: _viewModel.skipRest,
                      onExtend: () => _viewModel.extendRest(30),
                    ),
                    if (upcoming != null)
                      UpcomingExerciseCard(exercise: upcoming),
                    LiveWorkoutTextListCard(
                      title: ProductCopy.coachTips,
                      items: state.coachTips,
                    ),
                    LiveWorkoutTextListCard(
                      title: ProductCopy.whyThisSuggestion,
                      items: state.explainability,
                    ),
                    const SizedBox(height: GymSpacing.massive),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
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
