import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/food_meta.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/screens/food_detail_screen.dart';
import 'package:gymaipro/screens/widgets/food_list_card.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

enum _FoodSort { popular, alphabetical }

enum _FoodFilter { all, favorites }

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

class _FoodListScreenState extends State<FoodListScreen> {
  final FoodService _foodService = FoodService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Food> _foods = [];
  List<Food> _filteredFoods = [];
  String _searchQuery = '';
  bool _isLoading = true;
  _FoodSort _sort = _FoodSort.popular;
  _FoodFilter _filter = _FoodFilter.all;
  String? _selectedGroup;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _loadData();
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch({bool unfocus = true}) {
    _searchDebounce?.cancel();
    if (_searchController.text.isEmpty && _searchQuery.isEmpty) {
      if (unfocus && _searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
      return;
    }
    _searchController.clear();
    setState(() => _searchQuery = '');
    _applyFilters();
    if (unfocus) {
      _searchFocusNode.unfocus();
    }
  }

  bool get _isSearchActive =>
      _searchQuery.isNotEmpty || _searchFocusNode.hasFocus;

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;

    if (!forceRefresh) {
      try {
        final cached = await _foodService.getFoodsFromCache();
        if (cached != null && cached.isNotEmpty && mounted) {
          _setFoods(cached, loading: false);
          unawaited(_refreshInBackground());
          return;
        }
      } catch (e) {
        debugPrint('Food list cache read error: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final foods = await _foodService.getFoods(forceRefresh: forceRefresh);
      if (!mounted) return;
      _setFoods(foods, loading: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در بارگذاری خوراکی‌ها: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final foods = await _foodService.getFoods(forceRefresh: true);
      if (!mounted || foods.isEmpty) return;

      final changed = foods.length != _foods.length ||
          foods.any((f) => !_foods.any((e) => e.id == f.id));
      if (changed || _needsUserPrefsRefresh(foods)) {
        _setFoods(foods, loading: false);
      }
    } catch (e) {
      debugPrint('Food list background refresh: $e');
    }
  }

  bool _needsUserPrefsRefresh(List<Food> fresh) {
    if (_foods.length != fresh.length) return true;
    for (var i = 0; i < fresh.length; i++) {
      final old = _foods.firstWhere(
        (f) => f.id == fresh[i].id,
        orElse: () => fresh[i],
      );
      if (old.isFavorite != fresh[i].isFavorite ||
          old.isLikedByUser != fresh[i].isLikedByUser ||
          old.likes != fresh[i].likes) {
        return true;
      }
    }
    return false;
  }

  void _setFoods(List<Food> foods, {required bool loading}) {
    setState(() {
      _foods = foods;
      _isLoading = loading;
    });
    _applyFilters();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
      _applyFilters();
    });
  }

  void _applyFilters() {
    var result = List<Food>.from(_foods);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (f) =>
                f.title.toLowerCase().contains(q) ||
                f.content.toLowerCase().contains(q) ||
                f.meta.matchesSearch(q),
          )
          .toList();
    }

    if (_selectedGroup != null && _selectedGroup!.isNotEmpty) {
      result =
          result.where((f) => f.meta.foodGroup == _selectedGroup).toList();
    }

    if (_filter == _FoodFilter.favorites) {
      result = result.where((f) => f.isFavorite).toList();
    }

    switch (_sort) {
      case _FoodSort.popular:
        result.sort((a, b) {
          final d = b.likes.compareTo(a.likes);
          if (d != 0) return d;
          return a.title.compareTo(b.title);
        });
      case _FoodSort.alphabetical:
        result.sort(
          (a, b) => a.displayTitle
              .toLowerCase()
              .compareTo(b.displayTitle.toLowerCase()),
        );
    }

    if (mounted) {
      setState(() => _filteredFoods = result);
    }
  }

  void _setSort(_FoodSort sort) {
    if (_sort == sort) return;
    setState(() => _sort = sort);
    _applyFilters();
  }

  void _setGroup(String? group) {
    if (_selectedGroup == group) return;
    setState(() => _selectedGroup = group);
    _applyFilters();
  }

  List<String> get _availableGroups {
    final groups = _foods
        .map((f) => f.meta.foodGroup)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    groups.sort();
    return groups;
  }

  void _setFilter(_FoodFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _applyFilters();
  }

  Future<void> _toggleFavorite(Food food) async {
    try {
      await _foodService.toggleFavorite(food.id);
      if (!mounted) return;
      if (food.isFavorite) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'به علاقه‌مندی‌ها اضافه شد',
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 1),
        );
      }
      if (_filter == _FoodFilter.favorites) {
        setState(() {});
        _applyFilters();
      }
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _toggleLike(Food food) async {
    try {
      await _foodService.toggleLike(food.id);
    } catch (e) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در لایک: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  void _openDetail(Food food) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FoodDetailScreen(food: food),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مرتب‌سازی',
                style: context.headerTitleStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Icon(
                  Icons.check,
                  color: _sort == _FoodSort.popular
                      ? AppTheme.goldColor
                      : Colors.transparent,
                ),
                title: Text(
                  'محبوب‌ترین',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _setSort(_FoodSort.popular);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.check,
                  color: _sort == _FoodSort.alphabetical
                      ? AppTheme.goldColor
                      : Colors.transparent,
                ),
                title: Text(
                  'الفبایی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _setSort(_FoodSort.alphabetical);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isSearchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return;
        }
        if (_searchQuery.isNotEmpty) {
          _clearSearch();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: DecoratedBox(
          decoration: context.pageDecoration,
          child: Scaffold(
            backgroundColor: context.backgroundColor,
            // ui-health: keyboard-inset-ok — search bar only; list stays full height
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: context.backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  LucideIcons.arrowRight,
                  color: AppTheme.goldColor,
                  size: 22.sp,
                ),
                onPressed: () => NavigationService.safePop(context),
              ),
              title: Text(
                'بانک خوراکی',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'مرتب‌سازی',
                  icon: Icon(
                    LucideIcons.arrowUpDown,
                    color: AppTheme.goldColor,
                    size: 22.sp,
                  ),
                  onPressed: _showSortSheet,
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSearchBar(isDark),
                _buildFilterRow(),
                if (_availableGroups.isNotEmpty) _buildGroupFilterRow(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingList(isDark)
                      : _filteredFoods.isEmpty
                      ? _buildEmptyState()
                      : _buildFoodList(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        textDirection: TextDirection.rtl,
        enableSuggestions: false,
        autocorrect: false,
        style: TextStyle(
          color: isDark ? AppTheme.goldColor : context.textColor,
          fontSize: 14.sp,
          fontFamily: AppTheme.fontFamily,
        ),
        decoration: InputDecoration(
          hintText: 'جستجوی نام خوراکی یا گروه…',
          hintStyle: TextStyle(
            color: context.textSecondary,
            fontSize: 13.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor,
            size: 20.sp,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'پاک کردن جستجو',
                onPressed: _clearSearch,
                icon: Icon(
                  LucideIcons.x,
                  color: context.textSecondary,
                  size: 18.sp,
                ),
              );
            },
          ),
          filled: true,
          fillColor: context.cardColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.25),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.25),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _FilterChip(
            label: 'همه',
            selected: _filter == _FoodFilter.all,
            onTap: () => _setFilter(_FoodFilter.all),
          ),
          SizedBox(width: 8.w),
          _FilterChip(
            label: 'علاقه‌مندی',
            icon: LucideIcons.heart,
            selected: _filter == _FoodFilter.favorites,
            onTap: () => _setFilter(_FoodFilter.favorites),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilterRow() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
      child: SizedBox(
        height: 36.h,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: 1 + _availableGroups.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _GroupFilterChip(
                  label: 'همه گروه‌ها',
                  selected: _selectedGroup == null,
                  onTap: () => _setGroup(null),
                );
              }
              final group = _availableGroups[index - 1];
              return _GroupFilterChip(
                label: group,
                selected: _selectedGroup == group,
                color: FoodDisplayLabels.groupColor(group),
                icon: FoodDisplayLabels.groupIcon(group),
                onTap: () => _setGroup(group),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingList(bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      itemCount: 8,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: context.cardColor,
        highlightColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        child: Container(
          height: 108.h,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFavorites = _filter == _FoodFilter.favorites;
    final hasSearch = _searchQuery.isNotEmpty;
    final hasGroup =
        _selectedGroup != null && _selectedGroup!.isNotEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFavorites
                  ? LucideIcons.heartOff
                  : hasSearch || hasGroup
                  ? LucideIcons.searchX
                  : LucideIcons.utensils,
              size: 56.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.45),
            ),
            SizedBox(height: 16.h),
            Text(
              isFavorites
                  ? 'خوراکی علاقه‌مندی ندارید'
                  : hasSearch || hasGroup
                  ? 'نتیجه‌ای یافت نشد'
                  : 'خوراکی‌ای موجود نیست',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              isFavorites
                  ? 'روی قلب کنار خوراکی بزنید'
                  : hasGroup
                  ? 'فیلتر گروه «$_selectedGroup» را بردارید یا جستجو را تغییر دهید'
                  : 'عبارت جستجو را تغییر دهید',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 13.sp,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFavorites || hasSearch || hasGroup) ...[
              SizedBox(height: 20.h),
              TextButton(
                onPressed: () {
                  _clearSearch();
                  setState(() {
                    _filter = _FoodFilter.all;
                    _selectedGroup = null;
                  });
                  _applyFilters();
                },
                child: Text(
                  'نمایش همه',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodList(bool isDark) {
    return RefreshIndicator(
      color: AppTheme.goldColor,
      backgroundColor: context.cardColor,
      onRefresh: () => _loadData(forceRefresh: true),
      child: ScrollConfiguration(
        behavior: const _NoGlowScrollBehavior(),
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          cacheExtent: 320,
          addAutomaticKeepAlives: false,
          itemCount: _filteredFoods.length,
          separatorBuilder: (_, __) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final food = _filteredFoods[index];
            return FoodListCard(
              key: ValueKey<int>(food.id),
              food: food,
              onTap: () => _openDetail(food),
              onFavoriteToggle: () => _toggleFavorite(food),
              onLikeToggle: () => _toggleLike(food),
            );
          },
        ),
      ),
    );
  }
}

class _GroupFilterChip extends StatelessWidget {
  const _GroupFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? AppTheme.goldColor;

    return Material(
      color: selected
          ? accent.withValues(alpha: isDark ? 0.14 : 0.12)
          : context.cardColor,
      elevation: selected ? 0 : 0,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.5)
                  : AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.2),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13.sp,
                  color: selected ? accent : context.textSecondary,
                ),
                SizedBox(width: 5.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: selected ? accent : context.textColor,
                  fontSize: 11.5.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? AppTheme.goldColor.withValues(alpha: isDark ? 0.14 : 0.12)
          : context.cardColor,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? AppTheme.goldColor.withValues(alpha: 0.5)
                  : AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.2),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14.sp,
                  color: selected
                      ? AppTheme.goldColor
                      : context.textSecondary,
                ),
                SizedBox(width: 5.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: selected ? AppTheme.goldColor : context.textColor,
                  fontSize: 12.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
