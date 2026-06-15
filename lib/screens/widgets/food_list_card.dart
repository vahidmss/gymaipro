import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/food_meta.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FoodListCard extends StatefulWidget {
  const FoodListCard({
    required this.food,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onLikeToggle,
    super.key,
  });

  final Food food;
  final VoidCallback onTap;
  final Future<void> Function() onFavoriteToggle;
  final Future<void> Function() onLikeToggle;

  @override
  State<FoodListCard> createState() => _FoodListCardState();
}

class _FoodListCardState extends State<FoodListCard> {
  late bool _isFavorite;
  late bool _isLiked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _syncFromFood();
  }

  @override
  void didUpdateWidget(covariant FoodListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food.id != widget.food.id) {
      _syncFromFood();
    }
  }

  void _syncFromFood() {
    _isFavorite = widget.food.isFavorite;
    _isLiked = widget.food.isLikedByUser;
    _likes = widget.food.likes;
  }

  Future<void> _handleFavorite() async {
    await widget.onFavoriteToggle();
    if (!mounted) return;
    setState(() => _isFavorite = widget.food.isFavorite);
  }

  Future<void> _handleLike() async {
    await widget.onLikeToggle();
    if (!mounted) return;
    setState(() {
      _isLiked = widget.food.isLikedByUser;
      _likes = widget.food.likes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final food = widget.food;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.26),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.08 : 0.1),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
            BoxShadow(
              color: context.headerShadowColor,
              blurRadius: 6.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  _FoodThumbnail(
                    imageUrl: food.listThumbnailUrl,
                    isFavorite: _isFavorite,
                    onFavoriteToggle: _handleFavorite,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.displayTitle,
                          style: _FoodListStyles.title(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                        ),
                        if (food.meta.foodGroup.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          _GroupBadge(group: food.meta.foodGroup),
                        ],
                        SizedBox(height: 10.h),
                        _MacroRow(nutrition: food.nutrition),
                        SizedBox(height: 8.h),
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            _LikeChip(
                              isLiked: _isLiked,
                              likes: _likes,
                              onTap: _handleLike,
                            ),
                            const Spacer(),
                            Icon(
                              LucideIcons.chevronLeft,
                              size: 16.sp,
                              color: context.textSecondary.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _CalorieBadge(calories: food.nutrition.calories),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodListStyles {
  static TextStyle title(BuildContext context) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: context.textColor,
    height: 1.35,
    letterSpacing: -0.15,
  );

  static TextStyle micro(BuildContext context, {Color? color}) => TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 10.5.sp,
    fontWeight: FontWeight.w600,
    color: color ?? context.textSecondary,
    height: 1.1,
  );
}

class _FoodThumbnail extends StatelessWidget {
  const _FoodThumbnail({
    required this.imageUrl,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: _size.w,
      height: _size.w,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: ColoredBox(
              color: isDark
                  ? AppTheme.veryDarkBackground
                  : AppTheme.lightDividerColor.withValues(alpha: 0.35),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 128,
                      memCacheHeight: 128,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (_, __) => _placeholderImage(),
                      errorWidget: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
          ),
          Positioned(
            top: 4.h,
            right: 4.w,
            child: _CircleAction(
              icon: isFavorite ? LucideIcons.bookmark : LucideIcons.bookmarkPlus,
              color: isFavorite ? AppTheme.goldColor : Colors.white,
              onTap: onFavoriteToggle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Image.asset(
      Food.placeholderAsset,
      fit: BoxFit.cover,
      cacheWidth: 128,
      cacheHeight: 128,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(
          LucideIcons.utensils,
          color: AppTheme.goldColor.withValues(alpha: 0.45),
          size: 24.sp,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Icon(icon, color: color, size: 14.sp),
        ),
      ),
    );
  }
}

class _CalorieBadge extends StatelessWidget {
  const _CalorieBadge({required this.calories});

  final String calories;

  @override
  Widget build(BuildContext context) {
    final calText = _formatCalories(calories);
    return Container(
      constraints: BoxConstraints(minWidth: 52.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.18),
            AppTheme.goldColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.flame,
            size: 14.sp,
            color: AppTheme.goldColor,
          ),
          SizedBox(height: 4.h),
          Text(
            calText,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.goldColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCalories(String raw) {
    final n = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (n == null) return raw;
    if (n % 1 == 0) return n.toInt().toString();
    return n.toStringAsFixed(0);
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.nutrition});

  final FoodNutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final protein = _parse(nutrition.protein);
    final carbs = _parse(nutrition.carbohydrates);
    final fat = _parse(nutrition.fat);
    final total = protein + carbs + fat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total > 0) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: SizedBox(
              height: 4.h,
              child: Row(
                children: [
                  Expanded(
                    flex: _flex(protein, total),
                    child: const ColoredBox(color: AppTheme.proteinColor),
                  ),
                  Expanded(
                    flex: _flex(carbs, total),
                    child: const ColoredBox(color: AppTheme.carbsColor),
                  ),
                  Expanded(
                    flex: _flex(fat, total),
                    child: const ColoredBox(color: AppTheme.fatColor),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6.h),
        ],
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: _MacroLabel(
                label: 'پ',
                value: nutrition.protein,
                color: AppTheme.proteinColor,
              ),
            ),
            Expanded(
              child: _MacroLabel(
                label: 'ک',
                value: nutrition.carbohydrates,
                color: AppTheme.carbsColor,
              ),
            ),
            Expanded(
              child: _MacroLabel(
                label: 'چ',
                value: nutrition.fat,
                color: AppTheme.fatColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static double _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  static int _flex(double part, double total) {
    if (total <= 0) return 1;
    return ((part / total) * 100).round().clamp(1, 100);
  }
}

class _MacroLabel extends StatelessWidget {
  const _MacroLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            '$label ${_formatGram(value)}',
            style: _FoodListStyles.micro(context, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  static String _formatGram(String raw) {
    final n = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (n == null) return '$raw گرم';
    if (n % 1 == 0) return '${n.toInt()} گرم';
    return '${n.toStringAsFixed(1)} گرم';
  }
}

class _LikeChip extends StatelessWidget {
  const _LikeChip({
    required this.isLiked,
    required this.likes,
    required this.onTap,
  });

  final bool isLiked;
  final int likes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isLiked ? AppTheme.goldColor : context.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isLiked
                ? AppTheme.goldColor.withValues(alpha: 0.1)
                : context.buttonBackground,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isLiked
                  ? AppTheme.goldColor.withValues(alpha: 0.35)
                  : context.separatorColor.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                LucideIcons.heart,
                size: 13.sp,
                color: color,
              ),
              if (likes > 0) ...[
                SizedBox(width: 4.w),
                Text(
                  likes.toString(),
                  style: _FoodListStyles.micro(context, color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.group});

  final String group;

  @override
  Widget build(BuildContext context) {
    final color = FoodDisplayLabels.groupColor(group);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            FoodDisplayLabels.groupIcon(group),
            size: 11.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            group,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
