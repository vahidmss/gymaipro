import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Compact Telegram-style voice bubble player.
/// Single row: play · waveform · duration (no bulky stacked chrome).
class ChatVoiceMessage extends StatefulWidget {
  const ChatVoiceMessage({
    required this.url,
    required this.isMe,
    this.durationSeconds,
    super.key,
  });

  final String url;
  final bool isMe;
  final int? durationSeconds;

  @override
  State<ChatVoiceMessage> createState() => _ChatVoiceMessageState();
}

class _ChatVoiceMessageState extends State<ChatVoiceMessage> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subs = [];

  bool _playing = false;
  bool _loading = false;
  bool _seeking = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  static const _barCount = 28;
  static final _rng = math.Random(7);
  static final _barHeights = List<double>.generate(
    _barCount,
    (_) => 0.28 + _rng.nextDouble() * 0.72,
  );

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      _total = Duration(seconds: widget.durationSeconds!);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    unawaited(_player?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  AudioPlayer _ensurePlayer() {
    if (_player != null) return _player!;
    final p = AudioPlayer();
    _player = p;
    _subs
      ..add(
        p.onPlayerStateChanged.listen((s) {
          if (!mounted) return;
          setState(() {
            _playing = s == PlayerState.playing;
            if (s == PlayerState.completed) {
              _position = Duration.zero;
              _playing = false;
            }
          });
        }),
      )
      ..add(
        p.onPositionChanged.listen((pos) {
          if (!mounted || _seeking) return;
          setState(() => _position = pos);
        }),
      )
      ..add(
        p.onDurationChanged.listen((d) {
          if (!mounted || d <= Duration.zero) return;
          setState(() => _total = d);
        }),
      );
    return p;
  }

  Duration get _effectiveTotal {
    if (_total > Duration.zero) return _total;
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      return Duration(seconds: widget.durationSeconds!);
    }
    return Duration.zero;
  }

  double get _progress {
    final t = _effectiveTotal;
    if (t.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / t.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> _toggle() async {
    final player = _ensurePlayer();
    if (_playing) {
      await player.pause();
      return;
    }
    setState(() => _loading = true);
    try {
      await player.play(UrlSource(widget.url));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seekFraction(double fraction) async {
    final t = _effectiveTotal;
    if (t <= Duration.zero) return;
    final target =
        Duration(milliseconds: (fraction * t.inMilliseconds).round());
    setState(() {
      _position = target;
      _seeking = false;
    });
    await _ensurePlayer().seek(target);
  }

  String _fmt(Duration d) {
    final s = d.inSeconds.clamp(0, 99 * 60);
    final mm = s ~/ 60;
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    // Contrast against gold outgoing bubble / white incoming bubble.
    final onBubble = widget.isMe
        ? AppTheme.onGoldColor
        : context.textColor;
    final playBg = widget.isMe
        ? Colors.black.withValues(alpha: 0.22)
        : AppTheme.goldColor;
    final playIcon = widget.isMe ? AppTheme.onGoldColor : AppTheme.onGoldColor;
    final waveActive = widget.isMe
        ? AppTheme.onGoldColor
        : AppTheme.goldColor;
    final waveIdle = widget.isMe
        ? AppTheme.onGoldColor.withValues(alpha: 0.35)
        : AppTheme.goldColor.withValues(alpha: 0.28);
    final timeColor = widget.isMe
        ? AppTheme.onGoldColor.withValues(alpha: 0.85)
        : context.textSecondary;

    final displayTime = _playing || _position > Duration.zero
        ? _fmt(_position)
        : (_effectiveTotal > Duration.zero
            ? _fmt(_effectiveTotal)
            : '0:00');

    return SizedBox(
      width: 210.w,
      height: 36.h,
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: playBg,
                  border: widget.isMe
                      ? Border.all(
                          color: onBubble.withValues(alpha: 0.35),
                        )
                      : null,
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 14.w,
                          height: 14.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: playIcon,
                          ),
                        )
                      : Icon(
                          _playing ? LucideIcons.pause : LucideIcons.play,
                          size: 16.sp,
                          color: playIcon,
                        ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => setState(() => _seeking = true),
                  onHorizontalDragUpdate: (d) {
                    final w = constraints.maxWidth;
                    if (w <= 0) return;
                    final frac = (d.localPosition.dx / w).clamp(0.0, 1.0);
                    final t = _effectiveTotal;
                    if (t <= Duration.zero) return;
                    setState(() {
                      _position = Duration(
                        milliseconds: (frac * t.inMilliseconds).round(),
                      );
                    });
                  },
                  onHorizontalDragEnd: (_) => unawaited(_seekFraction(_progress)),
                  onTapDown: (d) {
                    final w = constraints.maxWidth;
                    if (w <= 0) return;
                    final frac = (d.localPosition.dx / w).clamp(0.0, 1.0);
                    unawaited(_seekFraction(frac));
                  },
                  child: CustomPaint(
                    painter: _ChatVoiceWavePainter(
                      progress: _progress,
                      activeColor: waveActive,
                      idleColor: waveIdle,
                      barHeights: _barHeights,
                    ),
                    size: Size(constraints.maxWidth, 22.h),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 34.w,
            child: Text(
              displayTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: timeColor,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatVoiceWavePainter extends CustomPainter {
  _ChatVoiceWavePainter({
    required this.progress,
    required this.activeColor,
    required this.idleColor,
    required this.barHeights,
  });

  final double progress;
  final Color activeColor;
  final Color idleColor;
  final List<double> barHeights;

  @override
  void paint(Canvas canvas, Size size) {
    final count = barHeights.length;
    final slot = size.width / count;
    final barW = math.max(2.0, slot * 0.55);
    final activeBars = (progress * count).round();

    for (var i = 0; i < count; i++) {
      final h = math.max(4.0, barHeights[i] * size.height);
      final x = i * slot + slot / 2;
      final top = (size.height - h) / 2;
      final paint = Paint()
        ..color = i < activeBars ? activeColor : idleColor
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, top), Offset(x, top + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChatVoiceWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.idleColor != idleColor;
  }
}
