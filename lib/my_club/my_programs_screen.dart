import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/meal_plan/meal_plan_builder/services/meal_plan_service.dart';
import 'package:gymaipro/models/meal_plan.dart';
import 'package:gymaipro/services/active_program_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/utils/cache_service.dart';
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
  final MealPlanService _mealPlanService = MealPlanService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _programs = [];
  String? _activeProgramId;
  List<MealPlan> _mealPlans = [];
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Cache-first for quick render
    final cached = await CacheService.getJsonMap('programs_screen_cache');
    if (cached != null) {
      final items = (cached['items'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = true);
      }
    }
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _programs = [];
            _activeProgramId = null;
            _isLoading = false;
            _mealPlans = [];
          });
        }
        return;
      }

      final activeState = await _active.getActiveProgramState();
      _activeProgramId = activeState?['active_program_id'] as String?;

      // بارگذاری برنامه‌های کاربر + اطلاعات مربی
      final rows = await _db
          .from('workout_programs')
          .select('''
            id, program_name, data, created_at, updated_at, trainer_id,
            trainer:profiles!workout_programs_trainer_id_fkey(
              id, username, first_name, last_name, avatar_url
            )
          ''')
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> items = [];
      for (final row in rows) {
        final r = Map<String, dynamic>.from(row as Map);
        final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');
        final bool isExpired = createdAt != null
            ? DateTime.now().difference(createdAt).inDays > 45
            : false;
        items.add({
          'id': r['id'],
          'program_name': r['program_name'] ?? 'بدون نام',
          'created_at': createdAt,
          'trainer': r['trainer'],
          'isExpired': isExpired,
        });
      }

      if (mounted) {
        setState(() {
          _programs = items;
          _isLoading = false;
        });
      }

      // بارگذاری برنامه‌های رژیمی کاربر
      try {
        final plans = await _mealPlanService.getPlans();
        if (mounted) {
          setState(() {
            // فقط برنامه‌های کاربر جاری را نگه داریم (در صورت نیاز)
            _mealPlans = plans
                .where(
                  (p) =>
                      p.userId ==
                      (Supabase.instance.client.auth.currentUser?.id ?? ''),
                )
                .toList();

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
              });
            }
            // Meal plans
            for (final mp in _mealPlans) {
              unified.add({
                'type': 'diet',
                'id': mp.id,
                'title': mp.planName.isEmpty ? 'برنامه رژیمی' : mp.planName,
                'subtitle': 'مربی: آزمایشی',
              });
            }

            _items = unified;
          });
        }
      } catch (_) {}
      // Update cache with final unified items
      await CacheService.setJson('programs_screen_cache', {'items': _items});
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری برنامه‌ها: $e',
              style: GoogleFonts.vazirmatn(),
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
      setState(() => _activeProgramId = programId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('برنامه فعال شد', style: GoogleFonts.vazirmatn()),
          backgroundColor: Colors.green,
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
          style: GoogleFonts.vazirmatn(),
        ),
        backgroundColor: AppTheme.goldColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'برنامه‌های من',
          style: GoogleFonts.vazirmatn(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            )
          : (_items.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.folderSearch,
                    size: 64.sp,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'هیچ برنامه‌ای یافت نشد',
                    style: GoogleFonts.vazirmatn(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/meal-plan-builder'),
                    child: Text(
                      'ایجاد برنامهٔ رژیمی',
                      style: GoogleFonts.vazirmatn(color: AppTheme.goldColor),
                    ),
                  ),
                ],
              ),
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
                    isActive: (it['isActive'] as bool?) ?? false,
                    isExpired: (it['isExpired'] as bool?) ?? false,
                    onActivate: () => _activateProgram(it['id'] as String),
                    onOpen: _goToWorkoutLog,
                    onRenew: () => _renewProgram(it['id'] as String),
                  );
                }
                return _DietPlanCard(
                  planName: it['title'] as String,
                  onOpen: () => Navigator.pushNamed(context, '/meal-log'),
                );
              },
            ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.programName,
    required this.trainerName,
    required this.isActive,
    required this.isExpired,
    required this.onActivate,
    required this.onOpen,
    required this.onRenew,
  });
  final String programName;
  final String trainerName;
  final bool isActive;
  final bool isExpired;
  final VoidCallback onActivate;
  final VoidCallback onOpen;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActive
              ? AppTheme.goldColor
              : isExpired
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.grey[700]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
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
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
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
                Icon(LucideIcons.user, size: 16.sp, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'مربی: $trainerName',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isExpired)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تمدید برنامه‌ای که قبلاً صادر شده نصف قیمت است.',
                        style: GoogleFonts.vazirmatn(
                          color: Colors.red,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isActive && !isExpired)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(LucideIcons.play),
                      label: Text(
                        'ورود به ثبت تمرین',
                        style: GoogleFonts.vazirmatn(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                if (!isActive && !isExpired) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onActivate,
                      icon: const Icon(LucideIcons.checkCircle2),
                      label: Text('فعال‌سازی', style: GoogleFonts.vazirmatn()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldColor,
                        side: const BorderSide(color: AppTheme.goldColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
                if (isExpired) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onRenew,
                      icon: const Icon(LucideIcons.refreshCw),
                      label: Text(
                        'تمدید با ۵۰٪',
                        style: GoogleFonts.vazirmatn(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final String label = isActive
        ? 'فعال'
        : isExpired
        ? 'منقضی'
        : 'غیرفعال';
    final Color color = isActive
        ? AppTheme.goldColor
        : isExpired
        ? Colors.red
        : Colors.grey;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.vazirmatn(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DietPlanCard extends StatelessWidget {
  const _DietPlanCard({required this.planName, required this.onOpen});
  final String planName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[700]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
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
                    style: GoogleFonts.vazirmatn(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const _TypeChip(
                  icon: LucideIcons.salad,
                  label: 'رژیمی',
                  color: Color(0xFFFFC069),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.user, size: 16.sp, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'مربی: آزمایشی',
                    style: GoogleFonts.vazirmatn(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(LucideIcons.utensils),
                    label: Text('ثبت تغذیه', style: GoogleFonts.vazirmatn()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldColor,
                      side: const BorderSide(color: AppTheme.goldColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            style: GoogleFonts.vazirmatn(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
