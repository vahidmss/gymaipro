import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Debug/profile frame timing monitor — logs jank without manual DevTools checks.
///
/// Enable in debug by default. In profile/release pass:
/// `--dart-define=PERF_MONITOR=true`
class PerformanceMonitor {
  PerformanceMonitor._();

  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance =>
      _instance ??= PerformanceMonitor._();

  static bool get enabled {
    if (const bool.fromEnvironment('PERF_MONITOR')) return true;
    return kDebugMode;
  }

  static const Duration _jankThreshold = Duration(microseconds: 17000); // ~60fps
  static const Duration _reportInterval = Duration(seconds: 30);

  bool _started = false;
  int _frameCount = 0;
  int _jankCount = 0;
  int _severeJankCount = 0;
  Duration _worstFrame = Duration.zero;
  DateTime _lastReport = DateTime.now();

  void start() {
    if (!enabled || _started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    debugPrint(
      '📊 PerformanceMonitor active '
      '(jank>${_jankThreshold.inMilliseconds}ms, report every ${_reportInterval.inSeconds}s)',
    );
  }

  void stop() {
    if (!_started) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _started = false;
    _emitReport(force: true);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameCount++;
      final build = timing.buildDuration;
      final raster = timing.rasterDuration;
      final total = build + raster;

      if (total > _jankThreshold) {
        _jankCount++;
        if (total > _worstFrame) _worstFrame = total;
      }
      if (total > const Duration(milliseconds: 32)) {
        _severeJankCount++;
      }
    }

    final now = DateTime.now();
    if (now.difference(_lastReport) >= _reportInterval) {
      _emitReport();
      _lastReport = now;
    }
  }

  void _emitReport({bool force = false}) {
    if (_frameCount == 0) return;
    if (!force && _jankCount == 0) {
      _resetCounters();
      return;
    }

    final jankPct = (_jankCount / _frameCount * 100).toStringAsFixed(1);
    debugPrint(
      '📊 Perf $_frameCount frames | jank $_jankCount ($jankPct%) | '
      'severe $_severeJankCount | worst ${_worstFrame.inMilliseconds}ms',
    );
    if (_jankCount > 0) {
      debugPrint(
        '   Tip: DevTools → Performance, or run '
        'dart run test/run_ui_health_audit.dart',
      );
    }
    _resetCounters();
  }

  void _resetCounters() {
    _frameCount = 0;
    _jankCount = 0;
    _severeJankCount = 0;
    _worstFrame = Duration.zero;
  }
}
