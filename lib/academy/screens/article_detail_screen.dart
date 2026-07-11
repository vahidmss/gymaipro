import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/services/article_comment_supabase_service.dart';
import 'package:gymaipro/academy/services/article_like_supabase_service.dart';
import 'package:gymaipro/academy/services/article_rating_supabase_service.dart';
import 'package:gymaipro/academy/services/article_read_supabase_service.dart';
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
    // Load all stats in parallel for faster loading
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
    final rows = await ProfileRepository.instance.fetchProfilesByIdentifiers(ids);
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
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final background = context.backgroundColor;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Always reload stats when returning to ensure they're up to date
        Navigator.pop(context, {
          'articleId': widget.article.id,
          'isRead': _markedReadLocally || _isRead,
          'statsChanged': true,
        });
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleSpacing: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bookOpen,
                size: 18.sp,
                color: AppTheme.goldColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'جزئیات مقاله',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: _loadingStats
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.article.featuredImageUrl != null)
                      Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.2),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20.r),
                            bottomRight: Radius.circular(20.r),
                          ),
                          child: ArticleImage(
                            imageUrl: widget.article.featuredImageUrl!,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(18.w),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 12.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.article.title,
                                  style: AppTheme.headingStyle.copyWith(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w900,
                                    color: context.textColor,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Wrap(
                                  spacing: 12.w,
                                  runSpacing: 8.h,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.calendar,
                                          size: 16.sp,
                                          color: AppTheme.goldColor,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          _formatJalali(widget.article.date),
                                          style: AppTheme.bodyStyle.copyWith(
                                            fontSize: 12.sp,
                                            color: context.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: _toggleLike,
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _liked
                                              ? Colors.pinkAccent.withValues(
                                                  alpha: 0.15,
                                                )
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              LucideIcons.heart,
                                              size: 16.sp,
                                              color: _liked
                                                  ? Colors.pinkAccent
                                                  : context.textSecondary,
                                            ),
                                            if (_likeCount > 0) ...[
                                              SizedBox(width: 4.w),
                                              Text(
                                                _likeCount.toString(),
                                                style: AppTheme.bodyStyle
                                                    .copyWith(
                                                      fontSize: 12.sp,
                                                      color: _liked
                                                          ? Colors.pinkAccent
                                                          : context
                                                                .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
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
                                      }
                                    } catch (_) {}
                                  },
                                ),
                                SizedBox(height: 16.h),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.icon(
                                    onPressed: _isRead
                                        ? null
                                        : () async {
                                            try {
                                              await ArticleReadSupabaseService.markAsRead(
                                                widget.article.id,
                                              );
                                              if (!context.mounted) return;
                                              setState(() {
                                                _isRead = true;
                                                _markedReadLocally = true;
                                              });
                                              // به‌روزرسانی امتیاز در پس‌زمینه تا UI سبک بماند
                                              RankingService().updateCurrentUserRanking().catchError((_, __) {});
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        LucideIcons
                                                            .checkCircle2,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          'این مقاله به‌عنوان مطالعه‌شده ثبت شد.',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  backgroundColor: Colors.green,
                                                  duration: Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'خطا در ثبت وضعیت مطالعه: $e',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                    style: AppTheme.primaryButtonStyle.copyWith(
                                      padding: WidgetStateProperty.all(
                                        EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 12.h,
                                        ),
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
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Container(
                            padding: EdgeInsets.all(18.w),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: AppTheme.goldColor.withValues(
                                  alpha: 0.18,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: ArticleContent(
                              contentHtml: widget.article.contentHtml,
                            ),
                          ),
                          SizedBox(height: 16.h),
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
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.goldColor),
            SizedBox(width: 12.w),
            Text(
              'در حال بارگیری نظرات...',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 12.sp,
                color: context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // Card container برای کل بخش نظرات
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.messageCircle,
                  size: 18.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'نظرات کاربران',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (total > 0)
                  Text(
                    '$total نظر',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 11.sp,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Divider(color: context.separatorColor, height: 1),
            SizedBox(height: 8.h),
            if (_comments.isEmpty)
              _buildEmptyCommentsState()
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.zero,
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCommentsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : AppTheme.goldColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.separatorColor.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.messageCircle,
            color: context.textSecondary,
            size: 44.sp,
          ),
          SizedBox(height: 14.h),
          Text(
            'هنوز نظری ثبت نشده',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'اولین نفری باشید که نظر خود را می‌نویسد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 13.sp,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
