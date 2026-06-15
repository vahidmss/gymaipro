import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/models/exercise_rich_meta.dart';
import 'package:gymaipro/models/exercise_comment.dart';
import 'package:gymaipro/services/exercise_comment_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/services/video_cache_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/widgets/add_comment_form_widget.dart';
import 'package:gymaipro/widgets/comment_card_widget.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late Exercise _exercise;
  bool _hydratingDetail = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isVideoInitialized = false;
  bool _videoBusy = false;
  int _activeVideoIndex = 0;
  late TabController _tabController;
  bool _isSubmittingComment = false;
  List<ExerciseComment> _comments = [];
  Timer? _downloadStatusTimer;

  // Keyboard management
  final FocusNode _commentFocusNode = FocusNode();

  Exercise get ex => _exercise;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeVideo(initial: true);
    _loadComments();
    _startDownloadStatusTimer();
    unawaited(_hydrateExerciseFromServer());
  }

  void _onTabChanged() {
    if (_tabController.index != 3) {
      _dismissKeyboard();
    }
  }

  /// بارگذاری کامل متا از Supabase (کش لیست فیلدهای جدید را ندارد).
  Future<void> _hydrateExerciseFromServer() async {
    if (_hydratingDetail) return;
    WidgetSafetyUtils.safeSetState(this, () => _hydratingDetail = true);

    try {
      final fresh =
          await _exerciseService.getExerciseById(widget.exercise.id);
      if (!mounted || fresh == null) {
        if (kDebugMode) {
          debugPrint(
            '[ExerciseDetail] hydrate miss id=${widget.exercise.id}',
          );
        }
        return;
      }

      fresh.isFavorite = _exercise.isFavorite;
      fresh.isLikedByUser = _exercise.isLikedByUser;
      fresh.likes = _exercise.likes;

      if (kDebugMode) {
        debugPrint(
          '[ExerciseDetail] hydrated id=${fresh.id} '
          'short=${fresh.shortDescription.length} '
          'heatmap=${fresh.muscleTargets.length} '
          'guide=${fresh.richMeta.hasExecutionGuide}',
        );
      }

      WidgetSafetyUtils.safeSetState(this, () => _exercise = fresh);
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _hydratingDetail = false);
      }
    }
  }

  Future<void> _initializeVideo({required bool initial}) async {
    if (initial) {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = true;
      });
    } else {
      WidgetSafetyUtils.safeSetState(this, () {
        _videoBusy = true;
      });
    }

    try {
      final videoUrls = ex.allVideoUrls;
      if (videoUrls.isNotEmpty) {
        final idx = _activeVideoIndex.clamp(0, videoUrls.length - 1);
        _activeVideoIndex = idx;
        final videoUrl = videoUrls[idx];

        final videoCacheService = VideoCacheService();
        final cachedPath = await videoCacheService.getCachedVideoPath(videoUrl);

        VideoPlayerController controller;
        if (cachedPath != null) {
          controller = VideoPlayerController.file(File(cachedPath));
        } else {
          if (videoCacheService.isVideoDownloading(videoUrl)) {
            controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          } else {
            final success = await _downloadAndCacheVideo(videoUrl);

            if (success) {
              final newCachedPath = await videoCacheService.getCachedVideoPath(
                videoUrl,
              );
              if (newCachedPath != null) {
                controller = VideoPlayerController.file(File(newCachedPath));
              } else {
                controller = VideoPlayerController.networkUrl(
                  Uri.parse(videoUrl),
                );
              }
            } else {
              controller = VideoPlayerController.networkUrl(
                Uri.parse(videoUrl),
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

        if (!mounted) return;
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
          _videoBusy = false;
        });
      } else {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
          _videoBusy = false;
        });
      }
    } catch (e) {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = false;
        _videoBusy = false;
      });
    }
  }

  Future<void> _switchActiveVideo(int index) async {
    final urls = ex.allVideoUrls;
    if (index < 0 || index >= urls.length || index == _activeVideoIndex) {
      return;
    }
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
    WidgetSafetyUtils.safeSetState(this, () {
      _activeVideoIndex = index;
      _isVideoInitialized = false;
    });
    await _initializeVideo(initial: false);
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

  void _dismissKeyboard() {
    _commentFocusNode.unfocus();
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  void _dismissKeyboardWithoutContext() {
    _commentFocusNode.unfocus();
  }

  void _startDownloadStatusTimer() {
    _downloadStatusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      SafeSetState.call(this, () {});
    });
  }

  @override
  void dispose() {
    _dismissKeyboardWithoutContext();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _downloadStatusTimer?.cancel();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _dismissKeyboardWithoutContext();
      },
      child: Scaffold(
      backgroundColor: context.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? _buildLoadingIndicator()
          : NestedScrollView(
              headerSliverBuilder: _buildDetailHeaderSlivers,
              body: _buildTabContent(),
            ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.goldColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildVideoSection() {
    final urls = ex.allVideoUrls;
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (urls.length > 1) ...[
          SizedBox(
            height: 40.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, i) {
                final selected = i == _activeVideoIndex;
                return ChoiceChip(
                  label: Text('ویدیو ${i + 1}'),
                  selected: selected,
                  onSelected: (_) => unawaited(_switchActiveVideo(i)),
                  selectedColor: AppTheme.goldColor.withValues(alpha: 0.35),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: context.textColor,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
        ],
        Container(
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
              child:
                  _videoBusy ||
                      (!_isVideoInitialized || _chewieController == null)
                  ? _buildVideoLoadingIndicator()
                  : Chewie(controller: _chewieController!),
            ),
          ),
        ),
      ],
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
            const CircularProgressIndicator(
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
                child: Icon(icon, color: AppTheme.goldColor, size: 18.sp),
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
                child: Icon(icon, color: AppTheme.goldColor, size: 20.sp),
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

  String _mainMuscleDisplayLabel() {
    final label = ExerciseDisplayLabels.musclesCsv(ex.mainMuscle).trim();
    if (label.isNotEmpty) return label;
    return ex.targetArea.trim();
  }

  List<String> _secondaryMuscleChips() {
    final main = _mainMuscleDisplayLabel().toLowerCase();
    final secondaryLabel =
        ExerciseDisplayLabels.musclesCsv(ex.secondaryMuscles);
    final raw = secondaryLabel.isNotEmpty
        ? secondaryLabel.split('، ').where((s) => s.isNotEmpty).toList()
        : _splitCSV(ex.secondaryMuscles);
    return raw
        .where((s) => s.trim().toLowerCase() != main && s.trim().isNotEmpty)
        .toList();
  }

  /// متن خلاصه بدون تکرار متا که در چیپ‌ها هست.
  String _overviewDescriptionText() {
    var text = ex.appShortDescription.trim();
    if (text.isEmpty) return text;

    const metaPrefixes = [
      'عضله هدف',
      'عضلات فرعی',
      'تجهیزات',
      'سطح',
      'نوع',
      'نکته کلیدی',
      'پیشنهاد حجم',
      'پیشنهاد',
      'نام های بین',
    ];
    for (final prefix in metaPrefixes) {
      text = text.replaceAll(
        RegExp('\\s*$prefix\\s*[:：][^.!؟]*[.!؟]?', caseSensitive: false),
        '',
      );
    }

    final sentences = text
        .split(RegExp(r'(?<=[.!؟])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final seen = <String>{};
    final unique = <String>[];
    for (final s in sentences) {
      final key = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (seen.add(key)) unique.add(s);
    }

    if (unique.length > 2) {
      return unique.take(2).join(' ');
    }
    return unique.join(' ');
  }

  Widget _buildMuscleFocusSection() {
    final secondaryChips = _secondaryMuscleChips();
    final hasHeatmap = MuscleTargets.hasData(ex.muscleTargets);
    final hasAliases = ex.otherNames.isNotEmpty;
    if (!hasHeatmap && secondaryChips.isEmpty && !hasAliases) {
      return const SizedBox.shrink();
    }

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
                  LucideIcons.target,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'عضلات درگیر',
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
          if (hasHeatmap) ...[
            ExerciseMuscleHeatmapWidget(muscleTargets: ex.muscleTargets),
            SizedBox(height: 16.h),
          ],
          if (secondaryChips.isNotEmpty)
            _buildChipsSection(
              title: 'عضلات کمکی',
              items: secondaryChips,
              icon: LucideIcons.activity,
            ),
          if (hasAliases) ...[
            if (hasHeatmap || secondaryChips.isNotEmpty)
              Divider(
                color: context.separatorColor,
                height: 28.h,
                thickness: 1.5,
              ),
            Row(
              children: [
                Icon(LucideIcons.tag, color: AppTheme.goldColor, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'نام‌های دیگر',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: ex.otherNames
                  .where((n) {
                    final t = n.trim().toLowerCase();
                    if (t.isEmpty) return false;
                    if (t == ex.name.trim().toLowerCase()) return false;
                    if (t == ex.title.trim().toLowerCase()) return false;
                    return true;
                  })
                  .take(8)
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

  /// ساخت placeholder یکسان و زیبا برای عکس تمرین
  Widget _buildImagePlaceholder(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[900]!.withValues(alpha: 0.8),
                  Colors.grey[800]!.withValues(alpha: 0.6),
                ]
              : [Colors.grey[200]!, Colors.grey[100]!],
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

  List<Widget> _buildDetailHeaderSlivers(
    BuildContext context,
    bool innerBoxIsScrolled,
  ) {
    return [
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: _buildCollapsingImageAppBar(),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: _ExerciseDetailTabBarDelegate(
          tabBar: _buildExerciseTabBar(),
          backgroundColor: context.cardColor,
          separatorColor: context.separatorColor,
        ),
      ),
    ];
  }

  Widget _buildCollapsingImageAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverUrl = ex.coverImageUrl;
    final borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(24.r),
      bottomRight: Radius.circular(24.r),
    );

    final Widget imageLayer = coverUrl.isEmpty
        ? SizedBox.expand(child: _buildImagePlaceholder(isDark))
        : Hero(
            tag: 'exercise_image_${ex.id}',
            child: SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
                placeholder: (context, u) => _buildImagePlaceholder(isDark),
                errorWidget: (context, error, stackTrace) =>
                    _buildImagePlaceholder(isDark),
                memCacheWidth: 800,
                memCacheHeight: 600,
              ),
            ),
          );

    return SliverAppBar(
      expandedHeight: 280.h,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: context.backgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          LucideIcons.arrowRight,
          color: isDark ? Colors.white : context.textColor,
        ),
        onPressed: () => NavigationService.safePop(context),
      ),
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            LucideIcons.heart,
            color: ex.isFavorite
                ? Colors.red[600]
                : (isDark ? Colors.white70 : context.textSecondary),
            size: 24.sp,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        titlePadding: EdgeInsetsDirectional.only(
          start: 48.w,
          end: 48.w,
          bottom: 14.h,
        ),
        centerTitle: false,
        title: Text(
          ex.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : context.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            shadows: isDark
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(borderRadius: borderRadius, child: imageLayer),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.88),
                          ]
                        : [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.75),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TabBar _buildExerciseTabBar() {
    return TabBar(
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
        Tab(text: 'خلاصه'),
        Tab(text: 'راهنما'),
        Tab(text: 'نکات'),
        Tab(text: 'نظرات'),
      ],
    );
  }

  Widget _nestedTabScroll({
    required String pageKey,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: PageStorageKey<String>(pageKey),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(child: child),
          ],
        );
      },
    );
  }

  Widget _nestedTabFillRemaining({
    required String pageKey,
    required Widget child,
  }) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: PageStorageKey<String>(pageKey),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: child,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildGuideTab(),
        _buildTipsTab(),
        _buildCommentsTab(),
      ],
    );
  }

  Future<void> _openWebsiteArticle() async {
    final url = Uri.parse(ex.websiteArticleUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در باز کردن صفحه این حرکت در وب‌سایت'),
        ),
      );
    }
  }

  Widget _buildOverviewTab() {
    return _nestedTabScroll(
      pageKey: 'exercise_overview_${ex.id}',
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hydratingDetail)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: LinearProgressIndicator(
                  minHeight: 3.h,
                  color: AppTheme.goldColor,
                  backgroundColor: AppTheme.goldColor.withValues(alpha: 0.15),
                ),
              ),
            _buildAppShortDescriptionCard(),
            SizedBox(height: 14.h),
            _buildQuickStatsRow(),
            if (ex.allVideoUrls.isNotEmpty) ...[
              SizedBox(height: 14.h),
              _buildVideoSection(),
            ],
            SizedBox(height: 14.h),
            _buildMuscleFocusSection(),
            _buildDescriptionImageGallery(),
            SizedBox(height: 14.h),
            _buildWebsiteCtaCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppShortDescriptionCard() {
    final text = _overviewDescriptionText();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (text.isEmpty) {
      return _sectionCard(
        title: 'درباره این حرکت',
        icon: LucideIcons.sparkles,
        child: Text(
          'فعلاً توضیحی برای این حرکت ثبت نشده. برای جزئیات بیشتر به وب‌سایت جیم‌اِی‌آی سر بزن.',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14.sp,
            height: 1.6,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppTheme.goldColor.withValues(alpha: 0.22),
                  const Color(0xFF1A1A1F),
                ]
              : [
                  AppTheme.goldColor.withValues(alpha: 0.18),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, color: AppTheme.goldColor, size: 22.sp),
                SizedBox(width: 10.w),
                Text(
                  'درباره این حرکت',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              text,
              style: TextStyle(
                color: context.textColor,
                fontSize: 15.sp,
                height: 1.75,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    final meta = ex.richMeta;
    final chips = <Widget>[];
    final mainMuscle = _mainMuscleDisplayLabel();

    void addChip(String label, String value, IconData icon) {
      if (value.trim().isEmpty) return;
      chips.add(_metricChip(label: label, value: value, icon: icon));
    }

    addChip(
      'سطح',
      ExerciseDisplayLabels.difficultyLabel(ex.difficulty),
      LucideIcons.gauge,
    );
    addChip(
      'تجهیزات',
      ExerciseDisplayLabels.equipmentLabel(ex.equipment),
      LucideIcons.dumbbell,
    );
    if (mainMuscle.isNotEmpty) {
      addChip('عضله اصلی', mainMuscle, LucideIcons.target);
    }

    final engagement = ex.bodyEngagementDisplay.trim();
    if (engagement.isNotEmpty &&
        engagement != ExerciseDisplayLabels.type(ex.exerciseType)) {
      addChip('نوع حرکت', engagement, LucideIcons.layers);
    }

    if (meta.recommendedSets.isNotEmpty && meta.repRangeHypertrophy.isNotEmpty) {
      addChip(
        'پیشنهاد',
        '${meta.recommendedSets} ست × ${meta.repRangeHypertrophy}',
        LucideIcons.repeat,
      );
    } else if (meta.recommendedSets.isNotEmpty) {
      addChip('ست', meta.recommendedSets, LucideIcons.repeat);
    }

    final isCardio = ex.exerciseType.toLowerCase().contains('cardio') ||
        ex.exerciseType.toLowerCase().contains('کاردیو');
    if (isCardio && ex.met != null) {
      addChip('MET', ex.met!.toString(), LucideIcons.zap);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8.w, runSpacing: 8.h, children: chips);
  }

  Widget _metricChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppTheme.goldColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppTheme.goldColor),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteCtaCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openWebsiteArticle,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: AppTheme.carbsColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.carbsColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Icon(
                      LucideIcons.globe,
                      color: AppTheme.carbsColor,
                      size: 26.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'آموزش کامل در وب‌سایت',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'تکنیک اجرا، اشتباهات رایج و برنامه پیشنهادی',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12.5.sp,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.externalLink,
                  color: isDark ? Colors.white70 : AppTheme.carbsColor,
                  size: 22.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideTab() {
    final meta = ex.richMeta;
    final hasGuide = meta.hasExecutionGuide || meta.hasProgramming;

    if (!hasGuide && meta.commonMistakes.isEmpty) {
      return _nestedTabFillRemaining(
        pageKey: 'exercise_guide_empty_${ex.id}',
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bookOpen,
                size: 56.sp,
                color: AppTheme.goldColor.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                'راهنمای گام‌به‌گام اینجا نیست',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'برای آموزش تصویری و جزئیات بیشتر، صفحه این حرکت در وب‌سایت را ببین.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20.h),
              FilledButton.icon(
                onPressed: _openWebsiteArticle,
                icon: Icon(LucideIcons.externalLink, size: 18.sp),
                label: const Text('آموزش در وب‌سایت'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.veryDarkBackground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _nestedTabScroll(
      pageKey: 'exercise_guide_${ex.id}',
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (meta.hasProgramming) _buildProgrammingSection(meta),
          if (meta.setupSteps.isNotEmpty)
            _buildNumberedGuideSection(
              title: 'آماده‌سازی',
              icon: LucideIcons.settings2,
              steps: meta.setupSteps,
            ),
          if (meta.executionSteps.isNotEmpty)
            _buildNumberedGuideSection(
              title: 'اجرای حرکت',
              icon: LucideIcons.play,
              steps: meta.executionSteps,
            ),
          if (meta.breathing.isNotEmpty)
            _sectionCard(
              title: 'تنفس',
              icon: LucideIcons.wind,
              child: Text(
                meta.breathing,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 14.sp,
                  height: 1.7,
                ),
              ),
            ),
          if (meta.commonMistakes.isNotEmpty)
            _sectionCard(
              title: 'اشتباهات رایج',
              icon: LucideIcons.alertTriangle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: meta.commonMistakes
                    .map(
                      (m) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.xCircle,
                              size: 16.sp,
                              color: AppTheme.errorColor.withValues(alpha: 0.85),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                m,
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 14.sp,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildProgrammingSection(ExerciseRichMeta meta) {
    final rows = <MapEntry<String, String>>[];
    void add(String k, String v) {
      if (v.trim().isNotEmpty) rows.add(MapEntry(k, v));
    }

    if (meta.programmingGoal.trim().isNotEmpty) {
      add('هدف', meta.programmingGoal);
    }
    if (meta.recommendedSets.isNotEmpty && meta.repRangeHypertrophy.isEmpty) {
      add('ست پیشنهادی', meta.recommendedSets);
    }
    if (meta.repRangeStrength.isNotEmpty) {
      add('تکرار قدرت', meta.repRangeStrength);
    }
    if (meta.repRangeEndurance.isNotEmpty) {
      add('تکرار استقامت', meta.repRangeEndurance);
    }
    add('استراحت', meta.restSeconds.isNotEmpty ? '${meta.restSeconds} ثانیه' : '');
    add('تمپو', meta.tempo);

    if (rows.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      title: 'برنامه پیشنهادی',
      icon: LucideIcons.clipboardList,
      child: Column(
        children: rows
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110.w,
                      child: Text(
                        e.key,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildNumberedGuideSection({
    required String title,
    required IconData icon,
    required List<String> steps,
  }) {
    return _sectionCard(
      title: title,
      icon: icon,
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: AppTheme.goldColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14.sp,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openExerciseImagesViewer(int initialIndex) {
    final urls = ex.allImageUrls;
    if (urls.isEmpty || initialIndex < 0 || initialIndex >= urls.length) {
      return;
    }
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ExerciseImageGalleryPage(
            urls: urls,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  Widget _buildDescriptionImageGallery() {
    final urls = ex.allImageUrls;
    // کاور در هدر است؛ گالری فقط برای تصاویر اضافی
    if (urls.length <= 1) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.goldColor.withValues(alpha: 0.15);

    return _sectionCard(
      title: 'تصاویر آموزشی',
      icon: LucideIcons.image,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'برای دیدن بزرگ و واضح، روی تصویر بزنید. با دو انگشت می‌توانید زوم کنید.',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
          SizedBox(height: 14.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: urls.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10.w,
              crossAxisSpacing: 10.w,
            ),
            itemBuilder: (context, i) {
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openExerciseImagesViewer(i),
                  splashColor: AppTheme.goldColor.withValues(alpha: 0.2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11.r),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: urls[i],
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 180),
                            placeholder: (context, url) => ColoredBox(
                              color: isDark
                                  ? Colors.grey[900]!
                                  : Colors.grey[200]!,
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.goldColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, error, stackTrace) =>
                                ColoredBox(
                                  color: isDark
                                      ? Colors.grey[900]!
                                      : Colors.grey[300]!,
                                  child: Icon(
                                    LucideIcons.imageOff,
                                    color: Colors.grey[500],
                                    size: 28.sp,
                                  ),
                                ),
                            memCacheWidth: 400,
                            memCacheHeight: 400,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 40.h,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.55),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (i == 0)
                            Positioned(
                              top: 8.h,
                              left: 8.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.92,
                                  ),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  'اصلی',
                                  style: TextStyle(
                                    color: AppTheme.veryDarkBackground,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 8.h,
                            right: 10.w,
                            child: Text(
                              '${i + 1} / ${urls.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _nestedTabScroll(
      pageKey: 'exercise_tips_${ex.id}',
      child: Padding(
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
          if (ex.tips.isEmpty)
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: context.separatorColor, width: 1.5),
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
              children: ex.tips.asMap().entries.map((entry) {
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
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: PageStorageKey<String>('exercise_comments_${ex.id}'),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(
              child: AddCommentFormWidget(
                focusNode: _commentFocusNode,
                onSubmit: _addComment,
                isLoading: _isSubmittingComment,
              ),
            ),
            if (_comments.isEmpty)
              const SliverToBoxAdapter(child: SizedBox.shrink())
            else
              SliverList.separated(
                itemCount: _comments.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                  color: context.separatorColor.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return CommentCardWidget(
                    comment: comment,
                    onDelete: () => _deleteComment(comment.id),
                    onReactionsChanged: () => _loadComments(silent: true),
                  );
                },
              ),
            SliverPadding(padding: EdgeInsets.only(bottom: 12.h)),
          ],
        );
      },
    );
  }

  // Comment methods
  Future<bool> _addComment(String content, int? rating) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'برای ثبت نظر ابتدا وارد حساب شوید',
        backgroundColor: Colors.redAccent,
      );
      return false;
    }

    WidgetSafetyUtils.safeSetState(this, () {
      _isSubmittingComment = true;
    });

    try {
      final newComment = await ExerciseCommentService.addComment(
        exerciseId: ex.id.toString(),
        content: content,
        rating: rating,
      );

      if (!mounted) return false;
      if (newComment != null) {
        WidgetSafetyUtils.safeSetState(this, () {
          _comments.insert(0, newComment);
        });

        _commentFocusNode.unfocus();
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'نظر ثبت شد',
          backgroundColor: Colors.green.shade700,
        );
        return true;
      }
      return false;
    } catch (e) {
      if (!mounted) return false;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'ثبت نظر انجام نشد. اتصال اینترنت را بررسی کن.',
        backgroundColor: Colors.redAccent,
      );
      return false;
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isSubmittingComment = false;
      });
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final success = await ExerciseCommentService.deleteComment(commentId);
      if (!mounted) return;
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
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در حذف نظر: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _loadComments({bool silent = false}) async {
    try {
      final comments = await ExerciseCommentService.getExerciseComments(
        ex.id.toString(),
      );

      WidgetSafetyUtils.safeSetState(this, () {
        _comments = comments;
      });
    } catch (e) {
      if (!silent && mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'بارگذاری نظرات ناموفق بود',
          backgroundColor: Colors.redAccent,
        );
      }
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
      await _exerciseService.toggleFavorite(ex.id);
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          // exercise.isFavorite is already updated in the service
        });

        if (ex.isFavorite) {
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
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا: $e',
        backgroundColor: Colors.red,
      );
    }
  }
}

class _ExerciseDetailTabBarDelegate extends SliverPersistentHeaderDelegate {
  _ExerciseDetailTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
    required this.separatorColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;
  final Color separatorColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: separatorColor, width: 1.5),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _ExerciseDetailTabBarDelegate old) {
    return tabBar != old.tabBar ||
        backgroundColor != old.backgroundColor ||
        separatorColor != old.separatorColor;
  }
}

/// تمام‌صفحه مثل گالری حرفه‌ای: تصویر متناسب صفحه، زوم دو انگشتی، سوایپ بین عکس‌ها
class _ExerciseImageGalleryPage extends StatefulWidget {
  const _ExerciseImageGalleryPage({
    required this.urls,
    required this.initialIndex,
  });

  final List<String> urls;
  final int initialIndex;

  @override
  State<_ExerciseImageGalleryPage> createState() =>
      _ExerciseImageGalleryPageState();
}

class _ExerciseImageGalleryPageState extends State<_ExerciseImageGalleryPage> {
  late final PageController _pageController;
  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, i) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
                    key: ValueKey<String>('viewer_${widget.urls[i]}_$i'),
                    minScale: 1,
                    maxScale: 4.5,
                    boundaryMargin: const EdgeInsets.all(64),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Center(
                        child: CachedNetworkImage(
                          imageUrl: widget.urls[i],
                          fit: BoxFit.contain,
                          fadeInDuration: const Duration(milliseconds: 200),
                          filterQuality: FilterQuality.high,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                color: AppTheme.goldColor,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                          errorWidget: (context, error, stackTrace) => Icon(
                            LucideIcons.imageOff,
                            color: Colors.white30,
                            size: 48.sp,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(LucideIcons.x, size: 22.sp),
                        tooltip: 'بستن',
                      ),
                      Expanded(
                        child: Text(
                          widget.urls.length > 1
                              ? '${_pageIndex + 1} از ${widget.urls.length}'
                              : 'نمایش تصویر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(width: 48.w),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 20.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.urls.length, (i) {
                  final active = i == _pageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: active ? 22.w : 7.w,
                    height: 7.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: active
                          ? AppTheme.goldColor
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
