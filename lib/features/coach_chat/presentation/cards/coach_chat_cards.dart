import 'package:flutter/material.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/design_system/animations/shimmer.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/widgets/coach_presence_core.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top bar matching private-chat chrome (avatar + name + online).
class CoachChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CoachChatAppBar({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.cardColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowRight, color: context.textColor),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        textDirection: TextDirection.rtl,
        children: <Widget>[
          const _CoachChatAvatar(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  textDirection: TextDirection.rtl,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        ProductCopy.coachName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: context.goldGradientColors
                              .map((c) => c.withValues(alpha: 0.22))
                              .toList(),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppConfig.gymAiDisplayName,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.gymPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  ProductCopy.online,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.green.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

/// Kept for backward compatibility with older list-header usage.
class CoachChatHeader extends StatelessWidget {
  const CoachChatHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CoachChatEmptyHero extends StatelessWidget {
  const CoachChatEmptyHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.3),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.14),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'سلام 👋',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'من مربی هستم.\nامروز روی چی کار کنیم؟',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: context.textColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: GymSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.28),
          ),
        ),
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
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                    ),
                  ),
                ),
            ],
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.gymPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  ProductCopy.thinking,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.gymPrimary,
                  ),
                ),
              ],
            ),
            if (steps.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              for (final step in steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    step,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const GymShimmerBlock(width: 8, height: 8),
            const SizedBox(width: 6),
            const GymShimmerBlock(width: 8, height: 8),
            const SizedBox(width: 6),
            const GymShimmerBlock(width: 8, height: 8),
            const SizedBox(width: 10),
            Text(
              ProductCopy.typing,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachChatAvatar extends StatelessWidget {
  const _CoachChatAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CoachPresenceCore(size: size, compact: true);
  }
}
