import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/app_feedback_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Telegram/WhatsApp-style composer.
///
/// Voice: hold mic → record; slide left → cancel; release → send.
/// Uses [GestureDetector] long-press (gesture survives rebuilds).
/// No full-screen overlay / no native amplitude stream (those caused ANRs).
class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({
    required this.controller,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    required this.isSending,
    this.onVoiceRecorded,
    this.onEmojiPressed,
    this.voiceEnabled = true,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final VoidCallback onAttachmentPressed;
  final bool isSending;
  final Future<void> Function(File file, int durationSeconds)? onVoiceRecorded;
  final VoidCallback? onEmojiPressed;
  final bool voiceEnabled;

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget>
    with SingleTickerProviderStateMixin {
  static const int _maxVoiceSeconds = 60;
  static const double _cancelDx = -64;

  AudioRecorder? _recorder;
  Timer? _recordTimer;
  late final AnimationController _pulse;

  bool _isRecording = false;
  bool _isStopping = false;
  bool _cancelArmed = false;
  int _recordSeconds = 0;
  String? _recordPath;
  double _slideDx = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant MessageInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordTimer?.cancel();
    _pulse.dispose();
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      unawaited(() async {
        try {
          if (await recorder.isRecording()) {
            await recorder.stop().timeout(const Duration(seconds: 1));
          }
        } catch (_) {
          try {
            await recorder.cancel();
          } catch (_) {}
        }
        recorder.dispose();
      }());
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted && !_isRecording) setState(() {});
  }

  bool get _canSend {
    if (widget.isSending || !widget.controller.isSafe) return false;
    return widget.controller.text.trim().isNotEmpty;
  }

  bool get _voiceAvailable {
    if (kIsWeb || !widget.voiceEnabled) return false;
    return widget.onVoiceRecorded != null;
  }

  bool get _showMic => _voiceAvailable && !_canSend && !widget.isSending;

  AudioRecorder _ensureRecorder() => _recorder ??= AudioRecorder();

  Future<void> _startRecording() async {
    if (_isRecording || _isStopping || widget.isSending) return;

    final recorder = _ensureRecorder();

    try {
      final ok = await recorder.hasPermission();
      if (!ok) {
        _toast('دسترسی میکروفون داده نشد');
        return;
      }
    } catch (_) {
      _toast('میکروفون در دسترس نیست');
      return;
    }

    // Avoid fighting other players / feedback audio session.
    try {
      await AppFeedbackService.instance.silence();
    } catch (_) {}

    try {
      if (await recorder.isRecording()) {
        await recorder.stop().timeout(const Duration(seconds: 1));
      }
    } catch (_) {
      try {
        await recorder.cancel();
      } catch (_) {}
    }

    Directory dir;
    try {
      dir = await getTemporaryDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    _recordPath =
        '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _recordPath!,
      );
    } catch (e) {
      debugPrint('MessageInputWidget: start failed: $e');
      _toast('شروع ضبط ممکن نشد');
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    _recordSeconds = 0;
    _cancelArmed = false;
    _slideDx = 0;

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= _maxVoiceSeconds) {
        unawaited(_stopRecording(send: !_cancelArmed));
      }
    });

    if (!mounted) {
      await _safeStop(recorder, delete: true);
      return;
    }

    setState(() => _isRecording = true);
    unawaited(_pulse.repeat(reverse: true));
  }

  Future<void> _stopRecording({required bool send}) async {
    if (!_isRecording || _isStopping) return;
    _isStopping = true;
    _recordTimer?.cancel();
    _pulse.stop();
    _pulse.reset();

    final recorder = _recorder;
    final pathHint = _recordPath;
    final seconds = _recordSeconds;
    final shouldSend = send && !_cancelArmed;

    String? path;
    if (recorder != null) {
      try {
        if (await recorder.isRecording().timeout(const Duration(seconds: 1))) {
          path = await recorder.stop().timeout(const Duration(seconds: 2));
        } else {
          path = pathHint;
        }
      } catch (e) {
        debugPrint('MessageInputWidget: stop failed: $e');
        path = pathHint;
        try {
          await recorder.cancel().timeout(const Duration(seconds: 1));
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isStopping = false;
        _cancelArmed = false;
        _slideDx = 0;
        _recordSeconds = 0;
      });
    } else {
      _isStopping = false;
      _isRecording = false;
    }

    final resolved = (path != null && path.isNotEmpty) ? path : pathHint;

    Future<void> deleteQuietly() async {
      try {
        if (resolved != null && resolved.isNotEmpty) {
          final f = File(resolved);
          if (await f.exists()) await f.delete();
        }
      } catch (_) {}
    }

    if (!shouldSend) {
      await deleteQuietly();
      return;
    }

    if (resolved == null || resolved.isEmpty || seconds < 1) {
      await deleteQuietly();
      if (seconds < 1) _toast('ویس خیلی کوتاه بود');
      return;
    }

    final file = File(resolved);
    if (!await file.exists()) {
      _toast('فایل ویس ذخیره نشد');
      return;
    }

    unawaited(HapticFeedback.lightImpact());
    try {
      await widget.onVoiceRecorded?.call(file, seconds);
    } catch (e) {
      debugPrint('MessageInputWidget: upload callback failed: $e');
      _toast(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _safeStop(AudioRecorder recorder, {required bool delete}) async {
    try {
      final p = await recorder.stop().timeout(const Duration(seconds: 1));
      if (delete && p != null) {
        try {
          await File(p).delete();
        } catch (_) {}
      }
    } catch (_) {
      try {
        await recorder.cancel();
      } catch (_) {}
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (!_showMic) return;
    unawaited(_startRecording());
  }

  void _onLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_isRecording) return;
    final dx = details.offsetFromOrigin.dx;
    final armed = dx <= _cancelDx;
    if (armed != _cancelArmed || (dx - _slideDx).abs() > 2) {
      setState(() {
        _slideDx = dx.clamp(-140.0, 0.0);
        if (armed != _cancelArmed) {
          _cancelArmed = armed;
          unawaited(HapticFeedback.selectionClick());
        }
      });
    }
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_isRecording) return;
    unawaited(_stopRecording(send: !_cancelArmed));
  }

  void _onLongPressCancel() {
    if (!_isRecording) return;
    unawaited(_stopRecording(send: false));
  }

  String _formatTimer(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(
            top: BorderSide(
              color: context.separatorColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_isRecording)
              _circleBtn(
                icon: LucideIcons.plus,
                onTap: widget.isSending ? null : widget.onAttachmentPressed,
              ),
            if (!_isRecording) SizedBox(width: 6.w),
            Expanded(
              child: _isRecording
                  ? _buildRecordingPanel(isDark)
                  : _buildTextField(isDark),
            ),
            SizedBox(width: 6.w),
            if (_showMic || _isRecording)
              // GestureDetector MUST stay mounted while recording.
              GestureDetector(
                onLongPressStart: _onLongPressStart,
                onLongPressMoveUpdate: _onLongPressMove,
                onLongPressEnd: _onLongPressEnd,
                onLongPressCancel: _onLongPressCancel,
                child: _buildMicButton(),
              )
            else
              AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: _canSend || widget.isSending ? 1 : 0.4,
                child: _circleBtn(
                  icon: LucideIcons.send,
                  filled: true,
                  loading: widget.isSending,
                  flipSend: true,
                  onTap: _canSend ? widget.onSendPressed : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(bool isDark) {
    return Container(
      constraints: BoxConstraints(minHeight: 44.h, maxHeight: 120.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.22),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: widget.controller.isSafe
                ? TextField(
                    controller: widget.controller,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 15.sp,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText: 'پیام…',
                      hintStyle: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      isDense: true,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    onSubmitted: (_) {
                      if (_canSend) widget.onSendPressed();
                    },
                  )
                : const SizedBox.shrink(),
          ),
          if (widget.onEmojiPressed != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                LucideIcons.smile,
                color: context.textSecondary,
                size: 20.sp,
              ),
              onPressed: widget.onEmojiPressed,
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingPanel(bool isDark) {
    final cancel = _cancelArmed;
    return Transform.translate(
      offset: Offset(_slideDx * 0.35, 0),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: (cancel ? Colors.redAccent : AppTheme.goldColor)
                .withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = _pulse.value;
                return Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: (cancel ? Colors.redAccent : const Color(0xFFE53935))
                        .withValues(alpha: 0.55 + t * 0.45),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
            SizedBox(width: 10.w),
            Text(
              _formatTimer(_recordSeconds),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 15.sp,
                color: context.textColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _MiniWavePainter(
                      progress: _pulse.value,
                      color: cancel ? Colors.redAccent : AppTheme.goldColor,
                    ),
                    size: Size(double.infinity, 22.h),
                  );
                },
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              cancel ? 'لغو' : '← لغو',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: cancel ? Colors.redAccent : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    final recording = _isRecording;
    final cancel = _cancelArmed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: recording ? 56.w : 44.w,
      height: recording ? 56.w : 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: cancel
              ? [Colors.redAccent, Colors.red.shade700]
              : context.goldGradientColors,
        ),
        boxShadow: recording
            ? [
                BoxShadow(
                  color: (cancel ? Colors.redAccent : AppTheme.goldColor)
                      .withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        cancel ? LucideIcons.x : LucideIcons.mic,
        color: AppTheme.onGoldColor,
        size: recording ? 24.sp : 20.sp,
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    VoidCallback? onTap,
    bool filled = false,
    bool loading = false,
    bool flipSend = false,
  }) {
    Widget child = loading
        ? SizedBox(
            width: 18.w,
            height: 18.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: filled ? AppTheme.onGoldColor : AppTheme.goldColor,
            ),
          )
        : Icon(
            icon,
            color: filled ? AppTheme.onGoldColor : AppTheme.goldColor,
            size: 20.sp,
          );
    if (flipSend && !loading) {
      child = Transform.flip(flipX: true, child: child);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Ink(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: filled
                ? LinearGradient(colors: context.goldGradientColors)
                : null,
            color: filled ? null : context.backgroundColor,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _MiniWavePainter extends CustomPainter {
  _MiniWavePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const bars = 16;
    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final phase = (i / bars) * math.pi * 2;
      final h = (0.25 + 0.75 * ((math.sin(phase + progress * math.pi * 2) + 1) / 2)) *
          size.height;
      final x = gap * i + gap / 2;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
