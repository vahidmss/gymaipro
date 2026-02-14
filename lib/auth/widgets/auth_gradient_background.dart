import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Shared gradient background widget for auth screens
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: _buildGradient(context, isDark),
          ),
        ),
        if (!isDark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    AppTheme.lightGradientStart.withValues(alpha: 0.12),
                    Colors.transparent,
                    AppTheme.lightGoldGradient.withValues(alpha: 0.08),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
      ],
    );
  }

  LinearGradient _buildGradient(BuildContext context, bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.backgroundColor,
          AppTheme.darkGold.withValues(alpha: 0.25),
          context.backgroundColor.withValues(alpha: 0.98),
          AppTheme.goldColor.withValues(alpha: 0.18),
          AppTheme.darkGold.withValues(alpha: 0.15),
          context.backgroundColor,
          AppTheme.goldColor.withValues(alpha: 0.08),
        ],
        stops: const [0.0, 0.2, 0.4, 0.55, 0.7, 0.85, 1.0],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.lightGradientStart.withValues(alpha: 0.35),
          AppTheme.lightCardColor.withValues(alpha: 0.98),
          AppTheme.lightGoldGradient.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.95),
          AppTheme.lightGradientEnd.withValues(alpha: 0.25),
          AppTheme.lightCardColor.withValues(alpha: 0.97),
          AppTheme.lightGoldGradient.withValues(alpha: 0.15),
        ],
        stops: const [0.0, 0.2, 0.4, 0.55, 0.7, 0.85, 1.0],
      );
    }
  }
}
