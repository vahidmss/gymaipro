import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/screens/food_detail_screen.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen>
    with SingleTickerProviderStateMixin {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showInfoHeader = true;

  // Enhanced Gold theme colors
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color backgroundColor = Color(0xFF0F0F0F);
  static const Color cardColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _foodService.init();
      final foods = await _foodService.getFoods();

      if (mounted) {
        setState(() {
          _foods = foods;
          _isLoading = false;
        });
        // Apply initial filter + sort by likes desc
        _filterFoods();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری خوراکی‌ها: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }

  void _filterFoods() {
    final filtered = _searchQuery.isEmpty
        ? _foods
        : _foods.where((food) {
            final query = _searchQuery.toLowerCase();
            return food.title.toLowerCase().contains(query) ||
                food.content.toLowerCase().contains(query);
          }).toList();

    // Sort by likes descending; then by title for stable order
    filtered.sort((a, b) {
      final likeDiff = b.likes.compareTo(a.likes);
      if (likeDiff != 0) return likeDiff;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    if (mounted) {
      setState(() {
        _filteredFoods = filtered;
      });
    }
  }

  Future<void> _toggleFavorite(Food food) async {
    try {
      await _foodService.toggleFavorite(food.id);
      if (mounted) {
        setState(() {
          // food.isFavorite is already updated in the service
        });

        if (food.isFavorite) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('به علاقه‌مندی‌ها اضافه شد'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(Food food) async {
    try {
      await _foodService.toggleLike(food.id);
      if (mounted) {
        setState(() {
          // Just update the UI state without re-sorting
          // The list will be re-sorted on next app launch or data refresh
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در لایک: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: backgroundColor,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/favorite-foods');
            },
            backgroundColor: AppTheme.goldColor,
            foregroundColor: Colors.black,
            icon: const Icon(LucideIcons.heart),
            label: const Text(
              'مورد علاقه‌ها',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [backgroundColor, Color(0xFF1A1A1A)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(),

                  // Food List
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingList()
                        : _filteredFoods.isEmpty
                        ? _buildEmptyState()
                        : _buildFoodList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          DecoratedBox(
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.arrowRight, color: goldColor, size: 20.sp),
              onPressed: () => NavigationService.safePop(context),
            ),
          ),
          const SizedBox(width: 16),

          // Title or Search Field
          Expanded(
            child: _isSearching
                ? _buildSearchField()
                : Text(
                    'خوراکی‌ها',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),

          // Search Button
          DecoratedBox(
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? LucideIcons.x : LucideIcons.search,
                color: goldColor,
                size: 20.sp,
              ),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchQuery = '';
                      _filterFoods();
                    }
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'جستجو در خوراکی‌ها...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          prefixIcon: Icon(LucideIcons.search, color: goldColor, size: 20.sp),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (value) {
          if (mounted) {
            setState(() {
              _searchQuery = value;
              _filterFoods();
            });
          }
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AppTheme.cardColor,
            highlightColor: Colors.grey[700]!,
            child: Container(
              height: 110.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Icon(
              LucideIcons.utensils,
              size: 64.sp,
              color: goldColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'هیچ خوراکی‌ای یافت نشد',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سعی کنید فیلترهای جستجو را تغییر دهید',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final int baseCount = _filteredFoods.length;
        final int totalCount = baseCount + (_showInfoHeader ? 1 : 0);
        return ScrollConfiguration(
          behavior: const _NoGlowScrollBehavior(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: totalCount,
            itemBuilder: (context, index) {
              if (_showInfoHeader && index == 0) {
                return _buildInfoHeader();
              }
              final int foodIndex = _showInfoHeader ? index - 1 : index;
              final food = _filteredFoods[foodIndex];
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (foodIndex * 100)),
                curve: Curves.easeOutBack,
                child: _buildFoodCard(food),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h, top: 8),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1A12), Color(0xFF13110B)],
        ),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.goldColor.withValues(alpha: 0.18),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              LucideIcons.info,
              color: AppTheme.goldColor,
              size: 18.sp,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'راهنمای خوراکی‌ها',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const _InfoBullet(
                  text: 'ارقام تغذیه‌ای برای هر ۱۰۰ گرم محاسبه شده‌اند.',
                ),
                const _InfoBullet(
                  text: 'نشان قلب برای علاقه‌مندی و انگشت‌بالا برای لایک است.',
                ),
                const _InfoBullet(
                  text: 'مرتب‌سازی اولیه بر اساس تعداد لایک‌ها است.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showInfoHeader = false),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Icon(LucideIcons.x, size: 16.sp, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Food food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 110.h, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.cardColor, Color(0xFF161616)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FoodDetailScreen(food: food),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: Offset(1.w, 0.h),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeInOut)),
                      ),
                      child: child,
                    );
                  },
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // Food Image with subtle gold border
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.18),
                    width: 1.2.w,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    width: 76.w,
                    height: 76.h,
                    child: food.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: food.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.goldColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: Icon(
                                LucideIcons.utensils,
                                color: AppTheme.goldColor,
                                size: 32.sp,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: Icon(
                              LucideIcons.utensils,
                              color: AppTheme.goldColor,
                              size: 32.sp,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Food Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 2),
                    // Nutrition Info - Column to avoid horizontal overflow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNutritionBadge(
                          icon: LucideIcons.flame,
                          value: food.nutrition.calories,
                          unit: 'کیلوکالری',
                          color: AppTheme.goldColor,
                        ),
                        const SizedBox(height: 4),
                        _buildNutritionBadge(
                          icon: LucideIcons.zap,
                          value: '${food.nutrition.protein}g',
                          unit: 'پروتئین',
                          color: AppTheme.goldColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons - Compact
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: food.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    isActive: food.isFavorite,
                    activeColor: Colors.red,
                    onTap: () => _toggleFavorite(food),
                    tooltip: 'مورد علاقه',
                  ),
                  const SizedBox(height: 6),
                  _buildLikeButton(food),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionBadge({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 13.sp, color: color),
          const SizedBox(width: 4),
          Text(
            _formatBadgeValue(value, unit),
            style: TextStyle(
              color: color,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatBadgeValue(String value, String unit) {
    final double? numVal = double.tryParse(value.trim().replaceAll(',', '.'));
    if (numVal == null) return '$value $unit';
    final String compact = numVal % 1 == 0
        ? numVal.toInt().toString()
        : numVal.toStringAsFixed(numVal < 10 ? 1 : 0);
    return '$compact $unit';
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.h,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: activeColor.withValues(alpha: 0.2),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
          ],
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: isActive ? activeColor : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildLikeButton(Food food) {
    final bool liked = food.isLikedByUser;
    return GestureDetector(
      onTap: () => _toggleLike(food),
      child: Container(
        constraints: const BoxConstraints(minWidth: 36),
        height: 28.h,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: liked
              ? AppTheme.goldColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: liked
                ? AppTheme.goldColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16.sp,
              color: liked ? AppTheme.goldColor : Colors.white70,
            ),
            if (food.likes > 0) ...[
              const SizedBox(width: 6),
              Text(
                food.likes.toString(),
                style: TextStyle(
                  color: liked ? Colors.white : Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6.w,
            height: 6.h,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.goldColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12.5.sp,
                height: 1.4.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
