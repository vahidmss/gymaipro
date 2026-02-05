import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

class ExercisesTabsSection extends StatefulWidget {
  const ExercisesTabsSection({super.key});

  @override
  State<ExercisesTabsSection> createState() => _ExercisesTabsSectionState();
}

class _ExercisesTabsSectionState extends State<ExercisesTabsSection> {
  int _selectedTab = 0; // 0: تمرینات, 1: تغذیه

  final List<String> _tabs = ['تمرینات', 'تغذیه'];

  // داده‌های واقعی
  List<Exercise> _exercises = [];
  List<Food> _foods = [];
  bool _isLoading = true;

  final ExerciseService _exerciseService = ExerciseService();
  final FoodService _foodService = FoodService();
  final DashboardCacheService _cacheService = DashboardCacheService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // بررسی کش برای تمرینات
      List<Exercise>? cachedExercises = _cacheService.getExercises();
      if (cachedExercises != null) {
        _exercises = cachedExercises;
      } else {
        // بارگذاری از API
        await _exerciseService.init();
        final exercises = await _exerciseService.getExercises();
        exercises.sort((a, b) => b.likes.compareTo(a.likes));
        _exercises = exercises.take(10).toList();
        // ذخیره در کش
        _cacheService.setExercises(_exercises);
      }

      // بررسی کش برای غذاها
      List<Food>? cachedFoods = _cacheService.getFoods();
      if (cachedFoods != null) {
        _foods = cachedFoods;
      } else {
        // بارگذاری از API
        await _foodService.init();
        final foods = await _foodService.getFoods();
        foods.sort((a, b) => b.likes.compareTo(a.likes));
        _foods = foods.take(10).toList();
        // ذخیره در کش
        _cacheService.setFoods(_foods);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // تب‌ها
        Stack(
          children: [
            // خط جداکننده پایین تب‌ها
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 1.h, color: context.separatorColor),
            ),
            // خط طلایی زیر تب فعال
            Positioned(
              bottom: 0,
              right: _getActiveTabPosition(),
              child: Container(
                width: 125.w,
                height: 1.h,
                color: AppTheme.goldTabIndicator,
              ),
            ),
            // تب‌ها
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _tabs.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        height: 1.611,
                        color: context.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        // دکمه مشاهده بیشتر
        Row(
          textDirection: TextDirection.ltr,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to view more based on selected tab
                if (_selectedTab == 0) {
                  Navigator.pushNamed(context, '/exercise-list');
                } else {
                  Navigator.pushNamed(context, '/food-list');
                }
              },
              child: Container(
                width: 90.w,
                height: 44.h, // حداقل 44px برای accessibility
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.textColor
                        : AppTheme.goldColor.withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'مشاهده بیشتر',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontWeight: FontWeight.w900,
                          fontSize: 7.sp,
                          height: 1.611,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.goldColor
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 9.sp,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.goldColor
                          : Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        // محتوای هر تب
        _isLoading
            ? SizedBox(
                height: 111.h,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.goldColor),
                ),
              )
            : _getItemCount() == 0
            ? SizedBox(
                height: 111.h,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedTab == 0
                            ? Icons.fitness_center
                            : Icons.restaurant,
                        size: 40.sp,
                        color: context.textSecondary,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'محتوایی یافت نشد',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: 111.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _getItemCount(),
                  itemBuilder: (context, index) {
                    if (_selectedTab == 0) {
                      return _buildExerciseCard(_exercises[index]);
                    } else {
                      return _buildFoodCard(_foods[index]);
                    }
                  },
                ),
              ),
      ],
    );
  }

  double _getActiveTabPosition() {
    // محاسبه موقعیت خط طلایی بر اساس تب فعال (RTL)
    // در RTL: تمرینات (0) در راست، تغذیه (1) در چپ
    final tabWidth = 73.w; // عرض تقریبی هر تب
    final spacing = 20.w * 2; // فاصله بین تب‌ها
    // برای RTL: تب 0 (تمرینات) در راست = 0, تب 1 (تغذیه) = tabWidth + spacing
    return _selectedTab * (tabWidth + spacing);
  }

  int _getItemCount() {
    if (_selectedTab == 0) {
      return _exercises.length;
    } else {
      return _foods.length;
    }
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/exercise-detail',
          arguments: {'exercise': exercise},
        );
      },
      child: Container(
        width: 130.w,
        height: 111.h,
        margin: EdgeInsets.only(left: 11.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(13.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.4,
              ),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // تصویر تمرین
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13.r),
                topRight: Radius.circular(13.r),
              ),
              child: Container(
                width: double.infinity,
                height: 81.h,
                color: context.placeholderColor,
                child: exercise.imageUrl.isNotEmpty
                    ? Image.network(
                        exercise.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: context.placeholderColor,
                            child: Icon(
                              Icons.fitness_center,
                              size: 40.sp,
                              color: context.placeholderIconColor,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: context.placeholderColor,
                        child: Icon(
                          Icons.fitness_center,
                          size: 40.sp,
                          color: context.placeholderIconColor,
                        ),
                      ),
              ),
            ),
            // بخش پایین با gradient
            Container(
              width: double.infinity,
              height: 30.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [AppTheme.darkGreyGradient, AppTheme.goldColor]
                      : [context.gradientStartColor, AppTheme.goldColor],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(13.r),
                  bottomRight: Radius.circular(13.r),
                ),
              ),
              child: Center(
                child: Text(
                  exercise.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.sp,
                    height: 1.611,
                    color: context.textColor,
                    shadows: [
                      Shadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.backgroundColor.withValues(alpha: 0.5)
                            : context.cardColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(Food food) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/food-detail', arguments: food);
      },
      child: Container(
        width: 130.w,
        height: 111.h,
        margin: EdgeInsets.only(left: 11.w),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(13.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.35
                    : 0.4,
              ),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // تصویر غذا
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13.r),
                topRight: Radius.circular(13.r),
              ),
              child: Container(
                width: double.infinity,
                height: 81.h,
                color: context.placeholderColor,
                child: food.imageUrl.isNotEmpty
                    ? Image.network(
                        food.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: context.placeholderColor,
                            child: Icon(
                              Icons.restaurant,
                              size: 40.sp,
                              color: context.placeholderIconColor,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: context.placeholderColor,
                        child: Icon(
                          Icons.restaurant,
                          size: 40.sp,
                          color: context.placeholderIconColor,
                        ),
                      ),
              ),
            ),
            // بخش پایین با gradient
            Container(
              width: double.infinity,
              height: 30.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [AppTheme.darkGreyGradient, AppTheme.goldColor]
                      : [context.gradientStartColor, AppTheme.goldColor],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(13.r),
                  bottomRight: Radius.circular(13.r),
                ),
              ),
              child: Center(
                child: Text(
                  food.title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.sp,
                    height: 1.611,
                    color: context.textColor,
                    shadows: [
                      Shadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? context.backgroundColor.withValues(alpha: 0.5)
                            : context.cardColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
