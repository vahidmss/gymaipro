import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';

/// RTL back control for AppBars / overlays.
///
/// Safari / iOS PWA system-back is unreliable for Flutter web routes, so
/// every pushed page should expose an in-app back affordance.
class GymBackButton extends StatelessWidget {
  const GymBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.tooltip = 'بازگشت',
  });

  /// Defaults to [Navigator.maybePop] (respects [PopScope]).
  final VoidCallback? onPressed;
  final Color? color;
  final String tooltip;

  /// True when this route can leave via pop / maybePop.
  static bool shouldShow(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route?.impliesAppBarDismissal ?? false) return true;
    return Navigator.of(context).canPop();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(
        GymIcons.back,
        color: color ?? context.gymTextPrimary,
      ),
    );
  }
}
