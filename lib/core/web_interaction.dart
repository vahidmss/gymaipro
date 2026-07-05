import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Web / desktop pointer UX — swipe gestures conflict with scroll and browser nav.
abstract final class WebInteraction {
  static bool get prefersTapNavigation => kIsWeb;

  /// Tab bars already have explicit taps — disable horizontal swipe between tabs.
  static ScrollPhysics get tabBarViewPhysics => prefersTapNavigation
      ? const NeverScrollableScrollPhysics()
      : const ClampingScrollPhysics();

  /// Nested carousels inside vertical scroll — use dots/arrows on web instead of drag.
  static ScrollPhysics get pageViewPhysics => prefersTapNavigation
      ? const NeverScrollableScrollPhysics()
      : const PageScrollPhysics();

  static bool get allowSwipeToDismiss => !prefersTapNavigation;

  static bool get allowCarouselAutoPlay => !prefersTapNavigation;

  /// Vertical scroll on web — Clamping avoids rubber-band fighting the browser.
  static ScrollPhysics get listScrollPhysics => prefersTapNavigation
      ? const ClampingScrollPhysics()
      : const BouncingScrollPhysics();

  static ScrollPhysics get alwaysScrollableListPhysics =>
      AlwaysScrollableScrollPhysics(parent: listScrollPhysics);

  /// Browser back / trackpad horizontal scroll should not fight nested PageViews.
  static ScrollBehavior get scrollBehavior => prefersTapNavigation
      ? const MaterialScrollBehavior().copyWith(
          scrollbars: true,
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
            PointerDeviceKind.touch,
          },
        )
      : const MaterialScrollBehavior();
}
