import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/store/models/store_product.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// بنر ورودی فروشگاه روی داشبورد.
class StoreTeaserBanner extends StatelessWidget {
  const StoreTeaserBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewProducts = StoreProduct.samples.take(3).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/store'),
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.darkGreyGradient,
                      AppTheme.goldColor.withValues(alpha: 0.3),
                    ]
                  : [
                      context.goldGradientColors[0],
                      context.goldGradientColors[1],
                    ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(
                alpha: isDark ? 0.3 : 0.45,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.2 : 0.3,
                ),
                blurRadius: 10.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _PreviewIcons(products: previewProducts),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'فروشگاه GymAI',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.onGoldColor,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              'به‌زودی',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'مکمل، پوشاک و تجهیزات ورزشی',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.sp,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.72)
                              : AppTheme.onGoldColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 16.sp,
                    color: isDark ? AppTheme.goldColor : AppTheme.onGoldColor,
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

class _PreviewIcons extends StatelessWidget {
  const _PreviewIcons({required this.products});

  final List<StoreProduct> products;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 72.w,
      height: 48.h,
      child: Stack(
        children: [
          for (var i = 0; i < products.length; i++)
            Positioned(
              right: i * 18.w,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      (products[i].accent ?? AppTheme.goldColor)
                          .withValues(alpha: 0.85),
                      AppTheme.goldColor.withValues(alpha: 0.45),
                    ],
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (products[i].accent ?? AppTheme.goldColor)
                          .withValues(alpha: 0.35),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  products[i].icon,
                  size: 18.sp,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
