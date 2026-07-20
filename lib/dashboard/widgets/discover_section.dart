import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// آیتم یکپارچه برای نمایش در کاروسل (تمرین یا غذا)
class _DiscoverItem {

  _DiscoverItem({
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.subtitleIcon,
    required this.showLock,
    required this.onTap,
    required this.date,
  });
  final String title;
  final String imageUrl;
  final String subtitle;
  final IconData subtitleIcon;
  final bool showLock;
  final VoidCallback onTap;
  final DateTime date;
}

/// بخش "کشف جدیدها" - ترکیب تمرینات و تغذیه در یک کاروسل واحد با تب‌سوئیچر
class DiscoverSection extends StatefulWidget {
  const DiscoverSection({super.key, this.refreshToken = 0});

  /// وقتی داشبورد pull-to-refresh می‌شود، این مقدار عوض می‌شود تا داده و تصاویر
  /// دوباره بارگذاری شوند.
  final int refreshToken;

  @override
  State<DiscoverSection> createState() => _DiscoverSectionState();
}

class _DiscoverSectionState extends State<DiscoverSection>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // تب انتخاب شده: 0 = تمرینات، 1 = تغذیه
  int _selectedTab = 0;

  // کنترلرهای کاروسل
  final PageController _pageController = PageController(viewportFraction: 0.88);
  Timer? _autoPlayTimer;
  int _carouselPageIndex = 0;

  // دیتا
  List<_DiscoverItem> _exerciseItems = [];
  List<_DiscoverItem> _foodItems = [];
  bool _isLoadingExercises = true;
  bool _isLoadingFoods = true;

  /// با هر resume یا refresh، epoch عوض می‌شود تا CachedNetworkImage دوباره mount شود
  /// (بعد از background اندروید کش حافظهٔ تصویر خالی می‌شود و بدون rebuild خطا می‌ماند).
  int _imageReloadEpoch = 0;

  // سرویس‌ها
  final CustomExerciseService _customExerciseService = CustomExerciseService();
  final ExerciseService _exerciseService = ExerciseService();
  final TrainerService _trainerService = TrainerService();
  final FoodService _foodService = FoodService();
  final DashboardCacheService _cacheService = DashboardCacheService();
  String? _currentUserId;

  // انیمیشن تب سوئیچ
  late AnimationController _tabAnimController;
  late Animation<double> _tabFadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserId = AuthHelper.currentUserIdSync;

    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tabAnimController, curve: Curves.easeOut),
    );
    _tabAnimController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadAll());
    });
  }

  @override
  void didUpdateWidget(covariant DiscoverSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      unawaited(_reloadFromDashboardRefresh());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  /// بعد از برگشت از background: ویجت تصویر را مجبور به rebuild می‌کنیم.
  /// اگر URL خالی مانده، داده را هم دوباره می‌گیریم.
  void _onAppResumed() {
    if (!mounted) return;
    setState(() => _imageReloadEpoch++);
    if (_itemsMissingImages) {
      unawaited(_loadAll());
    }
  }

  bool get _itemsMissingImages =>
      _exerciseItems.any((i) => i.imageUrl.isEmpty) ||
      _foodItems.any((i) => i.imageUrl.isEmpty);

  Future<void> _loadAll() async {
    // Preload catalog so carousel reads URLs that are already in memory/disk cache.
    // Catalog failures (e.g. WordPress timeout) must not crash the dashboard.
    try {
      await Future.wait([
        _exerciseService.getExercises().catchError((Object e) {
          debugPrint('Discover preload exercises failed: $e');
          return <Exercise>[];
        }),
        _foodService.getFoods().catchError((Object e) {
          debugPrint('Discover preload foods failed: $e');
          return <Food>[];
        }),
      ]);
    } catch (e) {
      debugPrint('Discover catalog preload failed: $e');
    }

    await Future.wait([_loadExercises(), _loadFoods()]);

    if (mounted && _itemsMissingImages) {
      try {
        await Future.wait([
          _exerciseService.getExercises(forceRefresh: true).catchError((
            Object e,
          ) {
            debugPrint('Discover refresh exercises failed: $e');
            return <Exercise>[];
          }),
          _foodService.getFoods(forceRefresh: true).catchError((Object e) {
            debugPrint('Discover refresh foods failed: $e');
            return <Food>[];
          }),
        ]);
      } catch (e) {
        debugPrint('Discover catalog refresh failed: $e');
      }
      await Future.wait([_loadExercises(), _loadFoods()]);
    }

    if (mounted) {
      setState(() => _imageReloadEpoch++);
    }
  }

  Future<void> _reloadFromDashboardRefresh() async {
    if (!mounted) return;
    setState(() {
      _imageReloadEpoch++;
      _isLoadingExercises = true;
      _isLoadingFoods = true;
    });
    await _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _tabAnimController.dispose();
    super.dispose();
  }

  List<_DiscoverItem> get _currentItems =>
      _selectedTab == 0 ? _exerciseItems : _foodItems;

  bool get _isCurrentLoading =>
      _selectedTab == 0 ? _isLoadingExercises : _isLoadingFoods;

  // ─── بارگذاری تمرینات ───
  Future<void> _loadExercises() async {
    try {
      final allExercises = <_DiscoverItem>[];

      final publicExercises = await _customExerciseService.getPublicExercises(
        limit: 20,
      );

      var trainerExercises = <CustomExercise>[];
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        trainerExercises = await _customExerciseService
            .getTrainerExercisesForClient(_currentUserId!);
      }

      final creatorIds = <String>{
        ...trainerExercises.map((e) => e.createdBy),
        ...publicExercises.take(10).map((e) => e.createdBy),
      }.where((id) => id.isNotEmpty).toList();

      final profilesById = creatorIds.isEmpty
          ? <String, Map<String, dynamic>>{}
          : await ProfileRepository.instance.fetchProfilesByIdsMap(
              creatorIds,
              columns: 'id, username, first_name, last_name',
            );

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        for (final customEx in trainerExercises) {
          final exercise = await _customExerciseService
              .customExerciseToExercise(customEx);
          final trainerProfile = profilesById[customEx.createdBy];
          final trainerName = _getTrainerName(trainerProfile);
          final isUserTrainer = await _trainerService.isClientOfTrainer(
            _currentUserId!,
            customEx.createdBy,
          );

          allExercises.add(
            _DiscoverItem(
              title: exercise.title,
              imageUrl: exercise.imageUrl,
              subtitle: trainerName,
              subtitleIcon: LucideIcons.user,
              showLock: !isUserTrainer,
              date: customEx.createdAt,
              onTap: () {
                if (mounted) {
                  Navigator.pushNamed(
                    context,
                    '/exercise-detail',
                    arguments: {'exercise': exercise},
                  );
                }
              },
            ),
          );
        }
      }

      for (final customEx in publicExercises.take(10)) {
        final exercise = await _customExerciseService.customExerciseToExercise(
          customEx,
        );
        final trainerProfile = profilesById[customEx.createdBy];
        final trainerName = _getTrainerName(trainerProfile);
        final isUserTrainer =
            (_currentUserId != null && _currentUserId!.isNotEmpty) && await _trainerService.isClientOfTrainer(
                _currentUserId!,
                customEx.createdBy,
              );

        allExercises.add(
          _DiscoverItem(
            title: exercise.title,
            imageUrl: exercise.imageUrl,
            subtitle: trainerName,
            subtitleIcon: LucideIcons.user,
            showLock: !isUserTrainer,
            date: customEx.createdAt,
            onTap: () {
              if (mounted) {
                Navigator.pushNamed(
                  context,
                  '/exercise-detail',
                  arguments: {'exercise': exercise},
                );
              }
            },
          ),
        );
      }

      await _appendCatalogExercises(allExercises);

      allExercises.sort((a, b) => b.date.compareTo(a.date));
      final exercisesWithImages =
          allExercises.where((e) => e.imageUrl.isNotEmpty).toList();
      final exercisePool =
          exercisesWithImages.length >= 5 ? exercisesWithImages : allExercises;

      if (mounted) {
        setState(() {
          _exerciseItems = exercisePool.take(5).toList();
          _isLoadingExercises = false;
        });
        if (_selectedTab == 0 && _exerciseItems.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startAutoPlay();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading exercises for discover: $e');
      if (mounted) setState(() => _isLoadingExercises = false);
    }
  }

  Future<void> _appendCatalogExercises(List<_DiscoverItem> allExercises) async {
    try {
      final regularExercises = await _exerciseService.getExercises();
      regularExercises.sort((a, b) => b.likes.compareTo(a.likes));
      final withImages =
          regularExercises.where((e) => e.imageUrl.isNotEmpty).toList();
      final pool = withImages.isNotEmpty ? withImages : regularExercises;
      final existingTitles = allExercises.map((e) => e.title).toSet();

      for (final ex in pool) {
        if (allExercises.length >= 5) break;
        if (existingTitles.contains(ex.title)) continue;
        allExercises.add(
          _DiscoverItem(
            title: ex.title,
            imageUrl: ex.imageUrl,
            subtitle: ex.author ?? 'جیم اِی آی',
            subtitleIcon: LucideIcons.user,
            showLock: false,
            date: DateTime.now().subtract(
              Duration(days: pool.indexOf(ex)),
            ),
            onTap: () {
              if (mounted) {
                Navigator.pushNamed(
                  context,
                  '/exercise-detail',
                  arguments: {'exercise': ex},
                );
              }
            },
          ),
        );
        existingTitles.add(ex.title);
      }
    } catch (e) {
      debugPrint('Error loading catalog exercises for discover: $e');
    }
  }

  // ─── بارگذاری غذاها ───
  Future<void> _loadFoods() async {
    try {
      final allFoods = await _foodService.getFoods();
      _cacheService.setFoods(allFoods);

      allFoods.sort((a, b) => b.date.compareTo(a.date));

      final withImages =
          allFoods.where((f) => f.imageUrl.isNotEmpty).toList();
      final pool = withImages.isNotEmpty ? withImages : allFoods;

      final foodItems = pool.take(5).map((food) {
        final caloriesText =
            (food.nutrition.calories.isNotEmpty &&
                food.nutrition.calories != '0')
            ? '${food.nutrition.calories} کالری'
            : '';
        return _DiscoverItem(
          title: food.title,
          imageUrl: food.imageUrl,
          subtitle: caloriesText.isNotEmpty ? caloriesText : food.title,
          subtitleIcon: caloriesText.isNotEmpty
              ? LucideIcons.flame
              : LucideIcons.utensilsCrossed,
          showLock: false,
          date: food.date,
          onTap: () {
            if (mounted) {
              Navigator.pushNamed(context, '/food-detail', arguments: food);
            }
          },
        );
      }).toList();

      if (mounted) {
        setState(() {
          _foodItems = foodItems;
          _isLoadingFoods = false;
        });
        if (_selectedTab == 1 && _foodItems.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startAutoPlay();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading foods for discover: $e');
      if (mounted) setState(() => _isLoadingFoods = false);
    }
  }

  String _getTrainerName(Map<String, dynamic>? profile) {
    if (profile == null) return 'مربی';
    final first = profile['first_name'] as String? ?? '';
    final last = profile['last_name'] as String? ?? '';
    final username = profile['username'] as String? ?? '';
    if ((first + last).trim().isNotEmpty) return '$first $last'.trim();
    if (username.isNotEmpty) return username;
    return 'مربی';
  }

  // ─── اتوپلی ───
  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (!WebInteraction.allowCarouselAutoPlay) return;
    final items = _currentItems;
    if (items.isEmpty || items.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final items = _currentItems;
      if (items.isEmpty || items.length <= 1) return;
      final target = (_carouselPageIndex + 1) % items.length;
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onTabChanged(int index) {
    if (_selectedTab == index) return;

    _autoPlayTimer?.cancel();
    _tabAnimController.reset();

    setState(() {
      _selectedTab = index;
      _carouselPageIndex = 0;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    _tabAnimController.forward();

    // شروع اتوپلی برای تب جدید
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _currentItems.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAutoPlay();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── هدر بخش ───
        _buildHeader(isDark),
        SizedBox(height: 14.h),

        // ─── تب‌سوئیچر شیک ───
        _buildTabSwitcher(isDark),
        SizedBox(height: 16.h),

        // ─── محتوای کاروسل ───
        FadeTransition(
          opacity: _tabFadeAnimation,
          child: _buildContent(isDark),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // عنوان با آیکون
        Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.2),
                    AppTheme.goldColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 16.sp,
                color: context.textColor,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'کشف جدیدها',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
          ],
        ),
        // دکمه مشاهده همه
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              _selectedTab == 0 ? '/exercise-list' : '/food-list',
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مشاهده همه',
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
    );
  }

  Widget _buildTabSwitcher(bool isDark) {
    return Container(
      height: 42.h,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _buildTab(
            index: 0,
            label: 'تمرینات',
            icon: LucideIcons.dumbbell,
            isDark: isDark,
          ),
          _buildTab(
            index: 1,
            label: 'تغذیه',
            icon: LucideIcons.utensilsCrossed,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.goldColor,
                      AppTheme.goldColor.withValues(alpha: 0.85),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: isSelected
                    ? Colors.black
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? Colors.black
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isCurrentLoading) {
      return SizedBox(
        height: 220.h,
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

    final items = _currentItems;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // کاروسل
        SizedBox(
          height: 220.h,
          child: PageView.builder(
            controller: _pageController,
            physics: WebInteraction.pageViewPhysics,
            itemCount: items.length,
            onPageChanged: (index) => _carouselPageIndex = index,
            itemBuilder: (context, index) {
              return _DiscoverCard(
                key: ValueKey(
                  'discover_${_selectedTab}_${items[index].title}_$index',
                ),
                item: items[index],
                isDark: isDark,
                isFood: _selectedTab == 1,
                imageReloadEpoch: _imageReloadEpoch,
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        // Page indicator
        if (items.length > 1)
          Center(
            child: SmoothPageIndicator(
              controller: _pageController,
              count: items.length,
              effect: WormEffect(
                dotWidth: 7.w,
                dotHeight: 7.w,
                spacing: 6.w,
                activeDotColor: AppTheme.goldColor,
                dotColor: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
              ),
              onDotClicked: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isExercise = _selectedTab == 0;
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.15),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExercise ? LucideIcons.dumbbell : LucideIcons.utensilsCrossed,
              size: 42.sp,
              color: context.textSecondary,
            ),
            SizedBox(height: 10.h),
            Text(
              isExercise ? 'هنوز تمرینی اضافه نشده' : 'هنوز غذایی اضافه نشده',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── کارت کاروسل ───
class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.isFood,
    required this.imageReloadEpoch,
  });

  final _DiscoverItem item;
  final bool isDark;
  final bool isFood;
  final int imageReloadEpoch;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: 0.12),
              blurRadius: 16.r,
              offset: Offset(0, 6.h),
            ),
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withValues(
                alpha: 0.08,
              ),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── تصویر ───
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // تصویر اصلی
                    if (item.imageUrl.isNotEmpty)
                      GymaiNetworkImage(
                            key: ValueKey(
                              'discover_img_${item.imageUrl}_$imageReloadEpoch',
                            ),
                            imageUrl: item.imageUrl,
                            placeholder: ColoredBox(
                              color: context.placeholderColor,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.goldColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: ColoredBox(
                              color: context.placeholderColor,
                              child: Icon(
                                isFood
                                    ? LucideIcons.utensilsCrossed
                                    : LucideIcons.dumbbell,
                                size: 40.sp,
                                color: context.placeholderIconColor,
                              ),
                            ),
                          ) else ColoredBox(
                            color: context.placeholderColor,
                            child: Icon(
                              isFood
                                  ? LucideIcons.utensilsCrossed
                                  : LucideIcons.dumbbell,
                              size: 40.sp,
                              color: context.placeholderIconColor,
                            ),
                          ),

                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 90.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // بج نوع محتوا (بالا سمت چپ)
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isFood
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.85)
                              : const Color(0xFF2196F3).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFood
                                  ? LucideIcons.utensilsCrossed
                                  : LucideIcons.dumbbell,
                              size: 10.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              isFood ? 'تغذیه' : 'تمرین',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // آیکون قفل (بالا سمت راست)
                    if (item.showLock)
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.lock,
                            size: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ─── بخش پایین ───
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppTheme.darkGreyGradient,
                            AppTheme.goldColor.withValues(alpha: 0.2),
                          ]
                        : [
                            context.gradientStartColor,
                            AppTheme.goldColor.withValues(alpha: 0.15),
                          ],
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // اطلاعات متنی
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.subtitle != item.title) ...[
                            SizedBox(height: 3.h),
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.subtitleIcon,
                                  size: 11.sp,
                                  color: context.textSecondary,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.sp,
                                      color: context.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // فلش "مشاهده"
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.arrowLeft,
                        size: 14.sp,
                        color: AppTheme.goldColor,
                      ),
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
}
