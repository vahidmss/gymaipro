import 'package:flutter/material.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/workout_program.dart';

class AddExerciseDialog extends StatefulWidget {
  final List<Exercise> exercises;

  const AddExerciseDialog({
    Key? key,
    required this.exercises,
  }) : super(key: key);

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
            break;
          case 1:
            _selectedExercises.clear();
            break;
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
                timeSeconds: null, // No time for sets-reps
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
              content: Text('لطفا دو تمرین برای سوپرست انتخاب کنید')),
        );
        return;
      }

      exercise = SupersetExercise(
        exercises: _selectedExercises,
        tag: MuscleTags.availableTags.first, // Default tag
        style: ExerciseStyle.setsReps, // Default style
      );
    }

    Navigator.of(context).pop({
      'exercise': exercise,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2C1810),
                Color(0xFF3D2317),
                Color(0xFF4A2C1A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.amber[700]!.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.dumbbell,
                        color: Colors.amber[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('افزودن تمرین جدید',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )),
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
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber[700]!.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: -20),
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'تمرین عادی',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'سوپرست',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    labelColor: Colors.amber[200],
                    unselectedLabelColor: Colors.amber[200]?.withOpacity(0.6),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.amber[700]?.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.amber[700]!.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Tab content
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNormalExerciseTab(),
                      _buildSupersetTab(),
                    ],
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
                            borderRadius: BorderRadius.circular(12),
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
                            borderRadius: BorderRadius.circular(12),
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
        .where((e) =>
            e.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            e.mainMuscle
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'جستجو...',
            hintStyle: TextStyle(color: Colors.amber[200]?.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      ? Colors.amber[700]!.withOpacity(0.15)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.amber[700]!.withOpacity(0.6)
                        : Colors.amber[700]!.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: exercise.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(exercise.imageUrl,
                              width: 40, height: 40, fit: BoxFit.cover),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.amber[700]!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            LucideIcons.dumbbell,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                        ),
                  title: Text(
                    exercise.name,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.amber[200]
                          : Colors.amber[200]?.withOpacity(0.8),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : Icon(
                          LucideIcons.plus,
                          color: Colors.amber[700]?.withOpacity(0.6),
                          size: 20,
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
        .where((e) =>
            e.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            e.mainMuscle
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with clear instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber[700]!.withOpacity(0.1),
                  Colors.amber[700]!.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber[700]!.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber[700]!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.link,
                    color: Colors.amber[700],
                    size: 16,
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
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedExercises.length}/2 تمرین انتخاب شده',
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 11,
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
                fontSize: 13,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'جستجو در تمرین‌ها...',
                hintStyle:
                    TextStyle(color: Colors.amber[200]?.withOpacity(0.7)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: Colors.amber[700]?.withOpacity(0.6),
                  size: 18,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: TextStyle(color: Colors.amber[200], fontSize: 13),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Exercises list with improved selection
            SizedBox(
              height: 200, // Fixed height for list
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.search,
                            color: Colors.amber[700]?.withOpacity(0.5),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'تمرینی یافت نشد',
                            style: TextStyle(
                              color: Colors.amber[200]?.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'کلمه کلیدی دیگری امتحان کنید',
                            style: TextStyle(
                              color: Colors.amber[300]?.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final exercise = filtered[index];
                        final isAlreadySelected = _selectedExercises
                            .any((e) => e.exerciseId == exercise.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isAlreadySelected
                                ? Colors.amber[700]!.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAlreadySelected
                                  ? Colors.amber[700]!.withOpacity(0.4)
                                  : Colors.amber[700]!.withOpacity(0.2),
                              width: isAlreadySelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            leading: exercise.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(exercise.imageUrl,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover),
                                  )
                                : Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.amber[700]!.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      LucideIcons.dumbbell,
                                      color: Colors.amber[700],
                                      size: 18,
                                    ),
                                  ),
                            title: Text(
                              exercise.name,
                              style: TextStyle(
                                color: isAlreadySelected
                                    ? Colors.amber[200]?.withOpacity(0.5)
                                    : Colors.amber[200],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            trailing: isAlreadySelected
                                ? Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.amber[700]?.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      LucideIcons.check,
                                      color: Colors.amber[700],
                                      size: 14,
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.amber[700]?.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      LucideIcons.plus,
                                      color: Colors.amber[700],
                                      size: 14,
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
              height: 200,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber[700]!.withOpacity(0.1),
                        Colors.amber[700]!.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber[700]!.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[700]!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.check,
                          color: Colors.amber[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'سوپرست آماده است!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[200],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'دو تمرین انتخاب شده و آماده افزودن به برنامه',
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 12,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber[700]!.withOpacity(0.1),
            Colors.amber[700]!.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber[700]!.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Number indicator with better design
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber[700]!,
                  Colors.amber[600]!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber[700]!.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Exercise image with better styling
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber[700]!.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: exerciseDetails.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      exerciseDetails.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.amber[700]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.dumbbell,
                      color: Colors.amber[700],
                      size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),

          // Remove button with better design
          Container(
            decoration: BoxDecoration(
              color: Colors.red[600]?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.red[600]?.withOpacity(0.3) ?? Colors.red,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.x,
                color: Colors.red[600],
                size: 16,
              ),
              onPressed: () => _removeExerciseFromSuperset(index),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
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
