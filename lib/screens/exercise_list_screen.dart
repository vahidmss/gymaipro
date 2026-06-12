import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_exercise_editor_screen.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen>
    with TickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  final CustomExerciseService _customExerciseService = CustomExerciseService();
  final TrainerService _trainerService = TrainerService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  List<String> _muscleGroups = []; // reserved for future chips
  String _selectedMuscleGroup = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearching = false;

  // فیلترهای پیشرفته جدید
  String _selectedDifficulty = '';
  String _selectedEquipment = '';
  String _selectedExerciseType = '';
  String _selectedSortBy = 'popularity';
  bool _sortAscending = false;

  // فیلترهای موجود
  Map<String, List<String>> _availableFilters = {};
  bool _showAdvancedFilters = false;


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

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;

    // اگر force refresh نیست، ابتدا از cache نمایش می‌دهیم
    if (!forceRefresh) {
      try {
        final cachedExercises = await _exerciseService.getExercisesFromCache();
        if (cachedExercises != null && cachedExercises.isNotEmpty) {
          // نمایش فوری از cache
          if (mounted) {
            cachedExercises.sort((a, b) => b.likes.compareTo(a.likes));
            WidgetSafetyUtils.safeSetState(this, () {
              _exercises = cachedExercises;
              _filteredExercises = cachedExercises;
              _isLoading = false;
            });
            
            // بارگذاری فیلترها در background
            _loadFiltersInBackground();
            
            // به‌روزرسانی داده‌ها در background
            _refreshDataInBackground();
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading from cache: $e');
      }
    }

    // اگر cache موجود نبود یا force refresh بود، loading نشان می‌دهیم
    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
    });

    try {
      await _exerciseService.init();
      final exercises = await _exerciseService.getExercises(forceRefresh: forceRefresh);
      final muscleGroups = await _exerciseService.getMuscleGroups();
      final availableFilters = await _exerciseService.getAvailableFilters();

      if (mounted) {
        // پیش‌فرض: محبوب‌ترین‌ها بالاتر
        exercises.sort((a, b) => b.likes.compareTo(a.likes));
        WidgetSafetyUtils.safeSetState(this, () {
          _exercises = exercises;
          _filteredExercises = exercises;
          _muscleGroups = muscleGroups;
          _availableFilters = availableFilters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });

        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگذاری تمرینات: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// بارگذاری فیلترها در background
  Future<void> _loadFiltersInBackground() async {
    try {
      final muscleGroups = await _exerciseService.getMuscleGroups();
      final availableFilters = await _exerciseService.getAvailableFilters();
      
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _muscleGroups = muscleGroups;
          _availableFilters = availableFilters;
        });
      }
    } catch (e) {
      debugPrint('Error loading filters in background: $e');
    }
  }

  /// به‌روزرسانی داده‌ها در background
  Future<void> _refreshDataInBackground() async {
    try {
      final exercises = await _exerciseService.getExercises(forceRefresh: false);
      
      if (mounted && exercises.isNotEmpty) {
        exercises.sort((a, b) => b.likes.compareTo(a.likes));
        
        // فقط اگر داده‌ها تغییر کرده باشند، به‌روزرسانی می‌کنیم
        if (exercises.length != _exercises.length ||
            exercises.any((e) => !_exercises.any((existing) => existing.id == e.id))) {
          WidgetSafetyUtils.safeSetState(this, () {
            _exercises = exercises;
            // اگر فیلتر فعال نیست، filteredExercises را هم به‌روزرسانی کن
            if (_searchQuery.isEmpty && 
                _selectedDifficulty.isEmpty && 
                _selectedEquipment.isEmpty && 
                _selectedExerciseType.isEmpty) {
              _filteredExercises = exercises;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing data in background: $e');
    }
  }

  /// فیلتر پیشرفته تمرینات
  Future<void> _applyAdvancedFilters() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final filteredExercises = await _exerciseService.getFilteredExercises(
        difficulty: _selectedDifficulty.isEmpty ? null : _selectedDifficulty,
        equipment: _selectedEquipment.isEmpty ? null : _selectedEquipment,
        exerciseType: _selectedExerciseType.isEmpty
            ? null
            : _selectedExerciseType,
        muscleGroups: _selectedMuscleGroup.isEmpty
            ? null
            : [_selectedMuscleGroup],
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      // اعمال ترتیب‌بندی
      final sortedExercises = await _exerciseService.getSortedExercises(
        sortBy: _selectedSortBy,
        ascending: _sortAscending,
      );

      // ترکیب فیلتر و ترتیب‌بندی
      final finalExercises = sortedExercises
          .where(filteredExercises.contains)
          .toList();

      if (mounted) {
        setState(() {
          _filteredExercises = finalExercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در اعمال فیلترها: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// جستجوی هوشمند
  @Deprecated('Not used')
  Future<void> _performSmartSearch(String query) async {
    // in use via onChanged filter
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final searchResults = await _exerciseService.searchExercises(query);

      if (mounted) {
        setState(() {
          _filteredExercises = searchResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// پاک کردن همه فیلترها
  void _clearAllFilters() {
    setState(() {
      _selectedMuscleGroup = '';
      _selectedDifficulty = '';
      _selectedEquipment = '';
      _selectedExerciseType = '';
      _selectedSortBy = 'name';
      _sortAscending = false;
      _searchQuery = '';
      _searchController.clear();
      _filteredExercises = _exercises;
    });
  }

  /// نمایش تعداد نتایج
  String _getResultsCountText() {
    if (_filteredExercises.isEmpty) {
      return 'نتیجه‌ای یافت نشد';
    }

    if (_filteredExercises.length == _exercises.length) {
      return 'همه تمرینات (${_exercises.length})';
    }

    return '${_filteredExercises.length} تمرین از ${_exercises.length}';
  }

  /// نمایش دیالوگ ترتیب‌بندی
  void _showSortDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(
              LucideIcons.arrowUpDown,
              color: AppTheme.goldColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'ترتیب‌بندی تمرینات',
              style: TextStyle(
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('name', 'نام تمرین'),
            _buildSortOption('difficulty', 'سطح دشواری'),
            _buildSortOption('duration', 'مدت زمان'),
            _buildSortOption('popularity', 'محبوبیت'),
            _buildSortOption('equipment', 'تجهیزات'),
            _buildSortOption('type', 'نوع تمرین'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'انصراف',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyAdvancedFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: AppTheme.onGoldColor,
            ),
            child: const Text('اعمال'),
          ),
        ],
      ),
    );
  }

  /// ساخت گزینه ترتیب‌بندی
  Widget _buildSortOption(String value, String label) {
    final isSelected = _selectedSortBy == value;
    return RadioListTile<String>(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.goldColor : context.textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      value: value,
      groupValue: _selectedSortBy,
      onChanged: (newValue) {
        setState(() {
          _selectedSortBy = newValue!;
        });
      },
      activeColor: AppTheme.goldColor,
    );
  }

  /// نمایش دیالوگ فیلتر پیشرفته
  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(
              LucideIcons.filter,
              color: AppTheme.goldColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'فیلتر پیشرفته',
              style: TextStyle(
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterDropdown(
                'سطح دشواری',
                _selectedDifficulty,
                _availableFilters['difficulties'] ?? [],
                (value) => _selectedDifficulty = value,
              ),
              _buildFilterDropdown(
                'تجهیزات',
                _selectedEquipment,
                _availableFilters['equipments'] ?? [],
                (value) => _selectedEquipment = value,
              ),
              _buildFilterDropdown(
                'نوع تمرین',
                _selectedExerciseType,
                _availableFilters['exerciseTypes'] ?? [],
                (value) => _selectedExerciseType = value,
              ),
              _buildFilterDropdown(
                'عضله هدف',
                _selectedMuscleGroup,
                _availableFilters['muscleGroups'] ?? [],
                (value) => _selectedMuscleGroup = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'انصراف',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyAdvancedFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: AppTheme.onGoldColor,
            ),
            child: const Text('اعمال'),
          ),
        ],
      ),
    );
  }

  /// ساخت dropdown فیلتر
  Widget _buildFilterDropdown(
    String label,
    String selectedValue,
    List<String> options,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedValue.isEmpty ? null : selectedValue,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              dropdownColor: context.cardColor,
              style: TextStyle(
                color: context.textColor,
                fontSize: 14.sp,
              ),
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(
                    'همه',
                    style: TextStyle(color: context.textSecondary),
                  ),
                ),
                ...options.map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(color: context.textColor),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                onChanged(value ?? '');
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ساخت پنل فیلترهای پیشرفته
  Widget _buildAdvancedFiltersPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppTheme.goldColor.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  LucideIcons.filter,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'فیلترهای پیشرفته',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  LucideIcons.settings,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
                onPressed: _showFilterDialog,
                tooltip: 'تنظیمات فیلتر',
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // فیلترهای سریع
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _buildQuickFilterChip(
                'سطح دشواری',
                _selectedDifficulty,
                _showFilterDialog,
              ),
              _buildQuickFilterChip(
                'تجهیزات',
                _selectedEquipment,
                _showFilterDialog,
              ),
              _buildQuickFilterChip(
                'نوع تمرین',
                _selectedExerciseType,
                _showFilterDialog,
              ),
              _buildQuickFilterChip(
                'عضله هدف',
                _selectedMuscleGroup,
                _showFilterDialog,
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // دکمه‌های عملیات
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyAdvancedFilters,
                  icon: Icon(LucideIcons.search, size: 18.sp),
                  label: const Text('اعمال فیلترها'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppTheme.onGoldColor,
                    backgroundColor: AppTheme.goldColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: Icon(LucideIcons.x, size: 18.sp),
                label: const Text('پاک کردن'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: AppTheme.goldColor,
                    width: 1.5,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ساخت chip فیلتر سریع
  Widget _buildQuickFilterChip(String label, String value, VoidCallback onTap) {
    final hasValue = value.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: hasValue
              ? AppTheme.goldColor.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: hasValue
                ? AppTheme.goldColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.goldColor.withValues(alpha: 0.3)),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: hasValue
                    ? AppTheme.goldColor
                    : context.textSecondary,
                fontSize: 13.sp,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (hasValue) ...[
              SizedBox(width: 6.w),
              Text(
                ': $value',
                style: TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// دریافت رنگ سطح دشواری
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'مبتدی':
        return Colors.green;
      case 'پیشرفته':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _filterExercises() {
    final filteredByMuscle = _selectedMuscleGroup.isEmpty
        ? _exercises
        : _exercises.where((exercise) {
            return exercise.mainMuscle.contains(_selectedMuscleGroup) ||
                exercise.secondaryMuscles.contains(_selectedMuscleGroup);
          }).toList();

    final filtered = _searchQuery.isEmpty
        ? filteredByMuscle
        : filteredByMuscle.where((exercise) {
            final query = _searchQuery.toLowerCase();
            return exercise.name.toLowerCase().contains(query) ||
                exercise.mainMuscle.toLowerCase().contains(query) ||
                exercise.secondaryMuscles.toLowerCase().contains(query) ||
                exercise.otherNames.any(
                  (name) => name.toLowerCase().contains(query),
                );
          }).toList();

    if (mounted) {
      setState(() {
        _filteredExercises = filtered;
      });
    }
  }

  Future<void> _toggleFavorite(Exercise exercise) async {
    try {
      await _exerciseService.toggleFavorite(exercise.id);
      if (mounted) {
        setState(() {
          // exercise.isFavorite is already updated in the service
        });

        if (exercise.isFavorite) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'تمرین به لیست علاقه‌مندی‌ها اضافه شد',
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          );
        } else {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'تمرین از لیست علاقه‌مندی‌ها حذف شد',
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _toggleLike(Exercise exercise) async {
    try {
      final wasLiked = exercise.isLikedByUser;
      await _exerciseService.toggleLike(exercise.id);
      if (mounted) {
        setState(() {
          // exercise.isLikedByUser and exercise.likes are already updated in the service
        });

        if (!wasLiked && exercise.isLikedByUser) {
          // Successfully liked
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'تمرین را پسندیدید',
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Hide keyboard on tap outside
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: _isSearching
              ? _buildSearchField()
              : Text(
                  'آموزش تمرینات',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontSize: 21.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching ? LucideIcons.x : LucideIcons.search,
                color: AppTheme.goldColor,
                size: 22.sp,
              ),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _searchQuery = '';
                      _applyAdvancedFilters();
                      // Hide keyboard when exiting search mode
                      FocusScope.of(context).unfocus();
                    } else {
                      // Focus on search field when entering search mode
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          FocusScope.of(context).requestFocus(FocusNode());
                        }
                      });
                    }
                  });
                }
              },
            ),
            IconButton(
              icon: Icon(
                _showAdvancedFilters
                    ? LucideIcons.filterX
                    : LucideIcons.filter,
                color: _showAdvancedFilters
                    ? Colors.red[600]
                    : AppTheme.goldColor,
                size: 22.sp,
              ),
              onPressed: () {
                setState(() {
                  _showAdvancedFilters = !_showAdvancedFilters;
                });
              },
            ),
            IconButton(
              icon: Icon(
                LucideIcons.arrowUpDown,
                color: AppTheme.goldColor,
                size: 22.sp,
              ),
              onPressed: _showSortDialog,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: AppTheme.goldColor,
            indicatorWeight: 3.5,
            labelColor: AppTheme.goldColor,
            unselectedLabelColor: context.textSecondary,
            labelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'همه تمرینات'),
              Tab(text: 'مورد علاقه‌ها'),
              Tab(text: 'تمرینات مربی'),
            ],
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoadingIndicator()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      color: AppTheme.goldColor,
                      onRefresh: () {
                        return _loadData(forceRefresh: true);
                      },
                      child: _buildScrollableContent(_filteredExercises),
                    ),
                    RefreshIndicator(
                      color: AppTheme.goldColor,
                      onRefresh: () {
                        return _loadData(forceRefresh: true);
                      },
                      child: FutureBuilder<List<Exercise>>(
                        future: _exerciseService.getFavoriteExercises(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingIndicator();
                          }
                          return _buildScrollableContent(
                            snapshot.data ?? [],
                          );
                        },
                      ),
                    ),
                    RefreshIndicator(
                      color: AppTheme.goldColor,
                      onRefresh: () async {
                        // Refresh trainer exercises
                        setState(() {});
                      },
                      child: _buildTrainerExercisesTab(),
                    ),
                  ],
                ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        hintText: 'جستجوی تمرین...',
        hintStyle: TextStyle(
          color: context.textSecondary,
          fontSize: 15.sp,
        ),
        border: InputBorder.none,
        prefixIcon: Icon(
          LucideIcons.search,
          color: AppTheme.goldColor,
          size: 20.sp,
        ),
      ),
      style: TextStyle(
        color: context.textColor,
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (value) {
        if (mounted) {
          setState(() {
            _searchQuery = value;
            _filterExercises();
          });
        }
      },
    );
  }

  Widget _buildLoadingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark
              ? context.cardColor
              : context.cardColor.withValues(alpha: 0.5),
          highlightColor: isDark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 14.h,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 14.h,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 50.w,
                              height: 12.h,
                              color: Colors.white,
                            ),
                            Container(
                              width: 60.w,
                              height: 12.h,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollableContent(List<Exercise> exercises) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // فیلترهای پیشرفته - فقط برای تب اول (همه تمرینات)
        if (_tabController.index == 0 && _showAdvancedFilters)
          SliverToBoxAdapter(
            child: _buildAdvancedFiltersPanel(),
          ),

        // لیست تمرینات
        if (exercises.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyStateContent(),
          )
        else
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildExerciseCard(exercises[index]);
                },
                childCount: exercises.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrainerExercisesTab() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return _buildEmptyStateContent();
    }

    // اول بررسی می‌کنیم که آیا خود کاربر مربی است
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator();
        }

        final userRole = roleSnapshot.data;
        
        // اگر کاربر مربی است، تمرینات اختصاصی خودش را نمایش می‌دهیم
        if (userRole == 'trainer') {
          return FutureBuilder<List<Exercise>>(
            future: _loadMyCustomExercises(),
            builder: (context, exercisesSnapshot) {
              if (exercisesSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingIndicator();
              }

              final exercises = exercisesSnapshot.data ?? [];
              if (exercises.isEmpty) {
                return _buildEmptyStateContent();
              }
              return _buildScrollableContent(exercises);
            },
          );
        }

        // اگر کاربر شاگرد است، تمرینات مربی‌هایش را نمایش می‌دهیم
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _trainerService.getClientTrainersWithProfiles(user.id),
          builder: (context, trainerSnapshot) {
            if (trainerSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }

            final trainers = trainerSnapshot.data ?? [];
            final activeTrainers = trainers.where((t) => t['status'] == 'active').toList();

            if (activeTrainers.isEmpty) {
              return _buildNoTrainerEmptyState();
            }

            return FutureBuilder<List<Exercise>>(
              future: _loadTrainerExercises(user.id),
              builder: (context, exercisesSnapshot) {
                if (exercisesSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                }

                final exercises = exercisesSnapshot.data ?? [];
                return _buildScrollableContent(exercises);
              },
            );
          },
        );
      },
    );
  }
  
  /// بارگذاری تمرینات اختصاصی خود مربی
  Future<List<Exercise>> _loadMyCustomExercises() async {
    try {
      final customExercises = await _customExerciseService.getMyExercises();
      return await _customExerciseService.customExercisesToExercises(customExercises);
    } catch (e) {
      debugPrint('Error loading my custom exercises: $e');
      return [];
    }
  }

  Future<List<Exercise>> _loadTrainerExercises(String clientId) async {
    try {
      final exercises = <Exercise>[];
      
      // 1. دریافت تمرینات اختصاصی مربی‌های کاربر (اگر کاربر شاگرد باشد)
      try {
        final customExercises = await _customExerciseService.getTrainerExercisesForClient(clientId);
        final trainerExercises = await _customExerciseService.customExercisesToExercises(customExercises);
        exercises.addAll(trainerExercises);
      } catch (e) {
        debugPrint('Error loading trainer exercises for client: $e');
      }
      
      // 2. بررسی اینکه آیا خود کاربر هم مربی است
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final profile = await SimpleProfileService.queryCurrentUserProfile(
            select: 'role',
          );
          final profileResponse = profile;
          
          final role = profileResponse?['role'] as String?;
          if (role == 'trainer') {
            // اگر کاربر مربی است، تمرینات اختصاصی خودش را هم اضافه می‌کنیم
            final myCustomExercises = await _customExerciseService.getMyExercises();
            final myExercises = await _customExerciseService.customExercisesToExercises(myCustomExercises);
            
            // جلوگیری از تکرار: فقط تمریناتی که قبلاً اضافه نشده‌اند
            final existingIds = exercises.map((e) => e.id).toSet();
            for (final exercise in myExercises) {
              if (!existingIds.contains(exercise.id)) {
                exercises.add(exercise);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking trainer role or loading own exercises: $e');
      }
      
      return exercises;
    } catch (e) {
      debugPrint('Error loading trainer exercises: $e');
      return [];
    }
  }
  
  Widget? _buildFloatingActionButton() {
    // فقط در تب تمرینات مربی (index 2) نمایش داده می‌شود
    if (_tabController.index != 2) return null;
    
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        // فقط برای مربی‌ها نمایش داده می‌شود
        if (snapshot.data != 'trainer') return const SizedBox.shrink();
        
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.goldColor,
                AppTheme.goldColor.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: 0.4),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CustomExerciseEditorScreen(),
                ),
              ).then((_) {
                // Refresh when returning from editor
                setState(() {});
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(
              LucideIcons.plus,
              color: AppTheme.onGoldColor,
              size: 28.sp,
            ),
          ),
        );
      },
    );
  }
  
  Future<String?> _getUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      
      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'role',
      );
      
      return profile?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  Widget _buildNoTrainerEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                LucideIcons.userPlus,
                color: AppTheme.goldColor,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'شما هنوز مربی ندارید',
              style: TextStyle(
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              'با داشتن مربی، می‌توانید به تمرینات اختصاصی و برنامه‌های تمرینی شخصی‌سازی شده دسترسی داشته باشید.',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14.sp,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to trainer ranking screen
                Navigator.pushNamed(context, '/trainer-ranking');
              },
              icon: Icon(LucideIcons.search, size: 18.sp),
              label: const Text('جستجوی مربی'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateContent() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.separatorColor,
                  width: 2,
                ),
              ),
              child: Icon(
                _tabController.index == 2
                    ? LucideIcons.dumbbell
                    : (_tabController.index == 1
                          ? LucideIcons.heartOff
                          : LucideIcons.searchX),
                color: context.textSecondary,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              _tabController.index == 2
                  ? 'مربی شما هنوز تمرین اختصاصی ایجاد نکرده است'
                  : (_tabController.index == 1
                        ? 'هنوز تمرینی را به علاقه‌مندی‌ها اضافه نکرده‌اید'
                        : 'هیچ تمرینی با این مشخصات یافت نشد!'),
              style: TextStyle(
                color: context.textColor,
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            if (_tabController.index == 0)
              Text(
                _searchQuery.isNotEmpty || _selectedMuscleGroup.isNotEmpty
                    ? 'جستجو یا فیلتر خود را تغییر دهید.'
                    : 'لیست تمرینات خالی است.',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }


  /// ساخت placeholder یکسان و زیبا برای عکس‌های تمرین
  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.grey[900]!.withValues(alpha: 0.8),
                  Colors.grey[800]!.withValues(alpha: 0.6),
                ]
              : [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                ],
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.dumbbell,
          color: AppTheme.goldColor.withValues(alpha: 0.4),
          size: 48.sp,
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? AppTheme.goldColor.withValues(alpha: 0.25)
              : AppTheme.goldColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            ).then((_) {
              // Refresh state when returning from details screen to reflect changes
              _loadData();
            });
          },
          borderRadius: BorderRadius.circular(20.r),
          splashColor: AppTheme.goldColor.withValues(alpha: 0.15),
          highlightColor: AppTheme.goldColor.withValues(alpha: 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              AspectRatio(
                aspectRatio: 16 / 10.5, // Adjusted for slightly more image
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'exercise_image_${exercise.id}',
                      child: CachedNetworkImage(
                        imageUrl: exercise.imageUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        fadeOutDuration: const Duration(milliseconds: 100),
                        placeholder: (context, url) => _buildImagePlaceholder(isDark),
                        errorWidget: (context, url, error) =>
                            _buildImagePlaceholder(isDark),
                        memCacheWidth: 400, // Optimize memory usage
                        memCacheHeight: 300,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.3, 0.6, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: Material(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: InkWell(
                          onTap: () => _toggleFavorite(exercise),
                          splashColor: AppTheme.goldColor.withValues(alpha: 0.3),
                          child: Padding(
                            padding: EdgeInsets.all(8.w),
                            child: Icon(
                              exercise.isFavorite
                                  ? LucideIcons.bookmark
                                  : LucideIcons.bookmarkPlus,
                              color: exercise.isFavorite
                                  ? AppTheme.goldColor
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : context.textSecondary),
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // سطح دشواری
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(
                            exercise.difficulty,
                          ).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          exercise.difficulty,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    if (exercise.mainMuscle.isNotEmpty)
                      Positioned(
                        bottom: 8.h,
                        left: 10.w,
                        right: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            exercise.mainMuscle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Text and Action Section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Use spaceBetween
                    children: [
                      Flexible(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            color: context.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            height: 1.4.h,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // اطلاعات اضافی
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            color: context.textSecondary,
                            size: 15.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${(exercise.estimatedDuration / 60).round()} دقیقه',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            LucideIcons.dumbbell,
                            color: context.textSecondary,
                            size: 15.sp,
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              exercise.equipment,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // نمایش نویسنده
                      if (exercise.author != null) ...[
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.user,
                              color: AppTheme.goldColor.withValues(alpha: 0.7),
                              size: 13.sp,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                exercise.author!,
                                style: TextStyle(
                                  color: AppTheme.goldColor.withValues(alpha: 0.8),
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _toggleLike(exercise),
                              borderRadius: BorderRadius.circular(10.r),
                              splashColor: AppTheme.goldColor.withValues(alpha: 0.2),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 6.h,
                                  horizontal: 8.w,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                      child: Icon(
                                        exercise.isLikedByUser
                                            ? LucideIcons.heart
                                            : LucideIcons.heart,
                                        key: ValueKey<bool>(
                                          exercise.isLikedByUser,
                                        ),
                                        color: exercise.isLikedByUser
                                            ? Colors.red[600]
                                            : context.textSecondary,
                                        size: 18.sp,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      transitionBuilder: (child, anim) =>
                                          FadeTransition(
                                            opacity: anim,
                                            child: child,
                                          ),
                                      child: Text(
                                        exercise.likes.toString(),
                                        key: ValueKey<int>(exercise.likes),
                                        style: TextStyle(
                                          color: exercise.isLikedByUser
                                              ? Colors.red[600]
                                              : context.textSecondary,
                                          fontSize: 13.sp,
                                          fontWeight: exercise.isLikedByUser
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronLeft,
                            color: AppTheme.goldColor,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
