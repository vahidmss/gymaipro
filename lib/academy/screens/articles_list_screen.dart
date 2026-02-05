import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/academy/services/article_stats_cache_service.dart';
import 'package:gymaipro/academy/widgets/article_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';

class ArticlesListScreen extends StatefulWidget {
  const ArticlesListScreen({super.key});

  @override
  State<ArticlesListScreen> createState() => _ArticlesListScreenState();
}

class _ArticlesListScreenState extends State<ArticlesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Article> _articles = [];
  final Map<int, ArticleStats> _articleStats = {};
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadPage();
      }
    });
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (refresh) {
        _currentPage = 1;
        _articles.clear();
        _articleStats.clear();
        _hasMore = true;
      }
      final newItems = await ArticleService.fetchArticles(
        page: _currentPage,
        forceRefresh: refresh,
      );

      // Load stats for new articles
      if (newItems.isNotEmpty) {
        final articleIds = newItems.map((article) => article.id).toList();
        final stats = await ArticleStatsCacheService.loadMultipleStats(
          articleIds,
        );

        WidgetSafetyUtils.safeSetState(this, () {
          _articles.addAll(newItems);
          _articleStats.addAll(stats);
          _currentPage++;
          if (newItems.isEmpty || newItems.length < 20) _hasMore = false;
        });
      } else {
        WidgetSafetyUtils.safeSetState(this, () {
          _currentPage++;
          _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگیری مقالات: $e',
        );
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(refresh: true),
        child: Container(
          color: context.backgroundColor,
          child: Column(
            children: [
              // Articles List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.w),
                  itemCount: _articles.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _articles.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.goldColor,
                          ),
                        ),
                      );
                    }
                    final article = _articles[index];
                    final stats = _articleStats[article.id];
                    return ArticleCard(article: article, stats: stats);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
