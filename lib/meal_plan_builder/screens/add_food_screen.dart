import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddFoodScreenMealPlanBuilder extends StatefulWidget {
  const AddFoodScreenMealPlanBuilder({
    required this.foods,
    required this.initialMealTitle,
    this.customTitle,
    super.key,
  });

  final List<Food> foods;
  final String initialMealTitle;
  final String? customTitle;

  @override
  State<AddFoodScreenMealPlanBuilder> createState() =>
      _AddFoodScreenMealPlanBuilderState();
}

class _AddFoodScreenMealPlanBuilderState
    extends State<AddFoodScreenMealPlanBuilder> {
  final FoodService _foodService = FoodService();
  final UserPreferencesService _preferencesService = UserPreferencesService();

  String _selectedMealTitle = '';
  String _searchQuery = '';
  String _filterType = 'همه'; // 'همه' | 'مورد علاقه' | 'مکمل‌ها'
  List<Food> _filteredFoods = [];
  Set<int> _favoriteFoodIds = {};

  // Supplement form fields
  final _supplementFormKey = GlobalKey<FormState>();
  String _supplementName = '';
  double? _supplementAmount;
  String? _supplementUnit = 'عدد';
  String _supplementType = 'مکمل';
  double? _supplementProtein;
  double? _supplementCarbs;
  double? _supplementCalories;
  String? _supplementNote;

  @override
  void initState() {
    super.initState();
    _selectedMealTitle = widget.initialMealTitle;
    // Initialize with all foods
    _filteredFoods = widget.foods;
    // Load favorites from database and sync
    _syncFavoritesFromDatabase();
  }

  Future<void> _syncFavoritesFromDatabase() async {
    try {
      final foodIds = widget.foods.map((f) => f.id).toList();
      final preferences = await _preferencesService.getFoodPreferences(foodIds);
      final favoriteIds = Set<int>.from(preferences['favorites'] as List);

      setState(() {
        // Update isFavorite for all foods
        for (final food in widget.foods) {
          food.isFavorite = favoriteIds.contains(food.id);
        }
        // Update favorite IDs set
        _favoriteFoodIds = favoriteIds;
        // Update filtered foods (they reference the same objects)
        _filteredFoods = widget.foods;
      });
      _filterFoods();
    } catch (e) {
      // Error handled silently
      // Fallback to existing isFavorite values
      setState(() {
        _favoriteFoodIds = widget.foods
            .where((f) => f.isFavorite)
            .map((f) => f.id)
            .toSet();
      });
      _filterFoods();
    }
  }

  void _filterFoods() {
    setState(() {
      var filtered = widget.foods;

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered
            .where(
              (f) => f.title.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }

      // Apply favorite filter
      if (_filterType == 'مورد علاقه') {
        filtered = filtered
            .where((f) => _favoriteFoodIds.contains(f.id))
            .toList();
      }

      _filteredFoods = filtered;
    });
  }

  Future<void> _toggleFavorite(Food food) async {
    try {
      await _foodService.toggleFavorite(food.id);
      setState(() {
        // Update food.isFavorite in the main list
        final foodIndex = widget.foods.indexWhere((f) => f.id == food.id);
        if (foodIndex != -1) {
          widget.foods[foodIndex].isFavorite =
              !widget.foods[foodIndex].isFavorite;
        }
        // Update food.isFavorite in the filtered list (same reference)
        final filteredIndex = _filteredFoods.indexWhere((f) => f.id == food.id);
        if (filteredIndex != -1) {
          _filteredFoods[filteredIndex].isFavorite =
              !_filteredFoods[filteredIndex].isFavorite;
        }
        // Update favorite IDs set
        if (_favoriteFoodIds.contains(food.id)) {
          _favoriteFoodIds.remove(food.id);
        } else {
          _favoriteFoodIds.add(food.id);
        }
      });
      // Only re-filter if we're in favorite filter mode
      if (_filterType == 'مورد علاقه') {
        _filterFoods();
      }
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> _showAmountDialog(Food food) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AmountInputDialog(food: food, mealTitle: _selectedMealTitle),
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final pageHeight = screenHeight * 0.8;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Container(
          height: pageHeight,
          decoration: BoxDecoration(
            color: isDark ? context.backgroundColor : context.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),
              // Search
              _buildSearchBar(isDark),
              // Filter tabs
              _buildFilterTabs(isDark),
              // Food list
              Expanded(child: _buildFoodList(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkGreySeparator
                : AppTheme.lightDividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            icon: Icon(
              LucideIcons.chevronDown,
              color: isDark ? AppTheme.goldColor : context.textColor,
              size: 24.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 12.w),
          // Title
          Expanded(
            child: Text(
              widget.customTitle ?? 'افزودن $_selectedMealTitle',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterFoods();
        },
        decoration: InputDecoration(
          hintText: 'جستجو...',
          hintStyle: TextStyle(
            color: isDark
                ? AppTheme.goldColor.withValues(alpha: 0.5)
                : context.textColor.withValues(alpha: 0.5),
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 20.sp,
          ),
          filled: true,
          fillColor: isDark
              ? AppTheme.darkCardColor
              : context.cardColor.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: isDark
                  ? AppTheme.darkGreySeparator
                  : AppTheme.lightDividerColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: isDark
                  ? AppTheme.darkGreySeparator
                  : AppTheme.lightDividerColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppTheme.goldColor, width: 1.5.w),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
        ),
        style: TextStyle(
          color: isDark ? AppTheme.goldColor : context.textColor,
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildFilterTab('همه', isDark),
          SizedBox(width: 12.w),
          _buildFilterTab('مورد علاقه', isDark),
          SizedBox(width: 12.w),
          _buildFilterTab('مکمل‌ها', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isDark) {
    final isSelected = _filterType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = label;
          });
          _filterFoods();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.goldColor
                  : (isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor),
              width: isSelected ? 1.5.w : 1.w,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isSelected
                  ? AppTheme.goldColor
                  : (isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.7)
                        : context.textColor.withValues(alpha: 0.7)),
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodList(bool isDark) {
    // تب مکمل‌ها: نمایش فرم ثبت مکمل
    if (_filterType == 'مکمل‌ها') {
      return _buildSupplementForm(isDark);
    }

    if (_filteredFoods.isEmpty) {
      return Center(
        child: Text(
          'غذایی یافت نشد',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark
                ? AppTheme.goldColor.withValues(alpha: 0.7)
                : context.textColor.withValues(alpha: 0.7),
            fontSize: 14.sp,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredFoods.length,
      itemBuilder: (context, index) {
        final food = _filteredFoods[index];
        return _buildFoodItem(
          food,
          food.isFavorite,
          isDark,
          key: ValueKey('${food.id}_${food.isFavorite}'),
        );
      },
    );
  }

  Widget _buildFoodItem(Food food, bool isFavorite, bool isDark, {Key? key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAmountDialog(food),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Food image
                if (food.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      food.imageUrl,
                      width: 50.w,
                      height: 50.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          LucideIcons.imageOff,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.5)
                              : context.textColor.withValues(alpha: 0.5),
                          size: 24.sp,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkGreySeparator
                          : AppTheme.lightDividerColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      LucideIcons.imageOff,
                      color: isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.5)
                          : context.textColor.withValues(alpha: 0.5),
                      size: 24.sp,
                    ),
                  ),
                SizedBox(width: 12.w),
                // Food title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${food.nutrition.calories} کالری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.7)
                              : context.textColor.withValues(alpha: 0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Favorite button
                IconButton(
                  icon: Icon(
                    isFavorite ? LucideIcons.heart : LucideIcons.heartOff,
                    color: isFavorite
                        ? Colors.red
                        : (isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.5)
                              : context.textColor.withValues(alpha: 0.5)),
                    size: 22.sp,
                  ),
                  onPressed: () => _toggleFavorite(food),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupplementForm(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: 16.h + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _supplementFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع مکمل/دارو
            DropdownButtonFormField<String>(
              initialValue: _supplementType,
              decoration: InputDecoration(
                labelText: 'نوع',
                labelStyle: TextStyle(
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.7)
                      : context.textColor.withValues(alpha: 0.7),
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkCardColor
                    : context.cardColor.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor,
                    width: 1.5.w,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'مکمل', child: Text('مکمل')),
                DropdownMenuItem(value: 'دارو', child: Text('دارو')),
              ],
              onChanged: (v) => setState(() => _supplementType = v ?? 'مکمل'),
              dropdownColor: isDark
                  ? AppTheme.darkCardColor
                  : context.cardColor,
              style: TextStyle(
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            // نام مکمل/دارو
            TextFormField(
              decoration: InputDecoration(
                labelText: 'نام',
                labelStyle: TextStyle(
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.7)
                      : context.textColor.withValues(alpha: 0.7),
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkCardColor
                    : context.cardColor.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor,
                    width: 1.5.w,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
              style: TextStyle(
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'نام را وارد کنید' : null,
              onChanged: (v) => setState(() => _supplementName = v),
            ),
            SizedBox(height: 16.h),
            // مقدار و واحد
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'مقدار',
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.7)
                            : context.textColor.withValues(alpha: 0.7),
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCardColor
                          : context.cardColor.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppTheme.goldColor,
                          width: 1.5.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'مقدار را وارد کنید'
                        : null,
                    onChanged: (v) => setState(
                      () => _supplementAmount = double.tryParse(
                        v.replaceAll(',', '.'),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _supplementUnit,
                    decoration: InputDecoration(
                      labelText: 'واحد',
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.7)
                            : context.textColor.withValues(alpha: 0.7),
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCardColor
                          : context.cardColor.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppTheme.goldColor,
                          width: 1.5.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 10.h,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'عدد', child: Text('عدد')),
                      DropdownMenuItem(value: 'گرم', child: Text('گرم')),
                      DropdownMenuItem(
                        value: 'میلی‌لیتر',
                        child: Text('میلی‌لیتر'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _supplementUnit = v),
                    dropdownColor: isDark
                        ? AppTheme.darkCardColor
                        : context.cardColor,
                    style: TextStyle(
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // پروتئین و کربوهیدرات (اختیاری)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'پروتئین (اختیاری)',
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.7)
                            : context.textColor.withValues(alpha: 0.7),
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCardColor
                          : context.cardColor.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppTheme.goldColor,
                          width: 1.5.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                    ),
                    onChanged: (v) => setState(
                      () => _supplementProtein = double.tryParse(
                        v.replaceAll(',', '.'),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'کربوهیدرات (اختیاری)',
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.7)
                            : context.textColor.withValues(alpha: 0.7),
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkCardColor
                          : context.cardColor.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppTheme.goldColor,
                          width: 1.5.w,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? AppTheme.goldColor : context.textColor,
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.sp,
                    ),
                    onChanged: (v) => setState(
                      () => _supplementCarbs = double.tryParse(
                        v.replaceAll(',', '.'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // کالری (اختیاری)
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'کالری (اختیاری)',
                labelStyle: TextStyle(
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.7)
                      : context.textColor.withValues(alpha: 0.7),
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkCardColor
                    : context.cardColor.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor,
                    width: 1.5.w,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
              style: TextStyle(
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
              ),
              onChanged: (v) => setState(
                () => _supplementCalories = double.tryParse(
                  v.replaceAll(',', '.'),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // یادداشت (اختیاری)
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'یادداشت (اختیاری)',
                labelStyle: TextStyle(
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.7)
                      : context.textColor.withValues(alpha: 0.7),
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkCardColor
                    : context.cardColor.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.goldColor,
                    width: 1.5.w,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
              style: TextStyle(
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
              ),
              onChanged: (v) =>
                  setState(() => _supplementNote = v.isEmpty ? null : v),
            ),
            SizedBox(height: 24.h),
            // دکمه افزودن
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_supplementFormKey.currentState?.validate() ?? false) {
                    final supplement = SupplementEntry(
                      name: _supplementName,
                      amount: _supplementAmount,
                      unit: _supplementUnit,
                      note: _supplementNote,
                      supplementType: _supplementType,
                      protein: _supplementProtein,
                      carbs: _supplementCarbs,
                      calories: _supplementCalories,
                    );
                    Navigator.of(context).pop({'supplement': supplement});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'افزودن',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _AmountInputDialog extends StatefulWidget {
  const _AmountInputDialog({required this.food, required this.mealTitle});

  final Food food;
  final String mealTitle;

  @override
  State<_AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<_AmountInputDialog> {
  String? _selectedUnit = 'گرم';
  double? _amount;
  final TextEditingController _amountController = TextEditingController();

  double _parse(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.5;

    final nutrition = widget.food.nutrition;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: dialogHeight,
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.food.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        size: 20.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                // Food image
                if (widget.food.imageUrl.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        widget.food.imageUrl,
                        width: 80.w,
                        height: 80.h,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80.w,
                          height: 80.h,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkGreySeparator
                                : AppTheme.lightDividerColor,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            LucideIcons.imageOff,
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.5)
                                : context.textColor.withValues(alpha: 0.5),
                            size: 30.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.food.imageUrl.isNotEmpty) SizedBox(height: 8.h),
                // Nutrition info (per 100g)
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCardColor
                        : context.cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkGreySeparator
                          : AppTheme.lightDividerColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اطلاعات تغذیه‌ای (۱۰۰ گرم)',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionItem(
                              context,
                              'کالری',
                              nutrition.calories,
                              AppTheme.goldColor,
                              isDark,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: _buildNutritionItem(
                              context,
                              'پروتئین',
                              '${nutrition.protein} گرم',
                              AppTheme.proteinColor,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNutritionItem(
                              context,
                              'کربو',
                              '${nutrition.carbohydrates} گرم',
                              AppTheme.carbsColor,
                              isDark,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: _buildNutritionItem(
                              context,
                              'چربی',
                              '${nutrition.fat} گرم',
                              AppTheme.fatColor,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                // Unit and amount inputs
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'واحد',
                          labelStyle: TextStyle(
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.7)
                                : context.textColor.withValues(alpha: 0.7),
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkCardColor
                              : context.cardColor.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkGreySeparator
                                  : AppTheme.lightDividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkGreySeparator
                                  : AppTheme.lightDividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(
                              color: AppTheme.goldColor,
                              width: 1.5.w,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'گرم', child: Text('گرم')),
                          DropdownMenuItem(value: 'عدد', child: Text('عدد')),
                        ],
                        onChanged: (v) => setState(() => _selectedUnit = v),
                        dropdownColor: isDark
                            ? AppTheme.darkCardColor
                            : context.cardColor,
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'مقدار',
                          labelStyle: TextStyle(
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.7)
                                : context.textColor.withValues(alpha: 0.7),
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.scale,
                            color: AppTheme.goldColor,
                            size: 16.sp,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkCardColor
                              : context.cardColor.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkGreySeparator
                                  : AppTheme.lightDividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppTheme.darkGreySeparator
                                  : AppTheme.lightDividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(
                              color: AppTheme.goldColor,
                              width: 1.5.w,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                        ),
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.sp,
                        ),
                        onChanged: (v) {
                          setState(() {
                            _amount = _parse(v);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedUnit != null && (_amount ?? 0) > 0)
                        ? () {
                            Navigator.of(context).pop({
                              'food': widget.food,
                              'amount': _amount!,
                              'unit': _selectedUnit!,
                              'mealTitle': widget.mealTitle,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'افزودن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark
                  ? color.withValues(alpha: 0.8)
                  : context.textColor.withValues(alpha: 0.7),
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark ? color : context.textColor,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
