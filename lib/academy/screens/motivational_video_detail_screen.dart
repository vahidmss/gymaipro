import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/motivational_video.dart';
import 'package:gymaipro/academy/services/motivational_video_service.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

class MotivationalVideoDetailScreen extends StatefulWidget {
  const MotivationalVideoDetailScreen({required this.video, super.key});

  final MotivationalVideo video;

  @override
  State<MotivationalVideoDetailScreen> createState() =>
      _MotivationalVideoDetailScreenState();
}

class _MotivationalVideoDetailScreenState
    extends State<MotivationalVideoDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    await MotivationalVideoService.incrementViewCount(widget.video.id);
  }

  Future<void> _initializeVideo() async {
    setState(() => _isLoading = true);

    try {
      final videoCacheService = VideoCacheService();
      final cachedPath = await videoCacheService.getCachedVideoPath(
        widget.video.videoUrl,
      );

      VideoPlayerController controller;
      if (cachedPath != null) {
        controller = VideoPlayerController.file(File(cachedPath));
      } else {
        controller = VideoPlayerController.network(widget.video.videoUrl);
      }

      _videoPlayerController = controller;
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.goldColor,
          handleColor: AppTheme.goldColor,
          backgroundColor: Colors.grey[800]!,
          bufferedColor: AppTheme.goldColor.withValues(alpha: 0.3),
        ),
        placeholder: const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor),
          ),
        ),
        autoInitialize: true,
        autoPlay: true,
      );

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگیری ویدیو: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        title: Text(
          'ویدیو انگیزشی',
          style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player
            if (_isLoading)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  ),
                ),
              )
            else if (_isVideoInitialized && _chewieController != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Chewie(controller: _chewieController!),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 48.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'خطا در بارگیری ویدیو',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.sp,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Video Info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 16.sp,
                        color: AppTheme.goldColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        widget.video.formattedDuration,
                        style: AppTheme.bodyStyle.copyWith(fontSize: 12.sp),
                      ),
                      SizedBox(width: 16.w),
                      if (widget.video.viewCount != null) ...[
                        Icon(
                          LucideIcons.eye,
                          size: 16.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${widget.video.viewCount} بازدید',
                          style: AppTheme.bodyStyle.copyWith(fontSize: 12.sp),
                        ),
                      ],
                    ],
                  ),
                  if (widget.video.description != null &&
                      widget.video.description!.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      widget.video.description!,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 14.sp,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

