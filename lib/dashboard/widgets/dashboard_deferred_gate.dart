import 'dart:async';

import 'package:flutter/material.dart';

/// Placeholder until [ready] is true (scroll or fallback timer).
class DashboardDeferredGate extends StatelessWidget {
  const DashboardDeferredGate({
    required this.ready,
    required this.placeholderHeight,
    required this.child,
    super.key,
  });

  final bool ready;
  final double placeholderHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return SizedBox(height: placeholderHeight);
    }
    return RepaintBoundary(child: child);
  }
}

/// Tracks scroll + fallback timer to reveal below-the-fold dashboard sections.
class DashboardDeferredReveal extends ChangeNotifier {
  DashboardDeferredReveal({
    required ScrollController scrollController,
    this.scrollRevealOffset = 64,
    this.fallbackDelay = const Duration(milliseconds: 2200),
  }) : _scrollController = scrollController {
    _scrollListener = () {
      if (_ready) return;
      if (!_scrollController.hasClients) return;
      if (_scrollController.offset >= scrollRevealOffset) {
        _markReady();
      }
    };
    _scrollController.addListener(_scrollListener);
    _fallbackTimer = Timer(fallbackDelay, _markReady);
  }

  final ScrollController _scrollController;
  final double scrollRevealOffset;
  final Duration fallbackDelay;

  late final VoidCallback _scrollListener;
  Timer? _fallbackTimer;
  bool _ready = false;

  bool get ready => _ready;

  void _markReady() {
    if (_ready) return;
    _ready = true;
    _fallbackTimer?.cancel();
    notifyListeners();
  }

  void forceReveal() => _markReady();

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }
}
