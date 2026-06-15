import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_format.dart';

/// پخش صدا — ظاهر تلگرام (ردیف افقی: دکمه پلی · موج · زمان)
class TrainerChannelAudioPlayer extends StatefulWidget {
  const TrainerChannelAudioPlayer({
    required this.url,
    required this.mode,
    this.durationSeconds,
    this.title,
    super.key,
  });

  final String url;
  final TrainerChannelAudioPlayerMode mode;
  final int? durationSeconds;
  final String? title;

  @override
  State<TrainerChannelAudioPlayer> createState() =>
      _TrainerChannelAudioPlayerState();
}

enum TrainerChannelAudioPlayerMode { voice, audioFile }

class _TrainerChannelAudioPlayerState
    extends State<TrainerChannelAudioPlayer> {
  AudioPlayer? _player;
  bool _listenersAttached = false;
  final List<StreamSubscription<dynamic>> _playerSubs = [];

  bool _playing = false;
  bool _loading = false;
  bool _seeking = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _speed = 1;

  static const _speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
  static const _barCount = 30;
  static final _rng = math.Random(42);
  static final _barHeights = List.generate(
    _barCount,
    (i) => 0.25 + _rng.nextDouble() * 0.75,
  );

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      _totalDuration = Duration(seconds: widget.durationSeconds!);
    }
  }

  AudioPlayer _ensurePlayer() {
    if (_player != null) return _player!;
    final p = AudioPlayer();
    _player = p;
    if (!_listenersAttached) {
      _listenersAttached = true;
      _playerSubs.add(p.onPlayerStateChanged.listen((s) {
        if (!mounted) return;
        setState(() {
          _playing = s == PlayerState.playing;
          if (s == PlayerState.completed) _position = Duration.zero;
        });
      }));
      _playerSubs.add(p.onPositionChanged.listen((pos) {
        if (!mounted || _seeking) return;
        setState(() => _position = pos);
      }));
      _playerSubs.add(p.onDurationChanged.listen((d) {
        if (!mounted || d <= Duration.zero) return;
        setState(() => _totalDuration = d);
      }));
    }
    return p;
  }

  @override
  void dispose() {
    for (final sub in _playerSubs) {
      sub.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  Duration get _total =>
      _totalDuration > Duration.zero
          ? _totalDuration
          : widget.durationSeconds != null
              ? Duration(seconds: widget.durationSeconds!)
              : Duration.zero;

  double get _progress {
    if (_total.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> _toggle() async {
    final player = _ensurePlayer();
    if (_playing) {
      await player.pause();
    } else {
      setState(() => _loading = true);
      try {
        await player.play(UrlSource(widget.url));
        await player.setPlaybackRate(_speed);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _seekTo(double fraction) async {
    final t = _total;
    if (t <= Duration.zero) return;
    final target =
        Duration(milliseconds: (fraction * t.inMilliseconds).round());
    setState(() {
      _position = target;
      _seeking = false;
    });
    await _ensurePlayer().seek(target);
  }

  Future<void> _skip(int seconds) async {
    final player = _ensurePlayer();
    var t = _position + Duration(seconds: seconds);
    if (t < Duration.zero) t = Duration.zero;
    if (_total > Duration.zero && t > _total) t = _total;
    setState(() => _position = t);
    await player.seek(t);
    if (!_playing) {
      setState(() => _loading = true);
      try {
        await player.play(UrlSource(widget.url));
        await player.setPlaybackRate(_speed);
        await player.seek(t);
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _cycleSpeed() async {
    final idx = (_speeds.indexOf(_speed) + 1) % _speeds.length;
    _speed = _speeds[idx];
    if (_player != null) {
      await _player!.setPlaybackRate(_speed);
    }
    if (mounted) setState(() {});
  }

  String _fmt(Duration d) => formatVoiceDuration(d.inSeconds);

  String get _speedLabel {
    if (_speed == 1.0) return '1×';
    if (_speed == 1.25) return '1.25×';
    if (_speed == 1.5) return '1.5×';
    if (_speed == 2.0) return '2×';
    return '0.5×';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVoice = widget.mode == TrainerChannelAudioPlayerMode.voice;
    const accent = AppTheme.goldColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // دکمه پلی/پاز
              GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _playing
                        ? accent
                        : accent.withValues(alpha: 0.15),
                    border: Border.all(color: accent, width: 1.5),
                  ),
                  child: _loading
                      ? Padding(
                          padding: EdgeInsets.all(12.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _playing ? Colors.white : accent,
                          ),
                        )
                      : Icon(
                          _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: _playing ? Colors.white : accent,
                          size: 26.sp,
                        ),
                ),
              ),
              SizedBox(width: 10.w),

              // موج + نوار پیشرفت
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.mode == TrainerChannelAudioPlayerMode.audioFile &&
                        widget.title != null &&
                        widget.title!.trim().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text(
                          widget.title!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor,
                          ),
                        ),
                      ),

                    // موج + slider یکجا
                    GestureDetector(
                      onHorizontalDragStart: (_) =>
                          setState(() => _seeking = true),
                      onHorizontalDragUpdate: (d) {
                        final box =
                            context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final total = box.size.width;
                        final dx =
                            (d.localPosition.dx / total).clamp(0.0, 1.0);
                        setState(() => _position = Duration(
                              milliseconds:
                                  (dx * (_total.inMilliseconds)).round(),
                            ));
                      },
                      onHorizontalDragEnd: (_) =>
                          _seekTo(_progress),
                      child: SizedBox(
                        height: 28.h,
                        child: CustomPaint(
                          painter: _WaveformPainter(
                            progress: _progress,
                            activeColor: accent,
                            inactiveColor: accent.withValues(alpha: 0.28),
                            barHeights: _barHeights,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(_position),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 10.sp,
                            color: isDark
                                ? Colors.white54
                                : Colors.black45,
                          ),
                        ),
                        Text(
                          _total > Duration.zero
                              ? _fmt(_total)
                              : '--:--',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 10.sp,
                            color: isDark
                                ? Colors.white54
                                : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 6.w),

              // اگر فایل صوتی: دکمه سرعت
              if (!isVoice)
                GestureDetector(
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 7.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: accent.withValues(alpha: 0.12),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _speedLabel,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // دکمه‌های جلو/عقب فقط برای فایل صوتی
          if (!isVoice)
            Padding(
              padding: EdgeInsets.only(top: 4.h, right: 44.w + 10.w),
              child: Row(
                children: [
                  _SkipButton(
                    label: '15−',
                    onTap: () => _skip(-15),
                    accent: accent,
                  ),
                  SizedBox(width: 8.w),
                  _SkipButton(
                    label: '+30',
                    onTap: () => _skip(30),
                    accent: accent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.barHeights,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final List<double> barHeights;

  @override
  void paint(Canvas canvas, Size size) {
    final count = barHeights.length;
    final barW = size.width / (count * 1.6);
    final gap = barW * 0.6;
    final total = barW + gap;
    final activeBars = (progress * count).round();

    for (var i = 0; i < count; i++) {
      final x = i * total + barW / 2;
      final h = barHeights[i] * size.height;
      final top = (size.height - h) / 2;
      final paint = Paint()
        ..color = i < activeBars ? activeColor : inactiveColor
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, top), Offset(x, top + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor;
}
