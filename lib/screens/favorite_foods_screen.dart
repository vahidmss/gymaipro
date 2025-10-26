import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/screens/food_detail_screen.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

class FavoriteFoodsScreen extends StatefulWidget {
  const FavoriteFoodsScreen({super.key});

  @override
  State<FavoriteFoodsScreen> createState() => _FavoriteFoodsScreenState();
}

class _FavoriteFoodsScreenState extends State<FavoriteFoodsScreen> {
  final UserPreferencesService _preferencesService = UserPreferencesService();
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _favoriteFoods = [];
  List<Map<String, dynamic>> _filteredFoods = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavoriteFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteFoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _preferencesService.getFavoriteFoods();
      setState(() {
        _favoriteFoods = favorites;
        _filteredFoods = favorites;
        _isLoading = false;
      });
      _filterFoods();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری غذاهای مورد علاقه: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterFoods() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredFoods = _favoriteFoods;
      } else {
        _filteredFoods = _favoriteFoods
            .where(
              (food) => (food['food_title'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterFoods();
  }

  Future<void> _removeFromFavorites(int foodId) async {
    try {
      await _preferencesService.removeFoodFromFavorites(foodId);
      setState(() {
        _favoriteFoods.removeWhere((food) => food['food_id'] == foodId);
      });
      _filterFoods(); // Re-filter after removal

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('غذا از لیست مورد علاقه‌ها حذف شد'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف غذا: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
          onPressed: () => NavigationService.safePop(context),
        ),
        title: const Text(
          'غذاهای مورد علاقه',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_favoriteFoods.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.search, color: Colors.white),
              onPressed: () {
                // Toggle search bar visibility by focusing/unfocusing
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (_favoriteFoods.isNotEmpty) _buildSearchBar(),
          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _favoriteFoods.isEmpty
                ? _buildEmptyState()
                : _filteredFoods.isEmpty
                ? _buildNoResultsState()
                : _buildFoodsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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
              height: 112.h,
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
          Icon(LucideIcons.heart, size: 80.sp, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'هیچ غذایی در لیست مورد علاقه‌ها ندارید',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'برای اضافه کردن غذا به لیست مورد علاقه‌ها،\nروی آیکون قلب کلیک کنید',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => NavigationService.safePop(context),
            icon: const Icon(LucideIcons.search),
            label: const Text('جستجو در غذاها'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.white),
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'جستجو در غذاهای مورد علاقه...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 20.sp,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 60.sp, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'نتیجه‌ای یافت نشد',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'برای کلمه کلیدی "$_searchQuery" غذایی یافت نشد',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodsList() {
    return ScrollConfiguration(
      behavior: const _NoGlowScrollBehavior(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredFoods.length,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemBuilder: (context, index) {
          final food = _filteredFoods[index];
          return _buildFoodCard(food);
        },
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    final foodId = food['food_id'] as int;
    final title = food['food_title'] as String;
    final imageUrl = food['food_image_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          // Try to get full food details from cache
          try {
            final foods = await _foodService.getFoods();
            final fullFood = foods.firstWhere((f) => f.id == foodId);
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailScreen(food: fullFood),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('خطا در بارگذاری جزئیات غذا'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // Food Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: SizedBox(
                  width: 80.w,
                  height: 80.h,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
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
              const SizedBox(width: 16),
              // Food Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          LucideIcons.heart,
                          size: 16.sp,
                          color: AppTheme.goldColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'مورد علاقه',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                onPressed: () => _showRemoveConfirmation(foodId, title),
                icon: Icon(
                  LucideIcons.heartOff,
                  color: Colors.red[300],
                  size: 20.sp,
                ),
                tooltip: 'حذف از مورد علاقه‌ها',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRemoveConfirmation(int foodId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text(
          'حذف از مورد علاقه‌ها',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'آیا از حذف "$title" از لیست مورد علاقه‌هایتان اطمینان دارید؟',
          style: TextStyle(color: Colors.grey[300]),
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('لغو', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[300]),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _removeFromFavorites(foodId);
    }
  }
}

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
