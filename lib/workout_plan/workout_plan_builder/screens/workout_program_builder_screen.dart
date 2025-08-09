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
import '../widgets/workout_program_app_bar.dart';
import '../widgets/exercise_card.dart';
import '../widgets/day_selector.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/bottom_info_bar.dart';
import 'package:gymaipro/utils/safe_set_state.dart';

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

  final TextEditingController _programNameController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Getter for current session's exercises
  List<WorkoutExercise> get _selectedExercises =>
      _program.sessions[_selectedDay].exercises;

  // Setter for current session's exercises
  set _selectedExercises(List<WorkoutExercise> exercises) {
    _program.sessions[_selectedDay].exercises = exercises;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SafeSetState.call(this, () {
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

      if (!mounted) return;
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری: $e')),
      );
      SafeSetState.call(this, () {
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
    Navigator.push(
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutProgramBuilderScreen(),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: WorkoutProgramAppBar(
            programId: widget.programId,
            isSaving: _isSaving,
            onSave: _saveProgram,
            onMenuPressed: () =>
                SafeSetState.call(this, () => _showDrawer = true),
          ),
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
          // Add drawer overlay
          body: Stack(
            children: [
              SizedBox.expand(
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
                            labelStyle: TextStyle(
                                color: Colors.amber[300], fontSize: 14),
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
                    DaySelector(
                      selectedDay: _selectedDay,
                      onDayChanged: (day) =>
                          SafeSetState.call(this, () => _selectedDay = day),
                    ),
                    const SizedBox(height: 4),
                    // لیست تمرین‌ها (اسکرول فقط روی این بخش)
                    Expanded(
                      child: _selectedExercises.isEmpty
                          ? const EmptyStateWidget()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _selectedExercises.length,
                              itemBuilder: (context, exerciseIndex) => Padding(
                                key: ValueKey('exercise_$exerciseIndex'),
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: ExerciseCard(
                                  exercise: _selectedExercises[exerciseIndex],
                                  exerciseDetails: _exercises.firstWhere(
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
                                  index: exerciseIndex,
                                  totalExercises: _selectedExercises.length,
                                  onDelete: () =>
                                      _deleteExercise(exerciseIndex),
                                  onMoveUp: exerciseIndex > 0
                                      ? () => _moveExerciseUp(exerciseIndex)
                                      : null,
                                  onMoveDown: exerciseIndex <
                                          _selectedExercises.length - 1
                                      ? () => _moveExerciseDown(exerciseIndex)
                                      : null,
                                  onNoteChanged: (note) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is NormalExercise) {
                                        (_selectedExercises[exerciseIndex]
                                                as NormalExercise)
                                            .note = note;
                                      } else if (_selectedExercises[
                                          exerciseIndex] is SupersetExercise) {
                                        (_selectedExercises[exerciseIndex]
                                                as SupersetExercise)
                                            .note = note;
                                      }
                                    });
                                  },
                                  onStyleChanged: (style) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is NormalExercise) {
                                        (_selectedExercises[exerciseIndex]
                                                as NormalExercise)
                                            .style = style;
                                        // Update sets based on new style
                                        for (final set in (_selectedExercises[
                                                    exerciseIndex]
                                                as NormalExercise)
                                            .sets) {
                                          if (style == ExerciseStyle.setsReps) {
                                            set.reps = set.reps ?? 10;
                                            set.timeSeconds = null;
                                          } else {
                                            set.timeSeconds =
                                                set.timeSeconds ?? 30;
                                            set.reps = null;
                                          }
                                        }
                                      }
                                    });
                                  },
                                  onSetsChanged: (sets) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is NormalExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as NormalExercise;
                                        final current = exercise.sets.length;
                                        if (sets > current) {
                                          for (int i = 0;
                                              i < sets - current;
                                              i++) {
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
                                                      ? exercise
                                                          .sets[0].timeSeconds
                                                      : 30)
                                                  : null,
                                              weight: exercise.sets.isNotEmpty
                                                  ? exercise.sets[0].weight
                                                  : 0,
                                            ));
                                          }
                                        } else if (sets < current) {
                                          exercise.sets
                                              .removeRange(sets, current);
                                        }
                                      }
                                    });
                                  },
                                  onRepsChanged: (reps) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is NormalExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as NormalExercise;
                                        for (final set in exercise.sets) {
                                          set.reps = reps;
                                        }
                                      }
                                    });
                                  },
                                  onTimeChanged: (time) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is NormalExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as NormalExercise;
                                        for (final set in exercise.sets) {
                                          set.timeSeconds = time;
                                        }
                                      }
                                    });
                                  },
                                  onWeightChanged: (weight) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is NormalExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as NormalExercise;
                                        for (final set in exercise.sets) {
                                          set.weight = weight;
                                        }
                                      }
                                    });
                                  },
                                  onSupersetStyleChanged:
                                      (supersetExerciseIndex, style) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is SupersetExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as SupersetExercise;
                                        if (supersetExerciseIndex <
                                            exercise.exercises.length) {
                                          exercise
                                              .exercises[supersetExerciseIndex]
                                              .style = style;
                                          // Update sets based on new style
                                          for (final set in exercise
                                              .exercises[supersetExerciseIndex]
                                              .sets) {
                                            if (style ==
                                                ExerciseStyle.setsReps) {
                                              set.reps = set.reps ?? 10;
                                              set.timeSeconds = null;
                                            } else {
                                              set.timeSeconds =
                                                  set.timeSeconds ?? 30;
                                              set.reps = null;
                                            }
                                          }
                                        }
                                      }
                                    });
                                  },
                                  onSupersetSetsChanged:
                                      (supersetExerciseIndex, sets) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is SupersetExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as SupersetExercise;
                                        if (supersetExerciseIndex <
                                            exercise.exercises.length) {
                                          final supersetItem = exercise
                                              .exercises[supersetExerciseIndex];
                                          final current =
                                              supersetItem.sets.length;
                                          if (sets > current) {
                                            for (int i = 0;
                                                i < sets - current;
                                                i++) {
                                              supersetItem.sets.add(ExerciseSet(
                                                reps: supersetItem.style ==
                                                        ExerciseStyle.setsReps
                                                    ? (supersetItem
                                                            .sets.isNotEmpty
                                                        ? supersetItem
                                                            .sets[0].reps
                                                        : 10)
                                                    : null,
                                                timeSeconds: supersetItem
                                                            .style ==
                                                        ExerciseStyle.setsTime
                                                    ? (supersetItem
                                                            .sets.isNotEmpty
                                                        ? supersetItem
                                                            .sets[0].timeSeconds
                                                        : 30)
                                                    : null,
                                                weight:
                                                    supersetItem.sets.isNotEmpty
                                                        ? supersetItem
                                                            .sets[0].weight
                                                        : 0,
                                              ));
                                            }
                                          } else if (sets < current) {
                                            supersetItem.sets
                                                .removeRange(sets, current);
                                          }
                                        }
                                      }
                                    });
                                  },
                                  onSupersetRepsChanged:
                                      (supersetExerciseIndex, reps) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is SupersetExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as SupersetExercise;
                                        if (supersetExerciseIndex <
                                            exercise.exercises.length) {
                                          final supersetItem = exercise
                                              .exercises[supersetExerciseIndex];
                                          for (final set in supersetItem.sets) {
                                            set.reps = reps;
                                          }
                                        }
                                      }
                                    });
                                  },
                                  onSupersetTimeChanged:
                                      (supersetExerciseIndex, time) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is SupersetExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as SupersetExercise;
                                        if (supersetExerciseIndex <
                                            exercise.exercises.length) {
                                          final supersetItem = exercise
                                              .exercises[supersetExerciseIndex];
                                          for (final set in supersetItem.sets) {
                                            set.timeSeconds = time;
                                          }
                                        }
                                      }
                                    });
                                  },
                                  allExercises: _exercises,
                                ),
                              ),
                            ),
                    ),
                    // Bottom Info Bar
                    BottomInfoBar(
                      exerciseCount: _selectedExercises.length,
                      updatedAt: _program.updatedAt,
                    ),
                  ],
                ),
              ),
              // Drawer overlay
              if (_showDrawer)
                SavedProgramsDrawer(
                  savedPrograms: _savedPrograms,
                  isLoading: _isLoading,
                  onSelect: _loadProgram,
                  onCreateNew: _createNewProgram,
                  onClose: () =>
                      SafeSetState.call(this, () => _showDrawer = false),
                ),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    _programNameController.dispose();
    super.dispose();
  }
}
