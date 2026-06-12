import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_exercise_editor_screen.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// تب تمرین‌های اختصاصی در داشبورد مربی
class CustomExercisesTab extends StatefulWidget {
  const CustomExercisesTab({super.key});

  @override
  State<CustomExercisesTab> createState() => _CustomExercisesTabState();
}

class _CustomExercisesTabState extends State<CustomExercisesTab> {
  final CustomExerciseService _service = CustomExerciseService();
  List<CustomExercise> _exercises = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, private, public

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);
    try {
      final exercises = await _service.getMyExercises();
      WidgetSafetyUtils.safeSetState(this, () {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در بارگذاری تمرین‌ها: $e',
          backgroundColor: AppTheme.errorColor,
        );
      }
    }
  }

  List<CustomExercise> get _filteredExercises {
    if (_filter == 'all') return _exercises;
    if (_filter == 'private') {
      return _exercises.where((e) => e.visibility == 'private').toList();
    }
    return _exercises.where((e) => e.visibility == 'public').toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header با دکمه ساخت جدید
          _buildHeader(isDark),

          // فیلتر
          _buildFilterBar(isDark),

          // لیست تمرین‌ها
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.goldColor),
                  )
                : _filteredExercises.isEmpty
                ? _buildEmptyState(isDark)
                : _buildExercisesList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تمرین‌های اختصاصی',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_exercises.length} تمرین',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<CustomExercise?>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomExerciseEditorScreen(),
                ),
              );
              if (result != null) {
                _loadExercises();
              }
            },
            icon: Icon(LucideIcons.plus, size: 18.sp),
            label: const Text('تمرین جدید'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldColor,
              foregroundColor: AppTheme.veryDarkBackground,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          _buildFilterChip(isDark, 'all', 'همه', _filter == 'all'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'private', 'خصوصی', _filter == 'private'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'public', 'عمومی', _filter == 'public'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    bool isDark,
    String value,
    String label,
    bool selected,
  ) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (selected) {
        WidgetSafetyUtils.safeSetState(this, () => _filter = value);
      },
      selectedColor: AppTheme.goldColor.withValues(alpha: 0.3),
      checkmarkColor: AppTheme.goldColor,
      labelStyle: TextStyle(
        color: selected
            ? AppTheme.goldColor
            : (isDark ? Colors.grey[300] : Colors.grey[700]),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.dumbbell,
            size: 64.sp,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'هنوز تمرینی نساخته‌اید',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'برای ساخت اولین تمرین اختصاصی روی دکمه بالا کلیک کنید',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadExercises,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _filteredExercises.length,
        itemBuilder: (context, index) {
          final exercise = _filteredExercises[index];
          return _buildExerciseCard(isDark, exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(bool isDark, CustomExercise exercise) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: isDark ? AppTheme.darkCardColor : AppTheme.darkTextColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: exercise.visibility == 'public'
              ? AppTheme.goldColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push<CustomExercise?>(
            context,
            MaterialPageRoute(
              builder: (_) => CustomExerciseEditorScreen(exercise: exercise),
            ),
          );
          if (result != null) {
            _loadExercises();
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // تصویر یا آیکون
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: exercise.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              exercise.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                LucideIcons.dumbbell,
                                color: AppTheme.goldColor,
                                size: 24.sp,
                              ),
                            ),
                            if (exercise.imageUrls.length > 1)
                              Positioned(
                                left: 4.w,
                                bottom: 4.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 5.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    '${exercise.imageUrls.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Icon(
                        LucideIcons.dumbbell,
                        color: AppTheme.goldColor,
                        size: 24.sp,
                      ),
              ),
              SizedBox(width: 12.w),

              // اطلاعات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.title,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (exercise.visibility == 'public')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.globe,
                                  size: 12.sp,
                                  color: AppTheme.goldColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'عمومی',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 10.sp,
                                    color: AppTheme.goldColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      exercise.mainMuscle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.gauge,
                          size: 12.sp,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          exercise.difficulty,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11.sp,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                        if (exercise.videoUrls.isNotEmpty) ...[
                          SizedBox(width: 12.w),
                          Icon(
                            LucideIcons.video,
                            size: 12.sp,
                            color: AppTheme.goldColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // آیکون ویرایش
              Icon(
                LucideIcons.chevronLeft,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
