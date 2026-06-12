import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/motivational_video.dart';
import 'package:gymaipro/academy/services/motivational_video_service.dart';
import 'package:gymaipro/academy/widgets/motivational_video_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MotivationalVideosScreen extends StatefulWidget {
  const MotivationalVideosScreen({super.key});

  @override
  State<MotivationalVideosScreen> createState() =>
      _MotivationalVideosScreenState();
}

class _MotivationalVideosScreenState extends State<MotivationalVideosScreen> {
  List<MotivationalVideo> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    setState(() => _isLoading = true);
    try {
      final videos = await MotivationalVideoService.fetchVideos(
        forceRefresh: refresh,
      );
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در بارگیری ویدیوها: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.backgroundColor,
      child: RefreshIndicator(
        onRefresh: () => _loadVideos(refresh: true),
        color: AppTheme.goldColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : _videos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.video,
                      size: 64.sp,
                      color: context.textSecondary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'ویدیویی یافت نشد',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.video,
                            size: 20.sp,
                            color: AppTheme.goldColor,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'ویدیوهای انگیزشی',
                            style: AppTheme.headingStyle.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_videos.length} ویدیو',
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 12.sp,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Videos List
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return MotivationalVideoCard(
                          video: _videos[index],
                          index: index,
                        );
                      }, childCount: _videos.length),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
