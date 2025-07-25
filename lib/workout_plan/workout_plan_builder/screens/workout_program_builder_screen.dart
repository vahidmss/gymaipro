// این فایل کاملاً ماژولار است. تمام دیالوگ‌ها، ویجت‌ها و سرویس‌های قابل استفاده مجدد در فولدرهای جدا قرار دارند. از افزودن کد تکراری یا لاگ بی‌دلیل خودداری کنید. برای توسعه، فقط منطق UI و تعاملات را اینجا نگه دارید و بقیه را جدا کنید.
import 'package:flutter/material.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/dialogs/add_exercise_dialog.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/dialogs/confirm_delete_program_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/workout_program.dart';
import '../services/workout_program_service.dart';
import '../widgets/saved_programs_drawer.dart';

class WorkoutProgramBuilderScreen extends StatefulWidget {
  final String? programId;

  const WorkoutProgramBuilderScreen({
    Key? key,
    this.programId,
  }) : super(key: key);

  @override
  State<WorkoutProgramBuilderScreen> createState() =>
      _WorkoutProgramBuilderScreenState();
}

class _WorkoutProgramBuilderScreenState
    extends State<WorkoutProgramBuilderScreen> {
  final WorkoutProgramService _programService = WorkoutProgramService();
  final ExerciseService _exerciseService = ExerciseService();

  WorkoutProgram _program = WorkoutProgram.empty();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Exercise> _exercises = [];
  List<WorkoutProgram> _savedPrograms = [];
  bool _showDrawer = false;
  int _selectedDay = 0;
  List<WorkoutExercise> _selectedExercises = []; // لیست حرکات انتخاب شده

  final TextEditingController _programNameController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // اطمینان از اینکه سرویس برنامه‌ها مقداردهی اولیه شده است
      await _programService.init();

      // بارگذاری تمام تمرین‌ها برای انتخاب
      _exercises = await _exerciseService.getExercises();

      // بارگذاری تمام برنامه‌های ذخیره شده برای دراور
      _savedPrograms = await _programService.getPrograms();

      if (widget.programId != null) {
        // Load existing program
        final program = await _programService.getProgramById(widget.programId!);
        if (program != null) {
          _program = program;
          _programNameController.text = program.name;
        } else {
          // If program not found, create a new one
          _program = WorkoutProgram.empty();
          _programNameController.text = _program.name;
        }
      } else {
        // Create a new program
        _program = WorkoutProgram.empty();
        _programNameController.text = _program.name;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgram() async {
    if (_programNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً نام برنامه را وارد کنید')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // اطمینان از به‌روزرسانی نام برنامه از TextEditingController
      _program.name = _programNameController.text;

      // ذخیره برنامه جدید یا به‌روزرسانی برنامه موجود
      if (_program.id.isNotEmpty &&
          _savedPrograms.any((p) => p.id == _program.id)) {
        // به‌روزرسانی برنامه موجود
        final updatedProgram = await _programService.updateProgram(_program);
        _program = updatedProgram;
      } else {
        // ایجاد یک برنامه جدید
        final newProgram = await _programService.createProgram(_program);
        _program = newProgram;
      }

      // بارگیری مجدد برنامه‌های ذخیره شده از Supabase
      _savedPrograms = await _programService.getPrograms();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برنامه با موفقیت ذخیره شد')),
      );

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره برنامه: $e')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _addExercise() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddExerciseDialog(
        exercises: _exercises,
      ),
    );

    if (result != null) {
      setState(() {
        final exercise = result['exercise'] as WorkoutExercise;
        _selectedExercises.add(exercise);
      });
    }
  }

  void _deleteExercise(int exerciseIndex) {
    setState(() {
      _selectedExercises.removeAt(exerciseIndex);
    });
  }

  void _moveExerciseUp(int exerciseIndex) {
    if (exerciseIndex > 0) {
      setState(() {
        final exercise = _selectedExercises.removeAt(exerciseIndex);
        _selectedExercises.insert(exerciseIndex - 1, exercise);
      });
    }
  }

  void _moveExerciseDown(int exerciseIndex) {
    if (exerciseIndex < _selectedExercises.length - 1) {
      setState(() {
        final exercise = _selectedExercises.removeAt(exerciseIndex);
        _selectedExercises.insert(exerciseIndex + 1, exercise);
      });
    }
  }

  void _loadProgram(String programId) {
    // Close drawer
    Navigator.of(context).pop();

    // Navigate to the program builder with the selected program ID
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutProgramBuilderScreen(programId: programId),
      ),
    );
  }

  void _createNewProgram() {
    // Close drawer
    Navigator.of(context).pop();

    // Navigate to create a new program
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutProgramBuilderScreen(),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C1810),
              Color(0xFF3D2317),
              Color(0xFF4A2C1A),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              children: [
                // Save button (rightmost)
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
                    icon: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber[700]!,
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.save,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                    onPressed: _isSaving ? null : _saveProgram,
                    tooltip: 'ذخیره',
                  ),
                ),
                const SizedBox(width: 12),
                // Menu button
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
                      LucideIcons.menu,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showDrawer = true),
                    tooltip: 'برنامه‌های ذخیره‌شده',
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.programId != null
                            ? 'ویرایش برنامه تمرینی'
                            : 'ایجاد برنامه تمرینی',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'طراحی و مدیریت جلسات تمرینی',
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Back button (leftmost)
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
                      Icons.arrow_back,
                      color: Colors.amber[700],
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: _buildCustomAppBar(context),
          drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
          drawerEnableOpenDragGesture: true,
          endDrawerEnableOpenDragGesture: false,
          floatingActionButton: Container(
            margin: const EdgeInsets.only(bottom: 60),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber[600]!,
                    Colors.amber[700]!,
                    Colors.amber[800]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber[700]!.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _addExercise,
                backgroundColor: Colors.transparent,
                elevation: 0,
                tooltip: 'افزودن حرکت',
                child: const Icon(
                  LucideIcons.plus,
                  color: Color(0xFF1A1A1A),
                  size: 28,
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: SizedBox.expand(
            child: Column(
              children: [
                // بخش بالایی (نام برنامه و انتخاب روز)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.amber[700]!.withOpacity(0.3),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: TextField(
                      controller: _programNameController,
                      style: TextStyle(
                          color: Colors.amber[100],
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'نام برنامه',
                        labelStyle:
                            TextStyle(color: Colors.amber[300], fontSize: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, idx) {
                      final daysFa = [
                        'روز ۱',
                        'روز ۲',
                        'روز ۳',
                        'روز ۴',
                        'روز ۵',
                        'روز ۶',
                        'روز ۷'
                      ];
                      final isSelected = _selectedDay == idx;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ChoiceChip(
                            label: Text(
                              daysFa[idx],
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.amber[200],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedDay = idx);
                            },
                            selectedColor: Colors.amber[700],
                            backgroundColor: const Color(0xFF2C1810),
                            side: BorderSide(
                                color: isSelected
                                    ? Colors.amber[700]!
                                    : Colors.amber[700]!.withOpacity(0.3),
                                width: 1.5),
                            elevation: isSelected ? 6 : 2,
                            shadowColor: Colors.black.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // لیست تمرین‌ها (اسکرول فقط روی این بخش)
                Expanded(
                  child: _selectedExercises.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.amber[700]!.withOpacity(0.3),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6))
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[700]?.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(LucideIcons.dumbbell,
                                      size: 64, color: Colors.amber[700]),
                                ),
                                const SizedBox(height: 24),
                                Text('برنامه تمرینی خود را بسازید',
                                    style: TextStyle(
                                        color: Colors.amber[200],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                Text(
                                    'با انتخاب حرکات مورد نظر، برنامه ورزشی شخصی‌سازی شده خود را ایجاد کنید. هر حرکت به ترتیب به برنامه شما اضافه خواهد شد.',
                                    style: TextStyle(
                                        color: Colors.amber[300], fontSize: 14),
                                    textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _selectedExercises.length,
                          itemBuilder: (context, exerciseIndex) => Padding(
                            key: ValueKey('exercise_$exerciseIndex'),
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildExerciseCard(
                              _selectedExercises[exerciseIndex],
                              _exercises.firstWhere(
                                (e) =>
                                    e.id ==
                                    (_selectedExercises[exerciseIndex]
                                            is NormalExercise
                                        ? (_selectedExercises[exerciseIndex]
                                                as NormalExercise)
                                            .exerciseId
                                        : 0),
                                orElse: () => Exercise(
                                  id: 0,
                                  title: '',
                                  name: 'حرکت ${exerciseIndex + 1}',
                                  mainMuscle: '',
                                  secondaryMuscles: '',
                                  tips: [],
                                  videoUrl: '',
                                  imageUrl: '',
                                  otherNames: [],
                                  content: '',
                                ),
                              ),
                              exerciseIndex,
                              isReorderable: false,
                            ),
                          ),
                        ),
                ),
                // Bottom Info Bar
                _buildBottomInfoBar(),
              ],
            ),
          ),
        ));
  }

  Widget _buildExerciseCard(
      WorkoutExercise exercise, Exercise exerciseDetails, int index,
      {bool isReorderable = false}) {
    final Color primaryColor = Colors.amber[700]!;
    final Color backgroundColor = Colors.amber[50]!;
    final Color borderColor = Colors.amber[200]!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Move up/down buttons
                if (index > 0)
                  IconButton(
                    icon:
                        Icon(Icons.arrow_upward, color: primaryColor, size: 20),
                    tooltip: 'انتقال به بالا',
                    onPressed: () => _moveExerciseUp(index),
                  ),
                if (index < _selectedExercises.length - 1)
                  IconButton(
                    icon: Icon(Icons.arrow_downward,
                        color: primaryColor, size: 20),
                    tooltip: 'انتقال به پایین',
                    onPressed: () => _moveExerciseDown(index),
                  ),
                const SizedBox(width: 8),
                // Exercise image or icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: exerciseDetails.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            exerciseDetails.imageUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(LucideIcons.dumbbell,
                          color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Exercise name only
                Expanded(
                  child: Text(
                    exerciseDetails.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Delete button only
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red[200]!,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(LucideIcons.trash2,
                        color: Colors.red[600], size: 18),
                    onPressed: () => _deleteExercise(index),
                    tooltip: 'حذف حرکت',
                  ),
                ),
              ],
            ),
            // در بخش کارت NormalExercise:
            if (exercise is NormalExercise)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  color: Colors.amber[50],
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0, top: 2.0),
                          child: Row(
                            children: [
                              Text('نوع حرکت:',
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.amber[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.amber[300]!, width: 1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      avatar: Icon(Icons.repeat,
                                          size: 15,
                                          color: exercise.style ==
                                                  ExerciseStyle.setsReps
                                              ? Colors.brown
                                              : Colors.amber[700]),
                                      label: const Text('ست-تکرار',
                                          style: TextStyle(fontSize: 11)),
                                      selected: exercise.style ==
                                          ExerciseStyle.setsReps,
                                      onSelected: (selected) {
                                        if (selected &&
                                            exercise.style !=
                                                ExerciseStyle.setsReps) {
                                          setState(() {
                                            exercise.style =
                                                ExerciseStyle.setsReps;
                                            for (final set in exercise.sets) {
                                              set.reps = set.reps ?? 10;
                                              set.timeSeconds = null;
                                            }
                                          });
                                        }
                                      },
                                      selectedColor: Colors.amber[300],
                                      backgroundColor: Colors.amber[50],
                                      labelStyle: TextStyle(
                                        color: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? Colors.brown
                                            : Colors.amber[700],
                                        fontWeight: exercise.style ==
                                                ExerciseStyle.setsReps
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      elevation: exercise.style ==
                                              ExerciseStyle.setsReps
                                          ? 2
                                          : 0,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 4),
                                    ChoiceChip(
                                      avatar: Icon(Icons.timer,
                                          size: 15,
                                          color: exercise.style ==
                                                  ExerciseStyle.setsTime
                                              ? Colors.brown
                                              : Colors.amber[700]),
                                      label: const Text('ست-زمان',
                                          style: TextStyle(fontSize: 11)),
                                      selected: exercise.style ==
                                          ExerciseStyle.setsTime,
                                      onSelected: (selected) {
                                        if (selected &&
                                            exercise.style !=
                                                ExerciseStyle.setsTime) {
                                          setState(() {
                                            exercise.style =
                                                ExerciseStyle.setsTime;
                                            for (final set in exercise.sets) {
                                              set.timeSeconds =
                                                  set.timeSeconds ?? 30;
                                              set.reps = null;
                                            }
                                          });
                                        }
                                      },
                                      selectedColor: Colors.amber[300],
                                      backgroundColor: Colors.amber[50],
                                      labelStyle: TextStyle(
                                        color: exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? Colors.brown
                                            : Colors.amber[700],
                                        fontWeight: exercise.style ==
                                                ExerciseStyle.setsTime
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      elevation: exercise.style ==
                                              ExerciseStyle.setsTime
                                          ? 2
                                          : 0,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('ست:',
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                              const SizedBox(width: 4),
                              _buildStepper(
                                value: exercise.sets.length,
                                min: 1,
                                onChanged: (val) {
                                  setState(() {
                                    final current = exercise.sets.length;
                                    if (val > current) {
                                      for (int i = 0; i < val - current; i++) {
                                        exercise.sets.add(ExerciseSet(
                                          reps: exercise.style ==
                                                  ExerciseStyle.setsReps
                                              ? (exercise.sets.isNotEmpty
                                                  ? exercise.sets[0].reps
                                                  : 10)
                                              : null,
                                          timeSeconds: exercise.style ==
                                                  ExerciseStyle.setsTime
                                              ? (exercise.sets.isNotEmpty
                                                  ? exercise.sets[0].timeSeconds
                                                  : 30)
                                              : null,
                                          weight: exercise.sets.isNotEmpty
                                              ? exercise.sets[0].weight
                                              : 0,
                                        ));
                                      }
                                    } else if (val < current) {
                                      exercise.sets.removeRange(val, current);
                                    }
                                  });
                                },
                                small: true,
                              ),
                              const SizedBox(width: 8),
                              if (exercise.style == ExerciseStyle.setsReps) ...[
                                Text('تکرار:',
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                _buildStepper(
                                  value: exercise.sets.isNotEmpty
                                      ? (exercise.sets[0].reps ?? 10)
                                      : 10,
                                  min: 1,
                                  onChanged: (val) {
                                    setState(() {
                                      for (final set in exercise.sets) {
                                        set.reps = val;
                                      }
                                    });
                                  },
                                  small: true,
                                ),
                              ] else ...[
                                Text('زمان (ثانیه):',
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                                const SizedBox(width: 4),
                                _buildStepper(
                                  value: exercise.sets.isNotEmpty
                                      ? (exercise.sets[0].timeSeconds ?? 30)
                                      : 30,
                                  min: 1,
                                  onChanged: (val) {
                                    setState(() {
                                      for (final set in exercise.sets) {
                                        set.timeSeconds = val;
                                      }
                                    });
                                  },
                                  small: true,
                                ),
                              ],
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 38,
                                child: TextFormField(
                                  initialValue: exercise.sets.isNotEmpty
                                      ? (exercise.sets[0].weight?.toString() ??
                                          '0')
                                      : '0',
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.amber[50],
                                    hintText: '-',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                  ),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold),
                                  onChanged: (val) {
                                    final w = double.tryParse(val);
                                    setState(() {
                                      for (final set in exercise.sets) {
                                        set.weight = w;
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('کیلو',
                                  style: TextStyle(
                                      color: primaryColor, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // در بخش کارت SupersetExercise:
            if (exercise is SupersetExercise)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  color: Colors.amber[50],
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('سوپرست',
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < exercise.exercises.length; i++) ...[
                          Builder(
                            builder: (context) {
                              final supersetItem = exercise.exercises[i];
                              final exDetails = _exercises.firstWhere(
                                (e) => e.id == supersetItem.exerciseId,
                                orElse: () => Exercise(
                                  id: 0,
                                  title: '',
                                  name: 'حرکت ${i + 1}',
                                  mainMuscle: '',
                                  secondaryMuscles: '',
                                  tips: [],
                                  videoUrl: '',
                                  imageUrl: '',
                                  otherNames: [],
                                  content: '',
                                ),
                              );
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      exDetails.imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.network(
                                                exDetails.imageUrl,
                                                width: 28,
                                                height: 28,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(LucideIcons.dumbbell,
                                              color: Colors.amber[700],
                                              size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          exDetails.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber[900],
                                              fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text('نوع حرکت:',
                                          style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12)),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.amber[100],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.amber[300]!,
                                              width: 1),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        child: Row(
                                          children: [
                                            ChoiceChip(
                                              avatar: Icon(Icons.repeat,
                                                  size: 15,
                                                  color: exercise.style ==
                                                          ExerciseStyle.setsReps
                                                      ? Colors.brown
                                                      : Colors.amber[700]),
                                              label: const Text('ست-تکرار',
                                                  style:
                                                      TextStyle(fontSize: 11)),
                                              selected: exercise.style ==
                                                  ExerciseStyle.setsReps,
                                              onSelected: (selected) {
                                                if (selected &&
                                                    exercise.style !=
                                                        ExerciseStyle
                                                            .setsReps) {
                                                  setState(() {
                                                    exercise.style =
                                                        ExerciseStyle.setsReps;
                                                    for (final set
                                                        in supersetItem.sets) {
                                                      set.reps = set.reps ?? 10;
                                                      set.timeSeconds = null;
                                                    }
                                                  });
                                                }
                                              },
                                              selectedColor: Colors.amber[300],
                                              backgroundColor: Colors.amber[50],
                                              labelStyle: TextStyle(
                                                color: exercise.style ==
                                                        ExerciseStyle.setsReps
                                                    ? Colors.brown
                                                    : Colors.amber[700],
                                                fontWeight: exercise.style ==
                                                        ExerciseStyle.setsReps
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              elevation: exercise.style ==
                                                      ExerciseStyle.setsReps
                                                  ? 2
                                                  : 0,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            const SizedBox(width: 4),
                                            ChoiceChip(
                                              avatar: Icon(Icons.timer,
                                                  size: 15,
                                                  color: exercise.style ==
                                                          ExerciseStyle.setsTime
                                                      ? Colors.brown
                                                      : Colors.amber[700]),
                                              label: const Text('ست-زمان',
                                                  style:
                                                      TextStyle(fontSize: 11)),
                                              selected: exercise.style ==
                                                  ExerciseStyle.setsTime,
                                              onSelected: (selected) {
                                                if (selected &&
                                                    exercise.style !=
                                                        ExerciseStyle
                                                            .setsTime) {
                                                  setState(() {
                                                    exercise.style =
                                                        ExerciseStyle.setsTime;
                                                    for (final set
                                                        in supersetItem.sets) {
                                                      set.timeSeconds =
                                                          set.timeSeconds ?? 30;
                                                      set.reps = null;
                                                    }
                                                  });
                                                }
                                              },
                                              selectedColor: Colors.amber[300],
                                              backgroundColor: Colors.amber[50],
                                              labelStyle: TextStyle(
                                                color: exercise.style ==
                                                        ExerciseStyle.setsTime
                                                    ? Colors.brown
                                                    : Colors.amber[700],
                                                fontWeight: exercise.style ==
                                                        ExerciseStyle.setsTime
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              elevation: exercise.style ==
                                                      ExerciseStyle.setsTime
                                                  ? 2
                                                  : 0,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text('ست:',
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12)),
                                        const SizedBox(width: 4),
                                        _buildStepper(
                                          value: supersetItem.sets.length,
                                          min: 1,
                                          onChanged: (val) {
                                            setState(() {
                                              final current =
                                                  supersetItem.sets.length;
                                              if (val > current) {
                                                for (int j = 0;
                                                    j < val - current;
                                                    j++) {
                                                  supersetItem.sets
                                                      .add(ExerciseSet(
                                                    reps: exercise.style ==
                                                            ExerciseStyle
                                                                .setsReps
                                                        ? (supersetItem
                                                                .sets.isNotEmpty
                                                            ? supersetItem
                                                                .sets[0].reps
                                                            : 10)
                                                        : null,
                                                    timeSeconds:
                                                        exercise.style ==
                                                                ExerciseStyle
                                                                    .setsTime
                                                            ? (supersetItem.sets
                                                                    .isNotEmpty
                                                                ? supersetItem
                                                                    .sets[0]
                                                                    .timeSeconds
                                                                : 30)
                                                            : null,
                                                    weight: supersetItem
                                                            .sets.isNotEmpty
                                                        ? supersetItem
                                                            .sets[0].weight
                                                        : 0,
                                                  ));
                                                }
                                              } else if (val < current) {
                                                supersetItem.sets
                                                    .removeRange(val, current);
                                              }
                                            });
                                          },
                                          small: true,
                                        ),
                                        const SizedBox(width: 8),
                                        if (exercise.style ==
                                            ExerciseStyle.setsReps) ...[
                                          Text('تکرار:',
                                              style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                          const SizedBox(width: 4),
                                          _buildStepper(
                                            value: supersetItem.sets.isNotEmpty
                                                ? (supersetItem.sets[0].reps ??
                                                    10)
                                                : 10,
                                            min: 1,
                                            onChanged: (val) {
                                              setState(() {
                                                for (final set
                                                    in supersetItem.sets) {
                                                  set.reps = val;
                                                }
                                              });
                                            },
                                            small: true,
                                          ),
                                        ] else ...[
                                          Text('زمان (ثانیه):',
                                              style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12)),
                                          const SizedBox(width: 4),
                                          _buildStepper(
                                            value: supersetItem.sets.isNotEmpty
                                                ? (supersetItem
                                                        .sets[0].timeSeconds ??
                                                    30)
                                                : 30,
                                            min: 1,
                                            onChanged: (val) {
                                              setState(() {
                                                for (final set
                                                    in supersetItem.sets) {
                                                  set.timeSeconds = val;
                                                }
                                              });
                                            },
                                            small: true,
                                          ),
                                        ],
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 38,
                                          child: TextFormField(
                                            initialValue: supersetItem
                                                    .sets.isNotEmpty
                                                ? (supersetItem.sets[0].weight
                                                        ?.toString() ??
                                                    '0')
                                                : '0',
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide.none),
                                              filled: true,
                                              fillColor: Colors.amber[50],
                                              hintText: '-',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4),
                                            ),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold),
                                            onChanged: (val) {
                                              final w = double.tryParse(val);
                                              setState(() {
                                                for (final set
                                                    in supersetItem.sets) {
                                                  set.weight = w;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('کیلو',
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (i < exercise.exercises.length - 1)
                            Divider(color: Colors.amber[100], height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProgram(WorkoutProgram program) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDeleteProgramDialog(
        program: program,
        onDelete: () async {
          await _programService.deleteProgram(program.id);
          setState(() {
            _savedPrograms.removeWhere((p) => p.id == program.id);
          });
          if (widget.programId == program.id && context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutProgramBuilderScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _programNameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return 'چند دقیقه پیش';
      }
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    } else {
      return '${(difference.inDays / 365).floor()} سال پیش';
    }
  }

  Widget _buildBottomInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C1810), Color(0xFF3D2317)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.amber[700]!.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.clipboardList,
                        color: Colors.amber[300], size: 16),
                    const SizedBox(width: 3),
                    Text(
                      'تعداد حرکات: ',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _selectedExercises.length.toString(),
                      style: TextStyle(
                        color: Colors.amber[100],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.clock, color: Colors.amber[300], size: 16),
                    const SizedBox(width: 3),
                    Text(
                      'آخرین ویرایش: ',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _selectedExercises.isNotEmpty
                          ? _formatDate(_program.updatedAt)
                          : '-',
                      style: TextStyle(
                        color: Colors.amber[100],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildStepper(
    {required int value,
    required int min,
    required void Function(int) onChanged,
    bool small = false}) {
  final Color primaryColor = Colors.amber[700]!;
  final double iconSize = small ? 14 : 18;
  final double fontSize = small ? 12 : 16;
  final double boxPad = small ? 1 : 6;
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: primaryColor.withOpacity(0.13), width: 1),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.04),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    padding: EdgeInsets.symmetric(horizontal: boxPad, vertical: 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: primaryColor, size: iconSize),
          splashRadius: small ? 13 : 18,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 22, minHeight: 22),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: small ? 2 : 6),
          child: Text(
            value.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: fontSize),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: primaryColor, size: iconSize),
          splashRadius: small ? 13 : 18,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 22, minHeight: 22),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    ),
  );
}
