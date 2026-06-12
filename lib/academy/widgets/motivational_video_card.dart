import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/motivational_video.dart';
import 'dart:async';

import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/services/video_download_manager.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class MotivationalVideoCard extends StatefulWidget {
  const MotivationalVideoCard({
    required this.video,
    required this.index,
    super.key,
  });

  final MotivationalVideo video;
  final int index;

  @override
  State<MotivationalVideoCard> createState() => _MotivationalVideoCardState();
}

class _MotivationalVideoCardState extends State<MotivationalVideoCard> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isCached = false;
  final VideoCacheService _cacheService = VideoCacheService();

  @override
  void initState() {
    super.initState();
    _checkCacheStatus();
  }

  Future<void> _checkCacheStatus() async {
    final cached = await _cacheService.isVideoCached(widget.video.videoUrl);
    if (mounted) {
      setState(() {
        _isCached = cached;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isInitialized && _chewieController != null) {
      if (_isPlaying) {
        _chewieController!.pause();
        setState(() => _isPlaying = false);
      } else {
        _chewieController!.play();
        setState(() => _isPlaying = true);
      }
      return;
    }

    if (!_isInitialized) {
      await _initializeVideo();
    }

    if (_isInitialized && _chewieController != null) {
      _chewieController!.play();
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _initializeVideo() async {
    if (_isLoading || _isInitialized) return;

    setState(() => _isLoading = true);

    try {
      // Dispose previous controllers if any
      _chewieController?.dispose();
      _videoPlayerController?.dispose();
      _chewieController = null;
      _videoPlayerController = null;

      final cachedPath = await _cacheService.getCachedVideoPath(
        widget.video.videoUrl,
      );

      VideoPlayerController controller;
      if (cachedPath != null) {
        controller = VideoPlayerController.file(File(cachedPath));
      } else {
        controller = VideoPlayerController.network(widget.video.videoUrl);
      }

      await controller.initialize();

      _videoPlayerController = controller;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        aspectRatio: controller.value.aspectRatio,
        autoPlay: false,
        looping: false,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.goldColor,
          handleColor: AppTheme.goldColor,
          backgroundColor: Colors.grey[800]!,
          bufferedColor: AppTheme.goldColor.withValues(alpha: 0.3),
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'خطا در بارگیری ویدیو',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Listen to video player state changes
      controller.addListener(() {
        if (mounted) {
          final isPlaying = controller.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() => _isPlaying = isPlaying);
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگیری ویدیو: $e',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  Future<void> _downloadVideo() async {
    final downloadManager = Provider.of<VideoDownloadManager>(
      context,
      listen: false,
    );

    // جلوگیری از دانلود مجدد
    if (downloadManager.isDownloading(widget.video.videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ویدیو در حال دانلود است',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isCached) {
      return;
    }

    // Reset progress before starting
    downloadManager.clearProgress(widget.video.videoUrl);

    try {
      // Start download in background
      downloadManager
          .downloadVideo(widget.video.videoUrl)
          .then((success) {
            if (mounted) {
              if (success) {
                _checkCacheStatus();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('ویدیو با موفقیت دانلود شد'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'خطا در دانلود ویدیو',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          })
          .catchError((Object e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text('خطا در دانلود: $e')),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خطا در شروع دانلود: $e',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'حذف ویدیو',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 18.sp,
            color: context.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این ویدیو را از حافظه حذف کنید؟',
          style: AppTheme.bodyStyle.copyWith(color: context.textColor),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'لغو',
              style: TextStyle(
                color: context.textSecondary,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'حذف',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // اگر ویدیو در حال پخش است، آن را متوقف کن
        if (_isInitialized && _chewieController != null) {
          _chewieController!.pause();
          _chewieController!.dispose();
          _chewieController = null;
        }
        if (_videoPlayerController != null) {
          _videoPlayerController!.dispose();
          _videoPlayerController = null;
        }
        if (mounted) {
          setState(() {
            _isInitialized = false;
            _isPlaying = false;
          });
        }

        final success = await _cacheService.deleteCachedVideo(
          widget.video.videoUrl,
        );

        if (mounted) {
          // بررسی مجدد وضعیت کش
          final stillCached = await _cacheService.isVideoCached(
            widget.video.videoUrl,
          );

          setState(() {
            _isCached = stillCached;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ویدیو با موفقیت حذف شد',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (!stillCached) {
            // اگر واقعاً حذف شده اما success false بود
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ویدیو حذف شد',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'خطا در حذف ویدیو',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطا در حذف: $e',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<VideoDownloadManager>(
      builder: (context, downloadManager, child) {
        final isDownloading = downloadManager.isDownloading(
          widget.video.videoUrl,
        );
        final downloadProgress = downloadManager.getProgress(
          widget.video.videoUrl,
        );

        // اگر دانلود کامل شد، وضعیت کش را بررسی کن
        if (!isDownloading && downloadProgress >= 1.0 && !_isCached) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkCacheStatus();
          });
        }

        return _buildCard(context, isDark, isDownloading, downloadProgress);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isDark,
    bool isDownloading,
    double downloadProgress,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.goldGradientColors[0].withValues(alpha: 0.15),
                  context.cardColor,
                  context.goldGradientColors[1].withValues(alpha: 0.1),
                ],
              ),
        color: isDark ? context.cardColor : null,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.lightTextColor.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player or Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isInitialized && _chewieController != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                          ),
                          child: Chewie(controller: _chewieController!),
                        )
                      : Image.network(
                          widget.video.thumbnailUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.black26,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.black26,
                            child: const Icon(
                              LucideIcons.video,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        ),
                ),
              ),
              // Play/Pause Button Overlay
              if (!_isInitialized || !_isPlaying)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppTheme.goldColor,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.9,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(12.w),
                                child: Icon(
                                  _isPlaying
                                      ? LucideIcons.pause
                                      : LucideIcons.play,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              // Duration Badge
              if (!_isInitialized || !_isPlaying)
                Positioned(
                  bottom: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          widget.video.formattedDuration,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              // Cache Status Badge
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCached
                            ? LucideIcons.checkCircle
                            : LucideIcons.download,
                        size: 12.sp,
                        color: _isCached ? Colors.green : Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _isCached ? 'دانلود شده' : 'آنلاین',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Download Progress
              if (isDownloading && downloadProgress > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80.w,
                                height: 80.w,
                                child: CircularProgressIndicator(
                                  value: downloadProgress,
                                  strokeWidth: 6.w,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.goldColor,
                                  ),
                                ),
                              ),
                              Text(
                                '${(downloadProgress * 100).toInt()}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'در حال دانلود...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontFamily: AppTheme.fontFamily,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Video Info
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ویدیو ${widget.index + 1}',
                        style: AppTheme.headingStyle.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    // Download Button
                    if (isDownloading)
                      SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: CircularProgressIndicator(
                          value: downloadProgress,
                          strokeWidth: 2.w,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.goldColor,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          _isCached ? LucideIcons.trash2 : LucideIcons.download,
                          size: 18.sp,
                          color: _isCached ? Colors.red : AppTheme.goldColor,
                        ),
                        onPressed: _isCached ? _deleteVideo : _downloadVideo,
                        tooltip: _isCached ? 'حذف از حافظه' : 'دانلود',
                      ),
                  ],
                ),
                if (widget.video.description != null &&
                    widget.video.description!.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    widget.video.description!,
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 12.sp,
                      color: context.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 8.h),
                Row(
                  children: [
                    if (widget.video.viewCount != null) ...[
                      Icon(
                        LucideIcons.eye,
                        size: 14.sp,
                        color: context.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatNumber(widget.video.viewCount!),
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11.sp,
                          color: context.textSecondary,
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    if (widget.video.likeCount != null) ...[
                      Icon(
                        LucideIcons.heart,
                        size: 14.sp,
                        color: Colors.pinkAccent,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          _formatNumber(widget.video.likeCount!),
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 11.sp,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    const Spacer(),
                    if (widget.video.createdAt != null)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 12.sp,
                            color: context.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              _formatDate(widget.video.createdAt!),
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 10.sp,
                                color: context.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} دقیقه پیش';
      }
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} هفته پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    } else {
      return '${(difference.inDays / 365).floor()} سال پیش';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
