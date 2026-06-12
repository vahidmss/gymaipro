import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({required this.exercises, super.key});

  final List<Exercise> exercises;

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // For superset
  final List<SupersetItem> _selectedExercises = [];
  int? _selectedExerciseId; // For normal exercise

  // Cache for filtered exercises
  List<Exercise>? _cachedFilteredExercises;
  String _lastSearchQuery = '';
  Timer? _searchDebounceTimer;
  int _currentTabIndex = 0;

  // Filter for exercises (all or custom)
  int _filterIndex = 0; // 0 = همه, 1 = اختصاصی

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
    _lastSearchQuery = '';
    // Apply initial filters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters('');
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      if (_currentTabIndex != newIndex) {
        setState(() {
          _currentTabIndex = newIndex;
          if (newIndex == 0) {
            _selectedExerciseId = null;
          } else {
            _selectedExercises.clear();
          }
        });
      }
    }
  }

  void _addExerciseToSuperset(Exercise exercise) {
    if (_tabController.index == 1 && _selectedExercises.length < 2) {
      setState(() {
        _selectedExercises.add(
          SupersetItem(
            exerciseId: exercise.id,
            sets: [ExerciseSet(reps: 10, weight: 0)],
            style: ExerciseStyle.setsReps,
          ),
        );
      });
    }
  }

  void _removeExerciseFromSuperset(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _performSearch(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final lowerQuery = query.toLowerCase();
      if (_cachedFilteredExercises != null && _lastSearchQuery == lowerQuery) {
        return;
      }

      _applyFilters(lowerQuery);
    });
  }

  void _applyFilters(String searchQuery) {
    var filtered = widget.exercises;

    // فیلتر بر اساس نوع (همه یا اختصاصی)
    if (_filterIndex == 1) {
      // فقط تمرین‌های اختصاصی مربی
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        filtered = filtered
            .where((e) => e.createdBy != null && e.createdBy == currentUserId)
            .toList();
      } else {
        filtered = [];
      }
    }

    // فیلتر بر اساس جستجو
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) =>
                e.name.toLowerCase().contains(searchQuery) ||
                e.mainMuscle.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    if (mounted) {
      setState(() {
        _cachedFilteredExercises = filtered;
        _lastSearchQuery = searchQuery;
      });
    }
  }

  void _onFilterChanged(int index) {
    setState(() {
      _filterIndex = index;
      _cachedFilteredExercises = null; // Reset cache
      _lastSearchQuery = '';
    });
    _applyFilters(_searchController.text.toLowerCase());
  }

  List<Exercise> _getFilteredExercises() {
    // اگر cache وجود داره، برگردون
    if (_cachedFilteredExercises != null) {
      return _cachedFilteredExercises!;
    }

    // اگر cache نداره، فیلترها رو اعمال کن
    var filtered = widget.exercises;

    // فیلتر بر اساس نوع (همه یا اختصاصی)
    if (_filterIndex == 1) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        filtered = filtered
            .where((e) => e.createdBy != null && e.createdBy == currentUserId)
            .toList();
      } else {
        filtered = [];
      }
    }

    // فیلتر بر اساس جستجو
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (e) =>
                e.name.toLowerCase().contains(searchQuery) ||
                e.mainMuscle.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    _cachedFilteredExercises = filtered;
    _lastSearchQuery = searchQuery;
    return filtered;
  }

  /// بررسی اینکه آیا تمرین متعلق به مربی فعلی است
  bool _isMyExercise(Exercise exercise) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      return false;
    }

    // Debug: بررسی createdBy
    if (exercise.createdBy != null) {
      debugPrint(
        '=== AddExerciseScreen: Exercise "${exercise.name}" createdBy: ${exercise.createdBy}, currentUserId: $currentUserId ===',
      );
    }

    if (exercise.createdBy == null) {
      return false;
    }

    final isMatch = exercise.createdBy == currentUserId;
    if (isMatch) {
      debugPrint(
        '=== AddExerciseScreen: Match found! Exercise "${exercise.name}" belongs to current trainer ===',
      );
    }

    return isMatch;
  }

  void _addExercise() {
    WorkoutExercise exercise;

    if (_tabController.index == 0) {
      if (_selectedExerciseId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفا یک تمرین انتخاب کنید')),
        );
        return;
      }

      exercise = NormalExercise(
        exerciseId: _selectedExerciseId!,
        tag: MuscleTags.availableTags.first,
        style: ExerciseStyle.setsReps,
        sets: [ExerciseSet(reps: 10, timeSeconds: 60, weight: 0)],
      );
    } else {
      if (_selectedExercises.length != 2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفا دو تمرین برای سوپرست انتخاب کنید'),
          ),
        );
        return;
      }

      exercise = SupersetExercise(
        exercises: _selectedExercises,
        tag: MuscleTags.availableTags.first,
        style: ExerciseStyle.setsReps,
      );
    }

    Navigator.of(context).pop({'exercise': exercise});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final pageHeight = screenHeight * 0.8;
    final screenWidth = MediaQuery.of(context).size.width;
    final borderRadius = screenWidth > 600 ? 28.0 : 24.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: pageHeight,
        decoration: BoxDecoration(
          color: isDark ? context.backgroundColor : context.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  _buildNormalExerciseTab(isDark),
                  _buildSupersetTab(isDark),
                ],
              ),
            ),
            _buildBottomButtons(isDark),
          ],
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
              size: 24.sp,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'افزودن تمرین',
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

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardColor
            : context.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Text(
              'تمرین عادی',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          Tab(
            child: Text(
              'سوپرست',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
        ],
        labelColor: AppTheme.goldColor,
        unselectedLabelColor: isDark
            ? AppTheme.goldColor.withValues(alpha: 0.5)
            : context.textColor.withValues(alpha: 0.5),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardColor
              : context.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark
                ? AppTheme.darkGreySeparator
                : AppTheme.lightDividerColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildFilterButton(
                isDark: isDark,
                label: 'همه',
                isSelected: _filterIndex == 0,
                onTap: () => _onFilterChanged(0),
              ),
            ),
            Container(
              width: 1,
              height: 32.h,
              color: isDark
                  ? AppTheme.darkGreySeparator
                  : AppTheme.lightDividerColor,
            ),
            Expanded(
              child: _buildFilterButton(
                isDark: isDark,
                label: 'اختصاصی',
                isSelected: _filterIndex == 1,
                onTap: () => _onFilterChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppTheme.goldColor
                    : (isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.7)
                          : context.textColor.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark, {String hint = 'جستجو...'}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        controller: _searchController,
        onChanged: _performSearch,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          hintText: hint,
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

  Widget _buildEmptyState(bool isDark, {double iconSize = 48.0}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            color: AppTheme.goldColor.withValues(alpha: 0.5),
            size: iconSize.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'تمرینی یافت نشد',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : context.textColor.withValues(alpha: 0.7),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem({
    required Exercise exercise,
    required bool isDark,
    required bool isSelected,
    required VoidCallback? onTap,
    double imageSize = 60.0,
    bool showMuscle = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15)
            : (isDark ? AppTheme.darkCardColor : context.cardColor),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected
              ? AppTheme.goldColor
              : (isDark
                    ? AppTheme.darkGreySeparator
                    : AppTheme.lightDividerColor),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: imageSize.w,
                  height: imageSize.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.asset(
                      'images/GYMAI_logo_transparent.png',
                      width: imageSize.w,
                      height: imageSize.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? AppTheme.goldColor
                                    : context.textColor,
                                fontSize: 15.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // تگ اختصاصی برای تمرین‌های مربی
                          if (_isMyExercise(exercise)) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.goldColor.withValues(
                                  alpha: isDark ? 0.3 : 0.2,
                                ),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: AppTheme.goldColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'تمرین من',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  color: AppTheme.goldColor,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (showMuscle && exercise.mainMuscle.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          exercise.mainMuscle,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.7)
                                : context.textColor.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      color: Colors.black,
                      size: 16.sp,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalExerciseTab(bool isDark) {
    final filtered = _getFilteredExercises();

    final slivers = <Widget>[
      SliverToBoxAdapter(child: _buildFilterBar(isDark)),
      SliverToBoxAdapter(child: _buildSearchField(isDark)),
    ];

    if (filtered.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(isDark),
        ),
      );
    } else {
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final exercise = filtered[index];
              final isSelected = _selectedExerciseId == exercise.id;

              return _buildExerciseItem(
                exercise: exercise,
                isDark: isDark,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedExerciseId = isSelected ? null : exercise.id;
                  });
                },
              );
            }, childCount: filtered.length),
          ),
        ),
      );
    }

    return CustomScrollView(slivers: slivers);
  }

  Widget _buildSupersetTab(bool isDark) {
    final filtered = _getFilteredExercises();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with instructions
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.2 : 0.15,
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      LucideIcons.link,
                      color: AppTheme.goldColor,
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'انتخاب تمرین‌های سوپرست',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.goldColor
                                : context.textColor,
                            fontSize: 14.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${_selectedExercises.length}/2 تمرین انتخاب شده',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.goldColor.withValues(alpha: 0.7)
                                : context.textColor.withValues(alpha: 0.7),
                            fontSize: 11.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected exercises
          if (_selectedExercises.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'تمرین‌های انتخاب شده:',
                style: TextStyle(
                  color: isDark ? AppTheme.goldColor : context.textColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            ...List.generate(
              _selectedExercises.length,
              (i) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: _buildSelectedExerciseItem(i, isDark),
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Search section
          if (_selectedExercises.length < 2) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'تمرین بعدی را انتخاب کنید:',
                style: TextStyle(
                  color: isDark ? AppTheme.goldColor : context.textColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            _buildFilterBar(isDark),
            SizedBox(height: 8.h),
            _buildSearchField(isDark, hint: 'جستجو در تمرین‌ها...'),
            SizedBox(height: 12.h),

            // Exercises list
            if (filtered.isEmpty)
              Padding(
                padding: EdgeInsets.all(16.w),
                child: _buildEmptyState(isDark, iconSize: 32.0),
              )
            else
              ...List.generate(filtered.length, (index) {
                final exercise = filtered[index];
                final isAlreadySelected = _selectedExercises.any(
                  (e) => e.exerciseId == exercise.id,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 4.h,
                  ),
                  child: _buildExerciseItem(
                    exercise: exercise,
                    isDark: isDark,
                    isSelected: isAlreadySelected,
                    onTap: isAlreadySelected
                        ? null
                        : () => _addExerciseToSuperset(exercise),
                    imageSize: 36.0,
                    showMuscle: false,
                  ),
                );
              }),
          ] else ...[
            // Success state when both exercises are selected
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.2 : 0.15,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          LucideIcons.check,
                          color: AppTheme.goldColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'سوپرست آماده است!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.goldColor
                              : context.textColor,
                          fontSize: 16.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'دو تمرین انتخاب شده و آماده افزودن به برنامه',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.7)
                              : context.textColor.withValues(alpha: 0.7),
                          fontSize: 12.sp,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedExerciseItem(int index, bool isDark) {
    final exerciseItem = _selectedExercises[index];
    final exerciseDetails = widget.exercises.firstWhere(
      (e) => e.id == exerciseItem.exerciseId,
      orElse: () => Exercise(
        id: 0,
        title: '',
        name: 'تمرین ناشناخته',
        mainMuscle: '',
        secondaryMuscles: '',
        tips: [],
        videoUrl: '',
        imageUrl: '',
        otherNames: [],
        content: '',
      ),
    );

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 2.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              color: AppTheme.goldColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.goldColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.asset(
                  'images/GYMAI_logo_transparent.png',
                  width: 40.w,
                  height: 40.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              exerciseDetails.name,
              style: TextStyle(
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.x, color: Colors.red, size: 18.sp),
            onPressed: () => _removeExerciseFromSuperset(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkGreySeparator
                : AppTheme.lightDividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? AppTheme.goldColor
                    : context.textColor,
                side: BorderSide(
                  color: isDark
                      ? AppTheme.darkGreySeparator
                      : AppTheme.lightDividerColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'انصراف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(LucideIcons.check, size: 18.sp),
              label: Text('افزودن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              onPressed: _addExercise,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
