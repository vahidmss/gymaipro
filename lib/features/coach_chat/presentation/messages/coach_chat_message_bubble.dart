import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/coach_chat/presentation/cards/coach_chat_cards.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Message bubble styled like private chat — gold user / card coach.
class CoachChatMessageBubble extends StatelessWidget {
  const CoachChatMessageBubble({required this.message, super.key});

  final CoachChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == CoachChatMessageRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
          top: 4,
          bottom: 8,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(colors: context.goldGradientColors)
              : null,
          color: isUser ? null : context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.22 : 0.3,
                  ),
                ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.goldColor.withValues(
                alpha: isDark ? 0.1 : 0.14,
              ),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!isUser) ...<Widget>[
              Text(
                ProductCopy.coachName,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.gymPrimary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message.text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: isUser ? AppTheme.onGoldColor : context.textColor,
              ),
            ),
            if (!isUser)
              for (final card in message.cards)
                CoachChatMessageCardView(card: card),
          ],
        ),
      ),
    );
  }
}
