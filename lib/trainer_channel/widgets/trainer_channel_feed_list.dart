import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:gymaipro/trainer_channel/theme/trainer_channel_theme.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_format.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_post_bubble.dart';

class TrainerChannelFeedList extends StatefulWidget {
  const TrainerChannelFeedList({
    required this.posts,
    required this.scrollController,
    this.isOwner = false,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  final List<TrainerChannelPost> posts;
  final ScrollController scrollController;
  final bool isOwner;
  final void Function(TrainerChannelPost post)? onDelete;
  final void Function(TrainerChannelPost post)? onEdit;

  @override
  State<TrainerChannelFeedList> createState() => _TrainerChannelFeedListState();
}

class _TrainerChannelFeedListState extends State<TrainerChannelFeedList> {
  List<_FeedItem>? _cachedItems;
  Object? _postsCacheKey;

  List<_FeedItem> get _items {
    final key = Object.hashAll(
      widget.posts.map(
        (p) => Object.hash(p.id, p.updatedAt, p.textContent, p.mediaUrl),
      ),
    );
    if (_cachedItems == null || _postsCacheKey != key) {
      _postsCacheKey = key;
      _cachedItems = _buildItems(widget.posts);
    }
    return _cachedItems!;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return ListView.builder(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 16.h),
      itemCount: items.length,
      addAutomaticKeepAlives: false,
      cacheExtent: 400,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isDateDivider) {
          return _DateDivider(label: item.dateLabel!);
        }
        return RepaintBoundary(
          child: TrainerChannelPostBubble(
            post: item.post!,
            isOwner: widget.isOwner,
            isFirstInGroup: item.isFirstInGroup,
            isLastInGroup: item.isLastInGroup,
            onDelete: widget.onDelete != null
                ? () => widget.onDelete!(item.post!)
                : null,
            onEdit: widget.onEdit != null && item.post!.canEditText
                ? () => widget.onEdit!(item.post!)
                : null,
          ),
        );
      },
    );
  }

  static List<_FeedItem> _buildItems(List<TrainerChannelPost> posts) {
    if (posts.isEmpty) return [];

    final sorted = List<TrainerChannelPost>.from(posts)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final out = <_FeedItem>[];
    DateTime? lastDay;

    for (var i = 0; i < sorted.length; i++) {
      final post = sorted[i];
      final day = DateTime(
        post.createdAt.year,
        post.createdAt.month,
        post.createdAt.day,
      );
      if (lastDay == null || day != lastDay) {
        out.add(_FeedItem.date(formatChannelDateDivider(post.createdAt)));
        lastDay = day;
      }

      final prev = i > 0 ? sorted[i - 1] : null;
      final next = i < sorted.length - 1 ? sorted[i + 1] : null;
      final gapPrev = _minutesBetween(prev?.createdAt, post.createdAt);
      final gapNext = _minutesBetween(post.createdAt, next?.createdAt);

      out.add(
        _FeedItem.post(
          post,
          isFirstInGroup: gapPrev == null || gapPrev > 5,
          isLastInGroup: gapNext == null || gapNext > 5,
        ),
      );
    }
    return out;
  }

  static int? _minutesBetween(DateTime? a, DateTime? b) {
    if (a == null || b == null) return null;
    return b.difference(a).inMinutes.abs();
  }
}

class _FeedItem {
  _FeedItem.date(this.dateLabel)
      : isDateDivider = true,
        post = null,
        isFirstInGroup = true,
        isLastInGroup = true;

  _FeedItem.post(
    this.post, {
    required this.isFirstInGroup,
    required this.isLastInGroup,
  })  : isDateDivider = false,
        dateLabel = null;

  final bool isDateDivider;
  final String? dateLabel;
  final TrainerChannelPost? post;
  final bool isFirstInGroup;
  final bool isLastInGroup;
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: TrainerChannelTheme.dateChipBackground(isDark),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
