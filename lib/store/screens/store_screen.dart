import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/store/models/store_product.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحهٔ فروشگاه (نسخهٔ teaser/پیش‌نمایش).
///
/// فعلاً فقط نمایشی است: محصولات نمونه با برچسب «به‌زودی» و امکان اطلاع‌رسانی.
/// وقتی فروشگاه واقعی راه بیفتد، همین صفحه به داده‌ی سرور و پرداخت از
/// کیف‌پول/زیبال وصل می‌شود.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  StoreCategory? _selectedCategory;

  static const _deepInk = Color(0xFF0B0B0F);
  static const _softInk = Color(0xFF17131A);
  static const _champagne = Color(0xFFF8E7B4);
  static const _bronze = Color(0xFF9A6A24);

  List<StoreProduct> get _filtered {
    if (_selectedCategory == null) return StoreProduct.samples;
    return StoreProduct.samples
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  void _notifyMe() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? _softInk
              : context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
            side: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.22)),
          ),
          content: Row(
            textDirection: TextDirection.rtl,
            children: [
              const Icon(LucideIcons.bellRing, color: AppTheme.goldColor),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'ثبت شد! با باز شدن فروشگاه GymAI اولین نفر بهت خبر می‌دیم.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? _deepInk : context.backgroundColor,
        appBar: AppBar(
          backgroundColor: isDark ? _deepInk : context.backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'فروشگاه',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: context.textColor,
            ),
          ),
          leading: IconButton(
            icon: Icon(LucideIcons.arrowRight, color: context.textColor),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
          children: [
            _buildHero(),
            SizedBox(height: 18.h),
            _buildLuxuryStrip(),
            SizedBox(height: 20.h),
            _buildCategoryChips(),
            SizedBox(height: 18.h),
            _buildSectionTitle(),
            SizedBox(height: 14.h),
            _buildFeaturedDrop(),
            SizedBox(height: 16.h),
            _buildGrid(),
            SizedBox(height: 24.h),
            _buildConciergeCard(),
            SizedBox(height: 14.h),
            _buildFooterNote(),
          ],
        ),
      ),
    );
  }

  // ─── هدر/هیرو ───
  Widget _buildHero() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppTheme.darkGreyGradient,
                  AppTheme.goldColor.withValues(alpha: 0.35),
                  _deepInk,
                ]
              : [
                  AppTheme.lightGradientStart,
                  AppTheme.lightGradientEnd,
                  AppTheme.goldColor.withValues(alpha: 0.55),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.28),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      LucideIcons.shoppingBag,
                      color: isDark ? _champagne : _deepInk,
                      size: 26.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'فروشگاه GymAI',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark ? Colors.white : _deepInk,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'مکمل، پوشاک و تجهیزات ورزشی',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.72)
                                : _deepInk.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _pill(
                    label: 'به‌زودی',
                    foreground: isDark ? _champagne : _bronze,
                    background: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.65),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'ویترین نمایشی محصولات منتخب برندهای همکار. '
                'با باز شدن فروشگاه واقعی، اولین نفر از راه‌اندازی باخبر می‌شوی.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : _deepInk.withValues(alpha: 0.75),
                  fontSize: 13.sp,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 16.h),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _notifyMe,
                  borderRadius: BorderRadius.circular(14.r),
                  child: Ink(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isDark ? _deepInk : Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.bellRing,
                          color: AppTheme.goldColor,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'خبرم کن وقتی باز شد',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark ? Colors.white : _deepInk,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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

  Widget _buildLuxuryStrip() {
    return Row(
      children: [
        Expanded(
          child: _luxuryInfoTile(
            icon: LucideIcons.sparkles,
            label: 'انتخاب ویژه',
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _luxuryInfoTile(
            icon: LucideIcons.truck,
            label: 'ارسال سریع',
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _luxuryInfoTile(
            icon: LucideIcons.badgeCheck,
            label: 'برند معتبر',
          ),
        ),
      ],
    );
  }

  Widget _luxuryInfoTile({
    required IconData icon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 20.sp),
          SizedBox(height: 6.h),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── چیپ‌های دسته‌بندی ───
  Widget _buildCategoryChips() {
    final chips = <Widget>[
      _categoryChip(
        label: 'همه',
        selected: _selectedCategory == null,
        onTap: () {
          setState(() => _selectedCategory = null);
        },
      ),
      ...StoreCategory.values.map(
        (c) => _categoryChip(
          label: c.label,
          icon: c.icon,
          selected: _selectedCategory == c,
          onTap: () => setState(() => _selectedCategory = c),
        ),
      ),
    ];

    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _categoryChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 9.h),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [_champagne, AppTheme.goldColor, _bronze],
                )
              : null,
          color: selected
              ? null
              : Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.055)
              : context.cardColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.goldColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.sp,
                color: selected ? _deepInk : context.textSecondary,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                color: selected ? _deepInk : context.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: AppTheme.goldColor,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          _selectedCategory == null
              ? 'محصولات منتخب'
              : _selectedCategory!.label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
        const Spacer(),
        Text(
          '${_filtered.length} محصول',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedDrop() {
    final product = _filtered.first;
    final accent = product.accent ?? AppTheme.goldColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 14.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 110.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      accent.withValues(alpha: 0.5),
                      AppTheme.goldColor.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ProductIconDisplay(
                      icon: product.icon,
                      accent: accent,
                      size: 52.sp,
                    ),
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          'ویژه',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: _champagne,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        product.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: context.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Text(
                            product.priceLabel,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: AppTheme.goldColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.star_rounded, color: accent, size: 15.sp),
                          SizedBox(width: 2.w),
                          Text(
                            product.ratingLabel,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── گرید محصولات ───
  Widget _buildGrid() {
    final items = _filtered;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 620 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (_, i) => _ProductCard(
            product: items[i],
            onNotify: _notifyMe,
          ),
        );
      },
    );
  }

  Widget _buildConciergeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              LucideIcons.sparkles,
              color: AppTheme.goldColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'پیشنهاد هوشمند خرید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'با باز شدن فروشگاه، محصولات بر اساس برنامه تمرین شما پیشنهاد می‌شود.',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 11.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 16.sp, color: context.textSecondary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'این صفحه نمایشی است. قیمت‌ها و محصولات واقعی نیستند.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.sp,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: foreground,
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── کارت محصول (الگوی مشابه کارت‌های داشبورد) ───
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onNotify,
  });

  final StoreProduct product;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    final accent = product.accent ?? AppTheme.goldColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onNotify,
        borderRadius: BorderRadius.circular(20.r),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : context.cardColor,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.1),
                blurRadius: 14.r,
                offset: Offset(0, 5.h),
              ),
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey)
                    .withValues(alpha: 0.06),
                blurRadius: 6.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              accent.withValues(alpha: 0.45),
                              AppTheme.goldColor.withValues(alpha: 0.15),
                              isDark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 50.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: _ProductIconDisplay(
                          icon: product.icon,
                          accent: accent,
                          size: 44.sp,
                        ),
                      ),
                      Positioned(
                        right: -20.w,
                        top: -10.h,
                        child: Icon(
                          product.icon,
                          size: 72.sp,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            product.badge,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: Colors.white,
                              fontSize: 8.5.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: accent,
                                size: 12.sp,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                product.ratingLabel,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: Colors.white,
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppTheme.darkGreyGradient,
                              AppTheme.goldColor.withValues(alpha: 0.15),
                            ]
                          : [
                              context.gradientStartColor,
                              AppTheme.goldColor.withValues(alpha: 0.12),
                            ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              product.priceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(7.w),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.bellRing,
                          color: AppTheme.goldColor,
                          size: 14.sp,
                        ),
                      ),
                    ],
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

/// نمایش آیکون محصول با پس‌زمینه دایره‌ای شیشه‌ای.
class _ProductIconDisplay extends StatelessWidget {
  const _ProductIconDisplay({
    required this.icon,
    required this.accent,
    required this.size,
  });

  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final circleSize = size * 1.45;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 16.r,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }
}
