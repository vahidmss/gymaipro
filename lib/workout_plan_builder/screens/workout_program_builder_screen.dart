// ??? ???? ?????? ??????? ???. ???? ?????????? ??????? ? ????????? ???? ??????? ???? ?? ???????? ??? ???? ?????. ?? ?????? ?? ?????? ?? ??? ??????? ??????? ????. ???? ?????? ??? ???? UI ? ??????? ?? ????? ??? ????? ? ???? ?? ??? ????.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/exercise_service.dart';
import 'package:gymaipro/services/navigation_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:gymaipro/utils/date_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/workout_plan_builder/screens/add_exercise_screen.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:gymaipro/workout_plan_builder/services/workout_program_service.dart';
import 'package:gymaipro/workout_plan_builder/widgets/bottom_info_bar.dart';
import 'package:gymaipro/workout_plan_builder/widgets/day_selector.dart';
import 'package:gymaipro/workout_plan_builder/widgets/exercise_card.dart';
import 'package:gymaipro/workout_plan_builder/widgets/saved_programs_drawer.dart';
import 'package:gymaipro/workout_plan_builder/widgets/workout_program_app_bar.dart';
import 'package:gymaipro/meal_plan_builder/screens/user_details_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class WorkoutProgramBuilderScreen extends StatefulWidget {
  // ????? ?????? ?? ?????? ??????

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
  final String? subscriptionId; // ????? ?????? ?? ??????
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
  bool _isAutoSaving = false;
  List<Exercise> _exercises = [];
  List<WorkoutProgram> _savedPrograms = [];
  bool _showDrawer = false;
  int _selectedDay = 0;
  String? _targetUserName; // ??? ????? ??? ???? ???? ??? ??????
  DateTime? _editableUntil; // ????? ????? ???? ??????

  // Getter for current session's exercises - used throughout the class
  // Getter for current session's exercises
  List<WorkoutExercise> get _selectedExercises =>
      _program.sessions[_selectedDay].exercises;


  @override
  void initState() {
    super.initState();
    // ???????? ?? ???? ???? ?? ???????? ??? ??
    // ?? ???? ????? ???? ?????? ?? ??????? ?? ????? ????.
    unawaited(_warmUpExercisesInBackground());
    _loadData();
  }

  Future<void> _loadData() async {
    SafeSetState.call(this, () {
      _isLoading = true;
    });

    try {
      // ??????? ?? ????? ????? ????????? ???????? ????? ??? ???
      await _programService.init();

      // cache ???? disk ?? ????????? warm-up ??????? ?? initState ????? ???? ???.
      final cachedExercises = await _exerciseService.getExercisesFromCache();
      if (cachedExercises != null && cachedExercises.isNotEmpty) {
        _exercises = cachedExercises;
      }

      // ??? ??????????? ?? ???? ???? ???? ?? ????? (trainer_id = current user)
      final currentTrainerId = Supabase.instance.client.auth.currentUser?.id;
      if (currentTrainerId != null && currentTrainerId.isNotEmpty) {
        _savedPrograms = await _programService.getProgramsCreatedByTrainer(
          currentTrainerId,
        );
      } else {
        _savedPrograms = [];
      }

      final user = Supabase.instance.client.auth.currentUser;
      final userId = widget.targetUserId ?? user?.id ?? '';

      // ????? ?????? ???? ?? ???????? ?? (??? ???? ????? ????)
      // ??? ???? ??? ?? ???????? ?? ??????? ????? ???
      if (widget.targetUserId != null && user != null) {
        final loadedFromLocal = await _loadProgramLocally();
        // ??? ?????? ???? ?????? ???????? ??? ?? ????? ??????? ??
        if (loadedFromLocal) {
          print('? ?????? ?? ????? ???? ???????? ?? - ?? ???????? ??????? ??????? ??????');
          if (!mounted) return;
          SafeSetState.call(this, () {
            _isLoading = false;
          });
          return;
        }
      }

      // ??? programId ???? ??? ????? ?????? ?? ?? ID ???????? ??
      if (widget.programId != null && widget.programId!.isNotEmpty) {
        final program = await _programService.getProgramById(widget.programId!);
        if (program != null) {
          _program = program;
          // ??? ??? ?????? ????? ??? ????? editable_until ?? ????
          if (widget.targetUserId != null && program.sentAt != null) {
            await _loadEditableUntil();
          }
        } else {
          // ??? ?????? ???? ???? ?????? ???? ????
          final programName = await _generatePlanName();
          _program = WorkoutProgram.empty().copyWith(
            name: programName,
            userId: userId,
          );
        }
      } else if (widget.targetUserId != null && user != null) {
        // ??? ???? ???? ????? ????? ?????? ???????? ????? ?? ??? ?????? ?????? ???? ????
        final existingPrograms = await _programService
            .getProgramsForUserByTrainer(widget.targetUserId!, user.id);

        if (existingPrograms.isNotEmpty) {
          // ?????? ????? ?? ???????? ?? (????? ??????)
          SafeSetState.call(this, () {
            _program = existingPrograms.first;
          });
          // ??? ??? ?????? ????? ??? ????? editable_until ?? ????
          if (_program.sentAt != null) {
            print('?? ?????? ????? ???????? ??? ?? ??? ?????? editable_until...');
            await _loadEditableUntil();
          }
        } else {
          // ?????? ???? ???? ?? ??? ??????
          final programName = await _generatePlanName();
          _program = WorkoutProgram.empty().copyWith(
            name: programName,
            userId: userId,
          );
        }
      } else {
        // ???? ????: ????? ???? ???? ?????? ???????
        if (_program.name.isEmpty) {
          final programName = await _generatePlanName();
          _program = WorkoutProgram.empty().copyWith(
            name: programName,
            userId: userId,
          );
        }
      }

      if (!mounted) return;
      SafeSetState.call(this, () {
        _isLoading = false;
      });
      
      // ??? ?????? ?? ??????? ???????? ?? ? ???? ????? ????? ?? ?? ???? ????? ??
      if (widget.targetUserId != null && _program.sentAt == null) {
        await _saveProgramLocally();
      }
    } catch (e) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        '??? ?? ????????: $e',
      );
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    }
  }

  Future<void> _warmUpExercisesInBackground() async {
    try {
      final freshExercises = await _exerciseService.getExercises();
      if (!mounted || freshExercises.isEmpty) return;
      WidgetSafetyUtils.safeSetState(this, () {
        _exercises = freshExercises;
      });
    } catch (_) {
      // Non-blocking warmup; ignore failures here.
    }
  }

  // ???? ?????? ??? ??????: "?????? ??????-??? ?????-?????"
  Future<String> _generatePlanName() async {
    final dateStr = toJalali(DateTime.now());
    
    if (widget.targetUserId == null) {
      return '?????? ??????-$dateStr';
    }

    try {
      final userProfile = await UserProfileService.fetchProfile(
        widget.targetUserId!,
      );
      if (userProfile != null) {
        final firstName = userProfile['first_name']?.toString() ?? '';
        final lastName = userProfile['last_name']?.toString() ?? '';
        final userName = '$firstName $lastName'.trim();

        if (userName.isNotEmpty) {
          _targetUserName = userName;
          return '?????? ??????-$userName-$dateStr';
        }
      }
    } catch (e) {
      print('??? ?? ?????? ??????? ????? ???? ???? ???: $e');
    }

    // ?? ???? ???? ?? ??? ????? ?? widget ??????? ??
    final userName = widget.targetUserName ?? '?????';
    _targetUserName = userName;
    return '?????? ??????-$userName-$dateStr';
  }

  // ?????? editable_until ?? ???????
  Future<void> _loadEditableUntil() async {
    if (_program.id.isEmpty || widget.targetUserId == null) {
      print(
        '?? _loadEditableUntil: ?????? ID ???? ??? ?? targetUserId null ???',
      );
      SafeSetState.call(this, () {
        _editableUntil = null;
      });
      return;
    }

    try {
      final client = Supabase.instance.client;
      print('?? ?? ??? ?????? editable_until ???? ??????: ${_program.id}');
      final planData = await client
          .from('workout_programs')
          .select('editable_until, sent_at')
          .eq('id', _program.id)
          .maybeSingle();

      print('?? ???????? ?????? ???: $planData');

      // ??? ??? ?????? ????? ??? ???? (sent_at != null)? editable_until ?? ????
      if (planData == null || planData['sent_at'] == null) {
        print('?? ?????? ???? ????? ???? ???. editable_until ????? ???????.');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
        return;
      }

      // editable_until ? expiry_date ??? ??? ?? ????? ?????? (sendProgram) ??? ???????
      // ?? ????? ?? ???? ??? ???? ????? ????? ??? ?????? null ?????
      if (planData['editable_until'] != null) {
        final editableUntilStr = planData['editable_until'] as String;
        print('? editable_until ???? ??: $editableUntilStr');
        SafeSetState.call(this, () {
          _editableUntil = DateTime.parse(editableUntilStr);
          print('? _editableUntil ????? ??: $_editableUntil');
        });
      } else {
        // ??? ?????? ???? ????? ???? (sent_at == null)? editable_until ?? null ???
        print('?? ?????? ???? ????? ???? ??? (editable_until null)');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      }
    } catch (e) {
      // ??? ???? editable_until ???? ?????? ??? ?? gracefully handle ???????
      final errorStr = e.toString();
      if (errorStr.contains('editable_until') ||
          errorStr.contains('does not exist') ||
          errorStr.contains('42703')) {
        print('?? ???? editable_until ?? ??????? ???? ?????.');
        print(
          '?? ????? ???? SQL ?? ???? ????: sql/add_expiry_and_editable_to_workout_programs.sql',
        );
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      } else {
        print('? ??? ?? ?????? editable_until: $e');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      }
    }
  }

  // ?????? ???????? ????????? ?? editable_until
  int? _getRemainingHours() {
    if (_editableUntil == null) {
      print('?? _getRemainingHours: _editableUntil null ???');
      return null;
    }
    final now = DateTime.now();
    if (now.isAfter(_editableUntil!)) {
      print('? ???? ?????? ?? ????? ????? ???');
      return 0;
    }
    final difference = _editableUntil!.difference(now);
    // ?????? ???? ???????: ??? ???????? ???? (???? ??? ????)
    final hours = difference.inHours;
    print(
      '? ???????? ?????????: $hours (?? ${difference.inDays} ??? ? ${difference.inHours % 24} ????)',
    );
    return hours;
  }

  // ????? ?????? ????? ????? ??????
  Future<void> _showConfirmDialog() async {
    final userName = _targetUserName ?? widget.targetUserName ?? '?????';
    final confirmed = await WidgetSafetyUtils.safeShowDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? context.backgroundColor
              : context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
          ),
          title: Text(
            '????? ????? ??????',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.goldColor
                  : context.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '????? ????? ????????? ?????? ???? ????? $userName ??????? ????\n\n?? ??? ??? ????? ?? ??? 3 ??? ??? ?????? ?????? ? ????? ????? ?? ?? ?????.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.goldColor.withValues(alpha: 0.9)
                  : context.textColor.withValues(alpha: 0.9),
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => WidgetSafetyUtils.safePop(context, false),
              style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
              child: const Text(
                '??????',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
            ),
            ElevatedButton(
              onPressed: () => WidgetSafetyUtils.safePop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text(
                '????? ? ?????',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed ?? false) {
      // ????? ?????? ?? ?? ??????? ????? ???? (??? ???? ????? ????)
      // ??? ????? ??? ??? ?? ?????? ?? ??????? ??????
      await _saveProgramToDatabase();

      // ??? ????? ?????? (????? sent_at? editable_until ? expiry_date)
      if (_program.id.isNotEmpty) {
        try {
          await _programService.sendProgram(
            _program.id,
            subscriptionId: widget.subscriptionId,
          );
          // ???????? ???? ?????? ???? ?????? sentAt
          final updatedProgram = await _programService.getProgramById(
            _program.id,
          );
          if (updatedProgram != null) {
            SafeSetState.call(this, () {
              _program = updatedProgram;
            });
            // ?????? editable_until ?? ???????
            await _loadEditableUntil();
            
            // ??????????? ???? ?????????? ????? ???
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              final updatedSavedPrograms = await _programService
                  .getProgramsCreatedByTrainer(user.id);
              SafeSetState.call(this, () {
                _savedPrograms = updatedSavedPrograms;
              });
            }
          }
        } catch (e) {
          print('??? ?? ????? ??????: $e');
          if (mounted) {
            WidgetSafetyUtils.safeShowSnackBar(
              context,
              '??? ?? ????? ??????: $e',
            );
          }
          return;
        }
      }

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          '?????? ?? ?????? ????? ??',
        );
        WidgetSafetyUtils.safePop(context);
      }
    }
  }

  // ????? ?????? ?????? (??? ???? - SharedPreferences)
  Future<void> _autoSaveProgram() async {
    if (_isAutoSaving || widget.targetUserId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    SafeSetState.call(this, () => _isAutoSaving = true);

    try {
      // ???? ??? ?????? ??? ???? ?????
      if (_program.name.isEmpty) {
        _program = _program.copyWith(name: await _generatePlanName());
      }

      // ????? ????? ??? ?????? ?? ??????? ????? ??? ??? ?? ??
      final isProgramSaved = _savedPrograms.any((p) => p.id == _program.id);

      // ??? ?????? ????? ????? ??? (sent_at != null)? ???? ?? ??????? ??????????? ???
      if (isProgramSaved && _program.sentAt != null) {
        // ??????????? ?????? ????? ?? ???????
        try {
          final updatedProgram = await _programService.updateProgram(_program);
          SafeSetState.call(this, () {
            _program = updatedProgram;
          });
          // ?????? editable_until
          await _loadEditableUntil();
        } catch (e) {
          // ??? ??????????? ?????? ???? ??? ???? ????? ??
          print('?? ??? ?? ??????????? ???????? ????? ????: $e');
          await _saveProgramLocally();
        }
      } else {
        // ?????? ???? ????? ???? - ??? ???? ????? ??????
        await _saveProgramLocally();
        print('?? ?????? ?? ???? ???? ????? ?? (????? ????)');
      }
    } catch (e) {
      print('??? ?? ????? ?????? ??????: $e');
    } finally {
      SafeSetState.call(this, () => _isAutoSaving = false);
    }
  }

  // ????? ?????? ?? ???? ???? ?? SharedPreferences
  // ??????? ?? ???? ???? ?? ???? targetUserId ? trainerId ???? ??????? ?? ??????????
  Future<void> _saveProgramLocally() async {
    try {
      if (widget.targetUserId == null) return;
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      // ??????? ?? ???? ???? ?? ???? targetUserId ? trainerId
      final key = 'workout_program_draft_${widget.targetUserId}_${user.id}';
      
      // ??????? ?? ????? ?????? ?? ID ????? ????
      if (_program.id.isEmpty) {
        // ??? ID ???? ???? ?? UUID ???? ????
        final uuid = const Uuid().v4();
        _program = _program.copyWith(id: uuid);
      }
      
      await prefs.setString(key, jsonEncode(_program.toJson()));
      print('?? ?????? ?? ???? ???? ????? ??: $key');
      print('?? Program ID: ${_program.id}');
      print('?? Sessions count: ${_program.sessions.length}');
    } catch (e) {
      print('? ??? ?? ????? ???? ??????: $e');
    }
  }

  // ???????? ?????? ?? SharedPreferences
  // ??????? ?? ???? ???? ?? ???? targetUserId ? trainerId
  Future<bool> _loadProgramLocally() async {
    try {
      if (widget.targetUserId == null) return false;
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      // ??????? ?? ???? ???? ?? ???? targetUserId ? trainerId
      final key = 'workout_program_draft_${widget.targetUserId}_${user.id}';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final localProgram = WorkoutProgram.fromJson(jsonMap);
        
        // ??? ??? ?????? ???? ????? ???? ????? ?? ???? ???? ??????? ??
        if (localProgram.sentAt == null) {
          SafeSetState.call(this, () {
            _program = localProgram;
          });
          print('?? ?????? ?? ????? ???? ???????? ??');
          print('?? Program ID: ${_program.id}');
          print('?? Sessions count: ${_program.sessions.length}');
          return true;
        } else {
          print('?? ?????? ???? ????? ????? ??? ??? - ?? ???? ???? ??????? ???????');
          return false;
        }
      } else {
        print('?? ?????? ???? ???? ???');
        return false;
      }
    } catch (e) {
      print('? ??? ?? ???????? ???? ??????: $e');
      return false;
    }
  }

  // ????? ?????? ?? ??????? (??? ???? ?????)
  Future<void> _saveProgramToDatabase() async {
    // ???? ??? ?????? ??? ???? ?????
    if (_program.name.isEmpty) {
      _program = _program.copyWith(name: await _generatePlanName());
    }

    // Prevent save if trainer-authored and edit window expired
    // ????? ?? ???? editable_until ??? meal plan builder
    if (widget.targetUserId != null && _program.sentAt != null) {
      if (_editableUntil != null) {
        final now = DateTime.now();
        if (now.isAfter(_editableUntil!)) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            '???? ?????? ??? ?????? ?? ????? ????? ???',
          );
          return;
        }
      }
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('????? ???? ????? ???? ???');
      }

      // ????? ????? ??? ?????? ?? ??????? ????? ??? ??? ?? ??
      final isProgramSaved = _savedPrograms.any((p) => p.id == _program.id);

      if (isProgramSaved) {
        // ??????????? ?????? ?????
        final updatedProgram = await _programService.updateProgram(_program);
        SafeSetState.call(this, () {
          _program = updatedProgram;
        });
      } else {
        // ????? ?? ?????? ???? ?? ??????? (?? autoSend=true ???? ????? ?? ???????)
        // ??? ????? ??? ??? ?? ?????? ?? ??????? ?????? (???? ?????)
        final newProgram = await _programService.createProgram(
          _program,
          trainerId: user.id,
          targetUserId: widget.targetUserId,
          subscriptionId: widget.subscriptionId,
          paymentTransactionId: widget.paymentTransactionId,
          autoSend: true, // ???? ????? ?? ??????? (??? sent_at ?? sendProgram ????? ??????)
        );
        SafeSetState.call(this, () {
          _program = newProgram;
        });
        
        // ??????????? ???? ?????????? ????? ???
        final updatedSavedPrograms = await _programService
            .getProgramsCreatedByTrainer(user.id);
        SafeSetState.call(this, () {
          _savedPrograms = updatedSavedPrograms;
        });
      }

    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          '??? ?? ????? ??????: $e',
        );
      }
      rethrow;
    }
  }

  Future<void> _addExercise() async {
    // ???? transitionAnimationController: ??? ?? ??? ?????? ????? ??????? ??
    // ?????? forward ??????? ? ?????/??? ???? ?????? (??????? showModalBottomSheet).
    // ???? ?? ???? await ??? ?? ??? ???? ??? ????? ???????: ??? state ????? ??? ?? ????? ?????.
    final immediateExercises = _exercises.isNotEmpty
        ? _exercises
        : _exerciseService.cachedExercisesSync;

    try {
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.7)
            : AppTheme.lightTextColor.withValues(alpha: 0.5),
        builder: (context) => AddExerciseScreen(
          exercises: immediateExercises,
          onRequestExercises: () async {
            final loaded = await _exerciseService.getExercises();
            if (mounted && loaded.isNotEmpty) {
              WidgetSafetyUtils.safeSetState(this, () {
                _exercises = loaded;
              });
            }
            return loaded;
          },
        ),
      );

      if (result != null && mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          final exercise = result['exercise'] as WorkoutExercise;
          _selectedExercises.add(exercise);
        });
        _autoSaveProgram();
      }
    } catch (_) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        '????? ?? ??? ??? ???? ?????? ???? ?? ???.',
      );
    }
  }

  void _deleteExercise(int exerciseIndex) {
    setState(() {
      _selectedExercises.removeAt(exerciseIndex);
    });
    // ????? ??????
    _autoSaveProgram();
  }

  void _moveExerciseUp(int exerciseIndex) {
    if (exerciseIndex > 0) {
      setState(() {
        final exercise = _selectedExercises.removeAt(exerciseIndex);
        _selectedExercises.insert(exerciseIndex - 1, exercise);
      });
      // ????? ??????
      _autoSaveProgram();
    }
  }

  void _moveExerciseDown(int exerciseIndex) {
    if (exerciseIndex < _selectedExercises.length - 1) {
      setState(() {
        final exercise = _selectedExercises.removeAt(exerciseIndex);
        _selectedExercises.insert(exerciseIndex + 1, exercise);
      });
      // ????? ??????
      _autoSaveProgram();
    }
  }

  void _loadProgram(String programId) {
    // Close drawer overlay and navigate to the selected program for editing
    SafeSetState.call(this, () => _showDrawer = false);
    WidgetSafetyUtils.safeNavigateReplacement(
      context,
      () => WorkoutProgramBuilderScreen(programId: programId),
    );
  }

  void _createNewProgram() {
    // Close drawer
    NavigationService.safePop(context);

    // Navigate to create a new program
    WidgetSafetyUtils.safeNavigate(
      context,
      () => const WorkoutProgramBuilderScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: context.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: isDark
                ? context.backgroundColor
                : Colors.transparent,
            elevation: 0,
          ),
        ),
        child: DecoratedBox(
          decoration: isDark
              ? const BoxDecoration()
              : BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightGradientStart.withValues(alpha: 0.15),
                      AppTheme.lightCardColor,
                      AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: WorkoutProgramAppBar(
              onConfirm: _showConfirmDialog,
              showConfirmButton:
                  widget.targetUserId != null &&
                  _selectedExercises.isNotEmpty &&
                  (_program.sentAt == null),
            ),
            drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
            endDrawerEnableOpenDragGesture: false,
            floatingActionButton: Container(
              margin: EdgeInsets.only(bottom: 60.h),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.goldColor, AppTheme.darkGold],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
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
                  tooltip: '?????? ????',
                  child: Icon(
                    LucideIcons.plus,
                    color: Colors.white,
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
                      // ????? ???? ???? ????? ???
                      if (widget.targetUserId != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Badge ??????? ???? ????? ?????
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(
                                        color: AppTheme.goldColor.withValues(
                                          alpha: isDark ? 0.4 : 0.5,
                                        ),
                                        width: 1.w,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6.w,
                                          height: 6.h,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.goldColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          '?? ??? ???? ?????? ???? ${widget.targetUserName ?? '?????'}',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            color: isDark
                                                ? AppTheme.goldColor
                                                : context.textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11.sp,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // ???? ?????? ?? ???? icon button ???????
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) =>
                                              UserDetailsScreenMealPlanBuilder(
                                            userId: widget.targetUserId!,
                                            userName: widget.targetUserName ??
                                                '?????',
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: AppTheme.goldColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.goldColor
                                                .withValues(
                                                  alpha: isDark ? 0.3 : 0.4,
                                                ),
                                            width: 1.w,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.user,
                                          color: isDark
                                              ? AppTheme.goldColor
                                              : context.textColor,
                                          size: 16.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // ????? ???????? ????????? ??? Badge
                              Builder(
                                builder: (context) {
                                  // ??? ?????? ????? ??? ? editable_until ???? ????
                                  if (_program.sentAt != null &&
                                      _editableUntil != null) {
                                    final remainingHours = _getRemainingHours();
                                    if (remainingHours != null) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          top: 8.h,
                                          right: 0.w,
                                        ),
                                        child: Text(
                                          '?? $remainingHours ???? ???? ???? ?? ?????? ?????? ?????',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            color: isDark
                                                ? AppTheme.goldColor.withValues(
                                                    alpha: 0.7,
                                                  )
                                                : context.textColor.withValues(
                                                    alpha: 0.7,
                                                  ),
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                  // ??? ?????? ????? ??? ??? editable_until ???? ???????? ????
                                  if (_program.sentAt != null &&
                                      _editableUntil == null) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: 8.h,
                                        right: 0.w,
                                      ),
                                      child: Text(
                                        '?? ??? ???????? ???????...',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          color: Colors.orange.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 11.sp,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      // Day selector
                      DaySelector(
                        selectedDay: _selectedDay,
                        onDayChanged: (day) =>
                            SafeSetState.call(this, () => _selectedDay = day),
                        currentSession: _program.sessions[_selectedDay],
                        onNotesChanged: _updateSessionNotes,
                      ),
                      const SizedBox(height: 4),
                      // ???? ???????? (?????? ??? ??? ??? ???)
                      Expanded(
                        child: ListView.builder(
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
                                        name: '???? ${exerciseIndex + 1}',
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
                                      // ????? ??????
                                      _autoSaveProgram();
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
                                      });
                                      // ????? ??????
                                      _autoSaveProgram();
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
                                                      ? (exercise
                                                                .sets
                                                                .isNotEmpty
                                                            ? exercise
                                                                  .sets[0]
                                                                  .reps
                                                            : 10)
                                                      : null,
                                                  timeSeconds:
                                                      exercise.style ==
                                                          ExerciseStyle.setsTime
                                                      ? (exercise
                                                                .sets
                                                                .isNotEmpty
                                                            ? exercise
                                                                  .sets[0]
                                                                  .timeSeconds
                                                            : 30)
                                                      : null,
                                                  weight:
                                                      exercise.sets.isNotEmpty
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
                                      // ????? ??????
                                      _autoSaveProgram();
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
                                      // ????? ??????
                                      _autoSaveProgram();
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
                                      // ????? ??????
                                      _autoSaveProgram();
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
                                      // ????? ??????
                                      _autoSaveProgram();
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
                                      // ????? ??????
                                      _autoSaveProgram();
                                    },
                                    onSupersetSetsChanged: (supersetExerciseIndex, sets) {
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
                                      // ????? ??????
                                      _autoSaveProgram();
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
                                          // ????? ??????
                                          _autoSaveProgram();
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
                                          // ????? ??????
                                          _autoSaveProgram();
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

    // Save to database (??? ??? ?????? ????? ??? ????)
    if (_program.sentAt != null) {
      try {
        final updatedProgram = await _programService.updateProgram(_program);
        SafeSetState.call(this, () {
          _program = updatedProgram;
        });
        print('??????? ??? ${_selectedDay + 1} ?? ?????? ????? ??');
      } catch (e) {
        print('??? ?? ????? ???????: $e');
      }
    } else {
      // ??? ?????? ???? ????? ????? ??? ???? ????? ??
      await _saveProgramLocally();
      print('??????? ??? ${_selectedDay + 1} ?? ???? ???? ????? ??');
    }
  }
}

