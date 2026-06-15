import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/services/music_cache_service.dart';
import 'package:gymaipro/academy/services/music_favorite_service.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class PlaylistItemWidget extends StatefulWidget {
  const PlaylistItemWidget({
    required this.music,
    required this.index,
    super.key,
  });

  final WorkoutMusic music;
  final int index;

  @override
  State<PlaylistItemWidget> createState() => _PlaylistItemWidgetState();
}

class _PlaylistItemWidgetState extends State<PlaylistItemWidget> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  bool _isCached = false;
  bool _isDownloading = false;
  bool _isCheckingCache = false;
  bool _isLiked = false;
  bool _isLoadingLike = false;
  int _likesCount = 0;
  final MusicCacheService _cacheService = MusicCacheService();
  final UserPreferencesService _preferencesService = UserPreferencesService();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _checkCache();
    _checkLike();
    _likesCount = widget.music.likes;
    _isLiked = widget.music.isLikedByUser;
  }

  @override
  void didUpdateWidget(PlaylistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh cache and favorite status when music changes
    // But don't reset state immediately - keep old state until check completes
    if (oldWidget.music.id != widget.music.id ||
        oldWidget.music.audioUrl != widget.music.audioUrl) {
      _checkCache();
      _checkFavorite();
      _checkLike();
      _likesCount = widget.music.likes;
      _isLiked = widget.music.isLikedByUser;
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await MusicFavoriteService().isFavorite(widget.music.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _checkCache() async {
    if (_isCheckingCache) return; // Prevent concurrent checks

    setState(() => _isCheckingCache = true);

    // Small delay to prevent flickering on tab change
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Normalize URL before checking cache
    final normalizedUrl = WorkoutMusic.normalizeAudioUrl(widget.music.audioUrl);
    final isDownloaded = await _cacheService.isDownloaded(normalizedUrl);
    if (mounted) {
      setState(() {
        _isCached = isDownloaded;
        _isDownloading = _cacheService.isDownloading(normalizedUrl);
        _isCheckingCache = false;
      });
    }
  }

  Future<void> _downloadMusic() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    try {
      // Normalize URL before downloading
      final normalizedUrl = WorkoutMusic.normalizeAudioUrl(
        widget.music.audioUrl,
      );
      await _cacheService.downloadMusic(normalizedUrl);
      if (mounted) {
        // Refresh cache status after download
        await _checkCache();
        final isDownloaded = await _cacheService.isDownloaded(normalizedUrl);
        if (!mounted) return;
        if (isDownloaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'موزیک دانلود شد',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در دانلود: $e',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteDownload() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف از حافظه',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          'آیا می‌خواهید "${widget.music.title}" را از حافظه حذف کنید؟',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );

    if ((confirm ?? false) && mounted) {
      // Normalize URL before deleting download
      final normalizedUrl = WorkoutMusic.normalizeAudioUrl(
        widget.music.audioUrl,
      );
      await _cacheService.deleteDownloadedMusic(normalizedUrl);
      await _checkCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('موزیک از حافظه حذف شد'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _checkLike() async {
    try {
      final isLiked = await _preferencesService.isMusicLiked(widget.music.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _likesCount = widget.music.likes;
        });
      }
    } catch (e) {
      debugPrint('Error checking like: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoadingLike) return;

    setState(() => _isLoadingLike = true);
    try {
      if (_isLiked) {
        await _preferencesService.removeMusicLike(
          widget.music.id,
          audioUrl: widget.music.audioUrl,
        );
        setState(() {
          _isLiked = false;
          _likesCount = (_likesCount - 1).clamp(0, double.infinity).toInt();
          widget.music.isLikedByUser = false;
          widget.music.likes = _likesCount;
        });
      } else {
        await _preferencesService.addMusicLike(
          widget.music.id,
          audioUrl: widget.music.audioUrl,
        );
        setState(() {
          _isLiked = true;
          _likesCount = _likesCount + 1;
          widget.music.isLikedByUser = true;
          widget.music.likes = _likesCount;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در لایک: $e',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLike = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    setState(() => _isLoadingFavorite = true);
    try {
      await MusicFavoriteService().toggleFavorite(widget.music);
      await _checkFavorite();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'به مورد علاقه اضافه شد' : 'از مورد علاقه حذف شد',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا: $e',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerService>(
      builder: (context, player, _) {
        final isCurrent = player.isCurrentTrack(widget.music);
        final isPlaying = isCurrent && player.isPlaying;

        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.goldColor.withValues(alpha: 0.15)
                : context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isCurrent
                  ? AppTheme.goldColor.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5.w,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                try {
                  // Standard behavior:
                  // - If this is the current track, tapping the row toggles play/pause (no reload)
                  // - Otherwise, play the selected track
                  final isCurrent = player.isCurrentTrack(widget.music);
                  if (isCurrent) {
                    await player.togglePlayPause();
                  } else {
                    await player.playMusic(widget.music, index: widget.index);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'خطا در پخش موزیک: $e',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Row(
                  children: [
                    // Album Art
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8.r,
                            offset: Offset(0.w, 2.h),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: widget.music.coverImageUrl.isNotEmpty
                            ? Image.network(
                                widget.music.coverImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => ColoredBox(
                                  color: Colors.black26,
                                  child: Icon(
                                    LucideIcons.music,
                                    size: 18.sp,
                                    color: AppTheme.goldColor,
                                  ),
                                ),
                              )
                            : ColoredBox(
                                color: Colors.black26,
                                child: Icon(
                                  LucideIcons.music,
                                  size: 18.sp,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Music Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.music.title,
                            style: AppTheme.headingStyle.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: isCurrent
                                  ? AppTheme.goldColor
                                  : context.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.h),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.music,
                                size: 8.sp,
                                color: context.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  widget.music.displayArtist,
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontSize: 8.sp,
                                    color: context.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (widget.music.showPublisherLine) ...[
                            SizedBox(height: 3.h),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.user,
                                  size: 8.sp,
                                  color: context.textSecondary,
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    'نویسنده: ${widget.music.author}',
                                    style: AppTheme.bodyStyle.copyWith(
                                      fontSize: 7.sp,
                                      color: context.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(width: 6.w),

                    // Cache/Download Button with smooth animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: IconButton(
                        key: ValueKey(
                          'cache_${_isCached}_${_isDownloading}_$_isCheckingCache',
                        ),
                        icon: _isDownloading || _isCheckingCache
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.goldColor,
                                ),
                              )
                            : Icon(
                                _isCached
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.download,
                                size: 16.sp,
                                color: _isCached
                                    ? AppTheme.goldColor
                                    : context.textSecondary,
                              ),
                        onPressed: (_isDownloading || _isCheckingCache)
                            ? null
                            : (_isCached ? _deleteDownload : _downloadMusic),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: _isCached ? 'حذف از حافظه' : 'دانلود',
                      ),
                    ),

                    SizedBox(width: 4.w),

                    // Like Button with smooth animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        key: ValueKey('like_${_isLiked}_$_isLoadingLike'),
                        onTap: _isLoadingLike ? null : _toggleLike,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoadingLike) SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppTheme.goldColor,
                                    ),
                                  ) else Icon(
                                    _isLiked
                                        ? LucideIcons.heart
                                        : LucideIcons.heartOff,
                                    size: 14.sp,
                                    color: _isLiked
                                        ? Colors.red
                                        : context.textSecondary,
                                  ),
                            if (_likesCount > 0) ...[
                              SizedBox(width: 3.w),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: Text(
                                  _likesCount.toString(),
                                  key: ValueKey<int>(_likesCount),
                                  style: TextStyle(
                                    color: _isLiked
                                        ? Colors.red[600]
                                        : context.textSecondary,
                                    fontSize: 9.sp,
                                    fontWeight: _isLiked
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 4.w),

                    // Favorite Button with smooth animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: IconButton(
                        key: ValueKey(
                          'favorite_${_isFavorite}_$_isLoadingFavorite',
                        ),
                        icon: _isLoadingFavorite
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.goldColor,
                                ),
                              )
                            : Icon(
                                _isFavorite
                                    ? LucideIcons.bookmark
                                    : LucideIcons.bookmarkPlus,
                                size: 16.sp,
                                color: _isFavorite
                                    ? AppTheme.goldColor
                                    : context.textSecondary,
                              ),
                        onPressed: _isLoadingFavorite ? null : _toggleFavorite,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: _isFavorite
                            ? 'حذف از مورد علاقه'
                            : 'افزودن به مورد علاقه',
                      ),
                    ),

                    SizedBox(width: 6.w),

                    // Play/Pause Indicator or Duration
                    if (isCurrent && player.isLoading)
                      // Lightweight loading indicator - no heavy animation
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 12.w,
                            height: 12.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.goldColor,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (isCurrent && isPlaying)
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: const BoxDecoration(
                          color: AppTheme.goldColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.pause,
                          size: 12.sp,
                          color: Colors.white,
                        ),
                      )
                    else if (isCurrent)
                      Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.play,
                          size: 12.sp,
                          color: AppTheme.goldColor,
                        ),
                      )
                    else
                      Text(
                        widget.music.formattedDuration,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 9.sp,
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
