import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({required this.food, super.key});
  final Food food;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FoodService _foodService = FoodService();
  bool _isFavorite = false;
  bool _isLiked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.3.h), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _isFavorite = widget.food.isFavorite;
    _isLiked = widget.food.isLikedByUser;
    _likes = widget.food.likes;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    try {
      await _foodService.toggleFavorite(widget.food.id);
      setState(() {
        _isFavorite = !_isFavorite;
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleLike() async {
    try {
      await _foodService.toggleLike(widget.food.id);
      setState(() {
        _isLiked = !_isLiked;
        _likes += _isLiked ? 1 : -1;
      });

      if (_isLiked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خوراکی را پسندیدید'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: CustomScrollView(
          slivers: [
            // App Bar with Image
            _buildSliverAppBar(),

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Actions
                        _buildTitleSection(),
                        const SizedBox(height: 24),

                        // Nutrition Information
                        _buildNutritionSection(),
                        const SizedBox(height: 24),

                        // Content
                        _buildContentSection(),
                        const SizedBox(height: 24),

                        // Action Buttons (only web link)
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
        onPressed: () => NavigationService.safePop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? LucideIcons.heart : LucideIcons.heart,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: Icon(
            _isLiked ? LucideIcons.thumbsUp : LucideIcons.thumbsUp,
            color: _isLiked ? AppTheme.goldColor : Colors.white,
          ),
          onPressed: _toggleLike,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Food Image
            if (widget.food.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.food.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const ColoredBox(
                  color: AppTheme.cardColor,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  ),
                ),
                errorWidget: (context, url, error) => ColoredBox(
                  color: AppTheme.cardColor,
                  child: Icon(
                    LucideIcons.utensils,
                    color: AppTheme.goldColor,
                    size: 64.sp,
                  ),
                ),
              )
            else
              ColoredBox(
                color: AppTheme.cardColor,
                child: Icon(
                  LucideIcons.utensils,
                  color: AppTheme.goldColor,
                  size: 64.sp,
                ),
              ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Like Count
            Positioned(
              bottom: 16.h,
              left: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.thumbsUp,
                      color: AppTheme.goldColor,
                      size: 16.sp,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _likes.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.food.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              LucideIcons.calendar,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16.sp,
            ),
            const SizedBox(width: 4),
            Text(
              'تاریخ انتشار: ${_formatDate(widget.food.date)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildQuickStats(),
      ],
    );
  }

  Widget _buildNutritionSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اطلاعات تغذیه‌ای (در هر ۱۰۰ گرم)',
            style: TextStyle(
              color: AppTheme.goldColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            children: [
              _buildNutritionItem(
                label: 'کالری',
                value: widget.food.nutrition.calories,
                unit: 'کیلوکالری',
                color: Colors.orange,
                icon: Icons.local_fire_department,
              ),
              _buildNutritionItem(
                label: 'پروتئین',
                value: widget.food.nutrition.protein,
                unit: 'گرم',
                color: Colors.green,
                icon: Icons.fitness_center,
              ),
              _buildNutritionItem(
                label: 'کربوهیدرات',
                value: widget.food.nutrition.carbohydrates,
                unit: 'گرم',
                color: Colors.blue,
                icon: Icons.rice_bowl,
              ),
              _buildNutritionItem(
                label: 'چربی',
                value: widget.food.nutrition.fat,
                unit: 'گرم',
                color: Colors.red,
                icon: Icons.opacity,
              ),
              _buildNutritionItem(
                label: 'چربی اشباع',
                value: widget.food.nutrition.saturatedFat,
                unit: 'گرم',
                color: Colors.deepOrange,
                icon: Icons.warning_amber_rounded,
              ),
              _buildNutritionItem(
                label: 'فیبر',
                value: widget.food.nutrition.fiber,
                unit: 'گرم',
                color: Colors.purple,
                icon: Icons.eco,
              ),
              _buildNutritionItem(
                label: 'قند',
                value: widget.food.nutrition.sugar,
                unit: 'گرم',
                color: Colors.pink,
                icon: Icons.icecream,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    final String display = _formatNutritionValue(value, unit: unit);
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  display,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.2.h,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNutritionValue(String raw, {required String unit}) {
    final String cleaned = raw.trim();
    if (cleaned.isEmpty) return 'نامشخص';
    final double? numVal = double.tryParse(cleaned.replaceAll(',', '.'));
    if (numVal == null) return '$cleaned $unit';
    final String compact = numVal % 1 == 0
        ? numVal.toInt().toString()
        : numVal.toStringAsFixed(numVal < 10 ? 1 : 0);
    return '$compact $unit';
  }

  // Reuse formatting in title quick stats

  Widget _buildContentSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: _buildRichContent(widget.food.content),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.35),
              ),
              color: Colors.black.withValues(alpha: 0.15),
            ),
            child: _QuickStatChip(
              icon: Icons.local_fire_department,
              label: 'کالری',
              value: _formatNutritionValue(
                widget.food.nutrition.calories,
                unit: 'کیلوکالری',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.35),
              ),
              color: Colors.black.withValues(alpha: 0.15),
            ),
            child: _QuickStatChip(
              icon: Icons.fitness_center,
              label: 'پروتئین',
              value: _formatNutritionValue(
                widget.food.nutrition.protein,
                unit: 'گرم',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRichContent(String html) {
    final List<Widget> children = [];

    // Title
    children.add(const SectionHeading(title: 'توضیحات'));
    children.add(const SizedBox(height: 12));

    // Preprocess headings, hr, blockquotes into tokens
    String content = html;
    final h1Regex = RegExp(r'<h1[^>]*>([\s\S]*?)<\/h1>', multiLine: true);
    final h2Regex = RegExp(r'<h2[^>]*>([\s\S]*?)<\/h2>', multiLine: true);
    final hrRegex = RegExp(r'<hr\s*\/?>', multiLine: true);
    final bqRegex = RegExp(
      r'<blockquote[^>]*>([\s\S]*?)<\/blockquote>',
      multiLine: true,
    );

    content = content
        .replaceAllMapped(
          h1Regex,
          (m) => '<p>::H1::${_cleanHtmlContent(m.group(1) ?? '')}</p>',
        )
        .replaceAllMapped(
          h2Regex,
          (m) => '<p>::H2::${_cleanHtmlContent(m.group(1) ?? '')}</p>',
        )
        .replaceAllMapped(hrRegex, (_) => '<p>::HR::</p>')
        .replaceAllMapped(
          bqRegex,
          (m) => '<p>::BQ::${_cleanHtmlContent(m.group(1) ?? '')}</p>',
        );
    // Extract and render unordered lists
    final ulRegex = RegExp(r'<ul[\s\S]*?>([\s\S]*?)<\/ul>', multiLine: true);
    final liRegex = RegExp(r'<li[\s\S]*?>([\s\S]*?)<\/li>', multiLine: true);

    // Split content by <ul> blocks to interleave paragraphs and lists
    int lastIndex = 0;
    for (final match in ulRegex.allMatches(content)) {
      final before = content.substring(lastIndex, match.start);
      _appendParagraphs(children, before);
      final ulInner = match.group(1) ?? '';
      final items = liRegex
          .allMatches(ulInner)
          .map((m) => _cleanHtmlContent(m.group(1) ?? ''))
          .where((t) => t.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        children.addAll(items.map((t) => _DetailBullet(text: t)));
        children.add(const SizedBox(height: 8));
      }
      lastIndex = match.end;
    }
    // Remaining tail as paragraphs
    if (lastIndex < content.length) {
      _appendParagraphs(children, content.substring(lastIndex));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  void _appendParagraphs(List<Widget> target, String htmlChunk) {
    final cleaned = htmlChunk
        .split(RegExp(r'<p[^>]*>|<\/p>'))
        .map(_cleanHtmlContent)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    for (final paragraph in cleaned) {
      // Token handling for headings and hr/blockquote
      if (paragraph.startsWith('::H1::')) {
        target.add(
          SectionHeading(title: paragraph.replaceFirst('::H1::', ''), level: 1),
        );
        target.add(const SizedBox(height: 8));
        continue;
      }
      if (paragraph.startsWith('::H2::')) {
        target.add(SectionHeading(title: paragraph.replaceFirst('::H2::', '')));
        target.add(const SizedBox(height: 8));
        continue;
      }
      if (paragraph.startsWith('::HR::')) {
        target.add(const SizedBox(height: 8));
        target.add(const Divider(color: Colors.white24, thickness: 0.6));
        target.add(const SizedBox(height: 8));
        continue;
      }
      if (paragraph.startsWith('::BQ::')) {
        final text = paragraph.replaceFirst('::BQ::', '');
        target.add(
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 2.h, left: 8),
                  width: 3.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white70, height: 1.7),
                  ),
                ),
              ],
            ),
          ),
        );
        target.add(const SizedBox(height: 8));
        continue;
      }

      target.add(
        Text(
          paragraph,
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.7.h),
        ),
      );
      target.add(const SizedBox(height: 8));
    }
  }

  // Categories section removed per request

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          if (widget.food.link.isNotEmpty) {
            try {
              final url = Uri.parse(widget.food.link);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('خطا در باز کردن لینک'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطا در باز کردن لینک: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: const Icon(LucideIcons.externalLink),
        label: const Text('مشاهده در وب'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.goldColor,
          side: const BorderSide(color: AppTheme.goldColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _cleanHtmlContent(String htmlContent) {
    // Simple HTML tag removal - you might want to use a proper HTML parser
    return htmlContent
        .replaceAll(RegExp('<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}

class _QuickStatChip extends StatelessWidget {
  const _QuickStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.goldColor, size: 18),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.goldColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailBullet extends StatelessWidget {
  const _DetailBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 6.w,
            height: 6.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.goldColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                height: 1.7.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  // 1 or 2
  const SectionHeading({required this.title, super.key, this.level = 2});
  final String title;
  final int level;

  @override
  Widget build(BuildContext context) {
    final double size = level == 1 ? 20 : 16;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 3.w,
          height: size + 6,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: AppTheme.goldColor,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.goldColor,
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }
}
