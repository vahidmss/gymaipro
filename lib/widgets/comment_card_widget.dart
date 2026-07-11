import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise_comment.dart';
import 'package:gymaipro/services/exercise_comment_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentCardWidget extends StatefulWidget {
  const CommentCardWidget({
    required this.comment,
    super.key,
    this.onEdit,
    this.onDelete,
    this.onReply,
    this.onReactionsChanged,
  });

  final ExerciseComment comment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(String)? onReply;
  final VoidCallback? onReactionsChanged;

  @override
  State<CommentCardWidget> createState() => _CommentCardWidgetState();
}

class _CommentCardWidgetState extends State<CommentCardWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : AppTheme.goldColor.withValues(alpha: 0.18);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserHeader(),
            SizedBox(height: 14.h),
            _buildCommentContent(),
            SizedBox(height: 14.h),
            _buildActionsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final displayName =
        widget.comment.userFullName ?? widget.comment.username ?? 'کاربر';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_isCurrentUserComment()) ...[
                    SizedBox(width: 4.w),
                    _buildOwnerMenu(),
                  ],
                ],
              ),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildMetaPill(
                    icon: LucideIcons.clock3,
                    label: _formatDate(widget.comment.createdAt),
                  ),
                  if (widget.comment.isEdited)
                    _buildMetaPill(
                      icon: LucideIcons.pencil,
                      label: 'ویرایش شده',
                    ),
                  if (widget.comment.hasRating) _buildRatingPill(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor =
        isDark ? Colors.grey[850]! : Colors.grey[200]!;

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: ClipOval(
        child: widget.comment.userAvatar != null &&
                widget.comment.userAvatar!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.comment.userAvatar!,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: placeholderColor,
                  child: Icon(
                    LucideIcons.user,
                    color: context.textSecondary,
                    size: 19.sp,
                  ),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: placeholderColor,
                  child: Icon(
                    LucideIcons.user,
                    color: context.textSecondary,
                    size: 19.sp,
                  ),
                ),
              )
            : ColoredBox(
                color: placeholderColor,
                child: Icon(
                  LucideIcons.user,
                  color: context.textSecondary,
                  size: 19.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.sp, color: context.textSecondary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final filled = index < (widget.comment.rating ?? 0);
          return Padding(
            padding: EdgeInsets.only(left: index == 4 ? 0 : 1.w),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppTheme.goldColor,
              size: 13.sp,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOwnerMenu() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(
        LucideIcons.ellipsisVertical,
        size: 17.sp,
        color: context.textSecondary,
      ),
      color: context.cardColor,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            widget.onEdit?.call();
          case 'delete':
            _showDeleteDialog();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(LucideIcons.pencil, size: 16.sp, color: context.textColor),
              SizedBox(width: 8.w),
              Text(
                'ویرایش',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 16.sp, color: Colors.redAccent),
              SizedBox(width: 8.w),
              const Text(
                'حذف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Text(
        widget.comment.content,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: context.textColor,
          fontSize: 14.5.sp,
          height: 1.85,
        ),
      ),
    );
  }

  Widget _buildActionsBar() {
    final hasReply = widget.onReply != null;
    return Row(
      children: [
        if (hasReply)
          TextButton.icon(
            onPressed: () => widget.onReply?.call(widget.comment.id),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: context.textSecondary,
            ),
            icon: Icon(
              LucideIcons.reply,
              size: 14.sp,
              color: context.textSecondary,
            ),
            label: Text(
              'پاسخ',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const Spacer(),
        _buildReactionButton(
          reactionType: 'like',
          icon: LucideIcons.thumbsUp,
          activeColor: AppTheme.proteinColor,
        ),
        SizedBox(width: 6.w),
        _buildReactionButton(
          reactionType: 'heart',
          icon: LucideIcons.heart,
          activeColor: Colors.pinkAccent,
        ),
        SizedBox(width: 6.w),
        _buildReactionButton(
          reactionType: 'dislike',
          icon: LucideIcons.thumbsDown,
          activeColor: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildReactionButton({
    required String reactionType,
    required IconData icon,
    required Color activeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.comment.hasUserReaction(
      _getCurrentUserId(),
      reactionType,
    );
    final count = _getReactionCount(reactionType);

    return InkWell(
      onTap: _isLoading ? null : () => _handleReaction(reactionType),
      borderRadius: BorderRadius.circular(999.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minWidth: 38.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.025)),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.55)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isActive ? activeColor : context.textSecondary,
            ),
            if (count > 0) ...[
              SizedBox(width: 4.w),
              Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: isActive ? activeColor : context.textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getReactionCount(String reactionType) {
    switch (reactionType) {
      case 'like':
        return widget.comment.likeCount;
      case 'heart':
        return widget.comment.heartCount;
      case 'dislike':
        return widget.comment.dislikeCount;
      default:
        return 0;
    }
  }

  Future<void> _handleReaction(String reactionType) async {
    final userId = _getCurrentUserId();
    if (userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای ثبت واکنش ابتدا وارد حساب شوید')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final hasReaction = widget.comment.hasUserReaction(userId, reactionType);

      if (hasReaction) {
        await ExerciseCommentService.removeReaction(
          commentId: widget.comment.id,
          reactionType: reactionType,
        );
      } else {
        await ExerciseCommentService.addReaction(
          commentId: widget.comment.id,
          reactionType: reactionType,
        );
      }

      SafeSetState.call(this, () {});
      widget.onReactionsChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ثبت واکنش: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'حذف نظر',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: dialogContext.textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید این نظر را حذف کنید؟',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: dialogContext.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: dialogContext.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  bool _isCurrentUserComment() {
    final currentUserId = _getCurrentUserId();
    return currentUserId.isNotEmpty && currentUserId == widget.comment.userId;
  }

  String _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} روز پیش';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} ساعت پیش';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقیقه پیش';
    }
    return 'همین الان';
  }
}
