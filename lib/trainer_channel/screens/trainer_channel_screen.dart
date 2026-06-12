import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_channel/models/trainer_channel_post.dart';
import 'package:gymaipro/trainer_channel/screens/trainer_channel_manage_screen.dart';
import 'package:gymaipro/trainer_channel/services/trainer_channel_service.dart';
import 'package:gymaipro/trainer_channel/theme/trainer_channel_theme.dart';
import 'package:gymaipro/trainer_channel/widgets/trainer_channel_feed_list.dart';
import 'package:gymaipro/widgets/gymai_trainer_avatar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نمایش کانال مربی برای بازدیدکنندگان (شبیه تلگرام)
class TrainerChannelScreen extends StatefulWidget {
  const TrainerChannelScreen({
    required this.trainer,
    super.key,
  });

  final UserProfile trainer;

  @override
  State<TrainerChannelScreen> createState() => _TrainerChannelScreenState();
}

class _TrainerChannelScreenState extends State<TrainerChannelScreen> {
  final TrainerChannelService _service = TrainerChannelService();
  final ScrollController _scrollController = ScrollController();
  List<TrainerChannelPost> _posts = [];
  bool _loading = true;
  String? _error;
  bool _isOwner = false;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      final myId = profile?['id']?.toString();
      final posts = await _service.getPosts(
        trainerId: widget.trainer.id!,
        forceRefresh: true,
      );
      posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isOwner = myId != null && myId == widget.trainer.id;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openManage() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const TrainerChannelManageScreen(),
      ),
    );
    if (changed ?? false) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.trainer.fullName.isNotEmpty
        ? widget.trainer.fullName
        : widget.trainer.username;

    return Scaffold(
      backgroundColor: TrainerChannelTheme.scaffoldBackground(isDark),
      appBar: AppBar(
        backgroundColor: TrainerChannelTheme.appBarBackground(isDark),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            LucideIcons.arrowRight,
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GymaiTrainerAvatar(
              avatarUrl: widget.trainer.avatarUrl,
              userId: widget.trainer.id,
              username: widget.trainer.username,
              size: 32.w,
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'کانال',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: AppTheme.goldColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_isOwner)
            IconButton(
              onPressed: _openManage,
              icon: const Icon(LucideIcons.edit3, color: AppTheme.goldColor),
              tooltip: 'ارسال پست',
            ),
        ],
      ),
      body: TrainerChannelTheme.wallpaper(
        isDark: isDark,
        child: RefreshIndicator(
          color: AppTheme.goldColor,
          onRefresh: _load,
          child: _buildBody(isDark),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          const Center(child: CircularProgressIndicator(color: AppTheme.goldColor)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          Icon(LucideIcons.alertCircle, size: 48.sp, color: Colors.red.shade300),
          SizedBox(height: 12.h),
          Text(
            'خطا در بارگذاری کانال',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 15.sp),
          ),
          TextButton(onPressed: _load, child: const Text('تلاش مجدد')),
        ],
      );
    }

    if (_posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          _buildEmpty(isDark),
        ],
      );
    }

    return TrainerChannelFeedList(
      posts: _posts,
      scrollController: _scrollController,
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          Icon(
            LucideIcons.inbox,
            size: 56.sp,
            color: AppTheme.goldColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'هنوز پستی نیست',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isOwner) ...[
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: _openManage,
              icon: Icon(LucideIcons.send, size: 18.sp),
              label: const Text('اولین پست را بفرستید'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
