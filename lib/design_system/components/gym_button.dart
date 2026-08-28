import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

enum GymButtonVariant { primary, secondary, ghost, danger }

enum GymButtonSize { regular, compact }

/// GymAI button with variants, loading, and disabled states.
class GymButton extends StatelessWidget {
  const GymButton({
    required this.label,
    required this.onPressed,
    this.variant = GymButtonVariant.primary,
    this.size = GymButtonSize.regular,
    this.fullWidth = false,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final GymButtonVariant variant;
  final GymButtonSize size;
  final bool fullWidth;
  final bool loading;
  final IconData? icon;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final height = size == GymButtonSize.compact ? 40.0 : 48.0;
    final horizontal = size == GymButtonSize.compact
        ? GymSpacing.lg
        : GymSpacing.xxl;

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(context),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: _foregroundColor(context)),
                const SizedBox(width: GymSpacing.sm),
              ],
              Text(label, style: _textStyle(context)),
            ],
          );

    final button = Material(
      color: _backgroundColor(context),
      borderRadius: GymRadius.radiusLg,
      child: InkWell(
        onTap: _enabled ? onPressed : null,
        borderRadius: GymRadius.radiusLg,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: GymRadius.radiusLg,
            border: _border(context),
          ),
          child: child,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color _backgroundColor(BuildContext context) {
    if (!_enabled) return context.gymNeutralFill;
    return switch (variant) {
      GymButtonVariant.primary => context.gymGold,
      GymButtonVariant.secondary => context.gymSurface,
      GymButtonVariant.ghost => Colors.transparent,
      GymButtonVariant.danger => context.gymDanger.withValues(alpha: 0.14),
    };
  }

  Color _foregroundColor(BuildContext context) {
    if (!_enabled) return context.gymTextDisabled;
    return switch (variant) {
      GymButtonVariant.primary => const Color(0xFF0A0A0A),
      GymButtonVariant.secondary => context.gymPrimary,
      GymButtonVariant.ghost => context.gymPrimary,
      GymButtonVariant.danger => context.gymDanger,
    };
  }

  Border? _border(BuildContext context) {
    if (!_enabled) {
      return Border.all(color: context.gymBorderSubtle);
    }
    return switch (variant) {
      GymButtonVariant.secondary => Border.all(color: context.gymPrimary),
      GymButtonVariant.ghost => Border.all(color: context.gymBorder),
      _ => null,
    };
  }

  TextStyle _textStyle(BuildContext context) {
    return GymTypography.button.copyWith(color: _foregroundColor(context));
  }
}
