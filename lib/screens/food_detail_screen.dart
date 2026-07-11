import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/food_meta.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({required this.food, super.key});
  final Food food;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final FoodService _foodService = FoodService();
  late Food _food;
  bool _isFavorite = false;
  bool _isLiked = false;
  int _likes = 0;

  Food get food => _food;

  @override
  void initState() {
    super.initState();
    _food = widget.food;
    _isFavorite = widget.food.isFavorite;
    _isLiked = widget.food.isLikedByUser;
    _likes = widget.food.likes;
  }

  Future<void> _toggleFavorite() async {
    try {
      await _foodService.toggleFavorite(food.id);
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? 'خوراکی به لیست علاقه‌مندی‌ها اضافه شد'
                : 'خوراکی از لیست علاقه‌مندی‌ها حذف شد',
          ),
          backgroundColor: _isFavorite ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e', maxLines: 2, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleLike() async {
    try {
      await _foodService.toggleLike(food.id);
      if (!mounted) return;
      setState(() {
        _isLiked = !_isLiked;
        _likes += _isLiked ? 1 : -1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e', maxLines: 2, overflow: TextOverflow.ellipsis),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _buildCollapsingImageAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildShortDescriptionCard(),
                  SizedBox(height: 14.h),
                  _buildMetaChips(),
                  SizedBox(height: 14.h),
                  _buildNutritionSection(),
                  if (food.meta.hasTips) ...[
                    SizedBox(height: 14.h),
                    _buildTipsSection(),
                  ],
                  if (food.meta.hasAllergens) ...[
                    SizedBox(height: 12.h),
                    _buildAllergenBanner(),
                  ],
                  if (food.meta.glycemicIndexValue != null) ...[
                    SizedBox(height: 8.h),
                    _buildGiBadge(food.meta.glycemicIndexValue!),
                  ],
                  if (food.meta.servingNotes.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _buildServingNotesBanner(),
                  ],
                  if (food.link.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _buildWebsiteCtaCard(),
                  ],
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsingImageAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(24.r),
      bottomRight: Radius.circular(24.r),
    );

    final imageLayer = food.imageUrl.isEmpty
        ? SizedBox.expand(child: _buildImagePlaceholder(isDark))
        : Hero(
            tag: 'food_image_${food.id}',
            child: SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: food.imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (_, __) => _buildImagePlaceholder(isDark),
                errorWidget: (_, __, ___) => _buildImagePlaceholder(isDark),
                memCacheWidth: 800,
                memCacheHeight: 600,
              ),
            ),
          );

    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: context.backgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowRight,
          color: isDark ? Colors.white : context.textColor,
        ),
        onPressed: () => NavigationService.safePop(context),
      ),
      actions: [
        IconButton(
          onPressed: _toggleLike,
          icon: Icon(
            LucideIcons.thumbsUp,
            color: _isLiked
                ? AppTheme.goldColor
                : (isDark ? Colors.white70 : context.textSecondary),
            size: 22.sp,
          ),
        ),
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            LucideIcons.heart,
            color: _isFavorite
                ? Colors.red[600]
                : (isDark ? Colors.white70 : context.textSecondary),
            size: 24.sp,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: EdgeInsetsDirectional.only(
          start: 48.w,
          end: 48.w,
          bottom: 14.h,
        ),
        centerTitle: false,
        title: Text(
          food.displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            shadows: isDark
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(borderRadius: borderRadius, child: imageLayer),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.88),
                          ]
                        : [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.75),
                          ],
                  ),
                ),
              ),
            ),
            if (_likes > 0)
              Positioned(
                bottom: 52.h,
                left: 16.w,
                child: _LikeBadge(likes: _likes),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[900]!.withValues(alpha: 0.8),
                  Colors.grey[800]!.withValues(alpha: 0.6),
                ]
              : [Colors.grey[200]!, Colors.grey[100]!],
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.utensils,
          color: AppTheme.goldColor.withValues(alpha: 0.4),
          size: 72.sp,
        ),
      ),
    );
  }

  String _overviewDescriptionText() {
    final short = food.meta.shortDescription.trim();
    if (short.isNotEmpty) {
      return _truncateToSentences(short, maxSentences: 2, maxChars: 240);
    }

    final cleaned = _cleanHtmlContent(food.content);
    if (cleaned.isEmpty) return '';
    return _truncateToSentences(cleaned, maxSentences: 2, maxChars: 240);
  }

  Widget _buildShortDescriptionCard() {
    final text = _overviewDescriptionText();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (text.isEmpty) {
      return _sectionCard(
        title: 'درباره این خوراکی',
        icon: LucideIcons.sparkles,
        child: Text(
          'فعلاً توضیحی برای این خوراکی ثبت نشده. برای جزئیات بیشتر به وب‌سایت جیم‌اِی‌آی سر بزن.',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14.sp,
            height: 1.6,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppTheme.goldColor.withValues(alpha: 0.22),
                  const Color(0xFF1A1A1F),
                ]
              : [
                  AppTheme.goldColor.withValues(alpha: 0.18),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  color: AppTheme.goldColor,
                  size: 22.sp,
                ),
                SizedBox(width: 10.w),
                Text(
                  'درباره این خوراکی',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              text,
              style: TextStyle(
                color: context.textColor,
                fontSize: 15.sp,
                height: 1.75,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChips() {
    final chips = <Widget>[];
    final group = food.meta.foodGroup.trim();
    if (group.isNotEmpty) {
      final color = FoodDisplayLabels.groupColor(group);
      chips.add(
        _metricChip(
          label: 'گروه',
          value: group,
          icon: FoodDisplayLabels.groupIcon(group),
          accent: color,
        ),
      );
    }
    if (food.meta.foodType.isNotEmpty) {
      chips.add(
        _metricChip(
          label: 'نوع',
          value: FoodDisplayLabels.foodTypeLabel(food.meta.foodType),
          icon: LucideIcons.tag,
        ),
      );
    }
    for (final meal in food.meta.mealTimes.take(2)) {
      chips.add(
        _metricChip(
          label: 'وعده',
          value: meal,
          icon: LucideIcons.clock,
        ),
      );
    }
    if (food.meta.nutritionBasisLabel.isNotEmpty) {
      chips.add(
        _metricChip(
          label: 'مبنای ارزش',
          value: food.meta.nutritionBasisLabel,
          icon: LucideIcons.scale,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8.w, runSpacing: 8.h, children: chips);
  }

  Widget _buildNutritionSection() {
    final calories = _nutritionDouble(food.nutrition.calories) ?? 0;
    final protein = _nutritionDouble(food.nutrition.protein) ?? 0;
    final carbs = _nutritionDouble(food.nutrition.carbohydrates) ?? 0;
    final fat = _nutritionDouble(food.nutrition.fat) ?? 0;

    return _sectionCard(
      title: 'ارزش غذایی',
      icon: LucideIcons.chartPie,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CalorieHero(calories: calories),
          SizedBox(height: 14.h),
          _MacroGrid(
            protein: protein,
            carbs: carbs,
            fat: fat,
          ),
          SizedBox(height: 14.h),
          _MicroNutritionList(nutrition: food.nutrition),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return _sectionCard(
      title: 'نکات',
      icon: LucideIcons.lightbulb,
      child: Column(
        children: food.meta.tips
            .map(
              (tip) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _InfoBanner(
                  icon: LucideIcons.lightbulb,
                  color: AppTheme.goldColor,
                  background: AppTheme.goldColor.withValues(alpha: 0.08),
                  border: AppTheme.goldColor.withValues(alpha: 0.3),
                  text: tip,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAllergenBanner() {
    return _InfoBanner(
      icon: LucideIcons.alertTriangle,
      color: const Color(0xFFC62828),
      background: const Color(0xFFC62828).withValues(alpha: 0.1),
      border: const Color(0xFFC62828).withValues(alpha: 0.35),
      text: 'آلرژن: ${food.meta.allergens}',
    );
  }

  Widget _buildGiBadge(double gi) {
    final color = FoodDisplayLabels.glycemicColor(gi);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.activity, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            '${FoodDisplayLabels.glycemicLabel(gi)} (${MealLogUtils.convertToPersianNumbers(gi.toStringAsFixed(0))})',
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingNotesBanner() {
    return _InfoBanner(
      icon: LucideIcons.info,
      color: context.textSecondary,
      background: context.cardColor,
      border: context.separatorColor,
      text: food.meta.servingNotes,
    );
  }

  Widget _buildWebsiteCtaCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openWebsiteArticle,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: AppTheme.carbsColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.carbsColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Icon(
                      LucideIcons.globe,
                      color: AppTheme.carbsColor,
                      size: 26.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جزئیات کامل در وب‌سایت',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'توضیحات کامل، ترکیبات و نکات تغذیه‌ای',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12.5.sp,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.externalLink,
                  color: isDark ? Colors.white70 : AppTheme.carbsColor,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWebsiteArticle() async {
    if (food.link.isEmpty) return;
    try {
      final url = Uri.parse(food.link);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در باز کردن لینک')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e', maxLines: 2)),
      );
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: AppTheme.goldColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          child,
        ],
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required String value,
    required IconData icon,
    Color? accent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = accent ?? AppTheme.goldColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: chipColor),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double? _nutritionDouble(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String _truncateToSentences(
    String text, {
    required int maxSentences,
    required int maxChars,
  }) {
    final sentences = text
        .split(RegExp(r'(?<=[.!؟])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    var result = sentences.take(maxSentences).join(' ');
    if (result.length > maxChars) {
      result = '${result.substring(0, maxChars).trim()}…';
    }
    return result;
  }

  String _cleanHtmlContent(String htmlContent) {
    return htmlContent
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}

class _LikeBadge extends StatelessWidget {
  const _LikeBadge({required this.likes});
  final int likes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.thumbsUp, color: AppTheme.goldColor, size: 14.sp),
          SizedBox(width: 4.w),
          Text(
            MealLogUtils.convertToPersianNumbers(likes.toString()),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieHero extends StatelessWidget {
  const _CalorieHero({required this.calories});
  final double calories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.18),
            AppTheme.goldColor.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.flame, color: AppTheme.goldColor, size: 22.sp),
          SizedBox(width: 8.w),
          Text(
            MealLogUtils.convertToPersianNumbers(
              calories % 1 == 0
                  ? calories.toInt().toString()
                  : calories.toStringAsFixed(0),
            ),
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            'کیلوکالری',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroGrid extends StatelessWidget {
  const _MacroGrid({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroTile(
            label: 'پروتئین',
            value: protein,
            color: AppTheme.proteinColor,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _MacroTile(
            label: 'کربوهیدرات',
            value: carbs,
            color: AppTheme.carbsColor,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _MacroTile(
            label: 'چربی',
            value: fat,
            color: AppTheme.fatColor,
          ),
        ),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final display = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            MealLogUtils.convertToPersianNumbers('${display}g'),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicroNutritionList extends StatelessWidget {
  const _MicroNutritionList({required this.nutrition});
  final FoodNutrition nutrition;

  double _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final items = <_MicroItem>[
      _MicroItem('فیبر', _parse(nutrition.fiber), 'g', LucideIcons.leaf),
      _MicroItem('قند', _parse(nutrition.sugar), 'g', LucideIcons.candy),
      _MicroItem(
        'چربی اشباع',
        _parse(nutrition.saturatedFat),
        'g',
        LucideIcons.droplet,
      ),
      _MicroItem('سدیم', _parse(nutrition.sodium), 'mg', LucideIcons.flaskConical),
      _MicroItem('پتاسیم', _parse(nutrition.potassium), 'mg', LucideIcons.zap),
      _MicroItem(
        'کلسترول',
        _parse(nutrition.cholesterol),
        'mg',
        LucideIcons.heartPulse,
      ),
    ].where((e) => e.value > 0.05).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'جزئیات بیشتر',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8.h),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: _MicroRow(item: item),
          ),
        ),
      ],
    );
  }
}

class _MicroItem {
  const _MicroItem(this.label, this.value, this.unit, this.icon);
  final String label;
  final double value;
  final String unit;
  final IconData icon;
}

class _MicroRow extends StatelessWidget {
  const _MicroRow({required this.item});
  final _MicroItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatted = MealLogUtils.convertToPersianNumbers(
      '${item.value.toStringAsFixed(item.unit == 'mg' ? 0 : 1)} ${item.unit}',
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.goldColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 15.sp,
            color: context.textSecondary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: context.textColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.background,
    required this.border,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
