// این فایل کاملاً ماژولار است. تمام دیالوگ‌ها، ویجت‌ها و سرویس‌های قابل استفاده مجدد در فولدرهای جدا قرار دارند. از افزودن کد تکراری یا لاگ بی‌دلیل خودداری کنید. برای توسعه، فقط منطق UI و تعاملات را اینجا نگه دارید و بقیه را جدا کنید.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/dialogs/add_exercise_dialog.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/services/workout_program_service.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/bottom_info_bar.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/day_selector.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/empty_state_widget.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/exercise_card.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/saved_programs_drawer.dart';
import 'package:gymaipro/workout_plan/workout_plan_builder/widgets/workout_program_app_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutProgramBuilderScreen extends StatefulWidget {
  // اتصال مستقیم به تراکنش پرداخت

  const WorkoutProgramBuilderScreen({
    super.key,
    this.programId,
    this.targetUserId,
    this.targetUserName,
    this.subscriptionId,
    this.paymentTransactionId,
  });
  final String? programId;
  final String? targetUserId;
  final String? targetUserName;
  final String? subscriptionId; // اتصال مستقیم به اشتراک
  final String? paymentTransactionId;

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

  // Getter for current session's exercises - used throughout the class
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

      // فقط برنامه‌هایی که مربی فعلی آنها را ساخته (trainer_id = current user)
      final currentTrainerId = Supabase.instance.client.auth.currentUser?.id;
      if (currentTrainerId != null && currentTrainerId.isNotEmpty) {
        _savedPrograms = await _programService.getProgramsCreatedByTrainer(
          currentTrainerId,
        );
      } else {
        _savedPrograms = [];
      }

      if (widget.programId != null) {
        // Load existing program
        final program = await _programService.getProgramById(widget.programId!);
        if (program != null) {
          _program = program;
          _programNameController.text = program.name;
        } else {
          // If program not found, create a new one
          _program = WorkoutProgram.empty();
          _programNameController.clear(); // Clear controller for new program
        }
      } else {
        // Create a new program
        _program = WorkoutProgram.empty();
        _programNameController.clear(); // Clear controller for new program
      }

      if (!mounted) return;
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در بارگذاری: $e')));
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

    // Prevent save if trainer-authored and edit window expired
    final isTrainerAuthored =
        _program.trainerId != null && _program.trainerId!.isNotEmpty;
    if (isTrainerAuthored) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final c = _program.createdAt;
      final createdDay = DateTime(c.year, c.month, c.day);
      final remaining = 3 - today.difference(createdDay).inDays;
      if (remaining <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مهلت ویرایش این برنامه به پایان رسیده است'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // اطمینان از به‌روزرسانی نام برنامه از TextEditingController و افزودن پسوند نام کاربر هدف برای یکتا شدن
      final baseName = _programNameController.text.trim();
      final suffix = widget.targetUserName != null
          ? ' (${widget.targetUserName})'
          : '';
      _program.name = baseName + suffix;

      // ذخیره برنامه جدید یا به‌روزرسانی برنامه موجود
      if (_program.id.isNotEmpty &&
          _savedPrograms.any((p) => p.id == _program.id)) {
        // به‌روزرسانی برنامه موجود
        final updatedProgram = await _programService.updateProgram(_program);
        _program = updatedProgram;
      } else {
        // ایجاد یک برنامه جدید
        final newProgram = await _programService.createProgram(
          _program,
          trainerId: Supabase.instance.client.auth.currentUser?.id,
          targetUserId: widget.targetUserId,
          subscriptionId: widget.subscriptionId,
          paymentTransactionId: widget.paymentTransactionId,
        );
        _program = newProgram;
      }

      // بارگیری مجدد برنامه‌های ذخیره شده از Supabase
      _savedPrograms = await _programService.getPrograms();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برنامه با موفقیت ذخیره شد')),
        );

        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ذخیره برنامه: $e')));

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _addExercise() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddExerciseDialog(exercises: _exercises),
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
    // Close drawer overlay and navigate to the selected program for editing
    SafeSetState.call(this, () => _showDrawer = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (context) => WorkoutProgramBuilderScreen(programId: programId),
      ),
    );
  }

  void _createNewProgram() {
    // Close drawer
    NavigationService.safePop(context);

    // Navigate to create a new program
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutProgramBuilderScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: WorkoutProgramAppBar(
          programId: widget.programId,
          isSaving: _isSaving,
          onSave: _saveProgram,
          onMenuPressed: () =>
              SafeSetState.call(this, () => _showDrawer = true),
        ),
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
        endDrawerEnableOpenDragGesture: false,
        floatingActionButton: Container(
          margin: EdgeInsets.only(bottom: 60.h),
          child: DecoratedBox(
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
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber[700]!.withValues(alpha: 0.4),
                  blurRadius: 12.r,
                  offset: Offset(0, 6.h),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8.r,
                  offset: Offset(0, 3.h),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _addExercise,
              backgroundColor: Colors.transparent,
              elevation: 0,
              tooltip: 'افزودن حرکت',
              child: Icon(
                LucideIcons.plus,
                color: const Color(0xFF1A1A1A),
                size: 28.sp,
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
                  // اطلاع ساخت برای کاربر هدف
                  if (widget.targetUserId != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF143C1D),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: const Color(0xFF2E7D32)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              color: Colors.white70,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'در حال ساخت برنامه برای ${widget.targetUserName ?? 'کاربر'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // بخش بالایی (نام برنامه و انتخاب روز)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0A0A0A),
                            Color(0xFF1A1A1A),
                            Color(0xFF2A2A2A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          width: 1.5.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20.r,
                            offset: Offset(0.w, 4.h),
                          ),
                          BoxShadow(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.1),
                            blurRadius: 10.r,
                            offset: Offset(0.w, 2.h),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _programNameController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'نام برنامه تمرینی خود را وارد کنید...',
                          hintStyle: TextStyle(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.6),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          labelText: 'نام برنامه',
                          labelStyle: TextStyle(
                            color: const Color(0xFFD4AF37),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: const Color(0xFFD4AF37),
                              width: 2.w,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DaySelector(
                    selectedDay: _selectedDay,
                    onDayChanged: (day) =>
                        SafeSetState.call(this, () => _selectedDay = day),
                    currentSession: _program.sessions[_selectedDay],
                    onNotesChanged: _updateSessionNotes,
                  ),
                  const SizedBox(height: 4),
                  // لیست تمرین‌ها (اسکرول فقط روی این بخش)
                  Expanded(
                    child: _selectedExercises.isEmpty
                        ? const EmptyStateWidget()
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            itemCount: _selectedExercises.length,
                            itemBuilder: (context, exerciseIndex) => Padding(
                              key: ValueKey('exercise_$exerciseIndex'),
                              padding: const EdgeInsets.only(bottom: 16),
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
                                onDelete: () => _deleteExercise(exerciseIndex),
                                onMoveUp: exerciseIndex > 0
                                    ? () => _moveExerciseUp(exerciseIndex)
                                    : null,
                                onMoveDown:
                                    exerciseIndex <
                                        _selectedExercises.length - 1
                                    ? () => _moveExerciseDown(exerciseIndex)
                                    : null,
                                onNoteChanged: (note) {
                                  setState(() {
                                    if (_selectedExercises[exerciseIndex]
                                        is NormalExercise) {
                                      (_selectedExercises[exerciseIndex]
                                                  as NormalExercise)
                                              .note =
                                          note;
                                    } else if (_selectedExercises[exerciseIndex]
                                        is SupersetExercise) {
                                      (_selectedExercises[exerciseIndex]
                                                  as SupersetExercise)
                                              .note =
                                          note;
                                    }
                                  });
                                },
                                onStyleChanged: (style) {
                                  setState(() {
                                    if (_selectedExercises[exerciseIndex]
                                        is NormalExercise) {
                                      (_selectedExercises[exerciseIndex]
                                                  as NormalExercise)
                                              .style =
                                          style;
                                      // Update sets based on new style
                                      for (final set
                                          in (_selectedExercises[exerciseIndex]
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
                                        for (
                                          int i = 0;
                                          i < sets - current;
                                          i++
                                        ) {
                                          exercise.sets.add(
                                            ExerciseSet(
                                              reps:
                                                  exercise.style ==
                                                      ExerciseStyle.setsReps
                                                  ? (exercise.sets.isNotEmpty
                                                        ? exercise.sets[0].reps
                                                        : 10)
                                                  : null,
                                              timeSeconds:
                                                  exercise.style ==
                                                      ExerciseStyle.setsTime
                                                  ? (exercise.sets.isNotEmpty
                                                        ? exercise
                                                              .sets[0]
                                                              .timeSeconds
                                                        : 30)
                                                  : null,
                                              weight: exercise.sets.isNotEmpty
                                                  ? exercise.sets[0].weight
                                                  : 0,
                                            ),
                                          );
                                        }
                                      } else if (sets < current) {
                                        exercise.sets.removeRange(
                                          sets,
                                          current,
                                        );
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
                                onSupersetStyleChanged: (supersetExerciseIndex, style) {
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
                                                .style =
                                            style;
                                        // Update sets based on new style
                                        for (final set
                                            in exercise
                                                .exercises[supersetExerciseIndex]
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
                                              for (
                                                int i = 0;
                                                i < sets - current;
                                                i++
                                              ) {
                                                supersetItem.sets.add(
                                                  ExerciseSet(
                                                    reps:
                                                        supersetItem.style ==
                                                            ExerciseStyle
                                                                .setsReps
                                                        ? (supersetItem
                                                                  .sets
                                                                  .isNotEmpty
                                                              ? supersetItem
                                                                    .sets[0]
                                                                    .reps
                                                              : 10)
                                                        : null,
                                                    timeSeconds:
                                                        supersetItem.style ==
                                                            ExerciseStyle
                                                                .setsTime
                                                        ? (supersetItem
                                                                  .sets
                                                                  .isNotEmpty
                                                              ? supersetItem
                                                                    .sets[0]
                                                                    .timeSeconds
                                                              : 30)
                                                        : null,
                                                    weight:
                                                        supersetItem
                                                            .sets
                                                            .isNotEmpty
                                                        ? supersetItem
                                                              .sets[0]
                                                              .weight
                                                        : 0,
                                                  ),
                                                );
                                              }
                                            } else if (sets < current) {
                                              supersetItem.sets.removeRange(
                                                sets,
                                                current,
                                              );
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
                                            for (final set
                                                in supersetItem.sets) {
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
                                            for (final set
                                                in supersetItem.sets) {
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
      ),
    );
  }

  // Update session notes
  Future<void> _updateSessionNotes(String notes) async {
    // Update in memory first
    SafeSetState.call(this, () {
      _program.sessions[_selectedDay] = _program.sessions[_selectedDay]
          .copyWith(notes: notes.isEmpty ? null : notes);
      _program = _program.copyWith(updatedAt: DateTime.now());
    });

    // Save to database
    try {
      await _programService.updateProgram(_program);
      print('توضیحات روز ${_selectedDay + 1} با موفقیت ذخیره شد');

      // Reload program from database to ensure consistency
      final updatedProgram = await _programService.getProgramById(_program.id);
      if (updatedProgram != null) {
        SafeSetState.call(this, () {
          _program = updatedProgram;
        });
        print('برنامه از دیتابیس بارگذاری شد');
      }
    } catch (e) {
      print('خطا در ذخیره توضیحات: $e');
    }
  }

  @override
  void dispose() {
    _programNameController.dispose();
    super.dispose();
  }
}
