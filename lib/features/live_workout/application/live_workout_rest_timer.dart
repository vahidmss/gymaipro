import 'dart:async';

import 'package:flutter/foundation.dart';

/// Real rest timer with pause/resume/skip/extend controls.
class LiveWorkoutRestTimer {
  LiveWorkoutRestTimer({VoidCallback? onTick}) : _onTick = onTick;

  final VoidCallback? _onTick;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _active = false;
  bool _paused = false;

  bool get isActive => _active;
  bool get isPaused => _paused;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;

  void start({required int seconds}) {
    _timer?.cancel();
    _remainingSeconds = seconds.clamp(0, 3600);
    _totalSeconds = _remainingSeconds;
    _active = _remainingSeconds > 0;
    _paused = false;
    if (!_active) {
      _onTick?.call();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _onTick?.call();
  }

  void pause() {
    if (!_active || _paused) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
    _onTick?.call();
  }

  void resume() {
    if (!_active || !_paused) return;
    _paused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _onTick?.call();
  }

  void skip() => stop();

  void extend(int extraSeconds) {
    if (extraSeconds <= 0) return;
    _remainingSeconds += extraSeconds;
    _totalSeconds += extraSeconds;
    if (!_active) {
      start(seconds: _remainingSeconds);
      return;
    }
    if (_paused) {
      resume();
    }
    _onTick?.call();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _active = false;
    _paused = false;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    _onTick?.call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_remainingSeconds <= 0) {
      stop();
      return;
    }
    _remainingSeconds -= 1;
    _onTick?.call();
    if (_remainingSeconds <= 0) {
      stop();
    }
  }
}
