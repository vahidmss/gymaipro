import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_comment_supabase_service.dart';
import 'package:gymaipro/academy/services/article_like_supabase_service.dart';
import 'package:gymaipro/academy/services/article_rating_supabase_service.dart';
import 'package:gymaipro/academy/widgets/article_content.dart';
import 'package:gymaipro/academy/widgets/article_image.dart';
import 'package:gymaipro/academy/widgets/comment_card.dart';
import 'package:gymaipro/academy/widgets/comment_form.dart';
import 'package:gymaipro/academy/widgets/rating_stars.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({required this.article, super.key});
  final Article article;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _liked = false;
  List<Map<String, dynamic>> _comments = const [];
  bool _loadingComments = true;
  double _avgRating = 0;
  int _ratingCount = 0;
  int? _myRating;
  Map<String, Map<String, dynamic>> _profilesByUserId = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final likeState = await ArticleLikeSupabaseService.getState(
        widget.article.id,
      );
      _liked = likeState.liked;
    } catch (_) {}
    try {
      final stats = await ArticleRatingSupabaseService.getStats(
        widget.article.id,
      );
      _avgRating = stats.avg;
      _ratingCount = stats.count;
      _myRating = stats.my;
    } catch (_) {}
    try {
      _comments = await ArticleCommentSupabaseService.fetchComments(
        widget.article.id,
      );
    } catch (_) {}
    try {
      await _loadProfilesForComments();
    } catch (_) {}
    if (mounted) setState(() => _loadingComments = false);
  }

  Future<void> _loadProfilesForComments() async {
    final ids = _comments
        .map((c) => (c['user_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    final rows = await Supabase.instance.client
        .from('profiles')
        .select('id, username, first_name, last_name, avatar_url')
        .inFilter('id', ids);
    final map = <String, Map<String, dynamic>>{};
    for (final r in (rows as List)) {
      final m = r as Map<String, dynamic>;
      final id = (m['id'] ?? '').toString();
      if (id.isNotEmpty) map[id] = m;
    }
    _profilesByUserId = map;
  }

  Future<void> _toggleLike() async {
    try {
      final state = await ArticleLikeSupabaseService.toggle(widget.article.id);
      if (mounted) {
        setState(() {
          _liked = state.liked;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitComment(String comment) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('برای ثبت نظر وارد شوید')));
        return;
      }
      final displayName =
          user.userMetadata?['username'] ??
          user.email?.split('@').first ??
          'کاربر';
      await ArticleCommentSupabaseService.addComment(
        articleId: widget.article.id,
        authorName: displayName.toString(),
        content: comment,
      );
      final list = await ArticleCommentSupabaseService.fetchComments(
        widget.article.id,
      );
      if (mounted) {
        setState(() => _comments = list);
        await _loadProfilesForComments();
        if (mounted) setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ثبت نظر: $e')));
    }
  }

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final f = j.formatter;
    return '${j.day} ${f.mN} ${j.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'جزئیات مقاله',
          style: AppTheme.headingStyle.copyWith(fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.article.featuredImageUrl != null)
              ArticleImage(imageUrl: widget.article.featuredImageUrl!),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.article.title,
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16.sp,
                        color: AppTheme.goldColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatJalali(widget.article.date),
                        style: AppTheme.bodyStyle.copyWith(fontSize: 12.sp),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? Colors.pinkAccent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RatingStars(
                    average: _avgRating,
                    count: _ratingCount,
                    myRating: _myRating,
                    onRate: (v) async {
                      try {
                        final out = await ArticleRatingSupabaseService.upsert(
                          widget.article.id,
                          v,
                        );
                        if (mounted) {
                          setState(() {
                            _avgRating = out.avg;
                            _ratingCount = out.count;
                            _myRating = v;
                          });
                        }
                      } catch (_) {}
                    },
                  ),
                  const SizedBox(height: 16),
                  ArticleContent(contentHtml: widget.article.contentHtml),
                  const SizedBox(height: 16),
                  CommentForm(onSubmit: _submitComment),
                  const SizedBox(height: 12),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_loadingComments) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: const CircularProgressIndicator(color: AppTheme.goldColor),
        ),
      );
    }
    if (_comments.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Text('نظری ثبت نشده است.', style: AppTheme.bodyStyle),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(12.w),
        itemCount: _comments.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
        itemBuilder: (context, i) {
          final c = _comments[i];
          final userId = (c['user_id'] ?? '').toString();
          final profile = _profilesByUserId[userId];
          final firstName = profile?['first_name']?.toString() ?? '';
          final lastName = profile?['last_name']?.toString() ?? '';
          final username = profile?['username']?.toString() ?? '';
          final displayName =
              [
                firstName,
                lastName,
              ].where((e) => e.isNotEmpty).toList().join(' ').isNotEmpty
              ? [
                  firstName,
                  lastName,
                ].where((e) => e.isNotEmpty).toList().join(' ')
              : (username.isNotEmpty
                    ? username
                    : (c['author_name'] ?? 'کاربر').toString());
          String avatarUrl = profile?['avatar_url']?.toString() ?? '';
          if (avatarUrl.toLowerCase() == 'null') avatarUrl = '';
          String content;
          final rawContent = c['content'];
          if (rawContent is Map<String, dynamic>) {
            content = (rawContent['rendered'] ?? '').toString();
          } else {
            content = rawContent?.toString() ?? '';
          }
          return CommentCard(
            displayName: displayName,
            content: content,
            avatarUrl: avatarUrl,
            onTap: userId.isNotEmpty
                ? () => Navigator.pushNamed(
                    context,
                    '/trainer-profile',
                    arguments: userId,
                  )
                : null,
          );
        },
      ),
    );
  }
}
