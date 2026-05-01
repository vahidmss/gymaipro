import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/services/music_player_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

class MusicPlayerWidget extends StatelessWidget {
  const MusicPlayerWidget({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerService>(
      builder: (context, player, _) {
        final currentMusic = player.currentMusic;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (currentMusic == null) {
          return Container(
            height: compact ? 72.h : 150.h,
            margin: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.1),
                  AppTheme.goldColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1.5.w,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.music,
                    size: compact ? 28.sp : 48.sp,
                    color: AppTheme.goldColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(height: compact ? 6.h : 12.h),
                  Text(
                    'موزیکی انتخاب نشده',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: compact ? 12.sp : 14.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (compact) {
          // Compact version with all features but smaller size
          return Container(
            margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        context.cardColor,
                        context.cardColor.withValues(alpha: 0.95),
                      ]
                    : [
                        AppTheme.goldColor.withValues(alpha: 0.12),
                        context.cardColor,
                      ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: isDark
                  ? Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      width: 1.w,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.15),
                  blurRadius: 12.r,
                  offset: Offset(0.w, 4.h),
                  spreadRadius: 1.r,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Album Art and Info (compact)
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      // Album Art (smaller)
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8.r,
                              offset: Offset(0.w, 4.h),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: currentMusic.coverImageUrl.isNotEmpty
                              ? Image.network(
                                  currentMusic.coverImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: Colors.black26,
                                    child: Icon(
                                      LucideIcons.music,
                                      size: 32.sp,
                                      color: AppTheme.goldColor,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.black26,
                                  child: Icon(
                                    LucideIcons.music,
                                    size: 32.sp,
                                    color: AppTheme.goldColor,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      
                      // Music Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentMusic.title,
                              style: AppTheme.headingStyle.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: context.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              currentMusic.displayArtist,
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 11.sp,
                                color: context.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (currentMusic.showPublisherLine) ...[
                              SizedBox(height: 3.h),
                              Text(
                                'نویسنده: ${currentMusic.author!.trim()}',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontSize: 10.sp,
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Bar (LTR)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: Directionality(
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
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
                              ),
                            ),
                            child: Slider(
                            value: player.duration.inSeconds > 0
                                ? player.position.inSeconds.toDouble()
                                : 0.0,
                            max: player.duration.inSeconds > 0
                                ? player.duration.inSeconds.toDouble()
                                : 100.0,
                            onChanged: (value) async {
                              await player.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                      ),
                    ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(player.position),
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 9.sp,
                                color: context.textSecondary,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                            Text(
                              _formatDuration(player.duration),
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 9.sp,
                                color: context.textSecondary,
                              ),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // Controls (RTL - compact)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Repeat Button
                        _RepeatButton(
                          repeatMode: player.repeatMode,
                          onTap: () => player.toggleRepeat(),
                          compact: true,
                        ),

                        // Previous Button
                        _ControlButton(
                          icon: LucideIcons.skipForward,
                          onTap: () => player.next(),
                          isEnabled: player.hasNext,
                          compact: true,
                        ),

                        // Play/Pause Button
                        Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldColor.withValues(alpha: 0.4),
                                blurRadius: 8.r,
                                spreadRadius: 1.r,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => player.togglePlayPause(),
                              borderRadius: BorderRadius.circular(22.r),
                              child: Center(
                                child: player.isLoading
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        player.isPlaying
                                            ? LucideIcons.pause
                                            : LucideIcons.play,
                                        color: Colors.white,
                                        size: 22.sp,
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // Next Button
                        _ControlButton(
                          icon: LucideIcons.skipBack,
                          onTap: () => player.previous(),
                          isEnabled: player.hasPrevious,
                          compact: true,
                        ),

                        // Shuffle Button
                        _ControlButton(
                          icon: LucideIcons.shuffle,
                          isActive: player.isShuffled,
                          onTap: () => player.toggleShuffle(),
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),
              ],
            ),
          );
        }

        return Container(
          margin: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      context.cardColor,
                      context.cardColor.withValues(alpha: 0.95),
                      context.veryDarkBackground,
                    ]
                  : [
                      AppTheme.goldColor.withValues(alpha: 0.15),
                      context.cardColor,
                      AppTheme.goldColor.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: isDark
                ? Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    width: 1.w,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.2),
                blurRadius: 20.r,
                offset: Offset(0.w, 8.h),
                spreadRadius: 2.r,
              ),
            ],
          ),
          child: Column(
            children: [
              // Album Art and Info
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Album Art
                    Container(
                      width: 140.w,
                      height: 140.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16.r,
                            offset: Offset(0.w, 8.h),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: currentMusic.coverImageUrl.isNotEmpty
                            ? Image.network(
                                currentMusic.coverImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.black26,
                                  child: Icon(
                                    LucideIcons.music,
                                    size: 48.sp,
                                    color: AppTheme.goldColor,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.black26,
                                child: Icon(
                                  LucideIcons.music,
                                  size: 48.sp,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Music Info
                    Text(
                      currentMusic.title,
                      style: AppTheme.headingStyle.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: context.textColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      currentMusic.displayArtist,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentMusic.showPublisherLine) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'نویسنده: ${currentMusic.author!.trim()}',
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 11.sp,
                          color: AppTheme.goldColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Progress Bar (LTR - چپ به راست)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.goldColor,
                            inactiveTrackColor: context.separatorColor,
                            thumbColor: AppTheme.goldColor,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            trackHeight: 3,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                          value: player.duration.inSeconds > 0
                              ? player.position.inSeconds.toDouble()
                              : 0.0,
                          max: player.duration.inSeconds > 0
                              ? player.duration.inSeconds.toDouble()
                              : 100.0,
                          onChanged: (value) async {
                            await player.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                    ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(player.position),
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 10.sp,
                              color: context.textSecondary,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          Text(
                            _formatDuration(player.duration),
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 10.sp,
                              color: context.textSecondary,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Controls (RTL - جابجایی دکمه‌ها برای فارسی)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Repeat Button
                      _RepeatButton(
                        repeatMode: player.repeatMode,
                        onTap: () => player.toggleRepeat(),
                      ),

                      // Previous Button (قبلی - مثل مینی پلیر)
                      _ControlButton(
                        icon: LucideIcons.skipForward,
                        onTap: () => player.next(),
                        isEnabled: player.hasNext,
                      ),

                      // Play/Pause Button
                      Container(
                        width: 52.w,
                        height: 52.w,
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.5),
                              blurRadius: 12.r,
                              spreadRadius: 1.5.r,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => player.togglePlayPause(),
                            borderRadius: BorderRadius.circular(26.r),
                            child: Center(
                              child: player.isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      player.isPlaying
                                          ? LucideIcons.pause
                                          : LucideIcons.play,
                                      color: Colors.white,
                                      size: 26.sp,
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Next Button (بعدی - مثل مینی پلیر)
                      _ControlButton(
                        icon: LucideIcons.skipBack,
                        onTap: () => player.previous(),
                        isEnabled: player.hasPrevious,
                      ),

                      // Shuffle Button
                      _ControlButton(
                        icon: LucideIcons.shuffle,
                        isActive: player.isShuffled,
                        onTap: () => player.toggleShuffle(),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _RepeatButton extends StatelessWidget {
  const _RepeatButton({
    required this.repeatMode,
    required this.onTap,
    this.compact = false,
  });

  final RepeatMode repeatMode;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isActive = repeatMode != RepeatMode.none;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: compact ? 36.w : 40.w,
          height: compact ? 36.w : 40.w,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.goldColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 18.r : 20.r),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.repeat,
                size: compact ? 18.sp : 20.sp,
                color: isActive ? AppTheme.goldColor : context.textColor,
              ),
              if (repeatMode == RepeatMode.one)
                Positioned(
                  bottom: compact ? 4.h : 5.h,
                  right: compact ? 4.w : 5.w,
                  child: Container(
                    width: compact ? 8.w : 10.w,
                    height: compact ? 8.w : 10.w,
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 6.sp : 7.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isEnabled = true,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isEnabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: compact ? 36.w : 40.w,
          height: compact ? 36.w : 40.w,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.goldColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 18.r : 20.r),
          ),
          child: Icon(
            icon,
            size: compact ? 18.sp : 20.sp,
            color: isEnabled
                ? (isActive ? AppTheme.goldColor : context.textColor)
                : context.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
