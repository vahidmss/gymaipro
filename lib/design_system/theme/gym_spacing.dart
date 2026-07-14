import 'package:flutter/material.dart';

/// GymAI spacing tokens.
abstract final class GymSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets page = EdgeInsets.fromLTRB(lg, xxl, lg, massive);
  static const EdgeInsets card = EdgeInsets.all(xl);

  static SizedBox gapXs = const SizedBox(width: xs, height: xs);
  static SizedBox gapSm = const SizedBox(width: sm, height: sm);
  static SizedBox gapMd = const SizedBox(width: md, height: md);
  static SizedBox gapLg = const SizedBox(width: lg, height: lg);
  static SizedBox gapXl = const SizedBox(width: xl, height: xl);
  static SizedBox gapXxl = const SizedBox(width: xxl, height: xxl);
}
