import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_shadows.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';

class CoachChatSuggestedChips extends StatelessWidget {
  const CoachChatSuggestedChips({
    required this.prompts,
    required this.onPromptTap,
    super.key,
  });

  final List<CoachChatSuggestedPrompt> prompts;
  final ValueChanged<CoachChatSuggestedPrompt> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: GymSpacing.sm,
      runSpacing: GymSpacing.sm,
      children: prompts
          .map(
            (prompt) => GymChip(
              label: prompt.label,
              onTap: () {
                HapticFeedback.selectionClick();
                onPromptTap(prompt);
              },
            ),
          )
          .toList(),
    );
  }
}

class CoachChatComposer extends StatefulWidget {
  const CoachChatComposer({
    required this.onSend,
    required this.enabled,
    super.key,
  });

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<CoachChatComposer> createState() => _CoachChatComposerState();
}

class _CoachChatComposerState extends State<CoachChatComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: GymSpacing.paddingMd,
      decoration: BoxDecoration(
        color: GymColors.surface,
        borderRadius: GymRadius.radiusXxl,
        border: Border.all(color: GymColors.borderSubtle),
        boxShadow: GymShadows.large,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'پیوست',
            onPressed: widget.enabled ? () {} : null,
            icon: const Icon(GymIcons.add, color: GymColors.textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              textDirection: GymTypography.direction,
              minLines: 1,
              maxLines: 4,
              style: GymTypography.bodyStrong,
              decoration: InputDecoration(
                hintText: 'از مربی بپرس...',
                hintTextDirection: GymTypography.direction,
                border: InputBorder.none,
                hintStyle: GymTypography.body.copyWith(
                  color: GymColors.textTertiary,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          IconButton(
            tooltip: 'صدا',
            onPressed: widget.enabled ? () {} : null,
            icon: const Icon(GymIcons.message, color: GymColors.textTertiary),
          ),
          IconButton(
            tooltip: 'ارسال',
            onPressed: widget.enabled ? _send : null,
            icon: Icon(
              GymIcons.send,
              color: widget.enabled
                  ? GymColors.textPrimary
                  : GymColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.clear();
    widget.onSend(text);
  }
}
