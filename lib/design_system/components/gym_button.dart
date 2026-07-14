import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
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
              color: _foregroundColor(),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: _foregroundColor()),
                const SizedBox(width: GymSpacing.sm),
              ],
              Text(label, style: _textStyle()),
            ],
          );

    final button = Material(
      color: _backgroundColor(),
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
            border: _border(),
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

  Color _backgroundColor() {
    if (!_enabled) return GymColors.neutral800;
    return switch (variant) {
      GymButtonVariant.primary => GymColors.primary,
      GymButtonVariant.secondary => GymColors.surface,
      GymButtonVariant.ghost => Colors.transparent,
      GymButtonVariant.danger => GymColors.dangerMuted,
    };
  }

  Color _foregroundColor() {
    if (!_enabled) return GymColors.textDisabled;
    return switch (variant) {
      GymButtonVariant.primary => GymColors.onPrimary,
      GymButtonVariant.secondary => GymColors.primary,
      GymButtonVariant.ghost => GymColors.primary,
      GymButtonVariant.danger => GymColors.danger,
    };
  }

  Border? _border() {
    if (!_enabled) {
      return Border.all(color: GymColors.borderSubtle);
    }
    return switch (variant) {
      GymButtonVariant.secondary => Border.all(color: GymColors.primary),
      GymButtonVariant.ghost => Border.all(color: GymColors.border),
      _ => null,
    };
  }

  TextStyle _textStyle() {
    return GymTypography.button.copyWith(color: _foregroundColor());
  }
}
