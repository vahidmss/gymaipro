import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/screens/exercise_detail_screen.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen>
    with TickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
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

  // Gold theme colors
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B); // theme reserve
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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _exerciseService.init();
      final exercises = await _exerciseService.getExercises();
      final muscleGroups = await _exerciseService.getMuscleGroups();
      final availableFilters = await _exerciseService.getAvailableFilters();

      if (mounted) {
        // پیش‌فرض: محبوب‌ترین‌ها بالاتر
        exercises.sort((a, b) => b.likes.compareTo(a.likes));
        setState(() {
          _exercises = exercises;
          _filteredExercises = exercises;
          _muscleGroups = muscleGroups;
          _availableFilters = availableFilters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری تمرینات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در اعمال فیلترها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// جستجوی هوشمند
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'ترتیب‌بندی تمرینات',
          style: TextStyle(color: Colors.white),
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
            child: const Text('انصراف', style: TextStyle(color: goldColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyAdvancedFilters();
            },
            child: const Text('اعمال', style: TextStyle(color: goldColor)),
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
          color: isSelected ? goldColor : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      value: value,
      groupValue: _selectedSortBy,
      onChanged: (newValue) {
        setState(() {
          _selectedSortBy = newValue!;
        });
      },
      activeColor: goldColor,
    );
  }

  /// نمایش دیالوگ فیلتر پیشرفته
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'فیلتر پیشرفته',
          style: TextStyle(color: Colors.white),
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
            child: const Text('انصراف', style: TextStyle(color: goldColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyAdvancedFilters();
            },
            child: const Text('اعمال', style: TextStyle(color: goldColor)),
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
    Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: goldColor.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedValue.isEmpty ? null : selectedValue,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
              ),
              dropdownColor: cardColor,
              style: const TextStyle(color: Colors.white),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('همه', style: TextStyle(color: Colors.white70)),
                ),
                ...options.map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: const TextStyle(color: Colors.white),
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
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.filter, color: goldColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'فیلترهای پیشرفته',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(LucideIcons.settings, color: goldColor, size: 18.sp),
                onPressed: _showFilterDialog,
                tooltip: 'تنظیمات فیلتر',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // فیلترهای سریع
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 16),

          // دکمه‌های عملیات
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyAdvancedFilters,
                  icon: const Icon(LucideIcons.search, size: 18),
                  label: const Text('اعمال فیلترها'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: goldColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(LucideIcons.x, size: 18),
                label: const Text('پاک کردن'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: goldColor,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: goldColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6),
        decoration: BoxDecoration(
          color: hasValue
              ? goldColor.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(color: hasValue ? goldColor : Colors.white24),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: hasValue ? goldColor : Colors.white70,
                fontSize: 12.sp,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 4),
              Text(
                ': $value',
                style: TextStyle(
                  color: goldColor,
                  fontSize: 12.sp,
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین به لیست علاقه‌مندی‌ها اضافه شد'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین از لیست علاقه‌مندی‌ها حذف شد'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمرین را پسندیدید'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
      }
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
                : Text(
                    'آموزش تمرینات',
                    style: TextStyle(
                      color: goldColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? LucideIcons.x : LucideIcons.search,
                  color: goldColor,
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
                  color: _showAdvancedFilters ? Colors.red : goldColor,
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
                  color: goldColor,
                  size: 22.sp,
                ),
                onPressed: _showSortDialog,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: goldColor,
              labelColor: goldColor,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Text('همه تمرینات', style: TextStyle(fontSize: 14.sp)),
                ),
                Tab(
                  child: Text('محبوب‌ترین', style: TextStyle(fontSize: 14.sp)),
                ),
                Tab(
                  child: Text(
                    'مورد علاقه‌ها',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: _isLoading
                ? _buildLoadingIndicator()
                : Column(
                    children: [
                      // نمایش تعداد نتایج
                      if (_filteredExercises.isNotEmpty ||
                          _searchQuery.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          color: cardColor.withValues(alpha: 0.5),
                          child: Row(
                            children: [
                              Text(
                                _getResultsCountText(),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
                                ),
                              ),
                              const Spacer(),
                              if (_filteredExercises.length !=
                                  _exercises.length)
                                TextButton(
                                  onPressed: _clearAllFilters,
                                  child: const Text(
                                    'پاک کردن فیلترها',
                                    style: TextStyle(color: goldColor),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // فیلترهای پیشرفته
                      if (_showAdvancedFilters) _buildAdvancedFiltersPanel(),

                      // محتوای اصلی با RefreshIndicator برای هر تب
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            RefreshIndicator(
                              color: goldColor,
                              onRefresh: () {
                                _exerciseService.clearCache();
                                return _loadData();
                              },
                              child: _buildExercisesList(_filteredExercises),
                            ),
                            RefreshIndicator(
                              color: goldColor,
                              onRefresh: () {
                                _exerciseService.clearCache();
                                return _loadData();
                              },
                              child: FutureBuilder<List<Exercise>>(
                                future: _exerciseService.getPopularExercises(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return _buildLoadingIndicator();
                                  }
                                  return _buildExercisesList(
                                    snapshot.data ?? [],
                                  );
                                },
                              ),
                            ),
                            RefreshIndicator(
                              color: goldColor,
                              onRefresh: () {
                                _exerciseService.clearCache();
                                return _loadData();
                              },
                              child: FutureBuilder<List<Exercise>>(
                                future: _exerciseService.getFavoriteExercises(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return _buildLoadingIndicator();
                                  }
                                  return _buildExercisesList(
                                    snapshot.data ?? [],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
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
        hintStyle: TextStyle(color: Colors.white54, fontSize: 15.sp),
        border: InputBorder.none,
      ),
      style: TextStyle(color: Colors.white, fontSize: 16.sp),
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
    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68, // Match the actual list
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6, // Show a few shimmer items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: cardColor,
          highlightColor: Colors.grey[800]!,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white, // This will be covered by shimmer
              borderRadius: BorderRadius.circular(16.r),
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
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
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

  Widget _buildExercisesList(List<Exercise> exercises) {
    if (exercises.isEmpty) {
      // برای فعال شدن Pull-to-Refresh حتی در حالت خالی
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabController.index == 2
                          ? LucideIcons.heartOff
                          : (_tabController.index == 1
                                ? LucideIcons.trendingDown
                                : LucideIcons.searchX),
                      color: Colors.white38,
                      size: 56.sp,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _tabController.index == 2
                          ? 'هنوز تمرینی را به علاقه‌مندی‌ها اضافه نکرده‌اید'
                          : (_tabController.index == 1
                                ? 'موردی برای نمایش در محبوب‌ترین‌ها یافت نشد'
                                : 'هیچ تمرینی با این مشخصات یافت نشد!'),
                      style: TextStyle(color: Colors.white70, fontSize: 17.sp),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_tabController.index > 0)
                      TextButton.icon(
                        onPressed: () {
                          _tabController.animateTo(0);
                        },
                        icon: Icon(
                          LucideIcons.listChecks,
                          size: 18.sp,
                          color: goldColor,
                        ),
                        label: Text(
                          'مشاهده همه تمرینات',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: goldColor.withValues(alpha: 0.9),
                        ),
                      )
                    else
                      Text(
                        _searchQuery.isNotEmpty ||
                                _selectedMuscleGroup.isNotEmpty
                            ? 'جستجو یا فیلتر خود را تغییر دهید.'
                            : 'لیست تمرینات خالی است.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(12.w),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68, // Adjusted for new card design
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0.w, 4.h),
          ),
          BoxShadow(color: goldColor.withValues(alpha: 0.03), blurRadius: 12),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            ).then((_) {
              // Refresh state when returning from details screen to reflect changes
              _loadData();
            });
          },
          borderRadius: BorderRadius.circular(16.r),
          splashColor: goldColor.withValues(alpha: 0.1),
          highlightColor: goldColor.withValues(alpha: 0.05),
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
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900]?.withValues(alpha: 0.5),
                          child: Center(
                            child: SizedBox(
                              width: 28.w,
                              height: 28.h,
                              child: CircularProgressIndicator(
                                color: goldColor.withValues(alpha: 0.7),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900]?.withValues(alpha: 0.5),
                          child: Icon(
                            LucideIcons.imageOff,
                            color: goldColor.withValues(alpha: 0.5),
                            size: 40.sp,
                          ),
                        ),
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
                      top: 8.h,
                      right: 8.w,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _toggleFavorite(exercise),
                          splashColor: goldColor.withValues(alpha: 0.3),
                          child: Padding(
                            padding: EdgeInsets.all(7.w),
                            child: Icon(
                              exercise.isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: exercise.isFavorite
                                  ? accentColor
                                  : Colors.white.withValues(alpha: 0.85),
                              size: 19.sp,
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
                      Text(
                        exercise.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5.sp,
                          height: 1.3.h,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // اطلاعات اضافی
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            color: Colors.white70,
                            size: 14.sp,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(exercise.estimatedDuration / 60).round()} دقیقه',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            LucideIcons.dumbbell,
                            color: Colors.white70,
                            size: 14.sp,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise.equipment,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _toggleLike(exercise),
                              borderRadius: BorderRadius.circular(8.r),
                              splashColor: goldColor.withValues(alpha: 0.2),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 4.h,
                                  horizontal: 5.w,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                            scale: anim,
                                            child: child,
                                          ),
                                      child: Icon(
                                        exercise.isLikedByUser
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        key: ValueKey<bool>(
                                          exercise.isLikedByUser,
                                        ),
                                        color: exercise.isLikedByUser
                                            ? Colors.redAccent
                                            : Colors.white70,
                                        size: 18.sp,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
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
                                              ? Colors.redAccent
                                              : Colors.white70,
                                          fontSize: 12.5.sp,
                                          fontWeight: exercise.isLikedByUser
                                              ? FontWeight.bold
                                              : FontWeight.normal,
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
                            color: goldColor.withValues(alpha: 0.7),
                            size: 18.sp,
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
