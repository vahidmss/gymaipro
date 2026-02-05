import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';

class AcademySection extends StatefulWidget {
  const AcademySection({super.key});

  @override
  State<AcademySection> createState() => _AcademySectionState();
}

class _AcademySectionState extends State<AcademySection> {
  List<Article> _articles = [];
  bool _isLoading = true;
  final DashboardCacheService _cacheService = DashboardCacheService();

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // بررسی کش برای مقالات
      List<Article>? cachedArticles = _cacheService.getArticles();
      if (cachedArticles != null) {
        _articles = cachedArticles.take(6).toList();
      } else {
        // بارگذاری از API
        final articles = await ArticleService.fetchArticles(perPage: 6);
        _articles = articles;
        // ذخیره در کش
        _cacheService.setArticles(_articles);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // هدر بخش با آیکون و عنوان
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // آیکون
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppTheme.goldColor.withValues(alpha: 0.3),
                            AppTheme.goldColor.withValues(alpha: 0.2),
                          ]
                        : [
                            AppTheme.goldColor.withValues(alpha: 0.2),
                            AppTheme.goldColor.withValues(alpha: 0.1),
                          ],
                  ),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.5 : 0.3,
                    ),
                    width: 1.w,
                  ),
                ),
                padding: EdgeInsets.all(6.w),
                child: Image.asset(
                  'images/curriculum.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  color: isDark ? AppTheme.goldColor : null,
                  colorBlendMode: isDark ? BlendMode.srcIn : null,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.school,
                      color: AppTheme.goldColor,
                      size: 20.sp,
                    );
                  },
                ),
              ),
              SizedBox(width: 10.w),
              // عنوان
              Expanded(
                child: Text(
                  'آنچه در آکادمی می‌آموزید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.sp,
                    height: 1.4,
                    color: context.textColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              // دکمه مشاهده بیشتر
              GestureDetector(
                onTap: () {
                  // بدون تغییر پشته، مستقیماً تب آکادمی را فعال کن
                  MainNavigationScreen.navigateToTab(
                    NavigationConstants.academyIndex,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.5),
                      width: 1.w,
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'مشاهده بیشتر',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 9.sp,
                          color: isDark ? AppTheme.goldColor : Colors.black,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 9.sp,
                        color: isDark ? AppTheme.goldColor : Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // محتوای مقالات - اسکرول افقی
        _isLoading
            ? SizedBox(
                height: 111.h,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                ),
              )
            : _articles.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 30.h),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.separatorColor,
                        width: 1.w,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 40.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'محتوایی یافت نشد',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 111.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _articles.length,
                      itemBuilder: (context, index) {
                        return _buildArticleCard(_articles[index], isDark);
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildArticleCard(Article article, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/article-detail', arguments: article);
      },
      child: Container(
        width: 130.w,
        height: 111.h,
        margin: EdgeInsets.only(left: 11.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(13.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.4,
              ),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // تصویر مقاله
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13.r),
                topRight: Radius.circular(13.r),
              ),
              child: Container(
                width: double.infinity,
                height: 81.h,
                color: context.placeholderColor,
                child: article.featuredImageUrl != null &&
                        article.featuredImageUrl!.isNotEmpty
                    ? Image.network(
                        article.featuredImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: context.placeholderColor,
                            child: Icon(
                              Icons.school,
                              size: 40.sp,
                              color: context.placeholderIconColor,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: context.placeholderColor,
                        child: Icon(
                          Icons.school,
                          size: 40.sp,
                          color: context.placeholderIconColor,
                        ),
                      ),
              ),
            ),
            // بخش پایین با gradient
            Container(
              width: double.infinity,
              height: 30.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [AppTheme.darkGreyGradient, AppTheme.goldColor]
                      : [context.gradientStartColor, AppTheme.goldColor],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(13.r),
                  bottomRight: Radius.circular(13.r),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                    article.title,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.sp,
                      height: 1.611,
                      color: context.textColor,
                      shadows: [
                        Shadow(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? context.backgroundColor.withValues(alpha: 0.5)
                              : context.cardColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


