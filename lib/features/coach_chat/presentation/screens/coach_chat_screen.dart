import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/fade_slide.dart';
import 'package:gymaipro/design_system/components/gym_divider.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/layout/responsive_breakpoints.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/features/coach_chat/presentation/cards/coach_chat_cards.dart';
import 'package:gymaipro/features/coach_chat/presentation/composer/coach_chat_composer.dart';
import 'package:gymaipro/features/coach_chat/presentation/messages/coach_chat_message_bubble.dart';
import 'package:gymaipro/features/coach_chat/state/coach_chat_state.dart';
import 'package:gymaipro/features/coach_chat/view_models/coach_chat_view_model.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;
        final maxWidth = GymBreakpoints.contentMaxWidth(
          MediaQuery.sizeOf(context).width,
        );
        return GymPageScaffold(
          centerContent: false,
          useSafeArea: true,
          padding: EdgeInsets.zero,
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _viewModel.refresh,
                      child: _buildConversation(state),
                    ),
                  ),
                  GymPagePadding(
                    padding: const EdgeInsets.fromLTRB(
                      GymSpacing.lg,
                      GymSpacing.sm,
                      GymSpacing.lg,
                      GymSpacing.lg,
                    ),
                    child: CoachChatComposer(
                      enabled: !state.isThinking,
                      onSend: (text) {
                        unawaited(_viewModel.sendMessage(text));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversation(CoachChatState state) {
    if (state.isLoading) return const _CoachChatSkeleton();
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        GymSpacing.lg,
        GymSpacing.xl,
        GymSpacing.lg,
        GymSpacing.lg,
      ),
      children: <Widget>[
        const GymFadeSlide(child: CoachChatHeader()),
        GymSpacing.gapXl,
        const GymDivider(label: ProductCopy.today),
        GymSpacing.gapXl,
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
        GymSkeleton(variant: GymSkeletonVariant.hero),
        SizedBox(height: GymSpacing.lg),
        GymSkeleton(variant: GymSkeletonVariant.chatBubble),
        SizedBox(height: GymSpacing.lg),
        GymSkeleton(variant: GymSkeletonVariant.chatBubble),
        SizedBox(height: GymSpacing.lg),
        GymSkeleton(variant: GymSkeletonVariant.card),
      ],
    );
  }
}
