import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/theme/trainer_channel_theme.dart';
import 'package:gymaipro/trainer_channel/constants/trainer_channel_constants.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_composer_payload.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:gymaipro/trainer_channel/screens/trainer_channel_media_compose_screen.dart';
import 'package:gymaipro/trainer_channel/services/trainer_channel_upload_service.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_format.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_media_utils.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_voice_waveform.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';

/// نوار ارسال کانال — مثل تلگرام (نگه‌داشتن میکروفون · یک گزینه ویدیو)
class TrainerChannelComposeBar extends StatefulWidget {
  const TrainerChannelComposeBar({
    required this.uploadService,
    required this.remainingToday,
    required this.onPublished,
    super.key,
  });

  final TrainerChannelUploadService uploadService;
  final int remainingToday;
  final Future<void> Function(TrainerChannelComposerPayload payload) onPublished;

  @override
  State<TrainerChannelComposeBar> createState() =>
      _TrainerChannelComposeBarState();
}

enum _DraftKind { none, audioFile }

class _TrainerChannelComposeBarState extends State<TrainerChannelComposeBar> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  _DraftKind _draft = _DraftKind.none;
  File? _audioFile;
  String? _audioFileName;
  bool _hasText = false;
  bool _sending = false;
  double _uploadProgress = 0;

  // ضبط صدا
  bool _isRecording = false;
  bool _isStoppingRecord = false;
  bool _cancelSlide = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  Timer? _holdDelayTimer;
  Offset? _recordStartPos;
  String? _recordPath;
  OverlayEntry? _recordOverlay;
  StreamSubscription<Amplitude>? _amplitudeSub;
  final List<double> _waveLevels =
      List<double>.filled(28, 0.12, growable: true);

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _holdDelayTimer?.cancel();
    _recordTimer?.cancel();
    _amplitudeSub?.cancel();
    _removeRecordOverlay();
    unawaited(_forceStopRecorder());
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _forceStopRecorder() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      try {
        await _recorder.cancel();
      } catch (_) {}
    }
  }

  /// مثل تلگرام: یک‌ضرب گالری (عکس + ویدیو)
  Future<void> _openGallery() async {
    if (_sending || widget.remainingToday <= 0) return;
    try {
      final media = await _picker.pickMedia();
      if (media == null || !mounted) return;

      final path = media.path.toLowerCase();
      final isVideo = path.endsWith('.mp4') ||
          path.endsWith('.mov') ||
          path.endsWith('.mkv') ||
          path.endsWith('.webm') ||
          path.endsWith('.avi') ||
          (media.mimeType?.startsWith('video/') ?? false);

      await Navigator.of(context).push<void>(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          pageBuilder: (_, __, ___) => TrainerChannelMediaComposeScreen(
            file: media,
            isVideo: isVideo,
            uploadService: widget.uploadService,
            onPublished: widget.onPublished,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      _snack('خطا در باز کردن گالری');
    }
  }

  /// نگه‌داشتن دکمه پیوست = فایل صوتی (پادکست)
  Future<void> _openAudioPicker() async {
    if (_sending || widget.remainingToday <= 0) return;
    await _pickAudioFile();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final path = picked.path;
      if (path == null || path.isEmpty) {
        _snack('مسیر فایل نامعتبر است');
        return;
      }
      final file = File(path);
      final size = await file.length();
      const maxBytes =
          TrainerChannelConstants.maxAudioFileSizeMb * 1024 * 1024;
      if (size > maxBytes) {
        _snack(
          'فایل بزرگ است (حداکثر ${TrainerChannelConstants.maxAudioFileSizeMb} مگابایت)',
        );
        return;
      }
      setState(() {
        _draft = _DraftKind.audioFile;
        _audioFile = file;
        _audioFileName = picked.name;
      });
    } catch (e) {
      _snack('خطا در انتخاب فایل صوتی');
    }
  }

  void _clearDraft() {
    setState(() {
      _draft = _DraftKind.none;
      _audioFile = null;
      _audioFileName = null;
    });
  }

  void _onMicPointerDown(PointerDownEvent e) {
    if (_sending || widget.remainingToday <= 0 || _isRecording) return;
    _recordStartPos = e.position;
    _holdDelayTimer?.cancel();
    _holdDelayTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted && !_isRecording) {
        unawaited(_beginRecording());
      }
    });
  }

  void _onMicPointerUp(PointerUpEvent e) {
    _holdDelayTimer?.cancel();
    if (_isRecording) {
      unawaited(_finishRecording(send: !_cancelSlide));
    }
  }

  void _onMicPointerCancel(PointerCancelEvent e) {
    _holdDelayTimer?.cancel();
    if (_isRecording) {
      unawaited(_finishRecording(send: false));
    }
  }

  void _onOverlayPointerMove(PointerMoveEvent e) {
    if (!_isRecording || _recordStartPos == null) return;
    final dx = e.position.dx - _recordStartPos!.dx;
    final shouldCancel = dx < -80;
    if (shouldCancel != _cancelSlide) {
      setState(() => _cancelSlide = shouldCancel);
      _recordOverlay?.markNeedsBuild();
      if (shouldCancel) unawaited(HapticFeedback.lightImpact());
    }
  }

  Future<void> _beginRecording() async {
    if (_isRecording || _sending) return;
    if (!await _recorder.hasPermission()) {
      _snack('دسترسی میکروفون داده نشد');
      return;
    }
    await _forceStopRecorder();

    unawaited(HapticFeedback.mediumImpact());
    _recordPath =
        '${Directory.systemTemp.path}/ch_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(
          
        ),
        path: _recordPath!,
      );
    } catch (e) {
      _snack('شروع ضبط ممکن نشد');
      return;
    }

    _recordSeconds = 0;
    _cancelSlide = false;
    for (var i = 0; i < _waveLevels.length; i++) {
      _waveLevels[i] = 0.1;
    }

    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
      _recordOverlay?.markNeedsBuild();
    });

    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
      if (!mounted) return;
      final db = amp.current;
      final norm = ((db + 45) / 45).clamp(0.0, 1.0);
      setState(() {
        _waveLevels.removeAt(0);
        _waveLevels.add(norm);
      });
      _recordOverlay?.markNeedsBuild();
    });

    setState(() => _isRecording = true);
    _insertRecordOverlay();
  }

  void _insertRecordOverlay() {
    _removeRecordOverlay();
    final overlay = Overlay.of(context, rootOverlay: true);
    _recordOverlay = OverlayEntry(
      builder: (ctx) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerUp: (_) {
          unawaited(_finishRecording(send: !_cancelSlide));
        },
        onPointerCancel: (_) {
          unawaited(_finishRecording(send: false));
        },
        onPointerMove: _onOverlayPointerMove,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.black26),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                elevation: 12,
                color: Theme.of(context).cardColor,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TrainerChannelVoiceWaveform(
                          levels: _waveLevels,
                          activeColor:
                              _cancelSlide ? Colors.red : AppTheme.goldColor,
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.arrowLeft,
                              color: _cancelSlide
                                  ? Colors.red
                                  : AppTheme.lightTextSecondary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _cancelSlide
                                    ? 'رها کنید — لغو'
                                    : '← بکشید برای لغو · رها کنید برای ارسال',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _cancelSlide ? Colors.red : null,
                                ),
                              ),
                            ),
                            _RecordingTimerBadge(seconds: _recordSeconds),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_recordOverlay!);
  }

  void _removeRecordOverlay() {
    _recordOverlay?.remove();
    _recordOverlay = null;
  }

  Future<void> _finishRecording({required bool send}) async {
    if (!_isRecording || _isStoppingRecord) return;
    _isStoppingRecord = true;
    _holdDelayTimer?.cancel();
    _recordTimer?.cancel();
    _amplitudeSub?.cancel();
    _removeRecordOverlay();

    String? path;
    try {
      if (await _recorder.isRecording()) {
        path = await _recorder.stop();
      }
    } catch (_) {
      try {
        await _recorder.cancel();
      } catch (_) {}
    }

    final seconds = _recordSeconds;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _cancelSlide = false;
        _isStoppingRecord = false;
      });
    } else {
      _isStoppingRecord = false;
    }

    if (!send || path == null || path.isEmpty) {
      if (path != null && path.isNotEmpty) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      return;
    }

    if (seconds < 1) {
      _snack('خیلی کوتاه بود');
      try {
        await File(path).delete();
      } catch (_) {}
      return;
    }

    await _publishVoice(XFile(path), seconds);
  }

  Future<void> _publishVoice(XFile file, int seconds) async {
    setState(() {
      _sending = true;
      _uploadProgress = 0;
    });
    try {
      final url = await widget.uploadService.uploadVoice(
        file,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      await widget.onPublished(
        TrainerChannelComposerPayload(
          contentType: TrainerChannelContentType.voice,
          mediaUrl: url,
          mediaDurationSeconds: seconds,
        ),
      );
      if (mounted) _snack('پیام صوتی منتشر شد');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<void> _send() async {
    if (_sending || widget.remainingToday <= 0) return;
    final text = _textController.text.trim();
    if (_draft == _DraftKind.none && text.isEmpty) return;

    final draft = _draft;
    final audioFile = _audioFile;

    // clear input immediately so it feels instant (like Telegram)
    _textController.clear();
    _clearDraft();
    setState(() {
      _sending = true;
      _uploadProgress = 0;
    });

    try {
      TrainerChannelComposerPayload payload;
      switch (draft) {
        case _DraftKind.none:
          payload = TrainerChannelComposerPayload(
            contentType: TrainerChannelContentType.text,
            textContent: text,
          );
        case _DraftKind.audioFile:
          if (audioFile == null) throw Exception('فایل صوتی انتخاب نشده');
          final duration =
              await TrainerChannelMediaUtils.readAudioDurationSeconds(audioFile);
          final url = await widget.uploadService.uploadAudioFile(
            audioFile,
            onProgress: (p) {
              if (mounted) setState(() => _uploadProgress = p);
            },
          );
          payload = TrainerChannelComposerPayload(
            contentType: TrainerChannelContentType.audio,
            textContent: text.isEmpty ? null : text,
            mediaUrl: url,
            mediaDurationSeconds: duration,
          );
      }

      await widget.onPublished(payload);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = TrainerChannelTheme.composeBarBackground(isDark);

    final showSend = _hasText || _draft != _DraftKind.none;

    return Material(
      color: barBg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // نوار پیشرفت آپلود — نازک بالای نوار
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _sending
                  ? LinearProgressIndicator(
                      key: const ValueKey('uploading'),
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      color: AppTheme.goldColor,
                      backgroundColor:
                          AppTheme.goldColor.withValues(alpha: 0.18),
                      minHeight: 2.5,
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
            // سقف روز
            if (widget.remainingToday <= 0)
              Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
                color: Colors.orange.withValues(alpha: 0.12),
                child: Text(
                  'سقف امروز پر شده — فردا ادامه دهید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            if (_draft == _DraftKind.audioFile && _audioFileName != null)
              _AudioFileDraftChip(
                name: _audioFileName!,
                onRemove: _clearDraft,
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 6.h, 6.w, 6.h),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onLongPress: _openAudioPicker,
                      child: IconButton(
                        onPressed: _openGallery,
                        tooltip: 'گالری · نگه‌داشتن = فایل صوتی',
                        icon: Icon(
                          Icons.add_circle_outline_rounded,
                          color: isDark
                              ? Colors.white70
                              : Colors.black54,
                          size: 28.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(maxHeight: 120.h),
                        decoration: BoxDecoration(
                          color: TrainerChannelTheme.composeFieldBackground(
                              isDark),
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: 5,
                          minLines: 1,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: _draft == _DraftKind.audioFile
                                ? 'عنوان پادکست (اختیاری)…'
                                : 'پیام…',
                            hintTextDirection: TextDirection.rtl,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            counterText: '',
                          ),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 15.sp,
                            color: isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: showSend
                          ? _CircleButton(
                              color: AppTheme.goldColor,
                              icon: _sending
                                  ? null
                                  : Icon(
                                      Icons.send_rounded,
                                      color: AppTheme.onGoldColor,
                                      size: 22.sp,
                                    ),
                              loading: _sending,
                              onTap:
                                  _sending || widget.remainingToday <= 0
                                      ? null
                                      : _send,
                            )
                          : Listener(
                              key: const ValueKey('mic'),
                              onPointerDown: _onMicPointerDown,
                              onPointerUp: _onMicPointerUp,
                              onPointerCancel: _onMicPointerCancel,
                              child: _CircleButton(
                                color: _isRecording
                                    ? Colors.red.shade500
                                    : AppTheme.goldColor,
                                icon: Icon(
                                  _isRecording
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: _isRecording ? 20.sp : 24.sp,
                                ),
                                onTap: _isRecording
                                    ? () => unawaited(
                                        _finishRecording(send: true))
                                    : null,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.color,
    this.icon,
    this.loading = false,
    this.onTap,
  });

  final Color color;
  final Widget? icon;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(11.w),
          child: loading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.onGoldColor,
                  ),
                )
              : icon ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _RecordingTimerBadge extends StatelessWidget {
  const _RecordingTimerBadge({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.red, size: 9.sp),
          SizedBox(width: 5.w),
          Text(
            formatVoiceDuration(seconds),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioFileDraftChip extends StatelessWidget {
  const _AudioFileDraftChip({required this.name, this.onRemove});
  final String name;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.headphones, color: AppTheme.goldColor, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 20.sp, color: AppTheme.goldColor),
            ),
        ],
      ),
    );
  }
}
