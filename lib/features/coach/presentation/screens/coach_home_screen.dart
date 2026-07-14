import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/ai/config/coach_v2_config.dart';
import 'package:gymaipro/design_system/animations/stagger_column.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach_chat/navigation/coach_chat_navigation.dart';
import 'package:gymaipro/features/coach/presentation/cards/coach_home_cards.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/coach/view_models/coach_home_view_model.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

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
          padding: EdgeInsets.zero,
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

    return RefreshIndicator(
      color: context.gymPrimary,
      backgroundColor: context.gymCard,
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
                  CoachHeroCard(
                    state: state,
                    onStartWorkout: _handleStartWorkout,
                  ),
                  CoachBriefCard(state: state),
                  CoachQuickActionChips(
                    actions: state.quickActions,
                    onActionTap: _handleQuickAction,
                  ),
                  CoachWhyCard(item: state.explainability),
                  const SizedBox(height: GymSpacing.massive),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStartWorkout() {
    HapticFeedback.mediumImpact();
    unawaited(Navigator.of(context).pushNamed('/workout-today'));
  }

  void _handleQuickAction(CoachQuickAction action) {
    HapticFeedback.selectionClick();
    if (action.id == 'today_program') {
      unawaited(Navigator.of(context).pushNamed('/workout-today'));
      return;
    }
    if (_opensCoachChat(action.id)) {
      unawaited(
        CoachChatNavigation.open(
          context,
          quickActionId: action.id,
          initialPrompt: action.previewMessage,
        ),
      );
      return;
    }
    unawaited(_runQuickAction(action));
  }

  bool _opensCoachChat(String actionId) {
    return switch (actionId) {
      'build_program' ||
      'modify_program' ||
      'review_program' ||
      'ask_coach' => true,
      _ => false,
    };
  }

  Future<void> _runQuickAction(CoachQuickAction action) async {
    final result = await _viewModel.runQuickAction(action);
    if (!mounted) return;
    if (result.routeName != null &&
        result.routeName!.isNotEmpty &&
        action.id != 'review_program' &&
        action.id != 'modify_program') {
      await Navigator.of(context).pushNamed(result.routeName!);
    }
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

class _CoachDisabledScreen extends StatelessWidget {
  const _CoachDisabledScreen();

  @override
  Widget build(BuildContext context) {
    return GymPageScaffold(
      body: GymEmptyState(
        title: ProductCopy.coachDisabledTitle,
        icon: GymIcons.coach,
      ),
    );
  }
}
