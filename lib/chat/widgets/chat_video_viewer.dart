import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

/// Fullscreen network video for chat attachments.
class ChatVideoViewer extends StatefulWidget {
  const ChatVideoViewer({
    required this.url,
    this.title,
    super.key,
  });

  final String url;
  final String? title;

  @override
  State<ChatVideoViewer> createState() => _ChatVideoViewerState();
}

class _ChatVideoViewerState extends State<ChatVideoViewer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _showUi = true;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    unawaited(_initPlayer());
  }

  Future<void> _initPlayer() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      await _controller.setLooping(true);
      await _controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_ready) return;
    if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showUi = !_showUi),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_failed)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.circleAlert, color: Colors.white54, size: 48.sp),
                    SizedBox(height: 12.h),
                    Text(
                      'پخش ویدیو ممکن نیست',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              )
            else if (!_ready)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            else
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showUi ? 1 : 0,
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white, size: 26),
                        ),
                        Expanded(
                          child: Text(
                            widget.title ?? 'ویدیو',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_ready && !_failed)
                      IconButton(
                        onPressed: () => unawaited(_togglePlay()),
                        iconSize: 56,
                        icon: Icon(
                          _controller.value.isPlaying
                              ? LucideIcons.pause
                              : LucideIcons.play,
                          color: Colors.white,
                        ),
                      ),
                    SizedBox(height: 24.h),
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
