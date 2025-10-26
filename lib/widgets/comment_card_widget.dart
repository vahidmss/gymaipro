import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:gymaipro/models/exercise_comment.dart';
import 'package:gymaipro/services/exercise_comment_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

class CommentCardWidget extends StatefulWidget {
  const CommentCardWidget({
    required this.comment,
    super.key,
    this.onEdit,
    this.onDelete,
    this.onReply,
  });
  final ExerciseComment comment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onReply;

  @override
  State<CommentCardWidget> createState() => _CommentCardWidgetState();
}

class _CommentCardWidgetState extends State<CommentCardWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            _buildUserHeader(),
            const SizedBox(height: 12),

            // Rating (if exists)
            if (widget.comment.hasRating) _buildRating(),

            // Comment Content
            _buildCommentContent(),
            const SizedBox(height: 12),

            // Actions Bar
            _buildActionsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        // User Avatar
        Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 2.w,
            ),
          ),
          child: ClipOval(
            child: widget.comment.userAvatar != null
                ? CachedNetworkImage(
                    imageUrl: widget.comment.userAvatar!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 24.sp,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 24.sp,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[600],
                      size: 24.sp,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.comment.userFullName ??
                    widget.comment.username ??
                    'کاربر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDate(widget.comment.createdAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),

        // Edit/Delete Menu (if user owns the comment)
        if (_isCurrentUserComment())
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  widget.onEdit?.call();
                case 'delete':
                  _showDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('ویرایش'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18.sp, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('حذف', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRating() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: List.generate(5, (index) {
          return Icon(
            index < (widget.comment.rating ?? 0)
                ? Icons.star
                : Icons.star_border,
            color: AppTheme.goldColor,
            size: 20.sp,
          );
        }),
      ),
    );
  }

  Widget _buildCommentContent() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.comment.content,
            style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.4),
          ),
          if (widget.comment.isEdited)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '(ویرایش شده)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsBar() {
    return Row(
      children: [
        // Reply Button
        TextButton.icon(
          onPressed: () => widget.onReply?.call(widget.comment.id),
          icon: Icon(
            Icons.reply,
            size: 18.sp,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          label: Text(
            'پاسخ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12.sp,
            ),
          ),
        ),

        const Spacer(),

        // Reactions
        _buildReactionButton('like', '👍'),
        const SizedBox(width: 8),
        _buildReactionButton('heart', '❤️'),
        const SizedBox(width: 8),
        _buildReactionButton('dislike', '👎'),
      ],
    );
  }

  Widget _buildReactionButton(String reactionType, String emoji) {
    final isActive = widget.comment.hasUserReaction(
      _getCurrentUserId(),
      reactionType,
    );

    final count = _getReactionCount(reactionType);

    return InkWell(
      onTap: _isLoading ? null : () => _handleReaction(reactionType),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.goldColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive
                ? AppTheme.goldColor
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isActive
                      ? AppTheme.goldColor
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
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
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final currentUserId = _getCurrentUserId();
      final hasReaction = widget.comment.hasUserReaction(
        currentUserId,
        reactionType,
      );

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

      // Refresh the comment
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت واکنش: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('حذف نظر', style: TextStyle(color: Colors.white)),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید این نظر را حذف کنید؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  bool _isCurrentUserComment() {
    final currentUserId = _getCurrentUserId();
    return currentUserId == widget.comment.userId;
  }

  String _getCurrentUserId() {
    // This should get the current user ID from your auth service
    // For now, returning empty string
    return '';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقیقه پیش';
    } else {
      return 'همین الان';
    }
  }
}
