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

  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  List<String> _foodCategories = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearching = false;

  // Gold theme colors
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFFFD700); // Gold accent

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری خوراکی‌ها: $e'),
            backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('خوراکی به لیست علاقه‌مندی‌ها اضافه شد'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خوراکی از لیست علاقه‌مندی‌ها حذف شد'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleLike(Food food) async {
    try {
      final wasLiked = food.isLikedByUser;
      await _foodService.toggleLike(food.id);
      setState(() {
        // food.isLikedByUser and food.likes are already updated in the service
        if (!wasLiked && food.isLikedByUser) {
          // Successfully liked
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خوراکی را پسندیدید'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // Hide keyboard on tap outside
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: _isSearching
                ? _buildSearchField()
                : const Text(
                    'خوراکی‌ها',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? LucideIcons.x : LucideIcons.search,
                  color: goldColor,
                  size: 22,
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
            ],
            leading: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: goldColor,
                size: 22,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
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
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'جستجو در خوراکی‌ها...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        border: InputBorder.none,
        prefixIcon: const Icon(LucideIcons.search, color: goldColor),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _filterFoods();
        });
      },
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _foodCategories.length + 1, // +1 for "همه" option
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
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? goldColor : cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? goldColor
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  index == 0 ? 'همه' : category,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
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
              borderRadius: BorderRadius.circular(16),
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
          Icon(
            LucideIcons.utensils,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'هیچ خوراکی‌ای یافت نشد',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredFoods.length,
      itemBuilder: (context, index) {
        final food = _filteredFoods[index];
        return _buildFoodCard(food);
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
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: food.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: food.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: cardColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: goldColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: cardColor,
                                child: const Icon(
                                  LucideIcons.utensils,
                                  color: goldColor,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: cardColor,
                              child: const Icon(
                                LucideIcons.utensils,
                                color: goldColor,
                                size: 32,
                              ),
                            ),
                    ),
                    // Favorite Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(food),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            food.isFavorite
                                ? LucideIcons.heart
                                : LucideIcons.heart,
                            color: food.isFavorite ? Colors.red : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // Like Button
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: () => _toggleLike(food),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                food.isLikedByUser
                                    ? LucideIcons.thumbsUp
                                    : LucideIcons.thumbsUp,
                                color: food.isLikedByUser
                                    ? goldColor
                                    : Colors.white,
                                size: 14,
                              ),
                              if (food.likes > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  food.likes.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  children: [
                    // Food Title
                    Flexible(
                      child: Text(
                        food.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Nutrition Info
                    Row(
                      children: [
                        Flexible(
                          child: _buildNutritionChip(
                            '${food.nutrition.calories} کالری',
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: _buildNutritionChip(
                            '${food.nutrition.protein}g پروتئین',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Categories
                    if (food.classList.isNotEmpty)
                      Flexible(
                        child: Text(
                          food.classList.first,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildNutritionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
