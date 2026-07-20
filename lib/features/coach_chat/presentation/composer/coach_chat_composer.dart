import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach_chat/domain/coach_chat_models.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: GymSpacing.sm,
      runSpacing: GymSpacing.sm,
      children: prompts.map((prompt) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              onPromptTap(prompt);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.35 : 0.4,
                  ),
                ),
              ),
              child: Text(
                prompt.label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.gymPrimary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    final next = _controller.text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = widget.enabled && _hasText;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.18),
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: <Widget>[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(
                    alpha: isDark ? 0.22 : 0.3,
                  ),
                ),
              ),
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                textDirection: TextDirection.rtl,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'پیام خود را بنویسید...',
                  hintTextDirection: TextDirection.rtl,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: canSend
                  ? LinearGradient(colors: context.goldGradientColors)
                  : null,
              color: canSend
                  ? null
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              borderRadius: BorderRadius.circular(24),
              boxShadow: canSend
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              tooltip: 'ارسال',
              onPressed: canSend ? _send : null,
              icon: Icon(
                LucideIcons.send,
                color: canSend
                    ? AppTheme.onGoldColor
                    : context.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    if (!widget.enabled) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    unawaited(HapticFeedback.lightImpact());
    _controller.clear();
    widget.onSend(text);
  }
}
