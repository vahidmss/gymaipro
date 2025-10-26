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
  bool _isKeyboardVisible = false;

  // Colors
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color backgroundColor = Color(0xFF121212);

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
    setState(() {
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

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: goldColor,
            handleColor: goldColor,
            backgroundColor: Colors.grey[800]!,
            bufferedColor: goldColor.withValues(alpha: 0.3),
          ),
          placeholder: const ColoredBox(
            color: Colors.black,
            child: Center(child: CircularProgressIndicator(color: goldColor)),
          ),
          autoInitialize: true,
        );

        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _downloadAndCacheVideo(String videoUrl) async {
    try {
      final videoCacheService = VideoCacheService();
      setState(() {
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
    // Listen to keyboard visibility changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      setState(() {
        _isKeyboardVisible = keyboardHeight > 0;
      });
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _startDownloadStatusTimer() {
    _downloadStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {});
      }
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
      backgroundColor: backgroundColor,
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
    return const Center(
      child: CircularProgressIndicator(color: goldColor, strokeWidth: 3),
    );
  }

  Widget _buildVideoSection() {
    if (widget.exercise.videoUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
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
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: goldColor, strokeWidth: 3),
            SizedBox(height: 16.h),
            Text(
              'در حال بارگذاری ویدیو...',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
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

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: goldColor, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: items
                .map(
                  (e) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      e,
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
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
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: goldColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: goldColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  Widget _buildExerciseInfo() {
    final mainChips = _splitCSV(widget.exercise.mainMuscle);
    final secondaryChips = _splitCSV(widget.exercise.secondaryMuscles);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اطلاعات تمرین',
            style: TextStyle(
              color: goldColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
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
          const Divider(color: Colors.white12, height: 24),
          _buildInfoRow(
            title: 'سطح دشواری:',
            content: widget.exercise.difficulty,
            icon: LucideIcons.gauge,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            title: 'تجهیزات مورد نیاز:',
            content: widget.exercise.equipment,
            icon: LucideIcons.dumbbell,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            title: 'نوع تمرین:',
            content: widget.exercise.exerciseType,
            icon: LucideIcons.layers,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            title: 'مدت زمان تخمینی:',
            content:
                '${(widget.exercise.estimatedDuration / 60).round()} دقیقه',
            icon: LucideIcons.clock,
          ),
          if (widget.exercise.otherNames.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 24),
            Text(
              'نام‌های دیگر',
              style: TextStyle(
                color: goldColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.exercise.otherNames
                  .take(12)
                  .map(
                    (n) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        n,
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
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
        Icon(icon, color: goldColor, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseHeader() {
    return Container(
      height: 240.h,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Exercise Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            child: Hero(
              tag: 'exercise_image_${widget.exercise.id}',
              child: CachedNetworkImage(
                imageUrl: widget.exercise.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: goldColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: Icon(
                    LucideIcons.dumbbell,
                    color: goldColor,
                    size: 80.sp,
                  ),
                ),
              ),
            ),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),

          // Exercise Name and Favorite Button
          Positioned(
            bottom: 16.h,
            left: 16.w,
            right: 60.w,
            child: Text(
              widget.exercise.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(blurRadius: 4)],
              ),
            ),
          ),

          // Favorite Button
          Positioned(
            bottom: 16.h,
            right: 16.w,
            child: IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                widget.exercise.isFavorite
                    ? LucideIcons.heart
                    : LucideIcons.heart,
                color: widget.exercise.isFavorite ? Colors.red : Colors.white,
                size: 28.sp,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                padding: EdgeInsets.all(8.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return ColoredBox(
      color: backgroundColor,
      child: Column(
        children: [
          // Exercise Header with Image
          _buildExerciseHeader(),

          // Tab Bar
          DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: goldColor,
              indicatorWeight: 3,
              labelColor: goldColor,
              unselectedLabelColor: Colors.white70,
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
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Section
          if (widget.exercise.videoUrl.isNotEmpty) _buildVideoSection(),

          // Exercise Info
          _buildExerciseInfo(),

          const SizedBox(height: 24),

          // Content
          if (widget.exercise.content.isNotEmpty)
            _sectionCard(
              title: 'توضیحات تمرین',
              icon: LucideIcons.fileText,
              child: SelectableText(
                widget.exercise.content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  height: 1.6.h,
                ),
              ),
            ),

          // Detailed Description
          if (widget.exercise.detailedDescription.isNotEmpty)
            _sectionCard(
              title: 'توضیح تکمیلی',
              icon: LucideIcons.fileText,
              child: SelectableText(
                widget.exercise.detailedDescription,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  height: 1.6.h,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نکات مهم برای انجام این تمرین:',
            style: TextStyle(
              color: goldColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.exercise.tips.isEmpty)
            Text(
              'نکات خاصی برای این تمرین ثبت نشده است.',
              style: TextStyle(color: Colors.white70, fontSize: 15.sp),
            )
          else
            Column(
              children: widget.exercise.tips.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.checkCircle,
                        color: goldColor,
                        size: 18.sp,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            height: 1.6.h,
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
              padding: EdgeInsets.all(16.w),
              child: AddCommentFormWidget(
                onSubmit: _addComment,
                isLoading: _isLoadingComments,
              ),
            ),

            // Comments Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    color: goldColor,
                    size: 20.sp,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نظرات کاربران',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_comments.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${_comments.length} نظر',
                        style: TextStyle(
                          color: goldColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Comments List
            if (_isLoadingComments)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: const CircularProgressIndicator(color: goldColor),
                ),
              )
            else
              _comments.isEmpty
                  ? _buildEmptyCommentsState()
                  : _buildCommentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCommentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.messageCircle, color: Colors.grey[600], size: 64),
          const SizedBox(height: 16),
          Text(
            'هنوز نظری ثبت نشده است',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اولین نفری باشید که نظر می‌دهد!',
            style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return Column(
      children: _comments.map((comment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final newComment = await ExerciseCommentService.addComment(
        exerciseId: widget.exercise.id.toString(),
        content: content,
        rating: rating,
      );

      if (newComment != null) {
        setState(() {
          _comments.insert(0, newComment);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نظر شما با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ثبت نظر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _editComment(ExerciseComment comment) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قابلیت ویرایش به زودی اضافه خواهد شد'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final success = await ExerciseCommentService.deleteComment(commentId);
      if (success) {
        setState(() {
          _comments.removeWhere((comment) => comment.id == commentId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نظر با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در حذف نظر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _replyToComment(String commentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قابلیت پاسخ به نظر به زودی اضافه خواهد شد'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await ExerciseCommentService.getExerciseComments(
        widget.exercise.id.toString(),
      );

      setState(() {
        _comments = comments;
      });
    } finally {
      setState(() {
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
      setState(() {
        if (widget.exercise.isFavorite) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین به لیست علاقه‌مندی‌ها اضافه شد'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین از لیست علاقه‌مندی‌ها حذف شد'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
