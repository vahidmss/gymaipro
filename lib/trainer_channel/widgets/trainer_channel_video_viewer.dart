import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/gymaipro_video_controller_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

/// پخش تمام‌صفحه ویدیو کانال (مثل تلگرام)
class TrainerChannelVideoViewer extends StatefulWidget {
  const TrainerChannelVideoViewer({
    required this.url,
    this.caption,
    super.key,
  });

  final String url;
  final String? caption;

  @override
  State<TrainerChannelVideoViewer> createState() =>
      _TrainerChannelVideoViewerState();
}

class _TrainerChannelVideoViewerState extends State<TrainerChannelVideoViewer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _init();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final controller = await GymaiproVideoControllerUtils.createForUrl(
        widget.url,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _videoController = controller;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
      );
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'ویدیو',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator(color: AppTheme.goldColor)
                  : _error != null
                      ? Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.alertCircle,
                                color: Colors.white70,
                                size: 48.sp,
                              ),
                              SizedBox(height: 12.h),
                              const Text(
                                'پخش ویدیو ممکن نشد',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _loading = true;
                                    _error = null;
                                  });
                                  _init();
                                },
                                child: const Text('تلاش مجدد'),
                              ),
                            ],
                          ),
                        )
                      : _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : const SizedBox.shrink(),
            ),
          ),
          if (widget.caption != null && widget.caption!.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              color: Colors.black87,
              child: Text(
                widget.caption!,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: Colors.white,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
