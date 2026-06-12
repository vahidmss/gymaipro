import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({
    required this.foods,
    required this.initialMealTitle,
    super.key,
  });

  final List<Food> foods;
  final String initialMealTitle;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final FoodService _foodService = FoodService();
  final UserPreferencesService _preferencesService = UserPreferencesService();

  String _selectedMealTitle = '';
  String _searchQuery = '';
  String _filterType = 'همه'; // 'همه' or 'مورد علاقه'
  List<Food> _filteredFoods = [];
  Set<int> _favoriteFoodIds = {};

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.7)
          : AppTheme.lightTextColor.withValues(alpha: 0.5),
      builder: (context) =>
          _AmountInputDialog(food: food, mealTitle: _selectedMealTitle),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final pageHeight = screenHeight * 0.8;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // استفاده از MediaQuery برای اندازه واقعی صفحه
          final screenWidth = mediaQuery.size.width;

          // محاسبه responsive border radius بر اساس اندازه واقعی
          final borderRadius = screenWidth > 600 ? 28.0 : 24.0;

          return Container(
            height: pageHeight,
            decoration: BoxDecoration(
              color: isDark ? context.backgroundColor : context.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader(isDark)),
                // Search
                SliverToBoxAdapter(child: _buildSearchBar(isDark)),
                // Filter tabs
                SliverToBoxAdapter(child: _buildFilterTabs(isDark)),
                // Food list
                _buildFoodListSliver(isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkGreySeparator
                : AppTheme.lightDividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.chevronDown,
              color: isDark ? AppTheme.goldColor : context.textColor,
              size: 20.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'افزودن ${_selectedMealTitle}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontSize: 14.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
            fontSize: 12.sp,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 18.sp,
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
            borderSide: BorderSide(color: AppTheme.goldColor, width: 1.2.w),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        ),
        style: TextStyle(
          color: isDark ? AppTheme.goldColor : context.textColor,
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          _buildFilterTab('همه', isDark),
          SizedBox(width: 8.w),
          _buildFilterTab('مورد علاقه', isDark),
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
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected
                  ? AppTheme.goldColor
                  : (isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor),
              width: isSelected ? 1.2.w : 1.w,
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
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodList(bool isDark) {
    if (_filteredFoods.isEmpty) {
      return Center(
        child: Text(
          'غذایی یافت نشد',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isDark
                ? AppTheme.goldColor.withValues(alpha: 0.7)
                : context.textColor.withValues(alpha: 0.7),
            fontSize: 12.sp,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 12.h),
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

  Widget _buildFoodListSliver(bool isDark) {
    if (_filteredFoods.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'غذایی یافت نشد',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : context.textColor.withValues(alpha: 0.7),
              fontSize: 12.sp,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(10.w, 2.h, 10.w, 12.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final food = _filteredFoods[index];
          return _buildFoodItem(
            food,
            food.isFavorite,
            isDark,
            key: ValueKey('${food.id}_${food.isFavorite}'),
          );
        }, childCount: _filteredFoods.length),
      ),
    );
  }

  Widget _buildFoodItem(Food food, bool isFavorite, bool isDark, {Key? key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : context.cardColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAmountDialog(food),
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: Image.asset(
                    'images/gymaifoodplaceholder.png',
                    width: 40.w,
                    height: 40.h,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkGreySeparator
                            : AppTheme.lightDividerColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        LucideIcons.imageOff,
                        color: isDark
                            ? AppTheme.goldColor.withValues(alpha: 0.5)
                            : context.textColor.withValues(alpha: 0.5),
                        size: 18.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        food.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${food.nutrition.calories} کالری',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.7)
                              : context.textColor.withValues(alpha: 0.7),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                IconButton(
                  icon: Icon(
                    isFavorite ? LucideIcons.heart : LucideIcons.heartOff,
                    color: isFavorite
                        ? Colors.red
                        : (isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.5)
                              : context.textColor.withValues(alpha: 0.5)),
                    size: 18.sp,
                  ),
                  onPressed: () => _toggleFavorite(food),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                ),
              ],
            ),
          ),
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
  String _selectedUnit = 'گرم';
  String _amountStr = '';
  final FocusNode _focusNode = FocusNode();

  double? get _parsed {
    final v = _amountStr.trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountStr.isNotEmpty)
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        return;
      }
      if (key == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
        return;
      }
      if (_amountStr == '0' && key != '.')
        _amountStr = key;
      else
        _amountStr += key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.70;

    final nutrition = widget.food.nutrition;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: dialogHeight,
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          fontSize: 12.sp,
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
                        size: 16.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: 28.w,
                        minHeight: 28.h,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.asset(
                      'images/gymaifoodplaceholder.png',
                      width: 40.w,
                      height: 40.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkGreySeparator
                              : AppTheme.lightDividerColor,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          LucideIcons.imageOff,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.5)
                              : context.textColor.withValues(alpha: 0.5),
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCardColor
                        : context.cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkGreySeparator
                          : AppTheme.lightDividerColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'اطلاعات تغذیه‌ای (۱۰۰ گرم)',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3.h),
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
                          SizedBox(width: 4.w),
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
                      SizedBox(height: 3.h),
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
                          SizedBox(width: 4.w),
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
                SizedBox(height: 6.h),
                Focus(
                  focusNode: _focusNode,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _unitChip(context, isDark, 'گرم'),
                          SizedBox(width: 10.w),
                          _unitChip(context, isDark, 'عدد'),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkCardColor
                              : context.cardColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkGreySeparator
                                : AppTheme.lightDividerColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _amountStr.isEmpty ? '0' : _amountStr,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              _selectedUnit,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color:
                                    (isDark
                                            ? AppTheme.goldColor
                                            : context.textColor)
                                        .withValues(alpha: 0.8),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _buildInlineKeypad(context, isDark),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_parsed != null && _parsed! > 0)
                        ? () {
                            Navigator.of(context).pop({
                              'food': widget.food,
                              'amount': _parsed!,
                              'unit': _selectedUnit,
                              'mealTitle': widget.mealTitle,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      minimumSize: Size(0, 40.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'افزودن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
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

  Widget _unitChip(BuildContext context, bool isDark, String unit) {
    final selected = _selectedUnit == unit;
    return GestureDetector(
      onTap: () => setState(() => _selectedUnit = unit),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.goldColor.withValues(alpha: isDark ? 0.25 : 0.2)
              : (isDark ? AppTheme.darkCardColor : context.cardColor),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected
                ? AppTheme.goldColor
                : (isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor),
          ),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: selected
                ? AppTheme.goldColor
                : context.textColor.withValues(alpha: 0.8),
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static const List<List<String>> _keypadRows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  Widget _buildInlineKeypad(BuildContext context, bool isDark) {
    final textColor = isDark ? AppTheme.goldColor : context.textColor;
    final surface = isDark ? AppTheme.darkCardColor : context.cardColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._keypadRows.map(
          (row) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              children: row.map((key) {
                final isBack = key == '⌫';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: Material(
                      color: surface,
                      borderRadius: BorderRadius.circular(8.r),
                      child: InkWell(
                        onTap: () => _onKey(key),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          height: 40.h,
                          alignment: Alignment.center,
                          child: isBack
                              ? Icon(
                                  Icons.backspace_outlined,
                                  size: 18.sp,
                                  color: textColor.withValues(alpha: 0.8),
                                )
                              : Text(
                                  key,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: textColor,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
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
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.1 : 0.08),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark
                  ? color.withValues(alpha: 0.8)
                  : context.textColor.withValues(alpha: 0.7),
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark ? color : context.textColor,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
