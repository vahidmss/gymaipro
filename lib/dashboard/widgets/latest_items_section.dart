import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/widgets/section_nav_carousel.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/screens/food_detail_screen.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LatestItemsSection extends StatefulWidget {
  const LatestItemsSection({super.key});

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
  bool _showFoods = true; // Toggle between foods and exercises in one place

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
    // Build Foods carousel items
    final foodItems = (_isLoading && _latestFoods.isEmpty)
        ? [
            SectionCardItem(
              title: 'در حال بارگیری...',
              subtitle: 'لطفاً صبر کنید',
              icon: Icons.hourglass_bottom,
              onTap: () {},
              gradientColors: [
                const Color(0xFF2C3E50),
                const Color(0xFF4CA1AF),
              ],
            ),
          ]
        : _latestFoods.take(6).map((f) {
            return SectionCardItem(
              title: f.title,
              subtitle: '${f.nutrition.calories} کالری',
              icon: LucideIcons.utensils,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => FoodDetailScreen(food: f),
                  ),
                );
              },
              gradientColors: [
                const Color(0xFF1F1C2C),
                const Color(0xFF928DAB),
              ],
              imageUrl: f.imageUrl.isNotEmpty ? f.imageUrl : null,
            );
          }).toList();

    // Build Exercises carousel items
    final exerciseItems = (_isLoading && _latestExercises.isEmpty)
        ? [
            SectionCardItem(
              title: 'در حال بارگیری...',
              subtitle: 'لطفاً صبر کنید',
              icon: Icons.hourglass_bottom,
              onTap: () {},
              gradientColors: [
                const Color(0xFF2C3E50),
                const Color(0xFF4CA1AF),
              ],
            ),
          ]
        : _latestExercises.take(6).map((e) {
            return SectionCardItem(
              title: e.title,
              subtitle: e.mainMuscle.isNotEmpty ? e.mainMuscle : 'بدنسازی',
              icon: LucideIcons.dumbbell,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ExerciseDetailScreen(exercise: e),
                  ),
                );
              },
              gradientColors: [
                const Color(0xFF2C3E50),
                const Color(0xFF4CA1AF),
              ],
              imageUrl: e.imageUrl.isNotEmpty ? e.imageUrl : null,
            );
          }).toList();

    final currentItems = _showFoods ? foodItems : exerciseItems;
    // Title removed per design; use empty string in carousel

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Single academy-like carousel with overlayed segmented toggle inside header area
        Stack(
          children: [
            // Title intentionally empty to remove the label area
            SectionNavCarousel(
              title: '',
              items: currentItems,
              onHeaderAction: () => Navigator.pushNamed(
                context,
                _showFoods ? '/food-list' : '/exercise-list',
              ),
            ),
            // Overlay toggle aligned to header's right padding
            Positioned(
              right: 16.w,
              top: 16.h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5.w,
                  ),
                ),
                padding: EdgeInsets.all(4.w),
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
          ],
        ),
      ],
    );
  }

  // old segmented toggle removed

  Widget _buildSegment(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.black : Colors.white.withValues(alpha: 0.8),
            fontSize: 11.sp,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Removed: replaced by SectionNavCarousel above
  // Widget _buildExercisesList()
  // Widget _buildExerciseCard()

  // Removed: replaced by SectionNavCarousel above

  // Removed: replaced by SectionNavCarousel above

  // Removed: replaced by SectionNavCarousel above
  // Widget _buildLoadingShimmer()
}
