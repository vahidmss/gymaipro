import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MusicCard extends StatefulWidget {
  const MusicCard({required this.music, super.key});

  final WorkoutMusic music;

  @override
  State<MusicCard> createState() => _MusicCardState();
}

class _MusicCardState extends State<MusicCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      setState(() => _isLoading = true);
      try {
        await _audioPlayer.play(UrlSource(widget.music.audioUrl));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطا در پخش موزیک: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.3 : 0.5),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.35),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
            spreadRadius: 0.5.r,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.lightTextColor.withValues(alpha: 0.08),
            blurRadius: 6.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Image and Play Button
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                  child: widget.music.coverImageUrl.isNotEmpty
                      ? Image.network(
                          widget.music.coverImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.black26,
                            child: const Icon(
                              LucideIcons.music,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.black26,
                          child: const Icon(
                            LucideIcons.music,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _togglePlayPause,
                        borderRadius: BorderRadius.circular(50.r),
                        child: Container(
                          width: 56.w,
                          height: 56.w,
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 12.r,
                                spreadRadius: 2.r,
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isPlaying
                                      ? LucideIcons.pause
                                      : LucideIcons.play,
                                  color: Colors.white,
                                  size: 28.sp,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Music Info
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.music.title,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      LucideIcons.music,
                      size: 12.sp,
                      color: AppTheme.goldColor,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        widget.music.artist,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11.sp,
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Progress Bar (only show when playing)
                if (_duration.inSeconds > 0 && _isPlaying)
                  Column(
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.goldColor,
                            inactiveTrackColor: context.separatorColor,
                            thumbColor: AppTheme.goldColor,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            trackHeight: 2.5,
                          ),
                          child: Slider(
                            value: _position.inSeconds.toDouble(),
                            max: _duration.inSeconds.toDouble(),
                            onChanged: (value) async {
                              await _audioPlayer.seek(
                                Duration(seconds: value.toInt()),
                              );
                            },
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: AppTheme.bodyStyle.copyWith(fontSize: 9.sp),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: AppTheme.bodyStyle.copyWith(fontSize: 9.sp),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Text(
                    widget.music.formattedDuration,
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 10.sp,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
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
