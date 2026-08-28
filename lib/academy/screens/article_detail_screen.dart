import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_comment_supabase_service.dart';
import 'package:gymaipro/academy/services/article_like_supabase_service.dart';
import 'package:gymaipro/academy/services/article_rating_supabase_service.dart';
import 'package:gymaipro/academy/services/article_read_supabase_service.dart';
import 'package:gymaipro/academy/services/article_stats_cache_service.dart';
import 'package:gymaipro/academy/widgets/article_content.dart';
import 'package:gymaipro/academy/widgets/article_image.dart';
import 'package:gymaipro/academy/widgets/comment_card.dart';
import 'package:gymaipro/academy/widgets/comment_form.dart';
import 'package:gymaipro/academy/widgets/rating_stars.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  int _likeCount = 0;
  List<Map<String, dynamic>> _comments = const [];
  bool _loadingComments = true;
  bool _loadingStats = true;
  double _avgRating = 0;
  int _ratingCount = 0;
  int? _myRating;
  Map<String, Map<String, dynamic>> _profilesByUserId = {};
  bool _isRead = false;
  bool _markedReadLocally = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadLikeState(),
      _loadRatingStats(),
      _loadComments(),
      _loadReadState(),
    ]);
    WidgetSafetyUtils.safeSetState(this, () {
      _loadingStats = false;
      _loadingComments = false;
    });
  }

  Future<void> _loadLikeState() async {
    try {
      final likeState = await ArticleLikeSupabaseService.getState(
        widget.article.id,
      );
      if (mounted) {
        setState(() {
          _liked = likeState.liked;
          _likeCount = likeState.likeCount;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRatingStats() async {
    try {
      final stats = await ArticleRatingSupabaseService.getStats(
        widget.article.id,
      );
      if (mounted) {
        setState(() {
          _avgRating = stats.avg;
          _ratingCount = stats.count;
          _myRating = stats.my;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    try {
      final comments = await ArticleCommentSupabaseService.fetchComments(
        widget.article.id,
      );
      if (mounted) {
        setState(() => _comments = comments);
        await _loadProfilesForComments();
      }
    } catch (_) {}
  }

  Future<void> _loadReadState() async {
    try {
      final isRead = await ArticleReadSupabaseService.isRead(widget.article.id);
      if (mounted) {
        setState(() => _isRead = isRead);
      }
    } catch (_) {}
  }

  Future<void> _loadProfilesForComments() async {
    final ids = _comments
        .map((c) => (c['user_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    final rows = await ProfileRepository.instance.fetchProfilesByIdentifiers(
      ids,
    );
    final map = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final profileId = row['id']?.toString();
      final authId = row['auth_user_id']?.toString();
      if (profileId != null && profileId.isNotEmpty) {
        map[profileId] = row;
      }
      if (authId != null && authId.isNotEmpty) {
        map[authId] = row;
      }
    }
    _profilesByUserId = map;
  }

  Future<void> _toggleLike() async {
    try {
      final state = await ArticleLikeSupabaseService.toggle(widget.article.id);
      if (mounted) {
        setState(() {
          _liked = state.liked;
          _likeCount = state.likeCount;
        });
      }
      _syncStatsCache();
    } catch (_) {}
  }

  void _syncStatsCache() {
    ArticleStatsCacheService.put(
      widget.article.id,
      ArticleStats(
        likeCount: _likeCount,
        avgRating: _avgRating,
        ratingCount: _ratingCount,
      ),
    );
  }

  Future<void> _markAsRead() async {
    try {
      await ArticleReadSupabaseService.markAsRead(widget.article.id);
      if (!mounted) return;
      setState(() {
        _isRead = true;
        _markedReadLocally = true;
      });
      RankingService().updateCurrentUserRanking().catchError((_, __) {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white),
              SizedBox(width: 8.w),
              const Expanded(
                child: Text(
                  'این مقاله به‌عنوان مطالعه‌شده ثبت شد.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در ثبت وضعیت مطالعه: $e',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _submitComment(String comment) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'برای ثبت نظر وارد شوید',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
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
        SafeSetState.call(this, () => _comments = list);
        await _loadProfilesForComments();
        SafeSetState.call(this, () {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در ثبت نظر: $e',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    final f = j.formatter;
    return '${j.day} ${f.mN} ${j.year}';
  }

  Map<String, dynamic> _popResult() => {
    'articleId': widget.article.id,
    'isRead': _markedReadLocally || _isRead,
    'statsChanged': true,
    'likeCount': _likeCount,
    'avgRating': _avgRating,
    'ratingCount': _ratingCount,
  };

  @override
  Widget build(BuildContext context) {
    final background = context.backgroundColor;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _popResult());
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'بازگشت',
            icon: Icon(LucideIcons.arrowRight, color: context.textColor),
            onPressed: () => Navigator.pop(context, _popResult()),
          ),
          title: Text(
            'جزئیات مقاله',
            style: context.headingStyle.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: _loadingStats
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.article.featuredImageUrl != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: ArticleImage(
                            imageUrl: widget.article.featuredImageUrl!,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article.title,
                            style: context.headingStyle.copyWith(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 15.sp,
                                color: context.textSecondary,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                _formatJalali(widget.article.date),
                                style: context.bodyStyle.copyWith(
                                  fontSize: 12.5.sp,
                                  color: context.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: _toggleLike,
                                borderRadius: BorderRadius.circular(20.r),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.heart,
                                        size: 18.sp,
                                        color: _liked
                                            ? Colors.pinkAccent
                                            : context.textSecondary,
                                      ),
                                      if (_likeCount > 0) ...[
                                        SizedBox(width: 4.w),
                                        Text(
                                          _likeCount.toString(),
                                          style: context.bodyStyle.copyWith(
                                            fontSize: 12.sp,
                                            color: _liked
                                                ? Colors.pinkAccent
                                                : context.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.h),
                          RatingStars(
                            average: _avgRating,
                            count: _ratingCount,
                            myRating: _myRating,
                            onRate: (v) async {
                              try {
                                final out =
                                    await ArticleRatingSupabaseService.upsert(
                                      widget.article.id,
                                      v,
                                    );
                                if (mounted) {
                                  setState(() {
                                    _avgRating = out.avg;
                                    _ratingCount = out.count;
                                    _myRating = v;
                                  });
                                  _syncStatsCache();
                                }
                              } catch (_) {}
                            },
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isRead ? null : _markAsRead,
                              style: AppTheme.primaryButtonStyle.copyWith(
                                padding: WidgetStateProperty.all(
                                  EdgeInsets.symmetric(vertical: 13.h),
                                ),
                              ),
                              icon: Icon(
                                _isRead
                                    ? LucideIcons.checkCircle2
                                    : LucideIcons.check,
                                size: 18.sp,
                              ),
                              label: Text(
                                _isRead ? 'مطالعه شده' : 'مطالعه کردم',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: context.separatorColor),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.w),
                              child: ArticleContent(
                                contentHtml: widget.article.contentHtml,
                                stripDuplicateTitle: widget.article.title,
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          CommentForm(onSubmit: _submitComment),
                          SizedBox(height: 16.h),
                          _buildCommentsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final total = _comments.length;
    if (_loadingComments) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(width: 12.w),
            Text(
              'در حال بارگیری نظرات...',
              style: context.bodyStyle.copyWith(fontSize: 12.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.messageCircle,
              size: 18.sp,
              color: context.textColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'نظرات کاربران',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (total > 0)
              Text(
                '$total نظر',
                style: context.bodyStyle.copyWith(
                  fontSize: 11.sp,
                  color: context.textSecondary,
                ),
              ),
          ],
        ),
        SizedBox(height: 12.h),
        if (_comments.isEmpty)
          _buildEmptyCommentsState()
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.separatorColor),
            ),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: EdgeInsets.all(12.w),
              itemCount: _comments.length,
              separatorBuilder: (_, __) =>
                  Divider(color: context.separatorColor, height: 16),
              itemBuilder: (context, i) {
                final c = _comments[i];
                final userId = (c['user_id'] ?? '').toString();
                final profile = _profilesByUserId[userId];
                final firstName = profile?['first_name']?.toString() ?? '';
                final lastName = profile?['last_name']?.toString() ?? '';
                final username = profile?['username']?.toString() ?? '';
                final namePart = [firstName, lastName]
                    .where((e) => e.isNotEmpty)
                    .join(' ')
                    .trim();
                final displayName = namePart.isNotEmpty
                    ? namePart
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
          ),
      ],
    );
  }

  Widget _buildEmptyCommentsState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: context.textSecondary,
            size: 22.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هنوز نظری ثبت نشده',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'اولین نفر باشید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
