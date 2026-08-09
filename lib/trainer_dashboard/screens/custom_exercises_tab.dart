import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/custom_exercise_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_exercise_editor_screen.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
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

  Future<void> _openEditor({CustomExercise? exercise}) async {
    final result = await Navigator.push<CustomExercise?>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomExerciseEditorScreen(exercise: exercise),
      ),
    );
    if (result != null) {
      _loadExercises();
    }
  }

  Color _muted(bool isDark) =>
      isDark ? Colors.grey[400]! : const Color(0xFF5A5A5A);

  Color _body(bool isDark) =>
      isDark ? AppTheme.darkTextColor : AppTheme.veryDarkBackground;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildFilterBar(isDark),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
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
                    color: _body(isDark),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_exercises.length} تمرین',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    color: _muted(isDark),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _openEditor(),
            icon: Icon(LucideIcons.plus, size: 16.sp),
            label: const Text('تمرین جدید'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.goldColor,
              side: BorderSide(
                color: AppTheme.goldColor.withValues(alpha: 0.55),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: [
          _buildFilterChip(isDark, 'all', 'همه'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'private', 'خصوصی'),
          SizedBox(width: 8.w),
          _buildFilterChip(isDark, 'public', 'عمومی'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(bool isDark, String value, String label) {
    final selected = _filter == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            WidgetSafetyUtils.safeSetState(this, () => _filter = value),
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.16)
                : (isDark
                    ? AppTheme.veryDarkBackground.withValues(alpha: 0.35)
                    : Colors.white),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? AppTheme.goldColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(LucideIcons.check, size: 14.sp, color: AppTheme.goldColor),
                SizedBox(width: 4.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _body(isDark) : _muted(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final muted = _muted(isDark);
    final hasAny = _exercises.isNotEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.28),
                    AppTheme.goldColor.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                LucideIcons.dumbbell,
                size: 36.sp,
                color: AppTheme.goldColor,
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              hasAny
                  ? 'تمرینی با این فیلتر نیست'
                  : 'اولین تمرین اختصاصی‌ات را بساز',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: _body(isDark),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              hasAny
                  ? 'فیلتر را عوض کن یا تمرین جدید بساز.'
                  : 'عنوان و عضله را بزن — نقشه عضلانی را AI پر می‌کند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                height: 1.45,
                color: muted,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              icon: Icon(LucideIcons.plus, size: 18.sp),
              label: const Text('ساخت تمرین جدید'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.veryDarkBackground,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadExercises,
      color: AppTheme.goldColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        itemCount: _filteredExercises.length,
        itemBuilder: (context, index) {
          final exercise = _filteredExercises[index];
          return _buildExerciseCard(isDark, exercise);
        },
      ),
    );
  }

  String _accessLabel(CustomExercise exercise) {
    if (exercise.visibility == 'public') return 'عمومی';
    if (exercise.sharedWithClients) return 'شاگردان';
    return 'خصوصی';
  }

  IconData _accessIcon(CustomExercise exercise) {
    if (exercise.visibility == 'public') return LucideIcons.globe;
    if (exercise.sharedWithClients) return LucideIcons.users;
    return LucideIcons.lock;
  }

  bool _coreReady(CustomExercise exercise) =>
      MuscleTargets.hasData(exercise.muscleTargets) && exercise.hasCoreMetrics;

  Widget _buildExerciseCard(bool isDark, CustomExercise exercise) {
    final coreReady = _coreReady(exercise);
    final muted = _muted(isDark);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: InkWell(
          onTap: () => _openEditor(exercise: exercise),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                _buildThumb(isDark, exercise),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.bold,
                          color: _body(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        exercise.mainMuscle.isEmpty
                            ? 'عضله نامشخص'
                            : exercise.mainMuscle,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: muted,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: [
                          _miniChip(
                            icon: _accessIcon(exercise),
                            label: _accessLabel(exercise),
                            isDark: isDark,
                          ),
                          _miniChip(
                            icon: LucideIcons.gauge,
                            label: exercise.difficulty,
                            isDark: isDark,
                          ),
                          if (coreReady)
                            _miniChip(
                              icon: LucideIcons.sparkles,
                              label: 'نقشه آماده',
                              isDark: isDark,
                              accent: true,
                            ),
                          if (exercise.videoUrls.isNotEmpty)
                            _miniChip(
                              icon: LucideIcons.video,
                              label: 'ویدیو',
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronLeft,
                  color: muted,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(bool isDark, CustomExercise exercise) {
    return Container(
      width: 72.w,
      height: 72.w,
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: exercise.imageUrls.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                GymaiNetworkImage(
                  imageUrl: exercise.imageUrls.first,
                  errorWidget: Icon(
                    LucideIcons.dumbbell,
                    color: AppTheme.goldColor,
                    size: 28.sp,
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
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.dumbbell,
                  color: AppTheme.goldColor,
                  size: 26.sp,
                ),
                if (exercise.mainMuscle.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    exercise.mainMuscle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 9.sp,
                      color: _muted(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _miniChip({
    required IconData icon,
    required String label,
    required bool isDark,
    bool accent = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent
            ? AppTheme.goldColor.withValues(alpha: isDark ? 0.18 : 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.sp,
            color: accent ? AppTheme.goldColor : _muted(isDark),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5.sp,
              fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
              color: accent ? AppTheme.goldColor : _muted(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
