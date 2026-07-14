import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/coach_chat/presentation/cards/coach_chat_cards.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';

class CoachChatMessageBubble extends StatelessWidget {
  const CoachChatMessageBubble({required this.message, super.key});

  final CoachChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == CoachChatMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: GymSpacing.sm),
          padding: GymSpacing.paddingLg,
          decoration: BoxDecoration(
            color: isUser ? GymColors.elevated : GymColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(GymRadius.xl),
              topRight: const Radius.circular(GymRadius.xl),
              bottomLeft: Radius.circular(isUser ? GymRadius.xl : GymRadius.sm),
              bottomRight: Radius.circular(isUser ? GymRadius.sm : GymRadius.xl),
            ),
            border: Border.all(
              color: isUser ? GymColors.border : GymColors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                isUser ? 'تو' : ProductCopy.coachName,
                style: GymTypography.overline.copyWith(
                  color: GymColors.textTertiary,
                ),
              ),
              GymSpacing.gapSm,
              Text(
                message.text,
                textDirection: GymTypography.direction,
                style: GymTypography.body.copyWith(
                  fontSize: 16,
                  height: 1.65,
                  color: GymColors.textPrimary,
                ),
              ),
              if (!isUser)
                for (final card in message.cards)
                  CoachChatMessageCardView(card: card),
            ],
          ),
        ),
      ),
    );
  }
}
