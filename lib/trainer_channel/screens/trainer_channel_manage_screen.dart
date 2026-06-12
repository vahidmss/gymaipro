import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/constants/trainer_channel_constants.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_composer_payload.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:gymaipro/trainer_channel/services/trainer_channel_service.dart';
import 'package:gymaipro/trainer_channel/services/trainer_channel_upload_service.dart';
import 'package:gymaipro/trainer_channel/theme/trainer_channel_theme.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_compose_bar.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_edit_sheet.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_feed_list.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// مدیریت و ارسال پست کانال — شبیه تلگرام
class TrainerChannelManageScreen extends StatefulWidget {
  const TrainerChannelManageScreen({super.key});

  @override
  State<TrainerChannelManageScreen> createState() =>
      _TrainerChannelManageScreenState();
}

class _TrainerChannelManageScreenState extends State<TrainerChannelManageScreen> {
  final TrainerChannelService _service = TrainerChannelService();
  final TrainerChannelUploadService _uploadService =
      TrainerChannelUploadService();
  final ScrollController _scrollController = ScrollController();

  TrainerChannel? _channel;
  List<TrainerChannelPost> _posts = [];
  int _todayPostCount = 0;
  int _remainingToday = 0;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final channel = await _service.ensureChannelForCurrentTrainer();
      final profile = await SimpleProfileService.getCurrentProfile();
      final trainerId = profile?['id']?.toString() ?? '';
      final posts = await _service.getPosts(
        trainerId: trainerId,
        includeWhenDisabledForOwner: true,
        forceRefresh: true,
      );
      posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final todayCount = await _service.getTodayPostCount(channel.id);
      final remaining = await _service.remainingPostsToday(channel.id);
      if (!mounted) return;
      setState(() {
        _channel = channel;
        _posts = posts;
        _todayPostCount = todayCount;
        _remainingToday = remaining;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    final ch = _channel;
    if (ch == null) return;
    await _service.setChannelEnabled(
      channelId: ch.id,
      enabled: value,
      trainerId: ch.trainerId,
    );
    setState(() {
      _channel = TrainerChannel(
        id: ch.id,
        trainerId: ch.trainerId,
        isEnabled: value,
        createdAt: ch.createdAt,
        updatedAt: DateTime.now(),
        postCount: ch.postCount,
        lastPostAt: ch.lastPostAt,
      );
      _changed = true;
    });
  }

  Future<void> _onPublished(TrainerChannelComposerPayload payload) async {
    final ch = _channel;
    if (ch == null) return;

    // optimistic: add placeholder immediately so UI doesn't freeze
    final placeholder = TrainerChannelPost(
      id: 'sending_${DateTime.now().millisecondsSinceEpoch}',
      channelId: ch.id,
      trainerId: ch.trainerId,
      contentType: payload.contentType,
      textContent: payload.textContent,
      mediaUrl: payload.mediaUrl,
      mediaDurationSeconds: payload.mediaDurationSeconds,
      createdAt: DateTime.now(),
    );

    setState(() {
      _posts = [..._posts, placeholder];
      _remainingToday = (_remainingToday - 1).clamp(0, TrainerChannelConstants.maxPostsPerDay);
      _changed = true;
    });
    _scrollToBottom();

    try {
      final saved = await _service.createPost(
        channelId: ch.id,
        trainerId: ch.trainerId,
        contentType: payload.contentType,
        textContent: payload.textContent,
        mediaUrl: payload.mediaUrl,
        mediaDurationSeconds: payload.mediaDurationSeconds,
      );

      if (!mounted) return;

      var channelEnabled = ch.isEnabled;
      if (!ch.isEnabled && _posts.where((p) => !p.id.startsWith('sending_')).length <= 1) {
        await _service.setChannelEnabled(
          channelId: ch.id,
          enabled: true,
          trainerId: ch.trainerId,
        );
        channelEnabled = true;
      }

      // replace placeholder with real post
      setState(() {
        _channel = TrainerChannel(
          id: ch.id,
          trainerId: ch.trainerId,
          isEnabled: channelEnabled,
          createdAt: ch.createdAt,
          updatedAt: DateTime.now(),
          postCount: ch.postCount + 1,
          lastPostAt: saved.createdAt,
        );
        _posts = _posts.map((p) => p.id == placeholder.id ? saved : p).toList();
        _todayPostCount += 1;
      });
    } catch (e) {
      if (!mounted) return;
      // roll back
      setState(() {
        _posts = _posts.where((p) => p.id != placeholder.id).toList();
        _remainingToday += 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _editPost(TrainerChannelPost post) async {
    final newText = await showTrainerChannelEditSheet(
      context: context,
      post: post,
    );
    if (newText == null) return;

    final oldText = post.contentType == TrainerChannelContentType.text
        ? (post.textContent ?? '').trim()
        : post.displayCaption;
    if (newText.trim() == oldText) return;

    try {
      await _service.updatePostText(
        postId: post.id,
        contentType: post.contentType,
        textContent: newText,
        trainerId: _channel?.trainerId,
      );
      _changed = true;
      if (mounted) {
        setState(() {
          _posts = _posts.map((p) {
            if (p.id != post.id) return p;
            return TrainerChannelPost(
              id: p.id,
              channelId: p.channelId,
              trainerId: p.trainerId,
              contentType: p.contentType,
              textContent: newText,
              mediaUrl: p.mediaUrl,
              mediaDurationSeconds: p.mediaDurationSeconds,
              createdAt: p.createdAt,
              updatedAt: DateTime.now(),
              trainerName: p.trainerName,
              trainerAvatarUrl: p.trainerAvatarUrl,
              trainerUsername: p.trainerUsername,
            );
          }).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ویرایش ذخیره شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _confirmDelete(TrainerChannelPost post) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف پیام'),
        content: const Text('این پست از کانال حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // پست موقت optimistic — فقط از UI حذف می‌شود
    if (post.id.startsWith('sending_')) {
      setState(() {
        _posts = _posts.where((p) => p.id != post.id).toList();
      });
      return;
    }

    // فوری از UI حذف کن (مثل تلگرام)
    final previous = _posts;
    setState(() {
      _posts = _posts.where((p) => p.id != post.id).toList();
      _changed = true;
    });

    try {
      await _service.deletePost(
        post.id,
        trainerId: _channel?.trainerId ?? post.trainerId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پست حذف شد')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _posts = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showChannelMenu() {
    final ch = _channel;
    if (ch == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('کانال فعال (عمومی)'),
              subtitle: Text(
                ch.isEnabled
                    ? 'همه می‌توانند ببینند'
                    : 'فقط شما می‌بینید',
              ),
              value: ch.isEnabled,
              activeThumbColor: AppTheme.goldColor,
              onChanged: (v) {
                Navigator.pop(ctx);
                _toggleEnabled(v);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.info, color: AppTheme.goldColor),
              title: Text(
                'امروز $_todayPostCount از ${TrainerChannelConstants.maxPostsPerDay}',
              ),
              subtitle: const Text(
                'نگه‌داشتن پیام: ویرایش یا حذف · گیره = پیوست',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      child: Scaffold(
        backgroundColor: TrainerChannelTheme.scaffoldBackground(isDark),
        appBar: AppBar(
          backgroundColor: TrainerChannelTheme.appBarBackground(isDark),
          leading: IconButton(
            onPressed: () => Navigator.pop(context, _changed),
            icon: Icon(
              LucideIcons.arrowRight,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          title: Column(
            children: [
              Text(
                'کانال من',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              if (!_loading)
                Text(
                  '${_posts.length} پست · امروز $_remainingToday باقی‌مانده',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: AppTheme.lightTextSecondary,
                  ),
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _showChannelMenu,
              icon: const Icon(LucideIcons.moreVertical, color: AppTheme.goldColor),
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : TrainerChannelTheme.wallpaper(
                isDark: isDark,
                child: Column(
                  children: [
                    if (_channel != null && !_channel!.isEnabled)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        color: Colors.orange.withValues(alpha: 0.2),
                        child: Text(
                          'کانال غیرفعال است — فقط شما می‌بینید. از منو فعال کنید.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    Expanded(
                      child: _posts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.radio,
                                      size: 56.sp,
                                      color:
                                          AppTheme.goldColor.withValues(alpha: 0.5),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'کانال شما خالی است',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'مثل تلگرام: پایین بنویسید یا گیره را بزنید\n(عکس · ویدیو · صدا)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 13.sp,
                                        color: AppTheme.lightTextSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : TrainerChannelFeedList(
                              posts: _posts,
                              scrollController: _scrollController,
                              isOwner: true,
                              onDelete: _confirmDelete,
                              onEdit: _editPost,
                            ),
                    ),
                    TrainerChannelComposeBar(
                      uploadService: _uploadService,
                      remainingToday: _remainingToday,
                      onPublished: _onPublished,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
