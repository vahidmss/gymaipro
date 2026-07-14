import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/animations/shimmer.dart';
import 'package:gymaipro/design_system/components/gym_avatar.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_loading_state.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class CoachChatHeader extends StatelessWidget {
  const CoachChatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GymSpacing.lg),
      child: Row(
        children: <Widget>[
          const GymAvatar(
            size: GymAvatarSize.lg,
            icon: GymIcons.coach,
            showOnline: true,
          ),
          GymSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(ProductCopy.coachName, style: GymTypography.display),
                GymSpacing.gapSm,
                Text(
                  '${ProductCopy.online} • ${ProductCopy.todayProgram}',
                  style: GymTypography.body.copyWith(
                    color: GymColors.textTertiary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoachChatEmptyHero extends StatelessWidget {
  const CoachChatEmptyHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: double.infinity,
        padding: GymSpacing.card,
        decoration: BoxDecoration(
          color: GymColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(GymSpacing.xl),
            topRight: Radius.circular(GymSpacing.xl),
            bottomLeft: Radius.circular(GymSpacing.xl),
            bottomRight: Radius.circular(GymSpacing.sm),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('سلام 👋', style: GymTypography.headline),
            GymSpacing.gapMd,
            Text(
              'من مربی هستم.\nامروز روی چی کار کنیم؟',
              style: GymTypography.body.copyWith(
                fontSize: 16,
                height: 1.65,
                color: GymColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoachChatMessageCardView extends StatelessWidget {
  const CoachChatMessageCardView({required this.card, super.key});

  final CoachChatMessageCard card;

  @override
  Widget build(BuildContext context) {
    final title = ProductCopy.localizeCardTitle(card.title);
    return Padding(
      padding: const EdgeInsets.only(top: GymSpacing.md),
      child: GymExpandableCard(
        title: title,
        subtitle: card.items.isNotEmpty
            ? ProductCopy.humanizeReason(card.items.first)
            : null,
        variant: GymCardVariant.compact,
        initiallyExpanded: card.type == CoachChatCardType.explanation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final item in card.items.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: GymSpacing.sm),
                child: Text(
                  ProductCopy.humanizeReason(item),
                  style: GymTypography.body.copyWith(
                    fontSize: 15,
                    height: 1.6,
                    color: GymColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CoachChatThinkingCard extends StatelessWidget {
  const CoachChatThinkingCard({required this.steps, super.key});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: GymSpacing.paddingLg,
        decoration: BoxDecoration(
          color: GymColors.surface,
          borderRadius: BorderRadius.circular(GymSpacing.xl),
          border: Border.all(color: GymColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GymLoadingState(message: ProductCopy.thinking, compact: true),
            GymSpacing.gapMd,
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: GymSpacing.xs),
                child: Text(step, style: GymTypography.caption),
              ),
          ],
        ),
      ),
    );
  }
}

class CoachChatErrorCard extends StatelessWidget {
  const CoachChatErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GymErrorState(
      message: message,
      onRetry: onRetry,
      retryLabel: 'تلاش دوباره',
    );
  }
}

class CoachChatTypingIndicator extends StatelessWidget {
  const CoachChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: GymSpacing.paddingMd,
        decoration: BoxDecoration(
          color: GymColors.surface,
          borderRadius: BorderRadius.circular(GymSpacing.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const GymShimmerBlock(width: 8, height: 8),
            GymSpacing.gapSm,
            const GymShimmerBlock(width: 8, height: 8),
            GymSpacing.gapSm,
            const GymShimmerBlock(width: 8, height: 8),
            GymSpacing.gapMd,
            Text(ProductCopy.typing, style: GymTypography.caption),
          ],
        ),
      ),
    );
  }
}
