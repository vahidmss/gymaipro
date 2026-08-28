import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/fade_slide.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/layout/responsive_breakpoints.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
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

  int _lastMessageCount = 0;
  bool _wasThinking = false;
  bool _pinnedToBottom = true;

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? CoachChatViewModel();
    _scrollController.addListener(_onScroll);
    _viewModel.addListener(_onViewModelChanged);
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
    _viewModel.removeListener(_onViewModelChanged);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // reverse:true → bottom (latest) is minScrollExtent (~0)
    final away = _scrollController.position.pixels -
        _scrollController.position.minScrollExtent;
    final nearBottom = away <= 80;
    if (nearBottom != _pinnedToBottom) {
      _pinnedToBottom = nearBottom;
    }
  }

  void _onViewModelChanged() {
    final state = _viewModel.state;
    final count = state.messages.length;
    final thinking = state.isThinking;
    final shouldStick = _pinnedToBottom ||
        count > _lastMessageCount ||
        thinking != _wasThinking ||
        _lastMessageCount == 0;

    _lastMessageCount = count;
    _wasThinking = thinking;

    if (shouldStick) {
      _scrollToLatest(animate: count > 0);
    }
  }

  void _scrollToLatest({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.minScrollExtent;
      if (animate) {
        unawaited(
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _scrollController.jumpTo(target);
      }
      _pinnedToBottom = true;
    });
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
            resizeToAvoidBottomInset: true,
            backgroundColor: context.backgroundColor,
            appBar: const CoachChatAppBar(),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: <Widget>[
                      Expanded(child: _buildConversation(state)),
                      CoachChatComposer(
                        enabled: !state.isThinking,
                        quotaHint: _quotaHint(state),
                        quotaExhausted: !(state.canSendChat),
                        onSend: (text) {
                          _pinnedToBottom = true;
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

    if (!state.hasConversation && !state.isThinking) {
      return RefreshIndicator(
        color: AppTheme.goldColor,
        onRefresh: _viewModel.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            GymSpacing.lg,
            GymSpacing.lg,
            GymSpacing.lg,
            GymSpacing.lg,
          ),
          children: <Widget>[
            if (state.hasError)
              CoachChatErrorCard(
                message: state.errorMessage ?? ProductCopy.coachLoadFailed,
                onRetry: _viewModel.retryLast,
              )
            else ...<Widget>[
              const GymFadeSlide(child: CoachChatEmptyHero()),
              GymSpacing.gapLg,
              CoachChatSuggestedChips(
                prompts: state.suggestedPrompts,
                onPromptTap: _onSuggestedPrompt,
              ),
            ],
          ],
        ),
      );
    }

    // Telegram-style: reverse list keeps latest messages glued above the
    // composer when opening, sending, or when the keyboard resizes the body.
    return RefreshIndicator(
      color: AppTheme.goldColor,
      onRefresh: _viewModel.refresh,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          GymSpacing.lg,
          GymSpacing.lg,
          GymSpacing.lg,
          GymSpacing.lg,
        ),
        itemCount: _conversationItemCount(state),
        itemBuilder: (context, index) => _conversationItem(state, index),
      ),
    );
  }

  void _onSuggestedPrompt(CoachChatSuggestedPrompt prompt) {
    if (!_viewModel.state.canSendChat &&
        prompt.id != 'build_program' &&
        !ProgramModifyNavigation.isModifyAction(prompt.id)) {
      return;
    }
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
    _pinnedToBottom = true;
    unawaited(_viewModel.sendSuggestedPrompt(prompt));
  }

  String? _quotaHint(CoachChatState state) {
    final quota = state.quota;
    if (quota == null || !quota.showRemaining) return null;
    return ProductCopy.chatDailyQuotaHint(
      remaining: quota.remaining,
      limit: quota.limit,
    );
  }

  /// reverse:true → index 0 sits at the visual bottom (above composer).
  int _conversationItemCount(CoachChatState state) {
    var count = state.messages.length;
    if (state.isThinking) count += 2; // thinking card + typing
    if (state.hasError) count += 1;
    return count;
  }

  Widget _conversationItem(CoachChatState state, int index) {
    var cursor = index;

    if (state.hasError) {
      if (cursor == 0) {
        return Padding(
          padding: const EdgeInsets.only(bottom: GymSpacing.md),
          child: CoachChatErrorCard(
            message: state.errorMessage ?? ProductCopy.coachLoadFailed,
            onRetry: _viewModel.retryLast,
          ),
        );
      }
      cursor -= 1;
    }

    if (state.isThinking) {
      if (cursor == 0) {
        return const Padding(
          padding: EdgeInsets.only(bottom: GymSpacing.sm),
          child: GymFadeSlide(child: CoachChatTypingIndicator()),
        );
      }
      if (cursor == 1) {
        return Padding(
          padding: const EdgeInsets.only(bottom: GymSpacing.sm),
          child: GymFadeSlide(
            child: CoachChatThinkingCard(steps: state.thinkingSteps),
          ),
        );
      }
      cursor -= 2;
    }

    final messageIndex = state.messages.length - 1 - cursor;
    final message = state.messages[messageIndex];
    return GymFadeSlide(
      key: ValueKey<String>(message.id),
      child: CoachChatMessageBubble(message: message),
    );
  }
}

class _CoachChatSkeleton extends StatelessWidget {
  const _CoachChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
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
