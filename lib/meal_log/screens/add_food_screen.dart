import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/meal_log/models/meal_quick_log_entry.dart';
import 'package:gymaipro/meal_log/services/meal_quick_log_service.dart';
import 'package:gymaipro/meal_log/widgets/meal_log_colors.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/food_meta.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/food_amount_utils.dart';
import 'package:gymaipro/widgets/food_serving_amount_sheet.dart';
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
  final MealQuickLogService _quickLogService = MealQuickLogService();

  String _selectedMealTitle = '';
  String _searchQuery = '';
  String _filterType = 'همه'; // 'همه' | 'اخیر' | 'مورد علاقه'
  List<Food> _filteredFoods = [];
  List<MealQuickLogEntry> _recentEntries = [];
  List<MealQuickLogEntry> _filteredRecentEntries = [];
  Set<int> _favoriteFoodIds = {};

  @override
  void initState() {
    super.initState();
    _selectedMealTitle = widget.initialMealTitle;
    // Initialize with all foods
    _filteredFoods = widget.foods;
    // Load favorites from database and sync
    _syncFavoritesFromDatabase();
    unawaited(_loadRecentEntries());
  }

  Future<void> _loadRecentEntries() async {
    final entries = await _quickLogService.getRecentEntries(limit: 12);
    if (!mounted) return;
    setState(() {
      _recentEntries = entries;
      if (_filterType == 'اخیر') {
        _applyRecentFilter();
      }
    });
  }

  Food? _foodForId(int foodId) {
    for (final food in widget.foods) {
      if (food.id == foodId) return food;
    }
    return null;
  }

  void _applyRecentFilter() {
    var entries = _recentEntries;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      entries = entries.where((entry) {
        final food = _foodForId(entry.foodId);
        return food != null &&
            (food.displayTitle.toLowerCase().contains(q) || food.meta.matchesSearch(q));
      }).toList();
    }
    _filteredRecentEntries = entries;
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
      if (_filterType == 'اخیر') {
        _applyRecentFilter();
        return;
      }

      var filtered = widget.foods;

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        filtered = filtered
            .where((f) => f.displayTitle.toLowerCase().contains(q) || f.meta.matchesSearch(q))
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

  String _formatAmount(double amount) {
    return amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(1);
  }

  String _unitDisplayLabel(Food food, String unit) {
    return food.meta.servingUnits.resolve(unit)?.displayLabel ?? unit;
  }

  int _estimatedCalories(Food food, MealQuickLogEntry entry) {
    return FoodAmountUtils.scaledCalories(
      food,
      entry.amount,
      entry.unit,
    ).round();
  }

  Future<void> _showAmountDialog(
    Food food, {
    double? initialAmount,
    String? initialUnit,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.7)
          : AppTheme.lightTextColor.withValues(alpha: 0.5),
      builder: (context) => FoodServingAmountSheet(
        food: food,
        mealTitle: _selectedMealTitle,
        initialAmount: initialAmount,
        initialUnit: initialUnit,
      ),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: MealLogColors.sectionBackground(context),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(child: _buildHeader(context)),
                // Search
                SliverToBoxAdapter(child: _buildSearchBar(context)),
                // Filter tabs
                SliverToBoxAdapter(child: _buildFilterTabs(context)),
                // Food list
                if (_filterType == 'اخیر')
                  _buildRecentListSliver(context)
                else
                  _buildFoodListSliver(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MealLogColors.inputBorder(context)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.chevronDown,
              color: MealLogColors.iconOnSurface(context),
              size: 20.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'افزودن $_selectedMealTitle',
              style: MealLogTypography.sectionTitle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
          hintText: 'جستجو نام، گروه یا وعده...',
          hintStyle: TextStyle(
            color: MealLogColors.hintText(context),
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: MealLogColors.accent(context),
            size: 18.sp,
          ),
          filled: true,
          fillColor: MealLogColors.inputFill(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: MealLogColors.inputBorder(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: MealLogColors.inputBorder(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: MealLogColors.inputBorderFocused(context),
              width: 1.2.w,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        ),
        style: TextStyle(
          color: MealLogColors.primaryText(context),
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          _buildFilterTab(context, 'همه'),
          SizedBox(width: 8.w),
          _buildFilterTab(context, 'اخیر'),
          SizedBox(width: 8.w),
          _buildFilterTab(context, 'مورد علاقه'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(BuildContext context, String label) {
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
                ? MealLogColors.chipFill(context, selected: true)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: MealLogColors.chipBorder(
                context,
                selected: isSelected,
              ),
              width: isSelected ? 1.2.w : 1.w,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: MealLogTypography.chip(
              context,
              selected: isSelected,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentListSliver(BuildContext context) {
    if (_filteredRecentEntries.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            _recentEntries.isEmpty
                ? 'هنوز غذایی ثبت نکردی — بعد از چند ثبت، اینجا سریع اضافه می‌کنی'
                : 'غذای اخیر با این جستجو پیدا نشد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: MealLogColors.mutedText(context),
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
          final entry = _filteredRecentEntries[index];
          final food = _foodForId(entry.foodId);
          if (food == null) return const SizedBox.shrink();
          return _buildRecentItem(context, entry, food);
        }, childCount: _filteredRecentEntries.length),
      ),
    );
  }

  Widget _buildRecentItem(
    BuildContext context,
    MealQuickLogEntry entry,
    Food food,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: MealLogColors.panelBackground(context),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: MealLogColors.chipBorder(context, selected: false)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAmountDialog(
            food,
            initialAmount: entry.amount,
            initialUnit: entry.unit,
          ),
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(
                  LucideIcons.history,
                  color: MealLogColors.accent(context),
                  size: 18.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.displayTitle,
                        style: MealLogTypography.foodName(context).copyWith(
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${_formatAmount(entry.amount)} ${_unitDisplayLabel(food, entry.unit)} · ≈ ${_estimatedCalories(food, entry)} کالری',
                        style: MealLogTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.plus,
                  color: MealLogColors.accent(context),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodListSliver(BuildContext context) {
    if (_filteredFoods.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'غذایی یافت نشد',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: MealLogColors.mutedText(context),
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
            context,
            food,
            food.isFavorite,
            key: ValueKey('${food.id}_${food.isFavorite}'),
          );
        }, childCount: _filteredFoods.length),
      ),
    );
  }

  Widget _buildFoodItem(
    BuildContext context,
    Food food,
    bool isFavorite, {
    Key? key,
  }) {
    final protein = double.tryParse(food.nutrition.protein) ?? 0;
    final group = food.meta.foodGroup.trim();

    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: MealLogColors.panelBackground(context),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: MealLogColors.chipBorder(context, selected: false),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: food.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: food.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _foodThumbPlaceholder(context),
                            errorWidget: (_, __, ___) =>
                                _foodThumbPlaceholder(context),
                          )
                        : _foodThumbPlaceholder(context),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        food.displayTitle,
                        style: MealLogTypography.foodName(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${food.nutrition.calories} کالری · ${food.nutritionBasisLabel}',
                        style: MealLogTypography.caption(context).copyWith(
                          fontSize: 10.sp,
                        ),
                      ),
                      if (group.isNotEmpty || protein >= 8) ...[
                        SizedBox(height: 4.h),
                        Wrap(
                          spacing: 4.w,
                          runSpacing: 3.h,
                          children: [
                            if (group.isNotEmpty)
                              _foodMetaChip(
                                context,
                                group,
                                FoodDisplayLabels.groupColor(group),
                              ),
                            if (protein >= 8)
                              _foodMetaChip(
                                context,
                                'پ ${protein.toStringAsFixed(0)}g',
                                AppTheme.proteinColor,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                IconButton(
                  icon: Icon(
                    isFavorite ? LucideIcons.heart : LucideIcons.heartOff,
                    color: isFavorite
                        ? Colors.red
                        : MealLogColors.hintText(context),
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

  Widget _foodThumbPlaceholder(BuildContext context) {
    return ColoredBox(
      color: MealLogColors.inputBorder(context),
      child: Icon(
        LucideIcons.utensils,
        color: MealLogColors.hintText(context),
        size: 18.sp,
      ),
    );
  }

  Widget _foodMetaChip(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 8.sp,
          fontWeight: FontWeight.w600,
          color: MealLogColors.macroText(context, color),
        ),
      ),
    );
  }
}
