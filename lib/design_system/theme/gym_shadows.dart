import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';

/// Dark-theme optimized elevation shadows.
abstract final class GymShadows {
  static List<BoxShadow> small = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.24),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.32),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: GymColors.primary.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> large = <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: GymColors.primary.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow = <BoxShadow>[
    BoxShadow(
      color: GymColors.primary.withValues(alpha: 0.22),
      blurRadius: 18,
      spreadRadius: -2,
    ),
  ];
}
