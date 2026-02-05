import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_comment.dart';
import 'package:gymaipro/services/exercise_comment_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/add_comment_form_widget.dart';
import 'package:gymaipro/widgets/comment_card_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({required this.exercise, super.key});
  final Exercise exercise;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isVideoInitialized = false;
  late TabController _tabController;
  bool _isLoadingComments = false;
  List<ExerciseComment> _comments = [];
  Timer? _downloadStatusTimer;

  // Keyboard management
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeVideo();
    _loadComments();
    _startDownloadStatusTimer();

    // Keyboard visibility listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupKeyboardListener();
    });
  }

  Future<void> _initializeVideo() async {
    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
    });

    try {
      if (widget.exercise.videoUrl.isNotEmpty) {
        final videoCacheService = VideoCacheService();
        final cachedPath = await videoCacheService.getCachedVideoPath(
          widget.exercise.videoUrl,
        );

        VideoPlayerController controller;
        if (cachedPath != null) {
          controller = VideoPlayerController.file(File(cachedPath));
        } else {
          if (videoCacheService.isVideoDownloading(widget.exercise.videoUrl)) {
            controller = VideoPlayerController.network(
              widget.exercise.videoUrl,
            );
          } else {
            final success = await _downloadAndCacheVideo(
              widget.exercise.videoUrl,
            );

            if (success) {
              final newCachedPath = await videoCacheService.getCachedVideoPath(
                widget.exercise.videoUrl,
              );
              if (newCachedPath != null) {
                controller = VideoPlayerController.file(File(newCachedPath));
              } else {
                controller = VideoPlayerController.network(
                  widget.exercise.videoUrl,
                );
              }
            } else {
              controller = VideoPlayerController.network(
                widget.exercise.videoUrl,
              );
            }
          }
        }

        _videoPlayerController = controller;

        try {
          await _videoPlayerController!.initialize().timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw TimeoutException(
                'Video initialization timeout',
                const Duration(minutes: 2),
              );
            },
          );
        } catch (e) {
          try {
            await _videoPlayerController!.initialize().timeout(
              const Duration(minutes: 1),
              onTimeout: () {
                throw TimeoutException(
                  'Video initialization retry timeout',
                  const Duration(minutes: 1),
                );
              },
            );
          } catch (retryError) {
            rethrow;
          }
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppTheme.goldColor,
            handleColor: AppTheme.goldColor,
            backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            bufferedColor: AppTheme.goldColor.withValues(alpha: 0.3),
          ),
          placeholder: ColoredBox(
            color: isDark ? Colors.black : Colors.grey[100]!,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            ),
          ),
          autoInitialize: true,
        );

        WidgetSafetyUtils.safeSetState(this, () {
          _isVideoInitialized = true;
          _isLoading = false;
        });
      } else {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    } catch (e) {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = false;
      });
    }
  }

  Future<bool> _downloadAndCacheVideo(String videoUrl) async {
    try {
      final videoCacheService = VideoCacheService();
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = true;
      });

      final success = await videoCacheService.cacheVideo(videoUrl);

      if (success) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void _setupKeyboardListener() {
    // Listen to keyboard visibility changes (reserved for future use)
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _startDownloadStatusTimer() {
    _downloadStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      SafeSetState.call(this, () {});
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _tabController.dispose();
    _downloadStatusTimer?.cancel();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? _buildLoadingIndicator()
          : Column(
              children: [
                _buildTabBar(),
                Expanded(child: _buildTabContent()),
              ],
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.goldColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildVideoSection() {
    if (widget.exercise.videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _isVideoInitialized && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : _buildVideoLoadingIndicator(),
        ),
      ),
    );
  }

  Widget _buildVideoLoadingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? Colors.black : Colors.grey[100]!,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.goldColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 16.h),
            Text(
              'در حال بارگذاری ویدیو...',
              style: TextStyle(
                color: context.textColor,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  List<String> _splitCSV(String value) {
    if (value.trim().isEmpty) return [];
    return value
        .split(RegExp('[،,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Widget _buildChipsSection({
    required String title,
    required List<String> items,
    required IconData icon,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.goldColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: items
                .map(
                  (e) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppTheme.goldColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.goldColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Text(
                      e,
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          child,
        ],
      ),
    );
  }

  Widget _buildExerciseInfo() {
    final mainChips = _splitCSV(widget.exercise.mainMuscle);
    final secondaryChips = _splitCSV(widget.exercise.secondaryMuscles);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.08),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  LucideIcons.info,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'اطلاعات تمرین',
                style: TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildChipsSection(
            title: 'عضلات اصلی',
            items: mainChips,
            icon: LucideIcons.target,
          ),
          _buildChipsSection(
            title: 'عضلات فرعی',
            items: secondaryChips,
            icon: LucideIcons.activity,
          ),
          Divider(
            color: context.separatorColor,
            height: 32.h,
            thickness: 1.5,
          ),
          _buildInfoRow(
            title: 'سطح دشواری:',
            content: widget.exercise.difficulty,
            icon: LucideIcons.gauge,
          ),
          SizedBox(height: 14.h),
          _buildInfoRow(
            title: 'تجهیزات مورد نیاز:',
            content: widget.exercise.equipment,
            icon: LucideIcons.dumbbell,
          ),
          SizedBox(height: 14.h),
          _buildInfoRow(
            title: 'نوع تمرین:',
            content: widget.exercise.exerciseType,
            icon: LucideIcons.layers,
          ),
          SizedBox(height: 14.h),
          _buildInfoRow(
            title: 'مدت زمان تخمینی:',
            content:
                '${(widget.exercise.estimatedDuration / 60).round()} دقیقه',
            icon: LucideIcons.clock,
          ),
          if (widget.exercise.author != null) ...[
            SizedBox(height: 14.h),
            _buildInfoRow(
              title: 'نویسنده:',
              content: widget.exercise.author!,
              icon: LucideIcons.user,
            ),
          ],
          if (widget.exercise.otherNames.isNotEmpty) ...[
            Divider(
              color: context.separatorColor,
              height: 32.h,
              thickness: 1.5,
            ),
            Row(
              children: [
                Icon(
                  LucideIcons.tag,
                  color: AppTheme.goldColor,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'نام‌های دیگر',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: widget.exercise.otherNames
                  .take(12)
                  .map(
                    (n) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppTheme.goldColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppTheme.goldColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        n,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: AppTheme.goldColor,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                content,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ساخت placeholder یکسان و زیبا برای عکس تمرین
  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[900]!.withValues(alpha: 0.8),
                  Colors.grey[800]!.withValues(alpha: 0.6),
                ]
              : [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                ],
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.dumbbell,
          color: AppTheme.goldColor.withValues(alpha: 0.4),
          size: 80.sp,
        ),
      ),
    );
  }

  Widget _buildExerciseHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 280.h,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Exercise Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
            child: Hero(
              tag: 'exercise_image_${widget.exercise.id}',
              child: CachedNetworkImage(
                imageUrl: widget.exercise.imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
                placeholder: (context, url) => _buildImagePlaceholder(isDark),
                errorWidget: (context, error, stackTrace) =>
                    _buildImagePlaceholder(isDark),
                memCacheWidth: 800, // Optimize memory usage
                memCacheHeight: 600,
              ),
            ),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.7),
                      ],
              ),
            ),
          ),

          // Exercise Name and Favorite Button
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 70.w,
            child: Text(
              widget.exercise.name,
              style: TextStyle(
                color: isDark ? Colors.white : context.textColor,
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                shadows: isDark
                    ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
            ),
          ),

          // Favorite Button
          Positioned(
            bottom: 16.h,
            right: 16.w,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  widget.exercise.isFavorite
                      ? LucideIcons.heart
                      : LucideIcons.heart,
                  color: widget.exercise.isFavorite
                      ? Colors.red[600]
                      : (isDark ? Colors.white70 : context.textSecondary),
                  size: 26.sp,
                ),
                padding: EdgeInsets.all(10.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return ColoredBox(
      color: context.backgroundColor,
      child: Column(
        children: [
          // Exercise Header with Image
          _buildExerciseHeader(),

          // Tab Bar
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border(
                bottom: BorderSide(
                  color: context.separatorColor,
                  width: 1.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.goldColor,
              indicatorWeight: 3.5,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.goldColor,
              unselectedLabelColor: context.textSecondary,
              labelStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'توضیحات'),
                Tab(text: 'نکات کلیدی'),
                Tab(text: 'نظرات کاربران'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [_buildDescriptionTab(), _buildTipsTab(), _buildCommentsTab()],
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Section
          if (widget.exercise.videoUrl.isNotEmpty) _buildVideoSection(),

          // Exercise Info
          _buildExerciseInfo(),

          SizedBox(height: 8.h),

          // Content
          if (widget.exercise.content.isNotEmpty)
            _sectionCard(
              title: 'توضیحات تمرین',
              icon: LucideIcons.fileText,
              child: SelectableText(
                widget.exercise.content,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 16.sp,
                  height: 1.8.h,
                  letterSpacing: 0.2,
                ),
              ),
            ),

          // Detailed Description
          if (widget.exercise.detailedDescription.isNotEmpty)
            _sectionCard(
              title: 'توضیح تکمیلی',
              icon: LucideIcons.bookOpen,
              child: SelectableText(
                widget.exercise.detailedDescription,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 16.sp,
                  height: 1.8.h,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  color: AppTheme.goldColor,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'نکات مهم برای انجام این تمرین',
                    style: TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          if (widget.exercise.tips.isEmpty)
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: context.separatorColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: context.textSecondary,
                      size: 48.sp,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'نکات خاصی برای این تمرین ثبت نشده است.',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 15.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: widget.exercise.tips.asMap().entries.map((entry) {
                final index = entry.key;
                final tip = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : AppTheme.goldColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : AppTheme.goldColor.withValues(alpha: 0.05),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppTheme.goldColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 15.sp,
                            height: 1.7.h,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Add Comment Form
            Padding(
              padding: EdgeInsets.all(20.w),
              child: AddCommentFormWidget(
                onSubmit: _addComment,
                isLoading: _isLoadingComments,
              ),
            ),

            // Comments Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: context.separatorColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        LucideIcons.messageCircle,
                        color: AppTheme.goldColor,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'نظرات کاربران',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    if (_comments.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${_comments.length} نظر',
                          style: TextStyle(
                            color: AppTheme.goldColor,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Comments List
            if (_isLoadingComments)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                ),
              )
            else
              _comments.isEmpty
                  ? _buildEmptyCommentsState()
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _buildCommentsList(),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCommentsState() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: context.separatorColor,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.messageCircle,
              color: context.textSecondary,
              size: 64.sp,
            ),
            SizedBox(height: 20.h),
            Text(
              'هنوز نظری ثبت نشده است',
              style: TextStyle(
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'اولین نفری باشید که نظر می‌دهد!',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return Column(
      children: _comments.map((comment) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: CommentCardWidget(
            comment: comment,
            onEdit: () => _editComment(comment),
            onDelete: () => _deleteComment(comment.id),
            onReply: _replyToComment,
          ),
        );
      }).toList(),
    );
  }

  // Comment methods
  Future<void> _addComment(String content, int? rating) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ثبت نظر ابتدا وارد حساب کاربری خود شوید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    WidgetSafetyUtils.safeSetState(this, () {
      _isLoadingComments = true;
    });

    try {
      final newComment = await ExerciseCommentService.addComment(
        exerciseId: widget.exercise.id.toString(),
        content: content,
        rating: rating,
      );

      if (newComment != null) {
        WidgetSafetyUtils.safeSetState(this, () {
          _comments.insert(0, newComment);
        });

        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'نظر شما با موفقیت ثبت شد',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در ثبت نظر: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _editComment(ExerciseComment comment) async {
    WidgetSafetyUtils.safeShowSnackBar(
      context,
      'قابلیت ویرایش به زودی اضافه خواهد شد',
      backgroundColor: Colors.orange,
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final success = await ExerciseCommentService.deleteComment(commentId);
      if (success) {
        WidgetSafetyUtils.safeSetState(this, () {
          _comments.removeWhere((comment) => comment.id == commentId);
        });

        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'نظر با موفقیت حذف شد',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در حذف نظر: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _replyToComment(String commentId) async {
    WidgetSafetyUtils.safeShowSnackBar(
      context,
      'قابلیت پاسخ به نظر به زودی اضافه خواهد شد',
      backgroundColor: Colors.orange,
    );
  }

  Future<void> _loadComments() async {
    WidgetSafetyUtils.safeSetState(this, () {
      _isLoadingComments = true;
    });

    try {
      final comments = await ExerciseCommentService.getExerciseComments(
        widget.exercise.id.toString(),
      );

      WidgetSafetyUtils.safeSetState(this, () {
        _comments = comments;
      });
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای ذخیره تمرین ابتدا وارد حساب کاربری خود شوید'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _exerciseService.toggleFavorite(widget.exercise.id);
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          // exercise.isFavorite is already updated in the service
        });

        if (widget.exercise.isFavorite) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'تمرین به لیست علاقه‌مندی‌ها اضافه شد',
            backgroundColor: Colors.green,
          );
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'تمرین از لیست علاقه‌مندی‌ها حذف شد',
            backgroundColor: Colors.blue,
          );
        }
      }
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا: $e',
        backgroundColor: Colors.red,
      );
    }
  }
}
