import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/food.dart';
import '../services/food_service.dart';
import '../theme/app_theme.dart';
import 'food_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({Key? key}) : super(key: key);

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen>
    with TickerProviderStateMixin {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late AnimationController _animationController;

  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  List<String> _foodCategories = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearching = false;

  // Enhanced Gold theme colors
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color backgroundColor = Color(0xFF0F0F0F);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFFFD700);
  static const Color gradientStart = Color(0xFF1A1A1A);
  static const Color gradientEnd = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _foodService.init();
      final foods = await _foodService.getFoods();
      final categories = await _foodService.getFoodCategories();

      setState(() {
        _foods = foods;
        _filteredFoods = foods;
        _foodCategories = categories;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری خوراکی‌ها: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _filterFoods() {
    final filteredByCategory = _selectedCategory.isEmpty
        ? _foods
        : _foods.where((food) {
            return food.classList
                .any((category) => category.contains(_selectedCategory));
          }).toList();

    final filtered = _searchQuery.isEmpty
        ? filteredByCategory
        : filteredByCategory.where((food) {
            final query = _searchQuery.toLowerCase();
            return food.title.toLowerCase().contains(query) ||
                food.content.toLowerCase().contains(query) ||
                food.classList
                    .any((category) => category.toLowerCase().contains(query));
          }).toList();

    setState(() {
      _filteredFoods = filtered;
    });
  }

  void _toggleFavorite(Food food) async {
    try {
      await _foodService.toggleFavorite(food.id);
      setState(() {
        // food.isFavorite is already updated in the service
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
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _toggleLike(Food food) async {
    try {
      final wasLiked = food.isLikedByUser;
      await _foodService.toggleLike(food.id);
      setState(() {
        if (!wasLiked && food.isLikedByUser) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.thumb_up, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('پسندیدید'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          body: Container(
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

                  // Category Filter Tabs
                  if (!_isSearching) _buildCategoryTabs(),

                  // Food List
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingGrid()
                        : _filteredFoods.isEmpty
                            ? _buildEmptyState()
                            : _buildFoodGrid(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.8),
            cardColor.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: goldColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),

          // Title or Search Field
          Expanded(
            child: _isSearching
                ? _buildSearchField()
                : const Text(
                    'خوراکی‌ها',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),

          // Search Button
          Container(
            decoration: BoxDecoration(
              color: goldColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isSearching ? LucideIcons.x : LucideIcons.search,
                color: goldColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                    _filterFoods();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'جستجو در خوراکی‌ها...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          prefixIcon:
              const Icon(LucideIcons.search, color: goldColor, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterFoods();
          });
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _foodCategories.length + 1,
        itemBuilder: (context, index) {
          final category = index == 0 ? '' : _foodCategories[index - 1];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _filterFoods();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [goldColor, darkGold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          cardColor.withValues(alpha: 0.8),
                          cardColor.withValues(alpha: 0.6),
                        ],
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? goldColor
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: goldColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  index == 0 ? 'همه' : category,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: cardColor,
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              LucideIcons.utensils,
              size: 64,
              color: goldColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'هیچ خوراکی‌ای یافت نشد',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سعی کنید فیلترهای جستجو را تغییر دهید',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodGrid() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.95, // افزایش ارتفاع کارت برای نمایش بهتر اسم
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _filteredFoods.length,
          itemBuilder: (context, index) {
            final food = _filteredFoods[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutBack,
              child: _buildFoodCard(food),
            );
          },
        );
      },
    );
  }

  Widget _buildFoodCard(Food food) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FoodDetailScreen(food: food),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withValues(alpha: 0.9),
              cardColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: goldColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            Expanded(
              flex: 2, // کاهش فضای عکس برای اسم بیشتر
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: food.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: food.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cardColor,
                                      cardColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: goldColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cardColor,
                                      cardColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.utensils,
                                  color: goldColor,
                                  size: 40,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cardColor,
                                    cardColor.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.utensils,
                                color: goldColor,
                                size: 40,
                              ),
                            ),
                    ),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                    // Action Buttons
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildActionButton(
                        icon: food.isFavorite
                            ? LucideIcons.heart
                            : LucideIcons.heart,
                        color: food.isFavorite ? Colors.red : Colors.white,
                        onTap: () => _toggleFavorite(food),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildLikeButton(food),
                    ),
                  ],
                ),
              ),
            ),
            // Food Info
            Expanded(
              flex: 3, // افزایش فضای متن
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Title - بزرگ‌تر و واضح‌تر
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        food.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right, // راست‌چین برای فارسی
                      ),
                    ),
                    // Main Nutrition Info
                    Flexible(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildNutritionChip(
                              food.nutrition.calories,
                              'کالری',
                              Colors.orange,
                              LucideIcons.flame,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: _buildNutritionChip(
                              '${food.nutrition.protein}g',
                              'پروتئین',
                              Colors.green,
                              LucideIcons.zap,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Secondary Nutrition Info
                    Flexible(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildNutritionChip(
                              '${food.nutrition.carbohydrates}g',
                              'کربوهیدرات',
                              Colors.blue,
                              LucideIcons.wheat,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: _buildNutritionChip(
                              '${food.nutrition.fat}g',
                              'چربی',
                              Colors.red,
                              LucideIcons.droplet,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildLikeButton(Food food) {
    return GestureDetector(
      onTap: () => _toggleLike(food),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              food.isLikedByUser ? LucideIcons.thumbsUp : LucideIcons.thumbsUp,
              color: food.isLikedByUser ? goldColor : Colors.white,
              size: 16,
            ),
            if (food.likes > 0) ...[
              const SizedBox(width: 4),
              Text(
                food.likes.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(
      String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 8),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    height: 0.9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 6,
                    height: 0.9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
