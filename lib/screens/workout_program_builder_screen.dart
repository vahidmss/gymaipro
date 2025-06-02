import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/workout_program.dart';
import '../models/exercise.dart';
import '../services/workout_program_service.dart';
import '../services/exercise_service.dart';
import '../widgets/workout_program_session_card.dart';
import '../widgets/add_exercise_dialog.dart';

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

      print("تعداد برنامه‌های بارگذاری شده: ${_savedPrograms.length}");

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

  void _addSession() {
    setState(() {
      final newSession = WorkoutSession(
        day: "روز ${_program.sessions.length + 1}",
        exercises: [],
      );
      _program.sessions.add(newSession);
    });
  }

  void _deleteSession(int sessionIndex) {
    setState(() {
      _program.sessions.removeAt(sessionIndex);
    });
  }

  void _renameSession(int sessionIndex, String newName) {
    setState(() {
      _program.sessions[sessionIndex].day = newName;
    });
  }

  void _addExercise(int sessionIndex) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddExerciseDialog(
        exercises: _exercises,
      ),
    );

    if (result != null) {
      setState(() {
        final exercise = result['exercise'] as WorkoutExercise;
        _program.sessions[sessionIndex].exercises.add(exercise);
      });
    }
  }

  void _deleteExercise(int sessionIndex, int exerciseIndex) {
    setState(() {
      _program.sessions[sessionIndex].exercises.removeAt(exerciseIndex);
    });
  }

  void _moveExerciseUp(int sessionIndex, int exerciseIndex) {
    if (exerciseIndex > 0) {
      setState(() {
        final exercise =
            _program.sessions[sessionIndex].exercises.removeAt(exerciseIndex);
        _program.sessions[sessionIndex].exercises
            .insert(exerciseIndex - 1, exercise);
      });
    }
  }

  void _moveExerciseDown(int sessionIndex, int exerciseIndex) {
    if (exerciseIndex < _program.sessions[sessionIndex].exercises.length - 1) {
      setState(() {
        final exercise =
            _program.sessions[sessionIndex].exercises.removeAt(exerciseIndex);
        _program.sessions[sessionIndex].exercises
            .insert(exerciseIndex + 1, exercise);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // مطمئن می‌شویم که جهت راست به چپ است
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.programId != null
              ? 'ویرایش برنامه تمرینی'
              : 'ایجاد برنامه تمرینی'),
          actions: [
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ))
                      : const Icon(LucideIcons.save),
                  label: Text(_isSaving ? 'در حال ذخیره...' : 'ذخیره'),
                  onPressed: _isSaving ? null : _saveProgram,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
          ],
          // دکمه منو در سمت راست (که با توجه به راست‌چین بودن، سمت راست قرار می‌گیرد)
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState!.openDrawer();
            },
          ),
        ),
        // استفاده از drawer به جای endDrawer برای دراور راست به چپ با توجه به تنظیم Directionality به rtl
        drawer: _buildProgramsDrawer(),
        // تنظیم عرض ناحیه کشیدن از لبه صفحه
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
        drawerEnableOpenDragGesture: true,
        endDrawerEnableOpenDragGesture: false, // غیرفعال کردن کشیدن از سمت چپ
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildProgramsDrawer() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'برنامه‌های تمرینی',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'برنامه دلخواه خود را انتخاب کنید',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.plusCircle),
                    title: const Text('برنامه جدید'),
                    onTap: _createNewProgram,
                  ),
                  const Divider(),
                  if (_isLoading)
                    const ListTile(
                      leading: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      title: Text('در حال بارگذاری برنامه‌ها...'),
                    )
                  else if (_savedPrograms.isEmpty)
                    const ListTile(
                      title: Text(
                        'هنوز برنامه‌ای ذخیره نشده است',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    )
                  else
                    ..._savedPrograms.map((program) => ListTile(
                          leading: const Icon(LucideIcons.dumbbell),
                          title: Text(program.name),
                          subtitle: Text(
                            '${program.sessions.length} سشن | ${_formatDate(program.updatedAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: widget.programId == program.id,
                          onTap: () => _loadProgram(program.id),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.edit,
                                    size: 18, color: Colors.blue),
                                onPressed: () => _loadProgram(program.id),
                                tooltip: 'ویرایش',
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2,
                                    size: 18, color: Colors.red),
                                onPressed: () => _confirmDeleteProgram(program),
                                tooltip: 'حذف',
                              ),
                            ],
                          ),
                        )),
                ],
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
      builder: (context) => AlertDialog(
        title: const Text('حذف برنامه'),
        content: Text('آیا از حذف برنامه "${program.name}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                // نمایش دیالوگ در حال بارگذاری
                if (context.mounted) {
                  Navigator.pop(context); // بستن دیالوگ تایید

                  // نشان دادن دیالوگ در حال بارگذاری
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('در حال حذف برنامه...'),
                          ],
                        ),
                      );
                    },
                  );
                }

                // چاپ اطلاعات برنامه قبل از حذف
                print('تلاش برای حذف برنامه:');
                print('شناسه: ${program.id}');
                print('نام: ${program.name}');
                print('تعداد سشن‌ها: ${program.sessions.length}');

                bool success = false;

                try {
                  // تلاش برای حذف برنامه از طریق سرویس
                  success = await _programService.deleteProgram(program.id);
                } catch (deleteError) {
                  print('خطا در حذف برنامه از دیتابیس: $deleteError');
                  print('تلاش برای حذف حداقل از کش محلی...');

                  // اگر برنامه فقط در کش محلی وجود دارد، آن را از کش پاک کن
                  setState(() {
                    _savedPrograms.removeWhere((p) => p.id == program.id);
                  });
                  success = true;
                }

                // بستن دیالوگ در حال بارگذاری
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                // بروزرسانی UI
                setState(() {
                  _savedPrograms.removeWhere((p) => p.id == program.id);
                });

                // نمایش پیام موفقیت
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برنامه با موفقیت حذف شد')),
                  );
                }

                // اگر برنامه فعلی حذف شد، یک برنامه جدید ایجاد کن
                if (widget.programId == program.id && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutProgramBuilderScreen(),
                    ),
                  );
                }
              } catch (error) {
                // نمایش خطا
                print('خطا در حذف برنامه: $error');

                // بستن دیالوگ در حال بارگذاری اگر هنوز باز است
                if (context.mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطا در حذف برنامه: $error'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'تلاش مجدد',
                        onPressed: () => _confirmDeleteProgram(program),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _programNameController,
            decoration: InputDecoration(
              labelText: 'نام برنامه',
              border: const OutlineInputBorder(),
              hintText: 'نام برنامه تمرینی را وارد کنید',
              prefixIcon: const Icon(LucideIcons.edit),
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.plusCircle, size: 18),
                label: const Text('افزودن سِشن جدید'),
                onPressed: _addSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        _program.sessions.isEmpty
            ? Expanded(child: _buildEmptyState())
            : Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _program.sessions.length,
                  itemBuilder: (context, sessionIndex) {
                    final session = _program.sessions[sessionIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: WorkoutProgramSessionCard(
                        session: session,
                        exercises: _exercises,
                        onAddExercise: () => _addExercise(sessionIndex),
                        onDeleteSession: () => _deleteSession(sessionIndex),
                        onRenameSession: (newName) =>
                            _renameSession(sessionIndex, newName),
                        onDeleteExercise: (exerciseIndex) =>
                            _deleteExercise(sessionIndex, exerciseIndex),
                        onMoveExerciseUp: (exerciseIndex) =>
                            _moveExerciseUp(sessionIndex, exerciseIndex),
                        onMoveExerciseDown: (exerciseIndex) =>
                            _moveExerciseDown(sessionIndex, exerciseIndex),
                        onAddSession: _addSession,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.clipboardList,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'برنامه تمرینی خود را بسازید',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'برای شروع، یک سشن تمرینی اضافه کنید',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.plusCircle),
              label: const Text('افزودن سِشن جدید'),
              onPressed: _addSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
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
}
