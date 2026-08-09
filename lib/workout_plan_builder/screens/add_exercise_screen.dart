import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/exercise_search.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({
    required this.exercises,
    this.onRequestExercises,
    super.key,
  });

  final List<Exercise> exercises;
  final Future<List<Exercise>> Function()? onRequestExercises;

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  late List<Exercise> _allExercises;
  bool _isLoadingExercises = false;
  String? _loadingExercisesError;

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
    _allExercises = List<Exercise>.from(widget.exercises);
    _tabController = TabController(length: 2, vsync: this);
    _currentTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
    _lastSearchQuery = '';
    // Apply initial filters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters('');
      if (_allExercises.isEmpty) {
        _loadExercisesInSheet();
      }
    });
  }

  Future<void> _loadExercisesInSheet() async {
    final loader = widget.onRequestExercises;
    if (loader == null || _isLoadingExercises) return;

    setState(() {
      _isLoadingExercises = true;
      _loadingExercisesError = null;
    });

    try {
      final loaded = await loader();
      if (!mounted) return;
      setState(() {
        _allExercises = loaded;
        _cachedFilteredExercises = null;
        _lastSearchQuery = '';
      });
      _applyFilters(_searchController.text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingExercisesError = 'خطا در بارگذاری لیست تمرین‌ها';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingExercises = false;
      });
    }
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

      final normalized = ExerciseSearch.normalize(query);
      if (_cachedFilteredExercises != null && _lastSearchQuery == normalized) {
        return;
      }

      _applyFilters(query);
    });
  }

  void _applyFilters(String searchQuery) {
    var filtered = _allExercises;

    // فیلتر بر اساس نوع (همه یا اختصاصی)
    if (_filterIndex == 1) {
      // فقط تمرین‌های اختصاصی مربی
      if (_currentUserId != null) {
        filtered = filtered
            .where((e) => e.createdBy != null && e.createdBy == _currentUserId)
            .toList();
      } else {
        filtered = [];
      }
    }

    // نام اصلی + other_names + عضله
    if (searchQuery.trim().isNotEmpty) {
      filtered = ExerciseSearch.filter(filtered, searchQuery);
    }

    if (mounted) {
      setState(() {
        _cachedFilteredExercises = filtered;
        _lastSearchQuery = ExerciseSearch.normalize(searchQuery);
      });
    }
  }

  void _onFilterChanged(int index) {
    setState(() {
      _filterIndex = index;
      _cachedFilteredExercises = null; // Reset cache
      _lastSearchQuery = '';
    });
    _applyFilters(_searchController.text);
  }

  List<Exercise> _getFilteredExercises() {
    // اگر cache وجود داره، برگردون
    if (_cachedFilteredExercises != null) {
      return _cachedFilteredExercises!;
    }

    // اگر cache نداره، فیلترها رو اعمال کن
    var filtered = _allExercises;

    // فیلتر بر اساس نوع (همه یا اختصاصی)
    if (_filterIndex == 1) {
      if (_currentUserId != null) {
        filtered = filtered
            .where((e) => e.createdBy != null && e.createdBy == _currentUserId)
            .toList();
      } else {
        filtered = [];
      }
    }

    final searchQuery = _searchController.text;
    if (searchQuery.trim().isNotEmpty) {
      filtered = ExerciseSearch.filter(filtered, searchQuery);
    }

    _cachedFilteredExercises = filtered;
    _lastSearchQuery = ExerciseSearch.normalize(searchQuery);
    return filtered;
  }

  /// بررسی اینکه آیا تمرین متعلق به مربی فعلی است
  bool _isMyExercise(Exercise exercise) {
    if (_currentUserId == null || exercise.createdBy == null) {
      return false;
    }
    return exercise.createdBy == _currentUserId;
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

      final selected = _catalogExerciseById(_selectedExerciseId!);
      exercise = NormalExercise(
        exerciseId: _selectedExerciseId!,
        tag: _muscleTagForExercise(selected),
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
        tag: _muscleTagForSuperset(),
        style: ExerciseStyle.setsReps,
      );
    }

    Navigator.of(context).pop({'exercise': exercise});
  }

  Exercise? _catalogExerciseById(int id) {
    for (final exercise in _allExercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  String _muscleTagForExercise(Exercise? exercise) {
    if (exercise == null) return MuscleTags.availableTags.first;
    final localized = ProductExperienceFormatter.displayMuscle(
      exercise.mainMuscle.isNotEmpty ? exercise.mainMuscle : exercise.targetArea,
    );
    if (localized.isNotEmpty) return localized;
    return MuscleTags.availableTags.first;
  }

  String _muscleTagForSuperset() {
    final labels = _selectedExercises
        .map((item) => _muscleTagForExercise(_catalogExerciseById(item.exerciseId)))
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (labels.length == 1) return labels.first;
    if (labels.isNotEmpty) return labels.take(2).join(' + ');
    return MuscleTags.availableTags.first;
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
            if (_isLoadingExercises)
              LinearProgressIndicator(
                minHeight: 2.h,
                color: AppTheme.goldColor,
                backgroundColor: isDark
                    ? AppTheme.darkGreySeparator
                    : AppTheme.lightDividerColor,
              ),
            Expanded(
              // فقط تب فعال را بساز؛ IndexedStack هر دو لیست کامل را همزمان می‌ساخت و لگ می‌داد.
              child: _currentTabIndex == 0
                  ? _buildNormalExerciseTab(isDark)
                  : _buildSupersetTab(isDark),
            ),
            _buildBottomButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        SizedBox(height: 8.h),
        Container(
          width: 36.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 10.h),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  LucideIcons.x,
                  color: isDark
                      ? AppTheme.goldColor.withValues(alpha: 0.8)
                      : context.textColor.withValues(alpha: 0.55),
                  size: 20.sp,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'افزودن حرکت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: isDark ? AppTheme.goldColor : context.textColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 40.w), // تعادل با دکمه بستن
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF3F1EC),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              height: 36.h,
              child: Text(
                'تک‌حرکت',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
            Tab(
              height: 36.h,
              child: Text(
                'سوپرست',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ],
          labelColor: isDark ? AppTheme.goldColor : context.textColor,
          unselectedLabelColor: isDark
              ? AppTheme.goldColor.withValues(alpha: 0.45)
              : context.textColor.withValues(alpha: 0.45),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          dividerColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
      child: Row(
        children: [
          _ScopeChip(
            label: 'همه',
            selected: _filterIndex == 0,
            isDark: isDark,
            onTap: () => _onFilterChanged(0),
          ),
          SizedBox(width: 8.w),
          _ScopeChip(
            label: 'مال من',
            selected: _filterIndex == 1,
            isDark: isDark,
            onTap: () => _onFilterChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark, {String hint = 'جستجوی حرکت...'}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          setState(() {}); // برای دکمه پاک‌کردن
          _performSearch(query);
        },
        textInputAction: TextInputAction.search,
        textAlign: TextAlign.right,
        keyboardType: TextInputType.text,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark
                ? AppTheme.goldColor.withValues(alpha: 0.4)
                : context.textColor.withValues(alpha: 0.4),
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
          ),
          // در RTL، prefix سمت راست (شروع خواندن) است
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppTheme.goldColor.withValues(alpha: 0.85),
            size: 18.sp,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 16.sp,
                    color: context.textColor.withValues(alpha: 0.4),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF7F5F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 10.h,
          ),
          isDense: true,
        ),
        style: TextStyle(
          color: isDark ? AppTheme.goldColor : context.textColor,
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark, {
    double iconSize = 48.0,
    String? subtitle,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
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
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.6)
                    : context.textColor.withValues(alpha: 0.6),
                fontSize: 12.sp,
              ),
            ),
          ],
          if (actionText != null && onActionTap != null) ...[
            SizedBox(height: 12.h),
            TextButton(
              onPressed: onActionTap,
              child: Text(
                actionText,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseItem({
    required Exercise exercise,
    required bool isDark,
    required bool isSelected,
    required VoidCallback? onTap,
    bool showMuscle = true,
  }) {
    final muscle = ProductExperienceFormatter.displayMuscle(
      exercise.mainMuscle.isNotEmpty ? exercise.mainMuscle : exercise.targetArea,
    );
    final mine = _isMyExercise(exercise);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.14 : 0.1)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? AppTheme.goldColor : context.textColor,
                        fontSize: 14.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showMuscle && muscle.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        muscle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: isDark
                              ? AppTheme.goldColor.withValues(alpha: 0.55)
                              : context.textColor.withValues(alpha: 0.5),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (mine) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.22 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'مال من',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppTheme.goldColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (isSelected) ...[
                SizedBox(width: 8.w),
                Icon(
                  LucideIcons.circleCheck,
                  color: AppTheme.goldColor,
                  size: 18.sp,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalExerciseTab(bool isDark) {
    final filtered = _getFilteredExercises();
    final showLoadingPlaceholder = _isLoadingExercises && filtered.isEmpty;

    final slivers = <Widget>[
      SliverToBoxAdapter(child: _buildFilterBar(isDark)),
      SliverToBoxAdapter(child: _buildSearchField(isDark)),
    ];

    if (showLoadingPlaceholder) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildLoadingState(isDark),
        ),
      );
    } else if (filtered.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            isDark,
            actionText: _loadingExercisesError != null ? 'تلاش مجدد' : null,
            onActionTap: _loadingExercisesError != null
                ? _loadExercisesInSheet
                : null,
            subtitle: _loadingExercisesError,
          ),
        ),
      );
    } else {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final exercise = filtered[index];
            return _buildExerciseItem(
              exercise: exercise,
              isDark: isDark,
              isSelected: false,
              onTap: () {
                _selectedExerciseId = exercise.id;
                _addExercise();
              },
            );
          }, childCount: filtered.length),
        ),
      );
    }

    return CustomScrollView(
      key: const PageStorageKey<String>('add_exercise_normal_tab'),
      slivers: slivers,
    );
  }

  Widget _buildSupersetTab(bool isDark) {
    final filtered = _getFilteredExercises();
    final showLoadingPlaceholder = _isLoadingExercises && filtered.isEmpty;

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
          child: Text(
            _selectedExercises.isEmpty
                ? 'دو حرکت پشت‌سرهم انتخاب کنید'
                : '${_selectedExercises.length} از ۲ انتخاب شد',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : context.textColor.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    ];

    if (_selectedExercises.isNotEmpty) {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _buildSelectedExerciseItem(i, isDark),
            childCount: _selectedExercises.length,
          ),
        ),
      );
      slivers.add(SliverToBoxAdapter(child: SizedBox(height: 8.h)));
    }

    if (_selectedExercises.length < 2) {
      slivers.add(SliverToBoxAdapter(child: _buildFilterBar(isDark)));
      slivers.add(
        SliverToBoxAdapter(
          child: _buildSearchField(isDark, hint: 'جستجوی حرکت...'),
        ),
      );

      if (showLoadingPlaceholder) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: _buildLoadingState(isDark),
            ),
          ),
        );
      } else if (filtered.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: _buildEmptyState(
                isDark,
                iconSize: 32,
                actionText: _loadingExercisesError != null
                    ? 'تلاش مجدد'
                    : null,
                onActionTap: _loadingExercisesError != null
                    ? _loadExercisesInSheet
                    : null,
                subtitle: _loadingExercisesError,
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final exercise = filtered[index];
                final isAlreadySelected = _selectedExercises.any(
                  (e) => e.exerciseId == exercise.id,
                );
                return _buildExerciseItem(
                  exercise: exercise,
                  isDark: isDark,
                  isSelected: isAlreadySelected,
                  onTap: isAlreadySelected
                      ? null
                      : () => _addExerciseToSuperset(exercise),
                );
              },
              childCount: filtered.length,
            ),
          ),
        );
      }
    } else {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Text(
              'آماده است — افزودن سوپرست را بزنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.goldColor,
              ),
            ),
          ),
        ),
      );
    }

    return CustomScrollView(
      key: const PageStorageKey<String>('add_exercise_superset_tab'),
      slivers: slivers,
    );
  }

  Widget _buildSelectedExerciseItem(int index, bool isDark) {
    final exerciseItem = _selectedExercises[index];
    final exerciseDetails = _allExercises.firstWhere(
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 3.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.goldColor,
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppTheme.onGoldColor,
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              exerciseDetails.name,
              style: TextStyle(
                color: isDark ? AppTheme.goldColor : context.textColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.x,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : context.textColor.withValues(alpha: 0.45),
              size: 16.sp,
            ),
            onPressed: () => _removeExerciseFromSuperset(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28.w,
            height: 28.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.goldColor,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'در حال بارگذاری تمرین‌ها...',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: isDark
                  ? AppTheme.goldColor.withValues(alpha: 0.8)
                  : context.textColor.withValues(alpha: 0.8),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    final isSuperset = _currentTabIndex == 1;
    final canAdd = isSuperset && _selectedExercises.length == 2;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // تک‌حرکت با لمس اضافه می‌شود؛ فوتر فقط برای سوپرست لازم است
    if (!isSuperset) {
      return SizedBox(height: bottomInset > 0 ? bottomInset : 8.h);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h + bottomInset),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'انصراف',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.7)
                    : context.textColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAdd
                    ? AppTheme.goldColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                foregroundColor: canAdd
                    ? AppTheme.onGoldColor
                    : (isDark
                          ? AppTheme.goldColor.withValues(alpha: 0.35)
                          : context.textColor.withValues(alpha: 0.35)),
                disabledForegroundColor: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.35)
                    : context.textColor.withValues(alpha: 0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              onPressed: canAdd ? _addExercise : null,
              child: Text(
                canAdd
                    ? 'افزودن سوپرست'
                    : '۲ حرکت انتخاب کنید (${_selectedExercises.length}/۲)',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
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

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? AppTheme.goldColor.withValues(alpha: 0.45)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppTheme.goldColor
                  : (isDark
                        ? AppTheme.goldColor.withValues(alpha: 0.55)
                        : context.textColor.withValues(alpha: 0.55)),
            ),
          ),
        ),
      ),
    );
  }
}
