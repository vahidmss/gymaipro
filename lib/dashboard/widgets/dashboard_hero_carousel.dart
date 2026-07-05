import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/article.dart';
import 'package:gymaipro/academy/models/motivational_video.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/screens/motivational_video_detail_screen.dart';
import 'package:gymaipro/academy/services/article_service.dart';
import 'package:gymaipro/academy/services/motivational_video_service.dart';
import 'package:gymaipro/academy/services/workout_music_service.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/navigation/screens/main_navigation_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_remote_image.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// نوع اسلاید کاروسل
enum HeroSlideType { video, article, music, poster }

/// مدل یک اسلاید در کاروسل
class HeroSlideItem {
  HeroSlideItem({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.type,
    this.video,
    this.article,
    this.music,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final HeroSlideType type;
  final MotivationalVideo? video;
  final Article? article;
  final WorkoutMusic? music;
}

/// کاروسل Hero برای داشبورد - اسکرول افقی با تصاویر/ویدیوها مثل اپ‌های سوپر
class DashboardHeroCarousel extends StatefulWidget {
  const DashboardHeroCarousel({super.key});

  @override
  State<DashboardHeroCarousel> createState() => _DashboardHeroCarouselState();
}

class _DashboardHeroCarouselState extends State<DashboardHeroCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  final DashboardCacheService _cacheService = DashboardCacheService();
  Timer? _autoPlayTimer;
  int _carouselPageIndex = 0;
  List<HeroSlideItem> _slides = [];
  bool _isLoading = true;

  static const List<Map<String, String>> _fallbackPosters = [
    {
      'image': 'images/poster1.png',
      'title': 'مسیر فیتنست رو شروع کن',
      'sub': 'تمرینات اختصاصی',
    },
    {
      'image': 'images/poster2.png',
      'title': 'آکادمی فیتنس',
      'sub': 'مقالات و آموزش‌ها',
    },
    {
      'image': 'images/poster3.png',
      'title': 'ویدیوهای انگیزشی',
      'sub': 'انرژی بگیر و ادامه بده',
    },
    {
      'image': 'images/poster4.png',
      'title': 'رتبه‌بندی و لیگ',
      'sub': 'با بقیه رقابت کن',
    },
    {
      'image': 'images/poster5.png',
      'title': 'تغذیه و برنامه غذایی',
      'sub': 'غذای مناسب، بدن آماده',
    },
  ];

  @override
  void initState() {
    super.initState();
    // بعد از Stories تا کش مقالات پر شود و درخواست تکراری کمتر شود
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) unawaited(_loadSlides());
      });
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Article>> _loadArticles() async {
    final cached = _cacheService.getArticles();
    if (cached != null && cached.isNotEmpty) return cached;

    final articles = await ArticleService.fetchArticles(perPage: 12);
    if (articles.isNotEmpty) {
      _cacheService.setArticles(articles);
    }
    return articles;
  }

  Future<void> _loadSlides() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait<dynamic>([
        MotivationalVideoService.fetchVideos(),
        _loadArticles(),
        WorkoutMusicService.fetchMusic(),
      ]);

      final videos = results[0] as List<MotivationalVideo>;
      final articles = results[1] as List<Article>;
      final allMusics = results[2] as List<WorkoutMusic>;

      final slides = <HeroSlideItem>[];

      // اول ویدیوهای انگیزشی (حداکثر 2)
      for (var i = 0; i < videos.length && i < 2; i++) {
        final v = videos[i];
        final thumb = v.thumbnailUrl.isNotEmpty
            ? v.thumbnailUrl
            : 'https://via.placeholder.com/1280x720?text=Video';
        slides.add(
          HeroSlideItem(
            imageUrl: thumb,
            title: v.title,
            subtitle: 'ویدیو انگیزشی • ${v.formattedDuration}',
            type: HeroSlideType.video,
            video: v,
          ),
        );
      }

      // موزیک‌ها: بر اساس لایک مرتب، از بین پرطرفدارترین‌ها رندوم انتخاب
      final musicsWithCover = allMusics
          .where((m) => m.coverImageUrl.isNotEmpty)
          .toList();
      if (musicsWithCover.isNotEmpty) {
        musicsWithCover.sort((a, b) => b.likes.compareTo(a.likes));
        final topPool = musicsWithCover.take(25).toList();
        final rnd = Random();
        topPool.shuffle(rnd);
        for (var i = 0; i < topPool.length && i < 2; i++) {
          final m = topPool[i];
          slides.add(
            HeroSlideItem(
              imageUrl: m.coverImageUrl,
              title: m.title,
              subtitle: '${m.artist} • ${m.formattedDuration}',
              type: HeroSlideType.music,
              music: m,
            ),
          );
        }
      }

      // بعد مقالات با تصویر (حداکثر 2)
      for (var i = 0; i < articles.length && slides.length < 6; i++) {
        final a = articles[i];
        if (a.featuredImageUrl != null && a.featuredImageUrl!.isNotEmpty) {
          slides.add(
            HeroSlideItem(
              imageUrl: a.featuredImageUrl!,
              title: a.title,
              subtitle: 'مقاله آکادمی',
              type: HeroSlideType.article,
              article: a,
            ),
          );
        }
      }

      // اگر کم بود، با پوسترها پر کن
      if (slides.isEmpty) {
        for (var i = 0; i < _fallbackPosters.length; i++) {
          final p = _fallbackPosters[i];
          slides.add(
            HeroSlideItem(
              imageUrl: p['image']!,
              title: p['title']!,
              subtitle: p['sub']!,
              type: HeroSlideType.poster,
            ),
          );
        }
      } else {
        while (slides.length < 5) {
          final idx = slides.length % _fallbackPosters.length;
          final p = _fallbackPosters[idx];
          slides.add(
            HeroSlideItem(
              imageUrl: p['image']!,
              title: p['title']!,
              subtitle: p['sub']!,
              type: HeroSlideType.poster,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _slides = slides;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAutoPlay();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _slides = _fallbackPosters
              .map(
                (p) => HeroSlideItem(
                  imageUrl: p['image']!,
                  title: p['title']!,
                  subtitle: p['sub']!,
                  type: HeroSlideType.poster,
                ),
              )
              .toList();
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAutoPlay();
        });
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (!WebInteraction.allowCarouselAutoPlay) return;
    if (_slides.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || _slides.isEmpty) return;
      final target = (_carouselPageIndex + 1) % _slides.length;
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onSlideTap(HeroSlideItem slide) {
    switch (slide.type) {
      case HeroSlideType.video:
        if (slide.video != null) {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  MotivationalVideoDetailScreen(video: slide.video!),
            ),
          );
        } else {
          MainNavigationScreen.navigateToTab(NavigationConstants.academyIndex);
        }
      case HeroSlideType.article:
        if (slide.article != null) {
          Navigator.pushNamed(
            context,
            '/article-detail',
            arguments: slide.article,
          );
        } else {
          MainNavigationScreen.navigateToTab(NavigationConstants.academyIndex);
        }
      case HeroSlideType.music:
        if (slide.music != null) {
          MainNavigationScreen.navigateToAcademyWithMusic(slide.music!);
        } else {
          MainNavigationScreen.navigateToTab(NavigationConstants.academyIndex);
        }
      case HeroSlideType.poster:
        MainNavigationScreen.navigateToTab(NavigationConstants.academyIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return SizedBox(
        height: 180.h,
        child: Center(
          child: SizedBox(
            width: 32.w,
            height: 32.w,
            child: const CircularProgressIndicator(
              color: AppTheme.goldColor,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── عنوان بخش ───
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.25),
                          AppTheme.goldColor.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      LucideIcons.tv,
                      size: 15.sp,
                      color: context.textColor,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'محتوای پیشنهادی',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  MainNavigationScreen.navigateToTab(
                    NavigationConstants.academyIndex,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.textColor),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'آکادمی',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        LucideIcons.arrowLeft,
                        size: 12.sp,
                        color: context.textColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: _pageController,
            physics: WebInteraction.pageViewPhysics,
            itemCount: _slides.length,
            onPageChanged: (index) => _carouselPageIndex = index,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _HeroSlideCard(
                slide: slide,
                isDark: isDark,
                onTap: () => _onSlideTap(slide),
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        SmoothPageIndicator(
          controller: _pageController,
          count: _slides.length,
          effect: WormEffect(
            dotWidth: 8.w,
            dotHeight: 8.w,
            activeDotColor: AppTheme.goldColor,
            dotColor: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.2),
          ),
          onDotClicked: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

class _HeroSlideCard extends StatelessWidget {
  const _HeroSlideCard({
    required this.slide,
    required this.isDark,
    required this.onTap,
  });

  final HeroSlideItem slide;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBundledOrCdn = slide.imageUrl.startsWith('images/');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: 0.25),
              blurRadius: 12.r,
              offset: Offset(0.w, 4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isBundledOrCdn)
                AppRemoteImage(
                  path: slide.imageUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  placeholder: _buildPlaceholder(),
                  errorWidget: _buildPlaceholder(),
                )
              else
                GymaiNetworkImage(
                  imageUrl: slide.imageUrl,
                  filterQuality: FilterQuality.medium,
                  placeholder: _buildPlaceholder(),
                  errorWidget: _buildPlaceholder(),
                ),
              // گرادیان پایین برای خوانایی متن
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 100.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // آیکون نوع
              Positioned(top: 12.h, right: 12.w, child: _buildTypeBadge()),
              // عنوان و زیرنویس
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 16.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slide.title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      slide.subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 11.sp,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          slide.type == HeroSlideType.music
                              ? LucideIcons.play
                              : LucideIcons.playCircle,
                          color: AppTheme.goldColor,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          slide.type == HeroSlideType.music ? 'پخش' : 'مشاهده',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                            color: AppTheme.goldColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    IconData icon = LucideIcons.sparkles;
    if (slide.type == HeroSlideType.video) icon = LucideIcons.video;
    if (slide.type == HeroSlideType.article) icon = LucideIcons.fileText;
    if (slide.type == HeroSlideType.music) icon = LucideIcons.music;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkGold.withValues(alpha: 0.6),
            AppTheme.goldColor.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.6),
          size: 48.sp,
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    IconData icon;
    String label;
    switch (slide.type) {
      case HeroSlideType.video:
        icon = LucideIcons.video;
        label = 'ویدیو';
      case HeroSlideType.article:
        icon = LucideIcons.fileText;
        label = 'مقاله';
      case HeroSlideType.music:
        icon = LucideIcons.music;
        label = 'موزیک';
      case HeroSlideType.poster:
        icon = LucideIcons.sparkles;
        label = 'پیشنهاد';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: AppTheme.goldColor, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 10.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
