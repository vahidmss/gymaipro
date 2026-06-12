import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExerciseCatalogCard extends StatelessWidget {
  const ExerciseCatalogCard({
    required this.exercise,
    required this.onTap,
    required this.onFavorite,
    required this.onLike,
    super.key,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onLike;

  static Color difficultyColor(String difficulty) {
    switch (ExerciseDisplayLabels.difficultyLabel(difficulty)) {
      case 'مبتدی':
        return Colors.green;
      case 'پیشرفته':
      case 'حرفه‌ای':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageUrl = exercise.imageUrl.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.28),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        key: ValueKey(imageUrl),
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 120),
                        fadeOutDuration: Duration.zero,
                        memCacheWidth: 360,
                        memCacheHeight: 240,
                        placeholder: (_, __) =>
                            _ImagePlaceholder(isDark: isDark),
                        errorWidget: (_, __, ___) =>
                            _ImagePlaceholder(isDark: isDark),
                      )
                    else
                      _ImagePlaceholder(isDark: isDark),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x8C000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: _CircleIconButton(
                        tooltip: exercise.isFavorite
                            ? 'حذف از علاقه‌مندی‌ها'
                            : 'افزودن به علاقه‌مندی‌ها',
                        icon: exercise.isFavorite
                            ? LucideIcons.bookmark
                            : LucideIcons.bookmarkPlus,
                        color: exercise.isFavorite
                            ? AppTheme.goldColor
                            : Colors.white,
                        onTap: onFavorite,
                      ),
                    ),
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor(exercise.difficulty),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          ExerciseDisplayLabels.difficultyLabel(
                            exercise.difficulty,
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (exercise.mainMuscle.isNotEmpty)
                      Positioned(
                        left: 8.w,
                        right: 8.w,
                        bottom: 8.h,
                        child: Text(
                          ExerciseDisplayLabels.muscle(exercise.mainMuscle),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 13.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${(exercise.estimatedDuration / 60).clamp(1, 999).round()} دقیقه',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                        const Spacer(),
                        _LikeButton(
                          isLiked: exercise.isLikedByUser,
                          likes: exercise.likes,
                          onTap: onLike,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(7.w),
          child: Icon(icon, color: color, size: 18.sp),
        ),
      ),
    );
    final hint = tooltip;
    if (hint == null || hint.isEmpty) return button;
    return Tooltip(message: hint, child: button);
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({
    required this.isLiked,
    required this.likes,
    required this.onTap,
  });

  final bool isLiked;
  final int likes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isLiked ? 'حذف لایک' : 'لایک',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 16.sp,
                  color: isLiked ? Colors.red : context.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  '$likes',
                  style: TextStyle(
                    color: isLiked ? Colors.red : context.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
      child: Center(
        child: Icon(
          LucideIcons.dumbbell,
          color: AppTheme.goldColor.withValues(alpha: 0.35),
          size: 40.sp,
        ),
      ),
    );
  }
}
