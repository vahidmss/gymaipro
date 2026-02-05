import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/my_club/widgets/unified_empty_state.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/services/active_meal_plan_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyProgramsScreen extends StatefulWidget {
  const MyProgramsScreen({super.key});

  @override
  State<MyProgramsScreen> createState() => _MyProgramsScreenState();
}

class _MyProgramsScreenState extends State<MyProgramsScreen> {
  final SupabaseClient _db = Supabase.instance.client;
  final ActiveProgramService _active = ActiveProgramService();
  final ActiveMealPlanService _activeMealPlan = ActiveMealPlanService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _programs = [];
  String? _activeProgramId;
  String? _activeMealPlanId;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // حذف کش - همیشه از دیتابیس می‌خوانیم
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _programs = [];
            _activeProgramId = null;
            _isLoading = false;
          });
        }
        return;
      }

      final activeState = await _active.getActiveProgramState();
      _activeProgramId = activeState?['active_program_id'] as String?;
      _activeMealPlanId = await _activeMealPlan.getActiveMealPlanId();

      // بارگذاری برنامه‌های کاربر + اطلاعات مربی
      // فقط برنامه‌هایی که ارسال شده‌اند (sent_at != null) برای شاگرد قابل نمایش هستند
      List<dynamic> rows;
      try {
        rows = await _db
            .from('workout_programs')
            .select('''
              id, program_name, data, created_at, updated_at, trainer_id, sent_at, expiry_date,
              trainer:profiles!workout_programs_trainer_id_fkey(
                id, username, first_name, last_name, avatar_url
              )
            ''')
            .eq('user_id', userId)
            .eq('is_deleted', false)
            .not('sent_at', 'is', null) // فقط برنامه‌های ارسال شده
            .order('created_at', ascending: false);
      } catch (e) {
        // اگر ستون sent_at وجود نداشت، بدون آن‌ها بخوانیم
        debugPrint('خطا در خواندن workout programs با sent_at: $e');
        debugPrint('تلاش برای خواندن بدون فیلتر sent_at...');
        try {
          rows = await _db
              .from('workout_programs')
              .select('''
                id, program_name, data, created_at, updated_at, trainer_id, expiry_date,
                trainer:profiles!workout_programs_trainer_id_fkey(
                  id, username, first_name, last_name, avatar_url
                )
              ''')
              .eq('user_id', userId)
              .eq('is_deleted', false)
              .order('created_at', ascending: false);
        } catch (e2) {
          debugPrint('خطا در خواندن workout programs: $e2');
          rows = [];
        }
      }

      final List<Map<String, dynamic>> items = [];
      for (final row in rows) {
        final r = Map<String, dynamic>.from(row as Map);
        final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');

        // خواندن expiry_date
        DateTime? expiryDate;
        if (r['expiry_date'] != null) {
          expiryDate = DateTime.tryParse(r['expiry_date'] as String);
        } else if (createdAt != null) {
          // اگر expiry_date وجود نداشت، از created_at محاسبه کن (33 روز)
          expiryDate = createdAt.add(const Duration(days: 33));
        }

        // بررسی انقضا بر اساس expiry_date
        final bool isExpired = expiryDate != null
            ? DateTime.now().isAfter(expiryDate)
            : (createdAt != null
                  ? DateTime.now().difference(createdAt).inDays > 45
                  : false);

        items.add({
          'id': r['id'],
          'program_name': r['program_name'] ?? 'بدون نام',
          'created_at': createdAt,
          'trainer': r['trainer'],
          'isExpired': isExpired,
          'expiry_date': expiryDate,
        });
      }

      if (mounted) {
        setState(() {
          _programs = items;
          // _isLoading را اینجا false نمی‌کنیم - باید تا انتهای لود شدن همه داده‌ها صبر کنیم
        });
      }

      // بارگذاری برنامه‌های رژیمی کاربر + اطلاعات مربی
      // فقط برنامه‌هایی که ارسال شده‌اند (sent_at != null) برای شاگرد قابل نمایش هستند
      // ابتدا meal plans را بدون join می‌خوانیم تا از خطای ambiguous relationship جلوگیری کنیم
      List<dynamic> mealPlanRows;
      try {
        mealPlanRows = await _db
            .from('meal_plans')
            .select(
              'id, plan_name, data, created_at, updated_at, user_id, trainer_id, sent_at, expiry_date',
            )
            .eq('user_id', userId)
            .not('sent_at', 'is', null) // فقط برنامه‌های ارسال شده
            .order('created_at', ascending: false);
      } catch (e) {
        // اگر ستون sent_at یا trainer_id وجود نداشت، بدون آن‌ها بخوانیم
        debugPrint('خطا در خواندن meal plans با trainer_id/sent_at: $e');
        debugPrint('تلاش برای خواندن بدون فیلتر sent_at...');
        try {
          mealPlanRows = await _db
              .from('meal_plans')
              .select(
                'id, plan_name, data, created_at, updated_at, user_id, trainer_id',
              )
              .eq('user_id', userId)
              .order('created_at', ascending: false);
        } catch (e2) {
          debugPrint('خطا در خواندن meal plans: $e2');
          try {
            mealPlanRows = await _db
                .from('meal_plans')
                .select('id, plan_name, data, created_at, updated_at, user_id')
                .eq('user_id', userId)
                .order('created_at', ascending: false);
          } catch (e3) {
            debugPrint('خطا در خواندن meal plans: $e3');
            mealPlanRows = [];
          }
        }
      }

      // خواندن پروفایل کاربر فعلی برای نمایش "خودم" در صورت نیاز
      Map<String, dynamic>? currentUserProfile;
      try {
        final profile = await _db
            .from('profiles')
            .select('id, username, first_name, last_name, avatar_url')
            .eq('id', userId)
            .maybeSingle();
        if (profile != null) {
          currentUserProfile = Map<String, dynamic>.from(profile as Map);
        }
      } catch (e) {
        debugPrint('خطا در خواندن پروفایل کاربر فعلی: $e');
      }

      // اگر trainer_id وجود داشت، اطلاعات مربی را جداگانه بخوانیم
      final List<Map<String, dynamic>> mealPlanItems = [];
      for (final row in mealPlanRows) {
        final r = Map<String, dynamic>.from(row as Map);
        final trainerId = r['trainer_id'] as String?;
        final planUserId = r['user_id'] as String?;

        // خواندن اطلاعات مربی اگر trainer_id وجود داشته باشد
        Map<String, dynamic>? trainer;
        if (trainerId != null && trainerId.isNotEmpty) {
          try {
            final trainerProfile = await _db
                .from('profiles')
                .select('id, username, first_name, last_name, avatar_url')
                .eq('id', trainerId)
                .maybeSingle();
            if (trainerProfile != null) {
              trainer = Map<String, dynamic>.from(trainerProfile as Map);
            }
          } catch (e) {
            debugPrint('خطا در خواندن اطلاعات مربی: $e');
            // در صورت خطا، trainer را null می‌گذاریم
          }
        } else if (planUserId == userId && currentUserProfile != null) {
          // اگر trainer_id null است و برنامه متعلق به کاربر فعلی است، از پروفایل کاربر استفاده می‌کنیم
          trainer = currentUserProfile;
        }

        // خواندن expiry_date
        DateTime? expiryDate;
        if (r['expiry_date'] != null) {
          expiryDate = DateTime.tryParse(r['expiry_date'] as String);
        } else {
          // اگر expiry_date وجود نداشت، از created_at یا sent_at محاسبه کن
          final createdAtStr = r['created_at'] as String?;
          final sentAtStr = r['sent_at'] as String?;
          DateTime? baseDate;
          if (sentAtStr != null) {
            baseDate = DateTime.tryParse(sentAtStr);
          } else if (createdAtStr != null) {
            baseDate = DateTime.tryParse(createdAtStr);
          }
          if (baseDate != null) {
            expiryDate = baseDate.add(const Duration(days: 33));
          }
        }

        mealPlanItems.add({
          'id': r['id'],
          'plan_name': r['plan_name'] ?? 'برنامه رژیمی',
          'created_at': r['created_at'],
          'trainer': trainer,
          'expiry_date': expiryDate,
        });
      }

      if (mounted) {
        setState(() {
          // ساخت لیست یکپارچه برای نمایش
          final unified = <Map<String, dynamic>>[];
          // Workout programs
          for (final p in _programs) {
            final String programId = p['id'] as String;
            final bool isActive = _activeProgramId == programId;
            final bool isExpired = p['isExpired'] as bool? ?? false;
            final trainer = p['trainer'] as Map<String, dynamic>?;
            final trainerName = trainer == null
                ? 'آزمایشی'
                : '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}'
                      .trim()
                      .isEmpty
                ? (trainer['username'] ?? 'آزمایشی')
                : '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}';

            unified.add({
              'type': 'workout',
              'id': programId,
              'title': p['program_name'] as String,
              'subtitle': 'مربی: $trainerName',
              'isActive': isActive,
              'isExpired': isExpired,
              'expiry_date': p['expiry_date'],
            });
          }
          // Meal plans
          for (final mp in mealPlanItems) {
            final trainer = mp['trainer'] as Map<String, dynamic>?;
            final trainerName = trainer == null
                ? 'آزمایشی'
                : '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}'
                      .trim()
                      .isEmpty
                ? (trainer['username'] ?? 'آزمایشی')
                : '${trainer['first_name'] ?? ''} ${trainer['last_name'] ?? ''}';
            final String mealPlanId = mp['id'] as String;
            final bool isActive = _activeMealPlanId == mealPlanId;

            unified.add({
              'type': 'diet',
              'id': mealPlanId,
              'title': (mp['plan_name'] as String?)?.isEmpty ?? true
                  ? 'برنامه رژیمی'
                  : mp['plan_name'] as String,
              'subtitle': 'مربی: $trainerName',
              'isActive': isActive,
              'expiry_date': mp['expiry_date'],
            });
          }

          _items = unified;
          _isLoading =
              false; // حالا که همه داده‌ها لود شدند و _items ساخته شد، loading را false می‌کنیم
        });
      }
      // کش حذف شد - دیگر ذخیره نمی‌کنیم
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _items = []; // در صورت خطا، لیست را خالی می‌کنیم
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری برنامه‌ها: $e',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateProgram(String programId) async {
    final ok = await _active.setActiveProgram(programId);
    if (ok && mounted) {
      // به‌روزرسانی state و _items
      setState(() {
        _activeProgramId = programId;
        // به‌روزرسانی وضعیت در _items
        for (var item in _items) {
          if (item['type'] == 'workout' && item['id'] == programId) {
            item['isActive'] = true;
          } else if (item['type'] == 'workout') {
            item['isActive'] = false;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'برنامه فعال شد',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deactivateProgram() async {
    final ok = await _active.clearActiveProgram();
    if (ok && mounted) {
      // فقط state را به‌روزرسانی می‌کنیم بدون reload کامل
      setState(() {
        _activeProgramId = null;
        // به‌روزرسانی وضعیت در _items
        for (var item in _items) {
          if (item['type'] == 'workout') {
            item['isActive'] = false;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'برنامه تمرینی غیرفعال شد',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _goToWorkoutLog() {
    Navigator.pushNamed(context, '/workout-log');
  }

  void _renewProgram(String programId) {
    // TODO: اتصال به پرداخت/تمدید واقعی. فعلاً پیام نمونه
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمدید با ۵۰٪ هزینه: به‌زودی',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: AppTheme.goldColor,
      ),
    );
  }

  Future<void> _activateMealPlan(String mealPlanId) async {
    final ok = await _activeMealPlan.setActiveMealPlan(mealPlanId);
    if (ok && mounted) {
      // فقط state را به‌روزرسانی می‌کنیم بدون reload کامل
      setState(() {
        _activeMealPlanId = mealPlanId;
        // به‌روزرسانی وضعیت در _items
        for (var item in _items) {
          if (item['type'] == 'diet' && item['id'] == mealPlanId) {
            item['isActive'] = true;
          } else if (item['type'] == 'diet') {
            item['isActive'] = false;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'برنامه رژیمی فعال شد',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deactivateMealPlan() async {
    final ok = await _activeMealPlan.clearActiveMealPlan();
    if (ok && mounted) {
      // فقط state را به‌روزرسانی می‌کنیم بدون reload کامل
      setState(() {
        _activeMealPlanId = null;
        // به‌روزرسانی وضعیت در _items
        for (var item in _items) {
          if (item['type'] == 'diet') {
            item['isActive'] = false;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'برنامه رژیمی غیرفعال شد',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              )
            : (_items.isEmpty)
            ? UnifiedEmptyState(
                icon: LucideIcons.folderSearch,
                title: 'هیچ برنامه‌ای یافت نشد',
                subtitle:
                    'برای شروع سفر ورزشی خود، یک برنامه تمرینی یا رژیمی تهیه کنید',
              )
            : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final it = _items[index];
                  if (it['type'] == 'workout') {
                    return _ProgramCard(
                      programName: it['title'] as String,
                      trainerName: (it['subtitle'] as String?) ?? '—',
                      programId: it['id'] as String,
                      isActive: (it['isActive'] as bool?) ?? false,
                      isExpired: (it['isExpired'] as bool?) ?? false,
                      expiryDate: it['expiry_date'] as DateTime?,
                      onActivate: () => _activateProgram(it['id'] as String),
                      onDeactivate: () => _deactivateProgram(),
                      onOpen: _goToWorkoutLog,
                      onRenew: () => _renewProgram(it['id'] as String),
                    );
                  }
                  return _DietPlanCard(
                    planName: it['title'] as String,
                    trainerName: (it['subtitle'] as String?) ?? '—',
                    mealPlanId: it['id'] as String,
                    isActive: (it['isActive'] as bool?) ?? false,
                    expiryDate: it['expiry_date'] as DateTime?,
                    onActivate: () => _activateMealPlan(it['id'] as String),
                    onDeactivate: () => _deactivateMealPlan(),
                    onOpen: () => Navigator.pushNamed(
                      context,
                      '/meal-log',
                      arguments: it['id'] as String,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.programName,
    required this.trainerName,
    required this.programId,
    required this.isActive,
    required this.isExpired,
    required this.expiryDate,
    required this.onActivate,
    required this.onDeactivate,
    required this.onOpen,
    required this.onRenew,
  });
  final String programName;
  final String trainerName;
  final String programId;
  final bool isActive;
  final bool isExpired;
  final DateTime? expiryDate;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onOpen;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isExpired
                  ? Colors.red.withValues(alpha: 0.5)
                  : isDark
                  ? Colors.grey[700]!
                  : AppTheme.lightDividerColor.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppTheme.goldColor.withValues(alpha: 0.08),
                blurRadius: 8.r,
                offset: Offset(0.w, 4.h),
              ),
            ],
          ),
          child: Opacity(
            opacity: isExpired ? 0.5 : 1.0,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          programName,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _TypeChip(
                        icon: LucideIcons.dumbbell,
                        label: 'تمرینی',
                        color: Color(0xFF7EC8FF),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 16.sp,
                        color: isDark
                            ? Colors.grey[400]
                            : AppTheme.lightTextSecondary.withValues(
                                alpha: 0.6,
                              ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'مربی: $trainerName',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // نمایش تاریخ انقضا
                  if (expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final difference = expiryDate!.difference(now);
                        final daysRemaining = difference.inDays;

                        String text;
                        if (daysRemaining < 0) {
                          text = 'اعتبار منقضی شده';
                        } else if (daysRemaining == 0) {
                          text = 'در دسترس تا امروز';
                        } else {
                          text = 'در دسترس تا $daysRemaining روز دیگر';
                        }

                        return Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 14.sp,
                              color: isExpired
                                  ? Colors.red
                                  : isDark
                                  ? Colors.grey[400]
                                  : AppTheme.lightTextSecondary.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              text,
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.red
                                    : context.textSecondary,
                                fontSize: 11.sp,
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: isExpired
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isExpired)
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'تمدید برنامه‌ای که قبلاً صادر شده نصف قیمت است.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                                fontFamily: AppTheme.fontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isExpired) ...[
                    const SizedBox(height: 12),
                    // کلید خاموش/روشن
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'وضعیت برنامه',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (value) {
                            if (value) {
                              onActivate();
                            } else {
                              onDeactivate();
                            }
                          },
                          activeColor: AppTheme.goldColor,
                          activeTrackColor: AppTheme.goldColor.withValues(
                            alpha: 0.5,
                          ),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // دکمه ثبت تمرین
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isActive ? onOpen : null,
                        icon: Icon(
                          isActive ? LucideIcons.dumbbell : LucideIcons.lock,
                        ),
                        label: Text(
                          isActive ? 'ثبت تمرین' : 'برنامه غیرفعال است',
                          style: TextStyle(fontFamily: AppTheme.fontFamily),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? AppTheme.goldColor
                              : Colors.grey.withValues(alpha: 0.5),
                          foregroundColor: isActive
                              ? AppTheme.onGoldColor
                              : Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          disabledBackgroundColor: Colors.grey.withValues(
                            alpha: 0.3,
                          ),
                          disabledForegroundColor: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                  if (isExpired) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRenew,
                        icon: const Icon(LucideIcons.refreshCw),
                        label: Text(
                          'تمدید با ۵۰٪',
                          style: TextStyle(fontFamily: AppTheme.fontFamily),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // نمایش قفل بزرگ وقتی اعتبار تموم شد
        if (isExpired)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.lock,
                  size: 64.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final String label = isActive ? 'فعال' : 'غیرفعال';
    final Color color = isActive ? AppTheme.goldColor : Colors.grey;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

class _DietPlanCard extends StatelessWidget {
  const _DietPlanCard({
    required this.planName,
    required this.trainerName,
    required this.mealPlanId,
    required this.isActive,
    required this.expiryDate,
    required this.onActivate,
    required this.onDeactivate,
    required this.onOpen,
  });
  final String planName;
  final String trainerName;
  final String mealPlanId;
  final bool isActive;
  final DateTime? expiryDate;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired = expiryDate != null && DateTime.now().isAfter(expiryDate!);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isExpired
                  ? Colors.red.withValues(alpha: 0.5)
                  : isDark
                  ? Colors.grey[700]!
                  : AppTheme.lightDividerColor.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppTheme.goldColor.withValues(alpha: 0.08),
                blurRadius: 8.r,
                offset: Offset(0.w, 4.h),
              ),
            ],
          ),
          child: Opacity(
            opacity: isExpired ? 0.5 : 1.0,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          planName.isEmpty ? 'برنامه رژیمی' : planName,
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _TypeChip(
                        icon: LucideIcons.salad,
                        label: 'رژیمی',
                        color: Color(0xFFFFC069),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        size: 16.sp,
                        color: isDark
                            ? Colors.grey[400]
                            : AppTheme.lightTextSecondary.withValues(
                                alpha: 0.6,
                              ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          trainerName.startsWith('مربی: ')
                              ? trainerName
                              : 'مربی: $trainerName',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.sp,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // نمایش تاریخ انقضا
                  if (expiryDate != null) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final difference = expiryDate!.difference(now);
                        final daysRemaining = difference.inDays;

                        String text;
                        if (daysRemaining < 0) {
                          text = 'اعتبار منقضی شده';
                        } else if (daysRemaining == 0) {
                          text = 'در دسترس تا امروز';
                        } else {
                          text = 'در دسترس تا $daysRemaining روز دیگر';
                        }

                        return Row(
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 14.sp,
                              color: isExpired
                                  ? Colors.red
                                  : isDark
                                  ? Colors.grey[400]
                                  : AppTheme.lightTextSecondary.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              text,
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.red
                                    : context.textSecondary,
                                fontSize: 11.sp,
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: isExpired
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  // کلید خاموش/روشن
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'وضعیت برنامه',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            color: context.textColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          if (value) {
                            onActivate();
                          } else {
                            onDeactivate();
                          }
                        },
                        activeColor: AppTheme.goldColor,
                        activeTrackColor: AppTheme.goldColor.withValues(
                          alpha: 0.5,
                        ),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // دکمه ثبت تغذیه
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isActive ? onOpen : null,
                      icon: Icon(
                        isActive ? LucideIcons.utensils : LucideIcons.lock,
                      ),
                      label: Text(
                        isActive ? 'ثبت تغذیه' : 'برنامه غیرفعال است',
                        style: TextStyle(fontFamily: AppTheme.fontFamily),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? AppTheme.goldColor
                            : Colors.grey.withValues(alpha: 0.5),
                        foregroundColor: isActive
                            ? AppTheme.onGoldColor
                            : Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor: Colors.grey.withValues(
                          alpha: 0.3,
                        ),
                        disabledForegroundColor: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // نمایش قفل بزرگ وقتی اعتبار تموم شد
        if (isExpired)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.lock,
                  size: 64.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final String label = isActive ? 'فعال' : 'غیرفعال';
    final Color color = isActive ? AppTheme.goldColor : Colors.grey;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
