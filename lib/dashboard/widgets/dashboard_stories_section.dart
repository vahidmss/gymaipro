import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_read_supabase_service.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// بخش داستان‌های افقی - سبک اینستاگرام برای مقالات آکادمی
/// حلقه طلایی = نخوانده، حلقه خاکستری = خوانده شده
class DashboardStoriesSection extends StatefulWidget {
  const DashboardStoriesSection({super.key});

  @override
  State<DashboardStoriesSection> createState() =>
      _DashboardStoriesSectionState();
}

class _DashboardStoriesSectionState extends State<DashboardStoriesSection> {
  List<Article> _articles = [];
  Set<int> _readIds = {};
  bool _isLoading = true;
  final DashboardCacheService _cacheService = DashboardCacheService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      List<Article>? cachedArticles = _cacheService.getArticles();
      List<Article> rawArticles;
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        rawArticles = cachedArticles;
      } else {
        rawArticles = await ArticleService.fetchArticles(perPage: 12);
        _cacheService.setArticles(rawArticles);
      }
      final articles = rawArticles
          .where(
            (a) => a.featuredImageUrl != null && a.featuredImageUrl!.isNotEmpty,
          )
          .take(8)
          .toList();

      final ids = articles.map((a) => a.id).toList();
      final readIds = await ArticleReadSupabaseService.getMyReadArticleIds();
      final relevantReadIds = readIds.where(ids.contains).toSet();

      if (mounted) {
        setState(() {
          _articles = articles;
          _readIds = relevantReadIds;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _articles = [];
          _readIds = {};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _articles.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.4),
                      AppTheme.goldColor.withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                ),
                child: Icon(
                  LucideIcons.sparkles,
                  color: context.textColor,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'داستان‌های امروز',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                    color: context.textColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              GestureDetector(
                onTap: () {
                  MainNavigationScreen.navigateToTab(
                    NavigationConstants.academyIndex,
                  );
                },
                child: Text(
                  'همه',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                    color: AppTheme.goldColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: 16.w),
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              final article = _articles[index];
              final isRead = _readIds.contains(article.id);
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child:
                    _StoryCircle(
                          article: article,
                          isRead: isRead,
                          index: index,
                          isDark: isDark,
                        )
                        .animate()
                        .fadeIn(duration: 280.ms, delay: (index * 40).ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                          delay: (index * 40).ms,
                          curve: Curves.easeOutCubic,
                        ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoryCircle extends StatelessWidget {
  const _StoryCircle({
    required this.article,
    required this.isRead,
    required this.index,
    required this.isDark,
  });

  final Article article;
  final bool isRead;
  final int index;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/article-detail', arguments: article);
      },
      child: SizedBox(
        width: 76.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isRead
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.9),
                          AppTheme.darkGold.withValues(alpha: 0.8),
                        ],
                      ),
              ),
              child: Padding(
                padding: EdgeInsets.all(2.5.w),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.cardColor,
                    border: Border.all(
                      color: isRead
                          ? context.separatorColor
                          : Colors.transparent,
                      width: 1.5.w,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      article.featuredImageUrl != null &&
                          article.featuredImageUrl!.isNotEmpty
                      ? Image.network(
                          article.featuredImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              article.title.length > 12
                  ? '${article.title.substring(0, 12)}...'
                  : article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 9.sp,
                fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                color: isRead ? context.textSecondary : context.textColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: context.placeholderColor,
      child: Icon(
        LucideIcons.bookOpen,
        color: AppTheme.goldColor.withValues(alpha: 0.7),
        size: 26.sp,
      ),
    );
  }
}
