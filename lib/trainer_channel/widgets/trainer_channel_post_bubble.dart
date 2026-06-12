import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:gymaipro/trainer_channel/theme/trainer_channel_theme.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_format.dart';
import 'package:gymaipro/trainer_channel/utils/trainer_channel_text_utils.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_audio_player.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_image_viewer.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_video_viewer.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_video_preview.dart';

/// حباب پیام کانال — مثل تلگرام
class TrainerChannelPostBubble extends StatelessWidget {
  const TrainerChannelPostBubble({
    required this.post,
    this.isOwner = false,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  final TrainerChannelPost post;
  final bool isOwner;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  // پست در حال ارسال (placeholder optimistic)
  bool get _isSending => post.id.startsWith('sending_');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topGap = isFirstInGroup ? 8.h : 3.h;
    final bottomGap = isLastInGroup ? 8.h : 3.h;

    return Padding(
      padding: EdgeInsets.only(top: topGap, bottom: bottomGap),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 0.92.sw),
                child: _BubbleBody(
                  post: post,
                  isDark: isDark,
                  isOwner: isOwner,
                  isSending: _isSending,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                  onDelete: onDelete,
                  onEdit: onEdit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.post,
    required this.isDark,
    required this.isOwner,
    required this.isSending,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.onDelete,
    this.onEdit,
  });

  final TrainerChannelPost post;
  final bool isDark;
  final bool isOwner;
  final bool isSending;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final radius = TrainerChannelTheme.channelBubbleRadius(
      isFirst: isFirstInGroup,
      isLast: isLastInGroup,
    );
    final bubbleColor = TrainerChannelTheme.bubbleColor(isDark);

    return GestureDetector(
      onLongPress: isOwner && !isSending ? () => _showActions(context) : null,
      child: Opacity(
        opacity: isSending ? 0.6 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: radius,
              boxShadow: TrainerChannelTheme.bubbleShadow(isDark),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (post.contentType) {
      case TrainerChannelContentType.image:
        return _ImageMessage(post: post, isDark: isDark, isSending: isSending);
      case TrainerChannelContentType.video:
        return _VideoMessage(post: post, isDark: isDark);
      case TrainerChannelContentType.voice:
      case TrainerChannelContentType.audio:
        return _AudioMessage(post: post, isDark: isDark, isSending: isSending);
      case TrainerChannelContentType.text:
        return _TextMessage(post: post, isDark: isDark);
    }
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1C2B3A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              if (onEdit != null)
                _ActionTile(
                  icon: Icons.edit_outlined,
                  label: post.hasMedia ? 'ویرایش کپشن' : 'ویرایش متن',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit!();
                  },
                ),
              if (onDelete != null)
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'حذف پیام',
                  color: Colors.red.shade400,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── عکس ─────────────────────────────────────────────────
class _ImageMessage extends StatelessWidget {
  const _ImageMessage({
    required this.post,
    required this.isDark,
    required this.isSending,
  });
  final TrainerChannelPost post;
  final bool isDark;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final url = post.mediaUrl!;
    final heroTag = 'channel_img_${post.id}';
    final hasCaption = post.hasCaption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: isSending
              ? null
              : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TrainerChannelImageViewer(
                        url: url,
                        heroTag: heroTag,
                        caption: post.displayCaption,
                      ),
                    ),
                  ),
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: double.infinity,
              memCacheWidth: 600,
              placeholder: (_, __) => Container(
                height: 200.h,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 120.h,
                color: Colors.black12,
                child: const Icon(Icons.broken_image, color: Colors.white38),
              ),
            ),
          ),
        ),
        if (hasCaption)
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
            child: _CaptionText(text: post.displayCaption, isDark: isDark),
          ),
        _Footer(post: post, isDark: isDark, hasMedia: true),
      ],
    );
  }
}

// ─── ویدیو ───────────────────────────────────────────────
class _VideoMessage extends StatelessWidget {
  const _VideoMessage({required this.post, required this.isDark});
  final TrainerChannelPost post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = post.mediaUrl!;
    final hasCaption = post.hasCaption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainerChannelVideoThumbnail(
          durationSeconds: post.mediaDurationSeconds,
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => TrainerChannelVideoViewer(
                url: url,
                caption: post.displayCaption.isEmpty ? null : post.displayCaption,
              ),
            ),
          ),
        ),
        if (hasCaption)
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
            child: _CaptionText(text: post.displayCaption, isDark: isDark),
          ),
        _Footer(post: post, isDark: isDark, hasMedia: true),
      ],
    );
  }
}

// ─── صدا (ویس + فایل صوتی) ───────────────────────────────
class _AudioMessage extends StatelessWidget {
  const _AudioMessage({
    required this.post,
    required this.isDark,
    required this.isSending,
  });
  final TrainerChannelPost post;
  final bool isDark;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
          child: isSending
              ? _SendingAudioPlaceholder(isDark: isDark)
              : TrainerChannelAudioPlayer(
                  url: post.mediaUrl!,
                  durationSeconds: post.mediaDurationSeconds,
                  mode: post.contentType == TrainerChannelContentType.audio
                      ? TrainerChannelAudioPlayerMode.audioFile
                      : TrainerChannelAudioPlayerMode.voice,
                  title: post.contentType == TrainerChannelContentType.audio
                      ? (post.textContent?.trim().isNotEmpty ?? false
                          ? post.textContent
                          : null)
                      : null,
                ),
        ),
        // کپشن برای فایل صوتی زیر موج
        if (post.contentType != TrainerChannelContentType.audio &&
            post.hasCaption)
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 0),
            child: _CaptionText(text: post.displayCaption, isDark: isDark),
          ),
        _Footer(post: post, isDark: isDark, hasMedia: false),
      ],
    );
  }
}

class _SendingAudioPlaceholder extends StatelessWidget {
  const _SendingAudioPlaceholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: AppTheme.goldColor.withValues(alpha: 0.4)),
            color: AppTheme.goldColor.withValues(alpha: 0.08),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.goldColor,
              strokeWidth: 2,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: 20.h,
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'در حال آپلود…',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10.sp,
                  color: AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── متن ─────────────────────────────────────────────────
class _TextMessage extends StatelessWidget {
  const _TextMessage({required this.post, required this.isDark});
  final TrainerChannelPost post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final text = post.textContent ?? '';
    final dir = TrainerChannelTextUtils.textDirectionFor(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0),
          child: Directionality(
            textDirection: dir,
            child: Text(
              text,
              textAlign: TrainerChannelTextUtils.textAlignFor(text),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                height: 1.5,
                color: isDark
                    ? AppTheme.darkTextColor
                    : AppTheme.lightTextColor,
              ),
            ),
          ),
        ),
        _Footer(post: post, isDark: isDark, hasMedia: false),
      ],
    );
  }
}

// ─── کپشن ────────────────────────────────────────────────
class _CaptionText extends StatelessWidget {
  const _CaptionText({required this.text, required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dir = TrainerChannelTextUtils.textDirectionFor(text);
    return Directionality(
      textDirection: dir,
      child: Text(
        text,
        textAlign: TrainerChannelTextUtils.textAlignFor(text),
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.sp,
          height: 1.45,
          color: isDark
              ? AppTheme.darkTextColor.withValues(alpha: 0.9)
              : AppTheme.lightTextColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ─── footer (زمان + edited) ───────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({
    required this.post,
    required this.isDark,
    required this.hasMedia,
  });
  final TrainerChannelPost post;
  final bool isDark;
  final bool hasMedia;

  @override
  Widget build(BuildContext context) {
    final timeColor = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.38);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hasMedia ? 10.w : 10.w,
        4.h,
        10.w,
        hasMedia ? 7.h : 6.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (post.isEdited) ...[
            Text(
              'ویرایش‌شده',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.sp,
                color: AppTheme.goldColor.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            formatChannelPostClock(post.createdAt),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── action tile ─────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor);
    return ListTile(
      leading: Icon(icon, color: c, size: 22.sp),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 15.sp,
          color: c,
        ),
      ),
      onTap: onTap,
    );
  }
}
