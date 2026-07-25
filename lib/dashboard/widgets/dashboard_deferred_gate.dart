import 'dart:async';

import 'package:flutter/material.dart';

/// Below-the-fold dashboard sections revealed after first paint.
enum DashboardDeferredSection {
  metrics,
  chart,
  heatmap,
  hero,
  rankings,
  discover,
}

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

/// Tracks scroll + fallback timer, then staggers section mounts to avoid
/// a single heavy mount wave. [forceReveal] mounts everything immediately
/// (used by the feature tour).
class DashboardDeferredReveal extends ChangeNotifier {
  DashboardDeferredReveal({
    required ScrollController scrollController,
    this.scrollRevealOffset = 64,
    this.fallbackDelay = const Duration(milliseconds: 2200),
    this.staggerDelay = const Duration(milliseconds: 100),
  }) : _scrollController = scrollController {
    _scrollListener = () {
      if (_started) return;
      if (!_scrollController.hasClients) return;
      if (_scrollController.offset >= scrollRevealOffset) {
        _beginReveal();
      }
    };
    _scrollController.addListener(_scrollListener);
    _fallbackTimer = Timer(fallbackDelay, _beginReveal);
  }

  /// Order: light UI first, Discover last (heaviest network).
  static const List<DashboardDeferredSection> staggerOrder = [
    DashboardDeferredSection.metrics,
    DashboardDeferredSection.chart,
    DashboardDeferredSection.heatmap,
    DashboardDeferredSection.hero,
    DashboardDeferredSection.rankings,
    DashboardDeferredSection.discover,
  ];

  final ScrollController _scrollController;
  final double scrollRevealOffset;
  final Duration fallbackDelay;
  final Duration staggerDelay;

  late final VoidCallback _scrollListener;
  Timer? _fallbackTimer;
  Timer? _staggerTimer;
  bool _started = false;
  bool _forceAll = false;
  int _staggerIndex = 0;
  final Set<DashboardDeferredSection> _readySections = {};

  /// True once reveal has started (compat / announcement scheduling).
  bool get ready => _started;

  bool isSectionReady(DashboardDeferredSection section) =>
      _forceAll || _readySections.contains(section);

  void _beginReveal() {
    if (_started) return;
    _started = true;
    _fallbackTimer?.cancel();
    _revealNextStaggered();
  }

  void _revealNextStaggered() {
    if (_forceAll) return;

    while (_staggerIndex < staggerOrder.length) {
      final section = staggerOrder[_staggerIndex++];
      if (_readySections.add(section)) {
        notifyListeners();
        break;
      }
    }

    if (_staggerIndex < staggerOrder.length && !_forceAll) {
      _staggerTimer?.cancel();
      _staggerTimer = Timer(staggerDelay, _revealNextStaggered);
    }
  }

  void forceReveal() {
    _fallbackTimer?.cancel();
    _staggerTimer?.cancel();
    _started = true;
    _forceAll = true;
    _staggerIndex = staggerOrder.length;
    _readySections.addAll(staggerOrder);
    notifyListeners();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _staggerTimer?.cancel();
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }
}
