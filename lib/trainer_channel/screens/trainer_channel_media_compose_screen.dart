import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/constants/trainer_channel_constants.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:gymaipro/trainer_channel/services/trainer_channel_upload_service.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_media_utils.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_composer_payload.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// صفحه ارسال عکس/ویدیو — شبیه تلگرام (تمام‌صفحه · برش · کپشن پایین)
class TrainerChannelMediaComposeScreen extends StatefulWidget {
  const TrainerChannelMediaComposeScreen({
    required this.file,
    required this.isVideo,
    required this.uploadService,
    required this.onPublished,
    super.key,
  });

  final XFile file;
  final bool isVideo;
  final TrainerChannelUploadService uploadService;
  final Future<void> Function(TrainerChannelComposerPayload payload)
      onPublished;

  @override
  State<TrainerChannelMediaComposeScreen> createState() =>
      _TrainerChannelMediaComposeScreenState();
}

class _TrainerChannelMediaComposeScreenState
    extends State<TrainerChannelMediaComposeScreen> {
  final _captionController = TextEditingController();
  final _captionFocus = FocusNode();

  File? _imageFile;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _sending = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.isVideo) {
      await _initVideo();
    } else {
      final local = await TrainerChannelMediaUtils.ensureLocalFile(widget.file);
      if (mounted) setState(() => _imageFile = local);
    }
    // کیبورد با لمس فیلد کپشن باز می‌شود — بدون فوکوس خودکار
  }

  Future<void> _initVideo() async {
    try {
      final local = await TrainerChannelMediaUtils.ensureLocalFile(widget.file);
      final size = await local.length();
      const maxBytes =
          TrainerChannelConstants.maxVideoSizeMb * 1024 * 1024;
      if (size > maxBytes) {
        if (!mounted) return;
        _showError(
          'ویدیو بزرگ است (حداکثر ${TrainerChannelConstants.maxVideoSizeMb} مگابایت)',
        );
        Navigator.pop(context);
        return;
      }
      final c = VideoPlayerController.file(local);
      await c.initialize();
      await c.pause();
      const maxSec = TrainerChannelConstants.maxVideoPickMinutes * 60;
      if (c.value.duration.inSeconds > maxSec) {
        c.dispose();
        if (!mounted) return;
        _showError(
          'ویدیو حداکثر ${TrainerChannelConstants.maxVideoPickMinutes} دقیقه باشد',
        );
        Navigator.pop(context);
        return;
      }
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _videoController = c;
        _videoReady = true;
      });
    } catch (_) {
      if (mounted) {
        _showError('خطا در بارگذاری ویدیو');
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _cropImage() async {
    final file = _imageFile;
    if (file == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      maxWidth: 2048,
      maxHeight: 2048,
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'برش عکس',
          toolbarColor: const Color(0xFF0E0E0E),
          toolbarWidgetColor: Colors.white,
          backgroundColor: const Color(0xFF0E0E0E),
          activeControlsWidgetColor: AppTheme.goldColor,
          cropFrameColor: AppTheme.goldColor,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.65),
          statusBarColor: const Color(0xFF0E0E0E),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'برش عکس',
          doneButtonTitle: 'تأیید',
          cancelButtonTitle: 'انصراف',
        ),
        WebUiSettings(context: context),
      ],
    );

    if (cropped == null || !mounted) return;
    setState(() => _imageFile = File(cropped.path));
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _uploadProgress = 0;
    });

    final caption = _captionController.text.trim();
    final captionOrNull = caption.isEmpty ? null : caption;

    try {
      if (widget.isVideo) {
        final local = await TrainerChannelMediaUtils.ensureLocalFile(widget.file);
        final url = await widget.uploadService.uploadVideo(
          XFile(local.path),
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        await widget.onPublished(
          TrainerChannelComposerPayload(
            contentType: TrainerChannelContentType.video,
            textContent: captionOrNull,
            mediaUrl: url,
          ),
        );
      } else {
        final file = _imageFile;
        if (file == null) throw Exception('فایل عکس یافت نشد');
        final url = await widget.uploadService.uploadImage(
          XFile(file.path),
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
        await widget.onPublished(
          TrainerChannelComposerPayload(
            contentType: TrainerChannelContentType.image,
            textContent: captionOrNull,
            mediaUrl: url,
          ),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    // مثل تلگرام: عکس تمام‌صفحه می‌ماند، فقط نوار کپشن با کیبورد بالا می‌آید
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        backgroundColor: Colors.black,
        // ui-health: keyboard-inset-ok — caption bar uses viewInsets.bottom manually
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: _TopBar(
                    onClose: _sending ? null : () => Navigator.pop(context),
                    onCrop: !widget.isVideo &&
                            _imageFile != null &&
                            !_sending
                        ? _cropImage
                        : null,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    behavior: HitTestBehavior.opaque,
                    child: _buildPreview(),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboardBottom,
              child: SafeArea(
                top: false,
                child: _CaptionBar(
                  controller: _captionController,
                  focusNode: _captionFocus,
                  sending: _sending,
                  progress: _uploadProgress,
                  onSend: _send,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.isVideo) {
      if (!_videoReady || _videoController == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor),
        );
      }
      return GestureDetector(
        onTap: () {
          setState(() {
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          });
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio == 0
                ? 16 / 9
                : _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                if (!_videoController!.value.isPlaying)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x66000000),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final file = _imageFile;
    if (file == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return InteractiveViewer(
      maxScale: 4,
      child: Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onClose, this.onCrop});
  final VoidCallback? onClose;
  final VoidCallback? onCrop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
          ),
          const Spacer(),
          if (onCrop != null)
            TextButton.icon(
              onPressed: onCrop,
              icon: Icon(Icons.crop_rounded, color: AppTheme.goldColor, size: 22.sp),
              label: Text(
                'برش',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CaptionBar extends StatelessWidget {
  const _CaptionBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.progress,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final double progress;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    // فیلد روشن + متن تیره = خوانایی بالا روی پس‌زمینه تیره (مثل تلگرام)
    const fieldBg = Color(0xFFF4F4F4);
    const textColor = AppTheme.lightTextColor;
    const hintColor = Color(0xFF8A8075);

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xE6000000),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sending)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                color: AppTheme.goldColor,
                backgroundColor: Colors.white24,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Material(
                    color: fieldBg,
                    elevation: 1,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(24.r),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !sending,
                      maxLines: 5,
                      minLines: 1,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      cursorColor: AppTheme.goldColor,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        height: 1.4,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'کپشن بنویسید…',
                        hintTextDirection: TextDirection.rtl,
                        hintStyle: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: hintColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: const BorderSide(
                            color: AppTheme.goldColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Material(
                  color: AppTheme.goldColor,
                  elevation: 2,
                  shadowColor: AppTheme.goldColor.withValues(alpha: 0.4),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: sending ? null : onSend,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: EdgeInsets.all(13.w),
                      child: sending
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.onGoldColor,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: AppTheme.onGoldColor,
                              size: 24.sp,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
