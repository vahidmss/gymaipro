import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_format.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_media_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

/// پیش‌نمایش ویدیو قبل از ارسال (فقط یک ویدیو — پلیر مجاز است)
class TrainerChannelVideoPreview extends StatefulWidget {
  const TrainerChannelVideoPreview({
    required this.file,
    this.onRemove,
    super.key,
  });

  final XFile file;
  final VoidCallback? onRemove;

  @override
  State<TrainerChannelVideoPreview> createState() =>
      _TrainerChannelVideoPreviewState();
}

class _TrainerChannelVideoPreviewState extends State<TrainerChannelVideoPreview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _sizeLabel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final local = await TrainerChannelMediaUtils.ensureLocalFile(widget.file);
      final size = await local.length();
      _sizeLabel = TrainerChannelMediaUtils.formatFileSize(size);
      final c = VideoPlayerController.file(local);
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: AspectRatio(
              aspectRatio: _ready && _controller != null
                  ? (_controller!.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller!.value.aspectRatio)
                  : 16 / 9,
              child: _ready && _controller != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPlayer(_controller!),
                        Center(
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              });
                            },
                            icon: Icon(
                              _controller!.value.isPlaying
                                  ? LucideIcons.pause
                                  : LucideIcons.play,
                              color: Colors.white,
                              size: 40.sp,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldColor,
                      ),
                    ),
            ),
          ),
          if (_sizeLabel != null)
            Positioned(
              left: 8.w,
              bottom: 8.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _sizeLabel!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
            ),
          if (widget.onRemove != null)
            Positioned(
              top: 4.h,
              left: 4.w,
              child: IconButton(
                onPressed: widget.onRemove,
                icon: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.x, color: Colors.white, size: 18.sp),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// بندانگشتی ویدیو در فید — بدون ExoPlayer (فقط با لمس، پلیر باز می‌شود)
class TrainerChannelVideoThumbnail extends StatelessWidget {
  const TrainerChannelVideoThumbnail({
    required this.onTap,
    this.durationSeconds,
    super.key,
  });

  final VoidCallback onTap;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(
              color: Color(0xFF1A2430),
              child: Center(
                child: Icon(
                  Icons.videocam_rounded,
                  color: Colors.white24,
                  size: 48,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black12, Colors.black45],
                ),
              ),
            ),
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x99000000),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
            if (durationSeconds != null && durationSeconds! > 0)
              Positioned(
                bottom: 8,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    formatVoiceDuration(durationSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
