// این فایل کاملاً ماژولار است. تمام دیالوگ‌ها، ویجت‌ها و سرویس‌های قابل استفاده مجدد در فولدرهای جدا قرار دارند. از افزودن کد تکراری یا لاگ بی‌دلیل خودداری کنید. برای توسعه، فقط منطق UI و تعاملات را اینجا نگه دارید و بقیه را جدا کنید.
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
  bool _isAutoSaving = false;
  List<Exercise> _exercises = [];
  List<WorkoutProgram> _savedPrograms = [];
  bool _showDrawer = false;
  int _selectedDay = 0;
  String? _targetUserName; // نام کاربر هدف برای ساخت نام برنامه
  DateTime? _editableUntil; // تاریخ پایان مهلت ویرایش

  // Getter for current session's exercises - used throughout the class
  // Getter for current session's exercises
  List<WorkoutExercise> get _selectedExercises =>
      _program.sessions[_selectedDay].exercises;


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

      final user = Supabase.instance.client.auth.currentUser;
      final userId = widget.targetUserId ?? user?.id ?? '';

      // ابتدا برنامه محلی را بارگذاری کن (اگر وجود داشته باشد)
      // این باید قبل از بارگذاری از دیتابیس انجام شود
      if (widget.targetUserId != null && user != null) {
        await _loadProgramLocally();
        // اگر برنامه محلی بارگذاری شد، از ادامه صرف‌نظر کن
        if (_program.sessions.isNotEmpty || _program.name.isNotEmpty) {
          print('✅ برنامه از حافظه محلی بارگذاری شد - از بارگذاری دیتابیس صرف‌نظر می‌شود');
          if (!mounted) return;
          SafeSetState.call(this, () {
            _isLoading = false;
          });
          return;
        }
      }

      // اگر programId مشخص شده باشد، برنامه را از ID بارگذاری کن
      if (widget.programId != null && widget.programId!.isNotEmpty) {
        final program = await _programService.getProgramById(widget.programId!);
        if (program != null) {
          _program = program;
          // فقط اگر برنامه ارسال شده باشه، editable_until رو بخون
          if (widget.targetUserId != null && program.sentAt != null) {
            await _loadEditableUntil();
          }
        } else {
          // اگر برنامه پیدا نشد، برنامه جدید بساز
          final programName = await _generatePlanName();
          _program = WorkoutProgram.empty().copyWith(
            name: programName,
            userId: userId,
          );
        }
      } else if (widget.targetUserId != null && user != null) {
        // اگر مربی برای کاربر دیگری برنامه می‌سازد، بررسی کن آیا برنامه موجودی وجود دارد
        final existingPrograms = await _programService
            .getProgramsForUserByTrainer(widget.targetUserId!, user.id);

        if (existingPrograms.isNotEmpty) {
          // برنامه موجود را بارگذاری کن (اولین برنامه)
          SafeSetState.call(this, () {
            _program = existingPrograms.first;
          });
          // فقط اگر برنامه ارسال شده باشه، editable_until رو بخون
          if (_program.sentAt != null) {
            print('📥 برنامه موجود بارگذاری شد، در حال خواندن editable_until...');
            await _loadEditableUntil();
          }
        } else {
          // برنامه جدید بساز با نام خودکار
          final programName = await _generatePlanName();
          _program = WorkoutProgram.empty().copyWith(
            name: programName,
            userId: userId,
          );
        }
      } else {
        // حالت عادی: کاربر برای خودش برنامه می‌سازد
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
      
      // اگر برنامه از دیتابیس بارگذاری شد و هنوز ارسال نشده، آن را محلی ذخیره کن
      if (widget.targetUserId != null && _program.sentAt == null) {
        await _saveProgramLocally();
      }
    } catch (e) {
      if (!mounted) return;
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در بارگذاری: $e',
      );
      SafeSetState.call(this, () {
        _isLoading = false;
      });
    }
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
      print('خطا در دریافت اطلاعات کاربر برای ساخت نام: $e');
    }

    // در صورت خطا، از نام کاربر از widget استفاده کن
    final userName = widget.targetUserName ?? 'کاربر';
    _targetUserName = userName;
    return 'برنامه تمرینی-$userName-$dateStr';
  }

  // خواندن editable_until از دیتابیس
  Future<void> _loadEditableUntil() async {
    if (_program.id.isEmpty || widget.targetUserId == null) {
      print(
        '⚠️ _loadEditableUntil: برنامه ID خالی است یا targetUserId null است',
      );
      SafeSetState.call(this, () {
        _editableUntil = null;
      });
      return;
    }

    try {
      final client = Supabase.instance.client;
      print('🔍 در حال خواندن editable_until برای برنامه: ${_program.id}');
      final planData = await client
          .from('workout_programs')
          .select('editable_until, sent_at')
          .eq('id', _program.id)
          .maybeSingle();

      print('📊 داده‌های خوانده شده: $planData');

      // فقط اگر برنامه ارسال شده باشه (sent_at != null)، editable_until رو بخون
      if (planData == null || planData['sent_at'] == null) {
        print('⚠️ برنامه هنوز ارسال نشده است. editable_until تنظیم نمی‌شود.');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
        return;
      }

      // editable_until و expiry_date فقط بعد از ارسال برنامه (sendProgram) ثبت می‌شوند
      // تا زمانی که مربی روی دکمه ارسال نزده، این فیلدها null هستند
      if (planData['editable_until'] != null) {
        final editableUntilStr = planData['editable_until'] as String;
        print('✅ editable_until پیدا شد: $editableUntilStr');
        SafeSetState.call(this, () {
          _editableUntil = DateTime.parse(editableUntilStr);
          print('✅ _editableUntil تنظیم شد: $_editableUntil');
        });
      } else {
        // اگر برنامه هنوز ارسال نشده (sent_at == null)، editable_until هم null است
        print('⚠️ برنامه هنوز ارسال نشده است (editable_until null)');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      }
    } catch (e) {
      // اگر ستون editable_until وجود نداشت، خطا را gracefully handle می‌کنیم
      final errorStr = e.toString();
      if (errorStr.contains('editable_until') ||
          errorStr.contains('does not exist') ||
          errorStr.contains('42703')) {
        print('⚠️ ستون editable_until در دیتابیس وجود ندارد.');
        print(
          '📄 لطفاً فایل SQL را اجرا کنید: sql/add_expiry_and_editable_to_workout_programs.sql',
        );
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      } else {
        print('❌ خطا در خواندن editable_until: $e');
        SafeSetState.call(this, () {
          _editableUntil = null;
        });
      }
    }
  }

  // محاسبه ساعت‌های باقیمانده تا editable_until
  int? _getRemainingHours() {
    if (_editableUntil == null) {
      print('⚠️ _getRemainingHours: _editableUntil null است');
      return null;
    }
    final now = DateTime.now();
    if (now.isAfter(_editableUntil!)) {
      print('⏰ زمان ویرایش به پایان رسیده است');
      return 0;
    }
    final difference = _editableUntil!.difference(now);
    // محاسبه دقیق ساعت‌ها: فقط ساعت‌های کامل (بدون رند کردن)
    final hours = difference.inHours;
    print(
      '⏳ ساعت‌های باقیمانده: $hours (از ${difference.inDays} روز و ${(difference.inHours % 24)} ساعت)',
    );
    return hours;
  }

  // نمایش دیالوگ تأیید ارسال برنامه
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
              child: Text(
                'انصراف',
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
              child: Text(
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

    if (confirmed == true) {
      // ابتدا برنامه را در دیتابیس ذخیره کنیم (اگر هنوز ذخیره نشده)
      // این اولین بار است که برنامه به دیتابیس می‌رود
      await _saveProgramToDatabase();

      // سپس ارسال برنامه (تنظیم sent_at، editable_until و expiry_date)
      if (_program.id.isNotEmpty) {
        try {
          await _programService.sendProgram(
            _program.id,
            subscriptionId: widget.subscriptionId,
          );
          // بارگذاری مجدد برنامه برای دریافت sentAt
          final updatedProgram = await _programService.getProgramById(
            _program.id,
          );
          if (updatedProgram != null) {
            SafeSetState.call(this, () {
              _program = updatedProgram;
            });
            // خواندن editable_until از دیتابیس
            await _loadEditableUntil();
            
            // به‌روزرسانی لیست برنامه‌های ذخیره شده
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
          print('خطا در ارسال برنامه: $e');
          if (mounted) {
            WidgetSafetyUtils.safeShowSnackBar(
              context,
              'خطا در ارسال برنامه: $e',
            );
          }
          return;
        }
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

  // ذخیره خودکار برنامه (فقط محلی - SharedPreferences)
  Future<void> _autoSaveProgram() async {
    if (_isAutoSaving || widget.targetUserId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    SafeSetState.call(this, () => _isAutoSaving = true);

    try {
      // ساخت نام برنامه اگر وجود نداشت
      if (_program.name.isEmpty) {
        _program = _program.copyWith(name: await _generatePlanName());
      }

      // بررسی اینکه آیا برنامه در دیتابیس ذخیره شده است یا نه
      final isProgramSaved = _savedPrograms.any((p) => p.id == _program.id);

      // اگر برنامه قبلاً ارسال شده (sent_at != null)، باید به دیتابیس به‌روزرسانی شود
      if (isProgramSaved && _program.sentAt != null) {
        // به‌روزرسانی برنامه موجود در دیتابیس
        try {
          final updatedProgram = await _programService.updateProgram(_program);
          SafeSetState.call(this, () {
            _program = updatedProgram;
          });
          // خواندن editable_until
          await _loadEditableUntil();
        } catch (e) {
          // اگر به‌روزرسانی ناموفق بود، فقط محلی ذخیره کن
          print('⚠️ خطا در به‌روزرسانی دیتابیس، ذخیره محلی: $e');
          await _saveProgramLocally();
        }
      } else {
        // برنامه هنوز ارسال نشده - فقط محلی ذخیره می‌شود
        await _saveProgramLocally();
        print('💾 برنامه به صورت محلی ذخیره شد (ارسال نشده)');
      }
    } catch (e) {
      print('خطا در ذخیره خودکار برنامه: $e');
    } finally {
      SafeSetState.call(this, () => _isAutoSaving = false);
    }
  }

  // ذخیره برنامه به صورت محلی در SharedPreferences
  // استفاده از کلید ثابت بر اساس targetUserId و trainerId برای اطمینان از ذخیره‌سازی
  Future<void> _saveProgramLocally() async {
    try {
      if (widget.targetUserId == null) return;
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      // استفاده از کلید ثابت بر اساس targetUserId و trainerId
      final key = 'workout_program_draft_${widget.targetUserId}_${user.id}';
      
      // اطمینان از اینکه برنامه یک ID معتبر داره
      if (_program.id.isEmpty) {
        // اگر ID خالی بود، یک UUID جدید بساز
        final uuid = const Uuid().v4();
        _program = _program.copyWith(id: uuid);
      }
      
      await prefs.setString(key, jsonEncode(_program.toJson()));
      print('💾 برنامه به صورت محلی ذخیره شد: $key');
      print('💾 Program ID: ${_program.id}');
      print('💾 Sessions count: ${_program.sessions.length}');
    } catch (e) {
      print('❌ خطا در ذخیره محلی برنامه: $e');
    }
  }

  // بارگذاری برنامه از SharedPreferences
  // استفاده از کلید ثابت بر اساس targetUserId و trainerId
  Future<void> _loadProgramLocally() async {
    try {
      if (widget.targetUserId == null) return;
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      // استفاده از کلید ثابت بر اساس targetUserId و trainerId
      final key = 'workout_program_draft_${widget.targetUserId}_${user.id}';
      final jsonStr = prefs.getString(key);
      
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final localProgram = WorkoutProgram.fromJson(jsonMap);
        
        // فقط اگر برنامه هنوز ارسال نشده باشه، از نسخه محلی استفاده کن
        if (localProgram.sentAt == null) {
          SafeSetState.call(this, () {
            _program = localProgram;
          });
          print('📥 برنامه از حافظه محلی بارگذاری شد');
          print('📥 Program ID: ${_program.id}');
          print('📥 Sessions count: ${_program.sessions.length}');
        } else {
          print('⚠️ برنامه محلی قبلاً ارسال شده است - از نسخه محلی استفاده نمی‌شود');
        }
      } else {
        print('ℹ️ برنامه محلی یافت نشد');
      }
    } catch (e) {
      print('❌ خطا در بارگذاری محلی برنامه: $e');
    }
  }

  // ذخیره برنامه در دیتابیس (فقط برای ارسال)
  Future<void> _saveProgramToDatabase() async {
    // ساخت نام برنامه اگر وجود نداشت
    if (_program.name.isEmpty) {
      _program = _program.copyWith(name: await _generatePlanName());
    }

    // Prevent save if trainer-authored and edit window expired
    // بررسی بر اساس editable_until مثل meal plan builder
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

      // بررسی اینکه آیا برنامه در دیتابیس ذخیره شده است یا نه
      final isProgramSaved = _savedPrograms.any((p) => p.id == _program.id);

      if (isProgramSaved) {
        // به‌روزرسانی برنامه موجود
        final updatedProgram = await _programService.updateProgram(_program);
        SafeSetState.call(this, () {
          _program = updatedProgram;
        });
      } else {
        // ایجاد یک برنامه جدید در دیتابیس (با autoSend=true برای ذخیره در دیتابیس)
        // این اولین بار است که برنامه به دیتابیس می‌رود (زمان ارسال)
        final newProgram = await _programService.createProgram(
          _program,
          trainerId: user.id,
          targetUserId: widget.targetUserId,
          subscriptionId: widget.subscriptionId,
          paymentTransactionId: widget.paymentTransactionId,
          autoSend: true, // برای ذخیره در دیتابیس (اما sent_at در sendProgram تنظیم می‌شود)
        );
        SafeSetState.call(this, () {
          _program = newProgram;
        });
        
        // به‌روزرسانی لیست برنامه‌های ذخیره شده
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
          'خطا در ذخیره برنامه: $e',
        );
      }
      rethrow;
    }
  }

  Future<void> _addExercise() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: false,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.7)
          : AppTheme.lightTextColor.withValues(alpha: 0.5),
      builder: (context) => AddExerciseScreen(exercises: _exercises),
    );

    if (result != null && mounted) {
      WidgetSafetyUtils.safeSetState(this, () {
        final exercise = result['exercise'] as WorkoutExercise;
        _selectedExercises.add(exercise);
      });
      // ذخیره خودکار
      _autoSaveProgram();
    }
  }

  void _deleteExercise(int exerciseIndex) {
    setState(() {
      _selectedExercises.removeAt(exerciseIndex);
    });
    // ذخیره خودکار
    _autoSaveProgram();
  }

  void _moveExerciseUp(int exerciseIndex) {
    if (exerciseIndex > 0) {
      setState(() {
        final exercise = _selectedExercises.removeAt(exerciseIndex);
        _selectedExercises.insert(exerciseIndex - 1, exercise);
      });
      // ذخیره خودکار
      _autoSaveProgram();
    }
  }

  void _moveExerciseDown(int exerciseIndex) {
    if (exerciseIndex < _selectedExercises.length - 1) {
      setState(() {
        final exercise = _selectedExercises.removeAt(exerciseIndex);
        _selectedExercises.insert(exerciseIndex + 1, exercise);
      });
      // ذخیره خودکار
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
        child: Container(
          decoration: isDark
              ? null
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
                  gradient: LinearGradient(
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
                  tooltip: 'افزودن حرکت',
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
                      // اطلاع ساخت برای کاربر هدف
                      if (widget.targetUserId != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Badge مینیمال برای نمایش کاربر
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
                                          decoration: BoxDecoration(
                                            color: AppTheme.goldColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'در حال ساخت برنامه برای ${widget.targetUserName ?? 'کاربر'}',
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
                                  // دکمه مشخصات به صورت icon button مینیمال
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
                                                'کاربر',
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
                              // نمایش ساعت‌های باقیمانده زیر Badge
                              Builder(
                                builder: (context) {
                                  // اگر برنامه ارسال شده و editable_until وجود دارد
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
                                  // اگر برنامه ارسال شده اما editable_until هنوز بارگذاری نشده
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
                        onDayChanged: (day) =>
                            SafeSetState.call(this, () => _selectedDay = day),
                        currentSession: _program.sessions[_selectedDay],
                        onNotesChanged: _updateSessionNotes,
                      ),
                      const SizedBox(height: 4),
                      // لیست تمرین‌ها (اسکرول فقط روی این بخش)
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
                                      // ذخیره خودکار
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
                                      // ذخیره خودکار
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
                                      // ذخیره خودکار
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
                                      // ذخیره خودکار
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
                                      // ذخیره خودکار
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
                                      // ذخیره خودکار
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
                                      // ذخیره خودکار
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
                                      // ذخیره خودکار
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
                                          // ذخیره خودکار
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
                                          // ذخیره خودکار
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

    // Save to database (فقط اگر برنامه ارسال شده باشد)
    if (_program.sentAt != null) {
      try {
        final updatedProgram = await _programService.updateProgram(_program);
        SafeSetState.call(this, () {
          _program = updatedProgram;
        });
        print('توضیحات روز ${_selectedDay + 1} با موفقیت ذخیره شد');
      } catch (e) {
        print('خطا در ذخیره توضیحات: $e');
      }
    } else {
      // اگر برنامه هنوز ارسال نشده، فقط محلی ذخیره کن
      await _saveProgramLocally();
      print('توضیحات روز ${_selectedDay + 1} به صورت محلی ذخیره شد');
    }
  }
}
