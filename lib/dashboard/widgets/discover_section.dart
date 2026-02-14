import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// آیتم یکپارچه برای نمایش در کاروسل (تمرین یا غذا)
class _DiscoverItem {
  final String title;
  final String imageUrl;
  final String subtitle;
  final IconData subtitleIcon;
  final bool showLock;
  final VoidCallback onTap;
  final DateTime date;

  _DiscoverItem({
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.subtitleIcon,
    required this.showLock,
    required this.onTap,
    required this.date,
  });
}

/// بخش "کشف جدیدها" - ترکیب تمرینات و تغذیه در یک کاروسل واحد با تب‌سوئیچر
class DiscoverSection extends StatefulWidget {
  const DiscoverSection({super.key});

  @override
  State<DiscoverSection> createState() => _DiscoverSectionState();
}

class _DiscoverSectionState extends State<DiscoverSection>
    with SingleTickerProviderStateMixin {
  // تب انتخاب شده: 0 = تمرینات، 1 = تغذیه
  int _selectedTab = 0;

  // کنترلرهای کاروسل
  PageController _pageController = PageController(viewportFraction: 0.88);
  Timer? _autoPlayTimer;

  // دیتا
  List<_DiscoverItem> _exerciseItems = [];
  List<_DiscoverItem> _foodItems = [];
  bool _isLoadingExercises = true;
  bool _isLoadingFoods = true;

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
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;

    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimController, curve: Curves.easeOut),
    );
    _tabAnimController.forward();

    _loadExercises();
    _loadFoods();
  }

  @override
  void dispose() {
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
        requireApproval: false,
      );

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        final trainerExercises = await _customExerciseService
            .getTrainerExercisesForClient(_currentUserId!);

        for (final customEx in trainerExercises) {
          final exercise = await _customExerciseService
              .customExerciseToExercise(customEx);
          final trainerProfile = await _fetchProfile(customEx.createdBy);
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
        final trainerProfile = await _fetchProfile(customEx.createdBy);
        final trainerName = _getTrainerName(trainerProfile);
        final isUserTrainer =
            _currentUserId != null && _currentUserId!.isNotEmpty
            ? await _trainerService.isClientOfTrainer(
                _currentUserId!,
                customEx.createdBy,
              )
            : false;

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

      // فالبک اگه خالی بود
      if (allExercises.isEmpty) {
        try {
          await _exerciseService.init();
          final regularExercises = await _exerciseService.getExercises();
          regularExercises.sort((a, b) => b.likes.compareTo(a.likes));
          for (final ex in regularExercises.take(5)) {
            allExercises.add(
              _DiscoverItem(
                title: ex.title,
                imageUrl: ex.imageUrl,
                subtitle: ex.author ?? 'جیم اِی آی',
                subtitleIcon: LucideIcons.user,
                showLock: false,
                date: DateTime.now().subtract(
                  Duration(days: regularExercises.indexOf(ex)),
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
          }
        } catch (e) {
          debugPrint('Error loading regular exercises: $e');
        }
      }

      allExercises.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _exerciseItems = allExercises.take(5).toList();
          _isLoadingExercises = false;
        });
        if (_selectedTab == 0 && _exerciseItems.length > 1) {
          _startAutoPlay();
        }
      }
    } catch (e) {
      debugPrint('Error loading exercises for discover: $e');
      if (mounted) setState(() => _isLoadingExercises = false);
    }
  }

  // ─── بارگذاری غذاها ───
  Future<void> _loadFoods() async {
    try {
      List<Food> allFoods = [];

      final cachedFoods = _cacheService.getFoods();
      if (cachedFoods != null && cachedFoods.isNotEmpty) {
        allFoods = cachedFoods;
      } else {
        await _foodService.init();
        allFoods = await _foodService.getFoods();
        _cacheService.setFoods(allFoods);
      }

      allFoods.sort((a, b) => b.date.compareTo(a.date));

      final foodItems = allFoods.take(5).map((food) {
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
          _startAutoPlay();
        }
      }
    } catch (e) {
      debugPrint('Error loading foods for discover: $e');
      if (mounted) setState(() => _isLoadingFoods = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username, first_name, last_name')
          .eq('id', userId)
          .maybeSingle();
      return response != null
          ? Map<String, dynamic>.from(response as Map)
          : null;
    } catch (e) {
      return null;
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
    final items = _currentItems;
    if (items.isEmpty || items.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final items = _currentItems;
      if (items.isEmpty || items.length <= 1) return;
      final next = (_pageController.page?.round() ?? 0) + 1;
      final target = next >= items.length ? 0 : next;
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
      _pageController.dispose();
      _pageController = PageController(viewportFraction: 0.88);
    });

    _tabAnimController.forward();

    // شروع اتوپلی برای تب جدید
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _currentItems.length > 1) {
        _startAutoPlay();
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
                width: 1,
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
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _DiscoverCard(
                item: items[index],
                isDark: isDark,
                isFood: _selectedTab == 1,
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
          width: 1,
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
    required this.item,
    required this.isDark,
    required this.isFood,
  });

  final _DiscoverItem item;
  final bool isDark;
  final bool isFood;

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
                    item.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: context.placeholderColor,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.goldColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: context.placeholderColor,
                              child: Icon(
                                isFood
                                    ? LucideIcons.utensilsCrossed
                                    : LucideIcons.dumbbell,
                                size: 40.sp,
                                color: context.placeholderIconColor,
                              ),
                            ),
                          )
                        : Container(
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
