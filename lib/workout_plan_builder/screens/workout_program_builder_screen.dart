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
import 'package:gymaipro/workout_plan_builder/widgets/empty_state_widget.dart';
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
  int? _expandedExerciseIndex;
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
        // پیش‌نویس محلی فقط اگر هنوز ارسال نشده؛ بعد با دیتابیس هماهنگ می‌شود
        if (loadedFromLocal) {
          await _reconcileLocalDraftWithRemote();
          await _ensureValidProgramName();
          debugPrint(
            '✅ برنامه از حافظه محلی بارگذاری شد (پس از reconcile با دیتابیس)',
          );
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
            debugPrint(
              '📥 برنامه موجود بارگذاری شد، در حال خواندن editable_until...',
            );
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
      WidgetSafetyUtils.safeShowSnackBar(context, 'خطا در بارگذاری: $e');
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

  bool _hasCorruptedPersianText(String text) {
    return RegExp(r'\?{2,}').hasMatch(text);
  }

  Future<void> _ensureValidProgramName() async {
    if (_program.name.isNotEmpty && !_hasCorruptedPersianText(_program.name)) {
      return;
    }
    final name = await _generatePlanName();
    if (!mounted) return;
    SafeSetState.call(this, () {
      _program = _program.copyWith(name: name);
    });
  }

  // ساخت خودکار نام برنامه: "برنامه تمرینی-نام کاربر-تاریخ"
  Future<String> _generatePlanName() async {
    final dateStr = toJalali(DateTime.now());

    if (widget.targetUserId == null) {
      return 'برنامه تمرینی-$dateStr';
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
          return 'برنامه تمرینی-$userName-$dateStr';
        }
      }
    } catch (e) {
      debugPrint('خطا در دریافت اطلاعات کاربر برای ساخت نام: $e');
    }

    // در صورت خطا، از نام کاربر از widget استفاده کن
    final userName = widget.targetUserName ?? 'کاربر';
    _targetUserName = userName;
    return 'برنامه تمرینی-$userName-$dateStr';
  }

  // ?????? editable_until ?? ???????
  Future<void> _loadEditableUntil() async {
    if (_program.id.isEmpty || widget.targetUserId == null) {
      debugPrint(
        '?? _loadEditableUntil: ?????? ID ???? ??? ?? targetUserId null ???',
      );
      SafeSetState.call(this, () {
        _editableUntil = null;
      });
      return;
    }

    try {
      final client = Supabase.instance.client;
      debugPrint('?? ?? ??? ?????? editable_until ???? ??????: ${_program.id}');
      final planData = await client
          .from('workout_programs')
          .select('editable_until, sent_at')
          .eq('id', _program.id)
          .maybeSingle();

      debugPrint('?? ???????? ?????? ???: $planData');

      // ??? ??? ?????? ????? ??? ???? (sent_at != null)? editable_until ?? ????
      if (planData == null || planData['sent_at'] == null) {
        debugPrint(
          '?? ?????? ???? ????? ???? ???. editable_until ????? ???????.',
        );
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
        return;
      }

      // editable_until ? expiry_date ??? ??? ?? ????? ?????? (sendProgram) ??? ???????
      // ?? ????? ?? ???? ??? ???? ????? ????? ??? ?????? null ?????
      if (planData['editable_until'] != null) {
        final editableUntilStr = planData['editable_until'] as String;
        debugPrint('? editable_until ???? ??: $editableUntilStr');
        SafeSetState.call(this, () {
          _editableUntil = DateTime.parse(editableUntilStr);
          debugPrint('? _editableUntil ????? ??: $_editableUntil');
        });
      } else {
        // ??? ?????? ???? ????? ???? (sent_at == null)? editable_until ?? null ???
        debugPrint('?? ?????? ???? ????? ???? ??? (editable_until null)');
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
        debugPrint('?? ???? editable_until ?? ??????? ???? ?????.');
        debugPrint(
          '?? ????? ???? SQL ?? ???? ????: sql/add_expiry_and_editable_to_workout_programs.sql',
        );
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      } else {
        debugPrint('? ??? ?? ?????? editable_until: $e');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      }
    }
  }

  // ?????? ???????? ????????? ?? editable_until
  int? _getRemainingHours() {
    if (_editableUntil == null) {
      debugPrint('?? _getRemainingHours: _editableUntil null ???');
      return null;
    }
    final now = DateTime.now();
    if (now.isAfter(_editableUntil!)) {
      debugPrint('? ???? ?????? ?? ????? ????? ???');
      return 0;
    }
    final difference = _editableUntil!.difference(now);
    // ?????? ???? ???????: ??? ???????? ???? (???? ??? ????)
    final hours = difference.inHours;
    debugPrint(
      '? ???????? ?????????: $hours (?? ${difference.inDays} ??? ? ${difference.inHours % 24} ????)',
    );
    return hours;
  }

  // ????? ?????? ????? ????? ??????
  Future<void> _showConfirmDialog() async {
    final userName = _targetUserName ?? widget.targetUserName ?? 'کاربر';
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
            'تأیید ارسال برنامه',
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
            'مطمئن هستید می‌خواهید برنامه برای کاربر $userName فرستاده بشه؟\n\nاز ثبت این تاریخ تا مدت 3 روز وقت ویرایش برنامه و تطبیق بیشتر آن را دارید.',
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
                'انصراف',
                style: TextStyle(fontFamily: AppTheme.fontFamily),
              ),
            ),
            ElevatedButton(
              onPressed: () => WidgetSafetyUtils.safePop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text(
                'تأیید و ارسال',
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
      // ابتدا ذخیره در دیتابیس (اگر هنوز فقط پیش‌نویس محلی است)
      await _saveProgramToDatabase();

      // سپس ارسال رسمی (sent_at / editable_until / expiry_date)
      if (_program.id.isNotEmpty) {
        try {
          await _programService.sendProgram(
            _program.id,
            subscriptionId: widget.subscriptionId,
          );
          // بلافاصله وضعیت محلی را به‌روز کن تا دکمه ارسال نماند
          final now = DateTime.now();
          SafeSetState.call(this, () {
            _program = _program.copyWith(sentAt: now);
            _editableUntil = now.add(const Duration(days: 3));
          });

          final updatedProgram = await _programService.getProgramById(
            _program.id,
          );
          if (updatedProgram != null) {
            SafeSetState.call(this, () {
              _program = updatedProgram;
            });
            await _loadEditableUntil();

            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              final updatedSavedPrograms = await _programService
                  .getProgramsCreatedByTrainer(user.id);
              SafeSetState.call(this, () {
                _savedPrograms = updatedSavedPrograms;
              });
            }
          }

          // پیش‌نویس محلی دیگر نباید «ارسال» را برگرداند
          await _clearProgramLocally();
        } catch (e) {
          debugPrint('خطا در ارسال برنامه: $e');
          if (mounted) {
            WidgetSafetyUtils.safeShowSnackBar(
              context,
              'خطا در ارسال برنامه: $e',
            );
          }
          return;
        }
      } else {
        if (mounted) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'برنامه ذخیره نشد؛ ارسال انجام نشد.',
          );
        }
        return;
      }

      if (mounted) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'برنامه با موفقیت ارسال شد',
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
      if (_program.name.isEmpty || _hasCorruptedPersianText(_program.name)) {
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
          debugPrint('?? ??? ?? ??????????? ???????? ????? ????: $e');
          await _saveProgramLocally();
        }
      } else {
        // ?????? ???? ????? ???? - ??? ???? ????? ??????
        await _saveProgramLocally();
        debugPrint('?? ?????? ?? ???? ???? ????? ?? (????? ????)');
      }
    } catch (e) {
      debugPrint('??? ?? ????? ?????? ??????: $e');
    } finally {
      SafeSetState.call(this, () => _isAutoSaving = false);
    }
  }

  // ذخیره برنامه در حافظه محلی با SharedPreferences
  // کلید بر اساس targetUserId و trainerId تا تداخل بین شاگردها پیش نیاید
  Future<void> _saveProgramLocally() async {
    try {
      if (widget.targetUserId == null) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // برنامه ارسال‌شده را به عنوان پیش‌نویس نگه نمی‌داریم
      if (_program.sentAt != null) {
        await _clearProgramLocally();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = 'workout_program_draft_${widget.targetUserId}_${user.id}';

      if (_program.id.isEmpty) {
        final uuid = const Uuid().v4();
        _program = _program.copyWith(id: uuid);
      }

      await prefs.setString(key, jsonEncode(_program.toJson()));
      debugPrint('💾 برنامه در حافظه محلی ذخیره شد: $key');
      debugPrint('📦 Program ID: ${_program.id}');
      debugPrint('📦 Sessions count: ${_program.sessions.length}');
    } catch (e) {
      debugPrint('❌ خطا در ذخیره پیش‌نویس محلی: $e');
    }
  }

  Future<void> _clearProgramLocally() async {
    try {
      if (widget.targetUserId == null) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final prefs = await SharedPreferences.getInstance();
      final key = 'workout_program_draft_${widget.targetUserId}_${user.id}';
      await prefs.remove(key);
      debugPrint('🧹 پیش‌نویس محلی پاک شد: $key');
    } catch (e) {
      debugPrint('❌ خطا در پاک کردن پیش‌نویس محلی: $e');
    }
  }

  /// اگر همان برنامه در دیتابیس قبلاً ارسال شده، پیش‌نویس محلی را دور می‌اندازد.
  Future<void> _reconcileLocalDraftWithRemote() async {
    if (_program.id.isEmpty || widget.targetUserId == null) return;

    try {
      final remote = await _programService.getProgramById(_program.id);
      if (remote != null && remote.sentAt != null) {
        debugPrint(
          '🔁 پیش‌نویس محلی با برنامه ارسال‌شده دیتابیس جایگزین شد',
        );
        SafeSetState.call(this, () {
          _program = remote;
        });
        await _clearProgramLocally();
        await _loadEditableUntil();
        return;
      }

      // اگر id محلی در دیتابیس نیست ولی برای این شاگرد برنامه ارسال‌شده هست
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final existing = await _programService.getProgramsForUserByTrainer(
        widget.targetUserId!,
        user.id,
      );
      final sent = existing.where((p) => p.sentAt != null).toList();
      if (sent.isNotEmpty && remote == null) {
        // پیش‌نویس یتیم؛ جدیدترین ارسال‌شده را بگیر
        debugPrint('🔁 پیش‌نویس یتیم؛ بارگذاری آخرین برنامه ارسال‌شده');
        SafeSetState.call(this, () {
          _program = sent.first;
        });
        await _clearProgramLocally();
        await _loadEditableUntil();
      }
    } catch (e) {
      debugPrint('⚠️ reconcile پیش‌نویس محلی ناموفق: $e');
    }
  }

  // بارگذاری برنامه از SharedPreferences
  Future<bool> _loadProgramLocally() async {
    try {
      if (widget.targetUserId == null) return false;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final key = 'workout_program_draft_${widget.targetUserId}_${user.id}';
      final jsonStr = prefs.getString(key);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final localProgram = WorkoutProgram.fromJson(jsonMap);

        if (localProgram.sentAt == null) {
          var program = localProgram;
          if (program.name.isEmpty ||
              RegExp(r'\?{2,}').hasMatch(program.name)) {
            program = program.copyWith(name: await _generatePlanName());
          }
          SafeSetState.call(this, () {
            _program = program;
          });
          debugPrint('📥 برنامه از حافظه محلی بارگذاری شد');
          debugPrint('📦 Program ID: ${_program.id}');
          debugPrint('📦 Sessions count: ${_program.sessions.length}');
          return true;
        } else {
          debugPrint('📦 پیش‌نویس محلی قبلاً ارسال شده — نادیده گرفته می‌شود');
          await _clearProgramLocally();
          return false;
        }
      } else {
        debugPrint('📦 پیش‌نویس محلی وجود ندارد');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطا در بارگذاری پیش‌نویس محلی: $e');
      return false;
    }
  }

  // ????? ?????? ?? ??????? (??? ???? ?????)
  Future<void> _saveProgramToDatabase() async {
    // ???? ??? ?????? ??? ???? ?????
    if (_program.name.isEmpty || _hasCorruptedPersianText(_program.name)) {
      _program = _program.copyWith(name: await _generatePlanName());
    }

    if (!mounted) return;
    // Prevent save if trainer-authored and edit window expired
    // ????? ?? ???? editable_until ??? meal plan builder
    if (widget.targetUserId != null && _program.sentAt != null) {
      if (_editableUntil != null) {
        final now = DateTime.now();
        if (now.isAfter(_editableUntil!)) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'مهلت ویرایش این برنامه به پایان رسیده است',
          );
          return;
        }
      }
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('کاربر وارد سیستم نشده است');
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
          autoSend:
              true, // ???? ????? ?? ??????? (??? sent_at ?? sendProgram ????? ??????)
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
        WidgetSafetyUtils.safeShowSnackBar(context, 'خطا در ذخیره برنامه: $e');
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
          _expandedExerciseIndex = _selectedExercises.length - 1;
        });
        _autoSaveProgram();
      }
    } catch (_) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'افزودن حرکت با خطا مواجه شد. دوباره تلاش کنید.',
      );
    }
  }

  void _deleteExercise(int exerciseIndex) {
    setState(() {
      _selectedExercises.removeAt(exerciseIndex);
      if (_expandedExerciseIndex == null) return;
      if (_expandedExerciseIndex == exerciseIndex) {
        _expandedExerciseIndex = null;
      } else if (_expandedExerciseIndex! > exerciseIndex) {
        _expandedExerciseIndex = _expandedExerciseIndex! - 1;
      }
    });
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
          decoration: context.pageDecoration,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: WorkoutProgramAppBar(
              onConfirm: _showConfirmDialog,
              isSent: _program.sentAt != null,
              showConfirmButton:
                  widget.targetUserId != null &&
                  _selectedExercises.isNotEmpty &&
                  (_program.sentAt == null),
            ),
            drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
            endDrawerEnableOpenDragGesture: false,
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
                                  Expanded(
                                    child: Material(
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
                                              userName:
                                                  widget.targetUserName ??
                                                  'کاربر',
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.06,
                                                  )
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.goldColor
                                                  .withValues(
                                                    alpha: isDark ? 0.25 : 0.3,
                                                  ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                LucideIcons.user,
                                                color: AppTheme.goldColor,
                                                size: 16.sp,
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  widget.targetUserName ??
                                                      'ورزشکار',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        AppTheme.fontFamily,
                                                    color: isDark
                                                        ? AppTheme.goldColor
                                                        : context.textColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12.sp,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                'مشخصات',
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTheme.fontFamily,
                                                  color: AppTheme.goldColor,
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 2.w),
                                              Icon(
                                                LucideIcons.chevronLeft,
                                                color: AppTheme.goldColor,
                                                size: 14.sp,
                                              ),
                                            ],
                                          ),
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
                                          'تا $remainingHours ساعت دیگر مجاز به ویرایش برنامه هستید',
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
                                        'در حال بارگذاری اطلاعات...',
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
                        onDayChanged: (day) => SafeSetState.call(this, () {
                          _selectedDay = day;
                          _expandedExerciseIndex = null;
                        }),
                        sessions: _program.sessions,
                        currentSession: _program.sessions[_selectedDay],
                        onNotesChanged: _updateSessionNotes,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _selectedExercises.isEmpty
                            ? EmptyStateWidget(onAdd: _addExercise)
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  16.w,
                                  4.h,
                                  16.w,
                                  16.h,
                                ),
                                itemCount: _selectedExercises.length + 1,
                                itemBuilder: (context, exerciseIndex) {
                                  if (exerciseIndex ==
                                      _selectedExercises.length) {
                                    return Padding(
                                      padding: EdgeInsets.only(top: 4.h),
                                      child: OutlinedButton.icon(
                                        onPressed: _addExercise,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.goldColor,
                                          side: BorderSide(
                                            color: AppTheme.goldColor.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12.h,
                                          ),
                                        ),
                                        icon: Icon(
                                          LucideIcons.plus,
                                          size: 16.sp,
                                        ),
                                        label: Text(
                                          'افزودن حرکت',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.sp,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    key: ValueKey('exercise_$exerciseIndex'),
                                    padding: EdgeInsets.only(bottom: 6.h),
                                    child: ExerciseCard(
                                      exercise:
                                          _selectedExercises[exerciseIndex],
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
                                      totalExercises:
                                          _selectedExercises.length,
                                      expanded:
                                          _expandedExerciseIndex ==
                                          exerciseIndex,
                                      onToggleExpand: () {
                                        SafeSetState.call(this, () {
                                          _expandedExerciseIndex =
                                              _expandedExerciseIndex ==
                                                  exerciseIndex
                                              ? null
                                              : exerciseIndex;
                                        });
                                      },
                                      onDelete: () =>
                                          _deleteExercise(exerciseIndex),
                                      onMoveUp: exerciseIndex > 0
                                          ? () =>
                                                _moveExerciseUp(exerciseIndex)
                                          : null,
                                      onMoveDown:
                                          exerciseIndex <
                                              _selectedExercises.length - 1
                                          ? () => _moveExerciseDown(
                                              exerciseIndex,
                                            )
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
                                      if (style == ExerciseStyle.setsReps) {
                                        set.reps = set.reps ?? 10;
                                        set.timeSeconds = null;
                                      } else {
                                        set.timeSeconds = set.timeSeconds ?? 60;
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
                                      for (int i = 0; i < sets - current; i++) {
                                        final last = exercise.sets.isNotEmpty
                                            ? exercise.sets.last
                                            : null;
                                        exercise.sets.add(
                                          ExerciseSet(
                                            reps:
                                                exercise.style ==
                                                    ExerciseStyle.setsReps
                                                ? (last?.reps ?? 10)
                                                : null,
                                            timeSeconds:
                                                exercise.style ==
                                                    ExerciseStyle.setsTime
                                                ? (last?.timeSeconds ?? 60)
                                                : null,
                                            weight: last?.weight ?? 0,
                                          ),
                                        );
                                      }
                                    } else if (sets < current) {
                                      exercise.sets.removeRange(sets, current);
                                    }
                                  }
                                });
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
                                _autoSaveProgram();
                              },
                              onSetRepsChanged: (setIndex, reps) {
                                setState(() {
                                  if (_selectedExercises[exerciseIndex]
                                      is NormalExercise) {
                                    final exercise =
                                        _selectedExercises[exerciseIndex]
                                            as NormalExercise;
                                    if (setIndex >= 0 &&
                                        setIndex < exercise.sets.length) {
                                      exercise.sets[setIndex].reps = reps;
                                    }
                                  }
                                });
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
                                _autoSaveProgram();
                              },
                              onSetTimeChanged: (setIndex, time) {
                                setState(() {
                                  if (_selectedExercises[exerciseIndex]
                                      is NormalExercise) {
                                    final exercise =
                                        _selectedExercises[exerciseIndex]
                                            as NormalExercise;
                                    if (setIndex >= 0 &&
                                        setIndex < exercise.sets.length) {
                                      exercise.sets[setIndex].timeSeconds =
                                          time;
                                    }
                                  }
                                });
                                _autoSaveProgram();
                              },
                              onRestChanged: (rest) {
                                setState(() {
                                  if (_selectedExercises[exerciseIndex]
                                      is NormalExercise) {
                                    (_selectedExercises[exerciseIndex]
                                            as NormalExercise)
                                        .restSeconds = rest;
                                  }
                                });
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
                                      for (final set
                                          in exercise
                                              .exercises[supersetExerciseIndex]
                                              .sets) {
                                        if (style == ExerciseStyle.setsReps) {
                                          set.reps = set.reps ?? 10;
                                          set.timeSeconds = null;
                                        } else {
                                          set.timeSeconds =
                                              set.timeSeconds ?? 60;
                                          set.reps = null;
                                        }
                                      }
                                    }
                                  }
                                });
                                _autoSaveProgram();
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
                                              final last = supersetItem
                                                      .sets.isNotEmpty
                                                  ? supersetItem.sets.last
                                                  : null;
                                              supersetItem.sets.add(
                                                ExerciseSet(
                                                  reps:
                                                      supersetItem.style ==
                                                          ExerciseStyle.setsReps
                                                      ? (last?.reps ?? 10)
                                                      : null,
                                                  timeSeconds:
                                                      supersetItem.style ==
                                                          ExerciseStyle.setsTime
                                                      ? (last?.timeSeconds ??
                                                            60)
                                                      : null,
                                                  weight: last?.weight ?? 0,
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
                                          for (final set in supersetItem.sets) {
                                            set.reps = reps;
                                          }
                                        }
                                      }
                                    });
                                    _autoSaveProgram();
                                  },
                              onSupersetSetRepsChanged:
                                  (supersetExerciseIndex, setIndex, reps) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is SupersetExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as SupersetExercise;
                                        if (supersetExerciseIndex <
                                            exercise.exercises.length) {
                                          final sets = exercise
                                              .exercises[supersetExerciseIndex]
                                              .sets;
                                          if (setIndex >= 0 &&
                                              setIndex < sets.length) {
                                            sets[setIndex].reps = reps;
                                          }
                                        }
                                      }
                                    });
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
                                          for (final set in supersetItem.sets) {
                                            set.timeSeconds = time;
                                          }
                                        }
                                      }
                                    });
                                    _autoSaveProgram();
                                  },
                              onSupersetSetTimeChanged:
                                  (supersetExerciseIndex, setIndex, time) {
                                    setState(() {
                                      if (_selectedExercises[exerciseIndex]
                                          is SupersetExercise) {
                                        final exercise =
                                            _selectedExercises[exerciseIndex]
                                                as SupersetExercise;
                                        if (supersetExerciseIndex <
                                            exercise.exercises.length) {
                                          final sets = exercise
                                              .exercises[supersetExerciseIndex]
                                              .sets;
                                          if (setIndex >= 0 &&
                                              setIndex < sets.length) {
                                            sets[setIndex].timeSeconds = time;
                                          }
                                        }
                                      }
                                    });
                                    _autoSaveProgram();
                                  },
                              onSupersetRestChanged: (rest) {
                                setState(() {
                                  if (_selectedExercises[exerciseIndex]
                                      is SupersetExercise) {
                                    (_selectedExercises[exerciseIndex]
                                            as SupersetExercise)
                                        .restSeconds = rest;
                                  }
                                });
                                _autoSaveProgram();
                              },
                              allExercises: _exercises,
                                    ),
                                  );
                                },
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
        debugPrint('??????? ??? ${_selectedDay + 1} ?? ?????? ????? ??');
      } catch (e) {
        debugPrint('??? ?? ????? ???????: $e');
      }
    } else {
      // ??? ?????? ???? ????? ????? ??? ???? ????? ??
      await _saveProgramLocally();
      debugPrint('??????? ??? ${_selectedDay + 1} ?? ???? ???? ????? ??');
    }
  }
}
