// Flutter imports
import 'package:flutter/material.dart';

// Third-party imports
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';

// App imports
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/screens/food_detail_screen.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';

class LatestItemsSection extends StatefulWidget {
  const LatestItemsSection({Key? key}) : super(key: key);

  @override
  State<LatestItemsSection> createState() => _LatestItemsSectionState();
}

class _LatestItemsSectionState extends State<LatestItemsSection>
    with TickerProviderStateMixin {
  final FoodService _foodService = FoodService();
  final ExerciseService _exerciseService = ExerciseService();

  List<Food> _latestFoods = [];
  List<Exercise> _latestExercises = [];
  bool _isLoading = true;
  bool _showFoods = true; // Toggle between foods and exercises

  @override
  void initState() {
    super.initState();
    _loadLatestItems();
  }

  Future<void> _loadLatestItems() async {
    SafeSetState.call(this, () {
      _isLoading = true;
    });

    try {
      final foods = await _foodService.getFoods();
      final exercises = await _exerciseService.getExercises();

      SafeSetState.call(this, () {
        _latestFoods = foods.take(5).toList();
        _latestExercises = exercises.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 232,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Elegant header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05), width: 0.5),
            ),
            child: Row(
              children: [
                // Decorative line
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.85),
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                // Title (RTL right-aligned) - ignore taps to avoid accidental clicks
                Expanded(
                  child: IgnorePointer(
                    ignoring: true,
                    child: const Text(
                      'جدیدترین‌ها',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Segmented toggle (minimal) with responsive fit
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.5),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _buildSegment('خوراکی‌ها', _showFoods, () {
                            if (!mounted) return;
                            setState(() => _showFoods = true);
                          }),
                          const SizedBox(width: 4),
                          _buildSegment('تمرینات', !_showFoods, () {
                            if (!mounted) return;
                            setState(() => _showFoods = false);
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // View all subtle action with larger hit area
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_showFoods) {
                      Navigator.pushNamed(context, '/food-list');
                    } else {
                      Navigator.pushNamed(context, '/exercise-list');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white.withOpacity(0.75),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingShimmer()
                : _showFoods
                    ? _buildFoodsList()
                    : _buildExercisesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.black : Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodsList() {
    if (_latestFoods.isEmpty) {
      return const Center(
        child: Text(
          'هیچ خوراکی‌ای یافت نشد',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      scrollDirection: Axis.horizontal,
      reverse: true,
      cacheExtent: 600,
      itemCount: _latestFoods.length,
      itemBuilder: (context, index) {
        final food = _latestFoods[index];
        final bool isLast = index == _latestFoods.length - 1;
        return Container(
          margin: EdgeInsets.only(left: isLast ? 0 : 12),
          child: _buildFoodCard(food),
        );
      },
    );
  }

  Widget _buildExercisesList() {
    if (_latestExercises.isEmpty) {
      return const Center(
        child: Text(
          'هیچ تمرینی یافت نشد',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      scrollDirection: Axis.horizontal,
      reverse: true,
      cacheExtent: 600,
      itemCount: _latestExercises.length,
      itemBuilder: (context, index) {
        final exercise = _latestExercises[index];
        final bool isLast = index == _latestExercises.length - 1;
        return Container(
          margin: EdgeInsets.only(left: isLast ? 0 : 12),
          child: _buildExerciseCard(exercise),
        );
      },
    );
  }

  Widget _buildFoodCard(Food food) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FoodDetailScreen(food: food),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.25),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: food.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: food.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.cardColor,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.cardColor,
                        child: const Center(
                          child: Icon(LucideIcons.utensils,
                              color: AppTheme.goldColor, size: 28),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.cardColor,
                      child: const Center(
                        child: Icon(LucideIcons.utensils,
                            color: AppTheme.goldColor, size: 28),
                      ),
                    ),
            ),
            // Top-right icon badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.flame,
                    color: Colors.orange, size: 14),
              ),
            ),
            // Gradient overlay & texts (bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      food.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          child: Text(
                            '${food.nutrition.calories} کالری',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.flame,
                            color: Colors.orange, size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: exercise),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.25),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: exercise.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: exercise.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.cardColor,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.cardColor,
                        child: const Center(
                          child: Icon(LucideIcons.dumbbell,
                              color: AppTheme.goldColor, size: 28),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.cardColor,
                      child: const Center(
                        child: Icon(LucideIcons.dumbbell,
                            color: AppTheme.goldColor, size: 28),
                      ),
                    ),
            ),
            // Top-right icon badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.target,
                    color: Colors.green, size: 14),
              ),
            ),
            // Gradient overlay & texts (bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          child: Text(
                            exercise.mainMuscle.isNotEmpty
                                ? exercise.mainMuscle
                                : 'بدنسازی',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.target,
                            color: Colors.green, size: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    // Minimal shimmer placeholders for performance
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      scrollDirection: Axis.horizontal,
      reverse: true,
      itemCount: 5,
      itemBuilder: (context, index) {
        final bool isLast = index == 4;
        return Container(
          width: 150,
          margin: EdgeInsets.only(left: isLast ? 0 : 12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
