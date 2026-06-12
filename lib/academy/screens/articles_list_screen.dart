import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_read_supabase_service.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/academy/services/article_stats_cache_service.dart';
import 'package:gymaipro/academy/widgets/article_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/json_parse_utils.dart';
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
  final Set<int> _readArticleIds = {};
  final Map<int, int> _readCounts = {};
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchReadStates().then((ids) {
      if (!mounted) return;
      setState(() {
        _readArticleIds
          ..clear()
          ..addAll(ids);
      });
    });
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

  /// Returns current user's read article ids (empty set on error).
  Future<Set<int>> _fetchReadStates() async {
    try {
      return await ArticleReadSupabaseService.getMyReadArticleIds();
    } catch (_) {
      return {};
    }
  }

  /// Only fetches read counts for [articleIds] and merges into _readCounts (no full-list refetch).
  Future<void> _loadReadCountsForIds(List<int> articleIds) async {
    if (articleIds.isEmpty) return;
    try {
      final counts = await ArticleReadSupabaseService.getReadCounts(articleIds);
      if (!mounted) return;
      setState(() => _readCounts.addAll(counts));
    } catch (_) {}
    // خطا در آمار مطالعه نباید UI را خراب کند
  }

  Future<void> _reloadArticleStats(int articleId) async {
    try {
      final stats = await ArticleStatsCacheService.getArticleStats(articleId);
      if (mounted) {
        setState(() {
          _articleStats[articleId] = stats;
        });
      }
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      Set<int>? refreshedReadIds;
      if (refresh) {
        _currentPage = 1;
        _articles.clear();
        _articleStats.clear();
        _readCounts.clear();
        _hasMore = true;
        refreshedReadIds = await _fetchReadStates();
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
          if (refreshedReadIds != null) {
            _readArticleIds
              ..clear()
              ..addAll(refreshedReadIds);
          }
          _articles.addAll(newItems);
          _articleStats.addAll(stats);
          _currentPage++;
          if (newItems.length < 20) _hasMore = false;
        });
        _loadReadCountsForIds(articleIds);
      } else {
        WidgetSafetyUtils.safeSetState(this, () {
          if (refreshedReadIds != null) {
            _readArticleIds
              ..clear()
              ..addAll(refreshedReadIds);
          }
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
        child: ColoredBox(
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
                    final isRead = _readArticleIds.contains(article.id);
                    final readCount = _readCounts[article.id] ?? 0;
                    return ArticleCard(
                      key: ValueKey('article_${article.id}'),
                      article: article,
                      stats: stats,
                      isRead: isRead,
                      readCount: readCount,
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/article-detail',
                          arguments: article,
                        );
                        if (result != null && result is Map) {
                          final map = result;
                          final articleId = JsonParse.fromIntOrNull(map['articleId']);
                          final isRead = map['isRead'] == true;
                          final statsChanged = map['statsChanged'] == true;

                          if (isRead && articleId != null) {
                            setState(() {
                              _readArticleIds.add(articleId);
                            });
                          }

                          if (statsChanged && articleId != null) {
                            _reloadArticleStats(articleId);
                          }
                        }
                      },
                    );
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
