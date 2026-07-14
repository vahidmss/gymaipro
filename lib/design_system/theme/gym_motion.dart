import 'package:flutter/animation.dart';

/// GymAI motion tokens — durations and curves.
abstract final class GymMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration slower = Duration(milliseconds: 480);
  static const Duration shimmer = Duration(milliseconds: 1400);

  // Curves
  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  // Stagger
  static const Duration staggerStep = Duration(milliseconds: 60);
}
