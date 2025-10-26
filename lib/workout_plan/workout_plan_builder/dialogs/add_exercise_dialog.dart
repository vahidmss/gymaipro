import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AddExerciseDialog extends StatefulWidget {
  const AddExerciseDialog({required this.exercises, super.key});
  final List<Exercise> exercises;

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // For superset
  final List<SupersetItem> _selectedExercises = [];
  int? _selectedExerciseId; // For normal exercise

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed to 2 tabs

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedExerciseId = null;
          case 1:
            _selectedExercises.clear();
        }
      });
    }
  }

  void _addExerciseToSuperset(Exercise exercise) {
    if (_tabController.index == 1 && _selectedExercises.length < 2) {
      setState(() {
        _selectedExercises.add(
          SupersetItem(
            exerciseId: exercise.id,
            sets: [
              ExerciseSet(
                reps: 10, // Default reps
                weight: 0, // Default weight
              ),
            ],
            style: ExerciseStyle.setsReps, // Default style
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
        tag: MuscleTags.availableTags.first, // Default tag
        style: ExerciseStyle.setsReps, // Default style
        sets: [
          ExerciseSet(
            reps: 10, // Default reps
            timeSeconds: 60, // Default time
            weight: 0, // Default weight
          ),
        ],
      );
    } else {
      // _selectedType == ExerciseType.superset
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
        tag: MuscleTags.availableTags.first, // Default tag
        style: ExerciseStyle.setsReps, // Default style
      );
    }

    Navigator.of(context).pop({'exercise': exercise});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(20.w),
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), Color(0xFF3D2317), Color(0xFF4A2C1A)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.amber[700]!.withValues(alpha: 0.1),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20.r,
                offset: Offset(0.w, 8.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.dumbbell,
                      color: Colors.amber[700],
                      size: 24.sp,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'افزودن تمرین جدید',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                // Tab bar for exercise type
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.amber[700]!.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TabBar(
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: -20,
                    ),
                    controller: _tabController,
                    tabs: [
                      Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'تمرین عادی',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'سوپرست',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    labelColor: Colors.amber[200],
                    unselectedLabelColor: Colors.amber[200]?.withValues(
                      alpha: 0.1,
                    ),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.amber[700]?.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.amber[700]!.withValues(alpha: 0.1),
                      ),
                    ),
                    dividerColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tab content
                SizedBox(
                  height: 300.h,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildNormalExerciseTab(), _buildSupersetTab()],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amber[200],
                          side: BorderSide(color: Colors.amber[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.check),
                        label: const Text('افزودن'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: _addExercise,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalExerciseTab() {
    final filtered = widget.exercises
        .where(
          (e) =>
              e.name.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              e.mainMuscle.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'جستجو...',
            hintStyle: TextStyle(
              color: Colors.amber[200]?.withValues(alpha: 0.1),
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
          ),
          style: TextStyle(color: Colors.amber[200]),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final exercise = filtered[index];
              final isSelected = _selectedExerciseId == exercise.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.amber[700]!.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? Colors.amber[700]!.withValues(alpha: 0.1)
                        : Colors.amber[700]!.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  leading: exercise.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            exercise.imageUrl,
                            width: 40.w,
                            height: 40.h,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Colors.amber[700]!.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            LucideIcons.dumbbell,
                            color: Colors.amber[700],
                            size: 20.sp,
                          ),
                        ),
                  title: Text(
                    exercise.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.amber[200]
                          : Colors.amber[200]?.withValues(alpha: 0.1),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        )
                      : Icon(
                          LucideIcons.plus,
                          color: Colors.amber[700]?.withValues(alpha: 0.1),
                          size: 20.sp,
                        ),
                  onTap: () {
                    setState(() {
                      _selectedExerciseId = isSelected ? null : exercise.id;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupersetTab() {
    final filtered = widget.exercises
        .where(
          (e) =>
              e.name.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
              e.mainMuscle.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ),
        )
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with clear instructions
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber[700]!.withValues(alpha: 0.1),
                  Colors.amber[700]!.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.amber[700]!.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    LucideIcons.link,
                    color: Colors.amber[700],
                    size: 16.sp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'انتخاب تمرین‌های سوپرست',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[200],
                          fontSize: 14.sp,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedExercises.length}/2 تمرین انتخاب شده',
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selected exercises with better visual design
          if (_selectedExercises.isNotEmpty) ...[
            Text(
              'تمرین‌های انتخاب شده:',
              style: TextStyle(
                color: Colors.amber[200],
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < _selectedExercises.length; i++) ...[
              _buildSelectedExerciseItem(i),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 12),
          ],

          // Search section
          if (_selectedExercises.length < 2) ...[
            Text(
              'تمرین بعدی را انتخاب کنید:',
              style: TextStyle(
                color: Colors.amber[200],
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'جستجو در تمرین‌ها...',
                hintStyle: TextStyle(
                  color: Colors.amber[200]?.withValues(alpha: 0.1),
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: Colors.amber[700]?.withValues(alpha: 0.1),
                  size: 18.sp,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
              ),
              style: TextStyle(color: Colors.amber[200], fontSize: 13),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Exercises list with improved selection
            SizedBox(
              height: 200.h, // Fixed height for list
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.search,
                            color: Colors.amber[700]?.withValues(alpha: 0.1),
                            size: 32.sp,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تمرینی یافت نشد',
                            style: TextStyle(
                              color: Colors.amber[200]?.withValues(alpha: 0.1),
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'کلمه کلیدی دیگری امتحان کنید',
                            style: TextStyle(
                              color: Colors.amber[300]?.withValues(alpha: 0.1),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final isAlreadySelected = _selectedExercises.any(
                          (e) => e.exerciseId == exercise.id,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isAlreadySelected
                                ? Colors.amber[700]!.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isAlreadySelected
                                  ? Colors.amber[700]!.withValues(alpha: 0.1)
                                  : Colors.amber[700]!.withValues(alpha: 0.1),
                              width: isAlreadySelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            leading: exercise.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6.r),
                                    child: Image.network(
                                      exercise.imageUrl,
                                      width: 36.w,
                                      height: 36.h,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 36.w,
                                    height: 36.h,
                                    decoration: BoxDecoration(
                                      color: Colors.amber[700]!.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      LucideIcons.dumbbell,
                                      color: Colors.amber[700],
                                      size: 18.sp,
                                    ),
                                  ),
                            title: Text(
                              exercise.name,
                              style: TextStyle(
                                color: isAlreadySelected
                                    ? Colors.amber[200]?.withValues(alpha: 0.1)
                                    : Colors.amber[200],
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                              ),
                            ),
                            trailing: isAlreadySelected
                                ? Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[700]?.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      LucideIcons.check,
                                      color: Colors.amber[700],
                                      size: 14.sp,
                                    ),
                                  )
                                : Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[700]?.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Icon(
                                      LucideIcons.plus,
                                      color: Colors.amber[700],
                                      size: 14.sp,
                                    ),
                                  ),
                            enabled: !isAlreadySelected,
                            onTap: isAlreadySelected
                                ? null
                                : () => _addExerciseToSuperset(exercise),
                          ),
                        );
                      },
                    ),
            ),
          ] else ...[
            // Success state when both exercises are selected
            SizedBox(
              height: 200.h,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber[700]!.withValues(alpha: 0.1),
                        Colors.amber[700]!.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.amber[700]!.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]!.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          LucideIcons.check,
                          color: Colors.amber[700],
                          size: 24.sp,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'سوپرست آماده است!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[200],
                          fontSize: 16.sp,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'دو تمرین انتخاب شده و آماده افزودن به برنامه',
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 12.sp,
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

  Widget _buildSelectedExerciseItem(int index) {
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
        gradient: LinearGradient(
          colors: [
            Colors.amber[700]!.withValues(alpha: 0.1),
            Colors.amber[700]!.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.amber[700]!.withValues(alpha: 0.1),
          width: 2.w,
        ),
      ),
      child: Row(
        children: [
          // Number indicator with better design
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[700]!, Colors.amber[600]!],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber[700]!.withValues(alpha: 0.1),
                  blurRadius: 4.r,
                  offset: Offset(0.w, 2.h),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Exercise image with better styling
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.amber[700]!.withValues(alpha: 0.1),
              ),
            ),
            child: exerciseDetails.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      exerciseDetails.imageUrl,
                      width: 40.w,
                      height: 40.h,
                      fit: BoxFit.cover,
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.amber[700]!.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      LucideIcons.dumbbell,
                      color: Colors.amber[700],
                      size: 20.sp,
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Exercise details with better layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseDetails.name,
                  style: TextStyle(
                    color: Colors.amber[200],
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),

          // Remove button with better design
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.red[600]?.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: Colors.red[600]?.withValues(alpha: 0.1) ?? Colors.red,
              ),
            ),
            child: IconButton(
              icon: Icon(LucideIcons.x, color: Colors.red[600], size: 16),
              onPressed: () => _removeExerciseFromSuperset(index),
              padding: EdgeInsets.all(6.w),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
