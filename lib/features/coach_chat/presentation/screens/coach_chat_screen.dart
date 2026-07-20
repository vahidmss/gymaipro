import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/fade_slide.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/layout/responsive_breakpoints.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/coach_chat/presentation/cards/coach_chat_cards.dart';
import 'package:gymaipro/features/coach_chat/presentation/composer/coach_chat_composer.dart';
import 'package:gymaipro/features/coach_chat/presentation/messages/coach_chat_message_bubble.dart';
import 'package:gymaipro/features/coach_chat/state/coach_chat_state.dart';
import 'package:gymaipro/features/coach_chat/view_models/coach_chat_view_model.dart';
import 'package:gymaipro/features/product_experience/navigation/program_modify_navigation.dart';
import 'package:gymaipro/features/product_experience/navigation/workout_program_request_navigation.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/theme/app_theme.dart';

class CoachChatScreen extends StatefulWidget {
  const CoachChatScreen({
    this.viewModel,
    this.autoLoad = true,
    this.initialPrompt,
    super.key,
  });

  final CoachChatViewModel? viewModel;
  final bool autoLoad;
  final String? initialPrompt;

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  late final CoachChatViewModel _viewModel;
  late final bool _ownsViewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? CoachChatViewModel();
    _viewModel.addListener(_scrollToBottom);
    if (widget.autoLoad && _ownsViewModel) {
      unawaited(_viewModel.load());
    }
    final seedPrompt = widget.initialPrompt?.trim();
    if (seedPrompt != null && seedPrompt.isNotEmpty && _ownsViewModel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_viewModel.sendMessage(seedPrompt));
      });
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_scrollToBottom);
    _scrollController.dispose();
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: GymTypography.direction,
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final state = _viewModel.state;
          final maxWidth = GymBreakpoints.contentMaxWidth(
            MediaQuery.sizeOf(context).width,
          );
          return Scaffold(
            backgroundColor: context.backgroundColor,
            appBar: const CoachChatAppBar(),
            body: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: RefreshIndicator(
                          color: AppTheme.goldColor,
                          onRefresh: _viewModel.refresh,
                          child: _buildConversation(state),
                        ),
                      ),
                      CoachChatComposer(
                        enabled: !state.isThinking,
                        onSend: (text) {
                          unawaited(_viewModel.sendMessage(text));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversation(CoachChatState state) {
    if (state.isLoading) return const _CoachChatSkeleton();
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        GymSpacing.lg,
        GymSpacing.lg,
        GymSpacing.lg,
        GymSpacing.lg,
      ),
      children: <Widget>[
        if (state.hasError && !state.hasConversation) ...<Widget>[
          CoachChatErrorCard(
            message: state.errorMessage ?? ProductCopy.coachLoadFailed,
            onRetry: _viewModel.retryLast,
          ),
        ] else if (!state.hasConversation) ...<Widget>[
          const GymFadeSlide(child: CoachChatEmptyHero()),
          GymSpacing.gapLg,
          CoachChatSuggestedChips(
            prompts: state.suggestedPrompts,
            onPromptTap: (prompt) {
              if (prompt.id == 'build_program') {
                unawaited(WorkoutProgramRequestNavigation.open(context));
                return;
              }
              if (ProgramModifyNavigation.isModifyAction(prompt.id)) {
                unawaited(
                  ProgramModifyNavigation.open(
                    context,
                    quickActionId: prompt.id,
                    initialRequest: prompt.prompt,
                  ),
                );
                return;
              }
              unawaited(_viewModel.sendSuggestedPrompt(prompt));
            },
          ),
        ],
        for (final message in state.messages)
          GymFadeSlide(
            duration: GymMotion.normal,
            child: CoachChatMessageBubble(message: message),
          ),
        if (state.isThinking) ...<Widget>[
          GymSpacing.gapSm,
          GymFadeSlide(
            child: CoachChatThinkingCard(steps: state.thinkingSteps),
          ),
          GymSpacing.gapSm,
          const GymFadeSlide(child: CoachChatTypingIndicator()),
        ],
        if (state.hasError) ...<Widget>[
          GymSpacing.gapMd,
          CoachChatErrorCard(
            message: state.errorMessage ?? ProductCopy.coachLoadFailed,
            onRetry: _viewModel.retryLast,
          ),
        ],
      ],
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: GymMotion.normal,
          curve: GymMotion.standard,
        ),
      );
    });
  }
}

class _CoachChatSkeleton extends StatelessWidget {
  const _CoachChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: GymSpacing.page,
      children: const <Widget>[
        GymSkeleton(variant: GymSkeletonVariant.chatBubble),
        SizedBox(height: GymSpacing.lg),
        GymSkeleton(variant: GymSkeletonVariant.chatBubble),
        SizedBox(height: GymSpacing.lg),
        GymSkeleton(variant: GymSkeletonVariant.card),
      ],
    );
  }
}
