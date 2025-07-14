import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food.dart';
import '../models/exercise.dart';
import '../services/food_service.dart';
import '../services/exercise_service.dart';
import '../theme/app_theme.dart';
import '../screens/food_detail_screen.dart';
import '../screens/exercise_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LatestItemsSection extends StatefulWidget {
  const LatestItemsSection({Key? key}) : super(key: key);

  @override
  State<LatestItemsSection> createState() => _LatestItemsSectionState();
}

class _LatestItemsSectionState extends State<LatestItemsSection> {
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
    setState(() {
      _isLoading = true;
    });

    try {
      final foods = await _foodService.getFoods();
      final exercises = await _exerciseService.getExercises();

      setState(() {
        _latestFoods = foods.take(5).toList();
        _latestExercises = exercises.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 280,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with toggle buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  color: AppTheme.goldColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'جدیدترین‌ها',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Toggle buttons
                Row(
                  children: [
                    _buildToggleButton('خوراکی‌ها', _showFoods, () {
                      setState(() {
                        _showFoods = true;
                      });
                    }),
                    const SizedBox(width: 8),
                    _buildToggleButton('تمرینات', !_showFoods, () {
                      setState(() {
                        _showFoods = false;
                      });
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  )
                : _showFoods
                    ? _buildFoodsList()
                    : _buildExercisesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.goldColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                isActive ? Colors.black : Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      itemCount: _latestFoods.length,
      itemBuilder: (context, index) {
        final food = _latestFoods[index];
        return _buildFoodCard(food);
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
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      itemCount: _latestExercises.length,
      itemBuilder: (context, index) {
        final exercise = _latestExercises[index];
        return _buildExerciseCard(exercise);
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
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: food.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: food.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.cardColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.goldColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.cardColor,
                            child: const Icon(
                              LucideIcons.utensils,
                              color: AppTheme.goldColor,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.cardColor,
                          child: const Icon(
                            LucideIcons.utensils,
                            color: AppTheme.goldColor,
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
            // Food Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        food.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.flame,
                          color: Colors.orange,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${food.nutrition.calories} کالری',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: exercise.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: exercise.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.cardColor,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.goldColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.cardColor,
                            child: const Icon(
                              LucideIcons.dumbbell,
                              color: AppTheme.goldColor,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.cardColor,
                          child: const Icon(
                            LucideIcons.dumbbell,
                            color: AppTheme.goldColor,
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
            // Exercise Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        exercise.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.target,
                          color: Colors.green,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            exercise.mainMuscle.isNotEmpty
                                ? exercise.mainMuscle
                                : 'بدنسازی',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
}
