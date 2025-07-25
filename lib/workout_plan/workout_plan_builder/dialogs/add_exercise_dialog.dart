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
  late List<Exercise> _filteredExercises;

  // 1. Remove DropdownButton, ChoiceChip, or any widget for selecting style (تکرار/زمان), sets, reps, time, weight, or tag.
  // 2. Only keep the search bar, exercise list, and selected exercises list in each tab.
  // 3. The only action is to select exercises and confirm.

  // رنگ‌های اصلی برای بهبود رابط کاربری
  final Color primaryColor = const Color(0xFF3F51B5);
  final Color secondaryColor = const Color(0xFF4CAF50);
  final Color accentColor = const Color(0xFFFF9800);

  // For superset/triset
  final List<SupersetItem> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filteredExercises = List.from(widget.exercises);

    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            // _selectedType = ExerciseType.normal; // Removed
            break;
          case 1:
            // _selectedType = ExerciseType.superset; // Removed
            _selectedExercises.clear();
            break;
          case 2:
            // _selectedType = ExerciseType.triset; // Removed
            _selectedExercises.clear();
            break;
        }
      });
    }
  }

  void _filterExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = List.from(widget.exercises);
      } else {
        _filteredExercises = widget.exercises
            .where((exercise) =>
                exercise.name.toLowerCase().contains(query.toLowerCase()) ||
                exercise.mainMuscle.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
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
                timeSeconds: 60, // Default time
                weight: 0, // Default weight
              ),
            ],
          ),
        );
      });
    } else if (_tabController.index == 2 && _selectedExercises.length < 3) {
      setState(() {
        _selectedExercises.add(
          SupersetItem(
            exerciseId: exercise.id,
            sets: [
              ExerciseSet(
                reps: 10, // Default reps
                timeSeconds: 60, // Default time
                weight: 0, // Default weight
              ),
            ],
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
    } else if (_tabController.index == 1) {
      if (_selectedExercises.length != 2) {
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
    } else {
      // _selectedType == ExerciseType.triset
      if (_selectedExercises.length != 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('لطفا سه تمرین برای تریپل‌ست انتخاب کنید')),
        );
        return;
      }

      exercise = TrisetExercise(
        exercises: _selectedExercises,
        tag: MuscleTags.availableTags.first, // Default tag
        style: ExerciseStyle.setsReps, // Default style
      );
    }

    Navigator.of(context).pop({
      'exercise': exercise,
    });
  }

  int? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
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
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[700]?.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      LucideIcons.dumbbell,
                      color: Colors.amber[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'افزودن تمرین جدید',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber[700]?.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber[700]!.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tab bar for exercise type
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber[700]?.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'تمرین عادی'),
                    Tab(text: 'سوپرست'),
                    Tab(text: 'تریپل‌ست'),
                  ],
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.amber[200],
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.amber[700]?.withOpacity(0.15),
                  ),
                  dividerColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 16),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNormalExerciseTab(),
                    _buildSupersetTab(),
                    _buildTrisetTab(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('انصراف',
                          style: TextStyle(color: Colors.amber)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(LucideIcons.check),
                      label: const Text('افزودن'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        textStyle: Theme.of(context).textTheme.titleMedium,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalExerciseTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'جستجوی تمرین...',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                LucideIcons.search,
                color: isDarkMode ? Colors.white54 : Colors.black54,
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _filterExercises,
          ),
        ),
        const SizedBox(height: 12),

        // Exercises list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredExercises.length,
            itemBuilder: (context, index) {
              final exercise = _filteredExercises[index];
              final isSelected = _selectedExerciseId == exercise.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? (isDarkMode
                          ? primaryColor.withOpacity(0.2)
                          : primaryColor.withOpacity(0.08))
                      : (isDarkMode ? Colors.black12 : Colors.white),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : isDarkMode
                            ? Colors.white12
                            : Colors.grey.withOpacity(0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: exercise.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(exercise.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: isDarkMode
                          ? Colors.black26
                          : Colors.grey.withOpacity(0.2),
                    ),
                    child: exercise.imageUrl.isEmpty
                        ? Icon(
                            LucideIcons.dumbbell,
                            color: isDarkMode ? Colors.white54 : Colors.grey,
                          )
                        : null,
                  ),
                  title: Text(
                    exercise.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          LucideIcons.checkCircle,
                          color: primaryColor,
                        )
                      : null,
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedExerciseId = exercise.id;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.blue.withOpacity(0.15)
                : Colors.blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                LucideIcons.info,
                color: Colors.blue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'انتخاب تمرین‌های سوپرست (${_selectedExercises.length}/2)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Selected exercises
        if (_selectedExercises.isNotEmpty) ...[
          for (int i = 0; i < _selectedExercises.length; i++) ...[
            _buildSelectedExerciseItem(i),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],

        // Search bar
        if (_selectedExercises.length < 2) ...[
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'جستجوی تمرین...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _filterExercises,
            ),
          ),
          const SizedBox(height: 12),

          // Exercises list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final isAlreadySelected =
                    _selectedExercises.any((e) => e.exerciseId == exercise.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDarkMode ? Colors.black12 : Colors.white,
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white12
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: exercise.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(exercise.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: isDarkMode
                            ? Colors.black26
                            : Colors.grey.withOpacity(0.2),
                      ),
                      child: exercise.imageUrl.isEmpty
                          ? Icon(
                              LucideIcons.dumbbell,
                              color: isDarkMode ? Colors.white54 : Colors.grey,
                            )
                          : null,
                    ),
                    title: Text(
                      exercise.name,
                      style: TextStyle(
                        color: isAlreadySelected
                            ? Colors.grey
                            : (isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: isAlreadySelected
                        ? const Icon(LucideIcons.checkCircle,
                            color: Colors.grey)
                        : const Icon(LucideIcons.plusCircle,
                            color: Colors.blue),
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
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.check,
                    color: Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تمرین‌های سوپرست انتخاب شدند',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrisetTab() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.purple.withOpacity(0.15)
                : Colors.purple.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.purple.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                LucideIcons.info,
                color: Colors.purple,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'انتخاب تمرین‌های تریپل‌ست (${_selectedExercises.length}/3)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Selected exercises
        if (_selectedExercises.isNotEmpty) ...[
          for (int i = 0; i < _selectedExercises.length; i++) ...[
            _buildSelectedExerciseItem(i),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],

        // Search bar
        if (_selectedExercises.length < 3) ...[
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'جستجوی تمرین...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _filterExercises,
            ),
          ),
          const SizedBox(height: 12),

          // Exercises list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final isAlreadySelected =
                    _selectedExercises.any((e) => e.exerciseId == exercise.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDarkMode ? Colors.black12 : Colors.white,
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white12
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: exercise.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(exercise.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: isDarkMode
                            ? Colors.black26
                            : Colors.grey.withOpacity(0.2),
                      ),
                      child: exercise.imageUrl.isEmpty
                          ? Icon(
                              LucideIcons.dumbbell,
                              color: isDarkMode ? Colors.white54 : Colors.grey,
                            )
                          : null,
                    ),
                    title: Text(
                      exercise.name,
                      style: TextStyle(
                        color: isAlreadySelected
                            ? Colors.grey
                            : (isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    trailing: isAlreadySelected
                        ? const Icon(LucideIcons.checkCircle,
                            color: Colors.grey)
                        : const Icon(LucideIcons.plusCircle,
                            color: Colors.purple),
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
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.check,
                    color: Colors.purple,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تمرین‌های تریپل‌ست انتخاب شدند',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTriset = _tabController.index == 2;
    final color = isTriset ? Colors.purple : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.1) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Number indicator
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
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
          const SizedBox(width: 10),

          // Exercise image
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: exerciseDetails.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(exerciseDetails.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
            ),
            child: exerciseDetails.imageUrl.isEmpty
                ? Icon(
                    LucideIcons.dumbbell,
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Exercise name
          Expanded(
            child: Text(
              exerciseDetails.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Remove button
          IconButton(
            icon: Icon(
              LucideIcons.x,
              color: color.withOpacity(0.8),
              size: 16,
            ),
            onPressed: () => _removeExerciseFromSuperset(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
