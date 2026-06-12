import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/screens/exercises/exercise_catalog_logic.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_catalog_grid.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_filter_sort_sheets.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_list_search_bar.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_muscle_chips.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_shimmer_grid.dart';
import 'package:gymaipro/screens/exercises/widgets/exercise_trainer_pane.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_exercise_editor_screen.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// بخش تمرینات اساسی — کاتالوگ سریع با جستجو، فیلتر و سه تب.
class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen>
    with SingleTickerProviderStateMixin {
  final _exerciseService = ExerciseService();
  late final TabController _tabs;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  List<Exercise> _allExercises = [];
  List<Exercise> _favoriteExercises = [];
  final _visibleCatalog = ValueNotifier<List<Exercise>>([]);

  ExerciseCatalogFilters _filters = const ExerciseCatalogFilters();
  Map<String, List<String>> _availableFilters = {};
  List<String> _muscleGroups = [];

  bool _isLoading = true;
  bool _loadingFavorites = false;
  int _trainerRefreshToken = 0;
  int _currentTab = 0;
  String? _userRole;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
    _searchController.addListener(_onSearchTextChanged);
    _loadCatalog();
    _loadFavorites();
    unawaited(_loadUserRole());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _visibleCatalog.dispose();
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _unfocusSearch() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_currentTab != _tabs.index) {
      _unfocusSearch();
      setState(() => _currentTab = _tabs.index);
      _recomputeVisible();
      if (_tabs.index == 1 && _favoriteExercises.isEmpty) {
        _loadFavorites();
      }
    }
  }

  void _onSearchTextChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final q = _searchController.text.trim();
      if (q == _filters.query) return;
      _filters = _filters.copyWith(query: q);
      _recomputeVisible();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    _filters = _filters.copyWith(query: '');
    _recomputeVisible();
  }

  void _recomputeVisible({bool force = false, bool preserveOrder = false}) {
    final source = _currentTab == 1 ? _favoriteExercises : _allExercises;
    final List<Exercise> next;
    if (preserveOrder && _visibleCatalog.value.isNotEmpty) {
      final byId = {for (final e in source) e.id: e};
      next = _visibleCatalog.value
          .map((e) => byId[e.id])
          .whereType<Exercise>()
          .toList();
      if (next.length != _visibleCatalog.value.length) {
        next.addAll(
          ExerciseCatalogLogic.apply(source, _filters)
              .where((e) => !next.any((v) => v.id == e.id)),
        );
      }
    } else {
      next = ExerciseCatalogLogic.apply(source, _filters);
    }
    final prev = _visibleCatalog.value;
    if (force ||
        !ExerciseCatalogLogic.sameIds(prev, next) ||
        ExerciseCatalogLogic.displayDataChanged(prev, next)) {
      _visibleCatalog.value = next;
    }
  }

  /// اعلام تغییر به گرید وقتی فیلدهای نمایشی (لایک/بوکمارک) درجا عوض شده‌اند.
  void _bumpVisibleCatalog() {
    final current = _visibleCatalog.value;
    if (current.isEmpty) return;
    _visibleCatalog.value = List<Exercise>.from(current);
  }

  void _syncFavoriteLists(Exercise exercise) {
    if (exercise.isFavorite) {
      if (!_favoriteExercises.any((e) => e.id == exercise.id)) {
        _favoriteExercises = [exercise, ..._favoriteExercises];
      }
    } else {
      _favoriteExercises =
          _favoriteExercises.where((e) => e.id != exercise.id).toList();
    }
  }

  Future<void> _loadCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      try {
        final cached = await _exerciseService.getExercisesFromCache();
        if (cached != null && cached.isNotEmpty && mounted) {
          setState(() {
            _allExercises = cached;
            _isLoading = false;
          });
          _recomputeVisible(force: true);
          unawaited(_loadFiltersBackground());
          unawaited(_refreshCatalogBackground());
          return;
        }
      } catch (e) {
        debugPrint('Exercise cache: $e');
      }
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      await _exerciseService.init();
      final exercises =
          await _exerciseService.getExercises(forceRefresh: forceRefresh);
      final muscles = await _exerciseService.getMuscleGroups();
      final filters = await _exerciseService.getAvailableFilters();

      if (!mounted) return;
      setState(() {
        _allExercises = exercises;
        _muscleGroups = muscles;
        _availableFilters = filters;
        _isLoading = false;
      });
      _recomputeVisible(force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در بارگذاری تمرینات: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _loadFiltersBackground() async {
    try {
      final muscles = await _exerciseService.getMuscleGroups();
      final filters = await _exerciseService.getAvailableFilters();
      if (mounted) {
        setState(() {
          _muscleGroups = muscles;
          _availableFilters = filters;
        });
      }
    } catch (_) {}
  }

  /// بعد از بازگشت از جزئیات — بدون shimmer و بدون force refresh سنگین.
  Future<void> _syncCatalogAfterDetail() async {
    try {
      final exercises = await _exerciseService.getExercises();
      if (!mounted || exercises.isEmpty) return;
      if (!ExerciseCatalogLogic.displayDataChanged(_allExercises, exercises) &&
          _allExercises.length == exercises.length) {
        return;
      }
      setState(() => _allExercises = exercises);
      _recomputeVisible(force: true);
    } catch (_) {}
  }

  Future<void> _refreshCatalogBackground() async {
    try {
      final needsNetworkImages = _allExercises.any(
        (e) => e.imageUrl.trim().isEmpty,
      );
      final exercises = await _exerciseService.getExercises(
        forceRefresh: needsNetworkImages,
      );
      if (!mounted || exercises.isEmpty) return;
      if (!ExerciseCatalogLogic.displayDataChanged(_allExercises, exercises) &&
          _allExercises.length == exercises.length) {
        return;
      }
      setState(() => _allExercises = exercises);
      _recomputeVisible(force: true);
    } catch (_) {}
  }

  Future<void> _loadFavorites() async {
    if (_loadingFavorites) return;
    setState(() => _loadingFavorites = true);
    try {
      final favs = await _exerciseService.getFavoriteExercises();
      if (!mounted) return;
      setState(() {
        _favoriteExercises = favs;
        _loadingFavorites = false;
      });
      if (_currentTab == 1) _recomputeVisible();
    } catch (e) {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await showExerciseFilterSheet(
      context: context,
      current: _filters,
      availableFilters: _availableFilters,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    _recomputeVisible();
  }

  Future<void> _openSort() async {
    final result = await showExerciseSortSheet(
      context: context,
      current: _filters,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    _recomputeVisible();
  }

  void _clearAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _filters = const ExerciseCatalogFilters();
    });
    _recomputeVisible();
  }

  void _onMuscleSelected(String muscle) {
    setState(() => _filters = _filters.copyWith(muscleGroup: muscle));
    _recomputeVisible();
  }

  Future<void> _toggleLike(Exercise exercise) async {
    try {
      await _exerciseService.toggleLike(exercise.id);
      if (!mounted) return;
      _bumpVisibleCatalog();
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در لایک: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  Future<void> _toggleFavorite(Exercise exercise) async {
    final adding = !exercise.isFavorite;
    try {
      await _exerciseService.toggleFavorite(exercise.id);
      if (!mounted) return;
      setState(() => _syncFavoriteLists(exercise));
      if (_currentTab == 1) {
        _recomputeVisible();
      } else {
        _bumpVisibleCatalog();
      }
      if (adding) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'به علاقه‌مندی‌ها اضافه شد',
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا: $e',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  void _openExercise(Exercise exercise) {
    _searchFocusNode.canRequestFocus = false;
    _unfocusSearch();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExerciseDetailScreen(exercise: exercise),
      ),
    ).then((_) {
      if (!mounted) return;
      _unfocusSearch();
      unawaited(_syncCatalogAfterDetail());
      unawaited(_loadFavorites());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _unfocusSearch();
        _searchFocusNode.canRequestFocus = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // جلوگیری از resize کل صفحه هنگام IME → کمتر viewport metric و لگ
      resizeToAvoidBottomInset: false,
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'تمرینات اساسی',
          style: TextStyle(
            color: AppTheme.goldColor,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_filters.hasActiveFilters)
            TextButton(
              onPressed: _clearAllFilters,
              child: Text(
                'پاک کردن',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 13.sp,
                ),
              ),
            ),
          IconButton(
            tooltip: 'فیلتر',
            icon: Icon(
              LucideIcons.slidersHorizontal,
              color: _filters.hasActiveFilters
                  ? AppTheme.goldColor
                  : context.textSecondary,
              size: 22.sp,
            ),
            onPressed: _openFilters,
          ),
          IconButton(
            tooltip: 'مرتب‌سازی',
            icon: Icon(
              LucideIcons.arrowUpDown,
              color: AppTheme.goldColor,
              size: 22.sp,
            ),
            onPressed: _openSort,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.goldColor,
          indicatorWeight: 3,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: context.textSecondary,
          labelStyle: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(fontSize: 13.sp),
          tabs: const [
            Tab(text: 'همه'),
            Tab(text: 'علاقه‌مندی'),
            Tab(text: 'مربی'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExerciseListSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onClear: _clearSearch,
          ),
          if (_currentTab == 0 && _muscleGroups.isNotEmpty) ...[
            ExerciseMuscleChips(
              muscles: _muscleGroups,
              selected: _filters.muscleGroup,
              onSelected: _onMuscleSelected,
            ),
            SizedBox(height: 4.h),
          ],
          Expanded(child: _buildActiveTab()),
        ],
      ),
      floatingActionButton:
          _currentTab == 2 && _userRole == 'trainer' ? _buildFab() : null,
    );
  }

  Widget _buildActiveTab() {
    switch (_currentTab) {
      case 1:
        return _buildFavoritesTab();
      case 2:
        return ExerciseTrainerPane(
          key: ValueKey(_trainerRefreshToken),
          filters: _filters,
          refreshToken: _trainerRefreshToken,
          onExerciseTap: _openExercise,
          onFavorite: _toggleFavorite,
          onLike: _toggleLike,
        );
      default:
        return _buildAllTab();
    }
  }

  Widget _buildAllTab() {
    if (_isLoading && _allExercises.isEmpty) {
      return const ExerciseShimmerGrid();
    }
    return ValueListenableBuilder<List<Exercise>>(
      valueListenable: _visibleCatalog,
      builder: (context, exercises, _) {
        return ExerciseCatalogGrid(
          key: const PageStorageKey<String>('exercise_tab_all'),
          exercises: exercises,
          onRefresh: () => _loadCatalog(forceRefresh: true),
          onExerciseTap: _openExercise,
          onFavorite: _toggleFavorite,
          onLike: _toggleLike,
          emptyTitle: 'تمرینی یافت نشد',
          emptySubtitle: _filters.hasActiveFilters
              ? 'فیلتر یا جستجو را تغییر دهید.'
              : 'لیست تمرینات خالی است.',
          emptyIcon: LucideIcons.searchX,
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_loadingFavorites && _favoriteExercises.isEmpty) {
      return const ExerciseShimmerGrid();
    }
    return ValueListenableBuilder<List<Exercise>>(
      valueListenable: _visibleCatalog,
      builder: (context, exercises, _) {
        return ExerciseCatalogGrid(
          key: const PageStorageKey<String>('exercise_tab_fav'),
          exercises: exercises,
          onRefresh: _loadFavorites,
          onExerciseTap: _openExercise,
          onFavorite: _toggleFavorite,
          onLike: _toggleLike,
          emptyTitle: 'علاقه‌مندی خالی است',
          emptySubtitle: _filters.hasActiveFilters
              ? 'با این جستجو چیزی پیدا نشد.'
              : 'با آیکن بوکمارک روی کارت، تمرین را اینجا ذخیره کنید.',
          emptyIcon: LucideIcons.heartOff,
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const CustomExerciseEditorScreen(),
          ),
        ).then((_) {
          if (mounted) setState(() => _trainerRefreshToken++);
        });
      },
      backgroundColor: AppTheme.goldColor,
      foregroundColor: AppTheme.onGoldColor,
      child: Icon(LucideIcons.plus, size: 26.sp),
    );
  }

  Future<void> _loadUserRole() async {
    try {
      if (Supabase.instance.client.auth.currentUser == null) return;
      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'role',
      );
      final role = profile?['role'] as String?;
      if (mounted && role != _userRole) {
        setState(() => _userRole = role);
      }
    } catch (_) {}
  }
}
