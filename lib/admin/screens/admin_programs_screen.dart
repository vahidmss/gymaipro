import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه مدیریت برنامه‌های تمرینی و رژیمی
class AdminProgramsScreen extends StatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  State<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends State<AdminProgramsScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  List<Map<String, dynamic>> _workoutPrograms = [];
  List<Map<String, dynamic>> _mealPlans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWorkoutPrograms();
    _loadMealPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutPrograms() async {
    setState(() => _isLoading = true);
    try {
      final programs = await _adminService.getAllWorkoutPrograms();
      if (mounted) {
        setState(() {
          _workoutPrograms = programs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری برنامه‌های تمرینی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMealPlans() async {
    try {
      final plans = await _adminService.getAllMealPlans();
      if (mounted) {
        setState(() {
          _mealPlans = plans;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری برنامه‌های رژیمی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteWorkoutProgram(String programId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف برنامه تمرینی'),
        content: const Text('آیا مطمئن هستید که می‌خواهید این برنامه را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _adminService.deleteWorkoutProgram(programId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برنامه تمرینی با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWorkoutPrograms();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در حذف برنامه تمرینی'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMealPlan(String mealPlanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف برنامه رژیمی'),
        content: const Text('آیا مطمئن هستید که می‌خواهید این برنامه را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _adminService.deleteMealPlan(mealPlanId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برنامه رژیمی با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMealPlans();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در حذف برنامه رژیمی'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getUserName(Map<String, dynamic>? user) {
    if (user == null) return 'کاربر ناشناس';
    final firstName = user['first_name'] as String?;
    final lastName = user['last_name'] as String?;
    final username = user['username'] as String?;

    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName;
    } else if (username != null) {
      return username;
    }
    return 'کاربر ناشناس';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: isDark
              ? AppTheme.darkTextColor.withValues(alpha: 0.6)
              : AppTheme.lightTextSecondary,
          tabs: const [
            Tab(text: 'برنامه‌های تمرینی'),
            Tab(text: 'برنامه‌های رژیمی'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // تب برنامه‌های تمرینی
              if (_isLoading) const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldColor,
                      ),
                    ) else _workoutPrograms.isEmpty
                      ? Center(
                          child: Text(
                            'برنامه تمرینی یافت نشد',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadWorkoutPrograms,
                          color: AppTheme.goldColor,
                          child: ListView.builder(
                            itemCount: _workoutPrograms.length,
                            itemBuilder: (context, index) {
                              final program = _workoutPrograms[index];
                              final user = program['user'] as Map<String, dynamic>?;
                              final isDeleted = program['is_deleted'] as bool? ?? false;

                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                color: isDark
                                    ? AppTheme.darkCardColor
                                    : AppTheme.lightCardColor,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.goldColor
                                        .withValues(alpha: 0.2),
                                    child: const Icon(LucideIcons.dumbbell),
                                  ),
                                  title: Text(
                                    program['name'] as String? ?? 'بدون نام',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor
                                          : AppTheme.lightTextColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: isDeleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'کاربر: ${_getUserName(user)}',
                                        style: TextStyle(
                                          color: isDeleted
                                              ? Colors.grey
                                              : (isDark
                                                  ? AppTheme.darkTextColor
                                                      .withValues(alpha: 0.7)
                                                  : AppTheme.lightTextSecondary),
                                        ),
                                      ),
                                      if (isDeleted)
                                        Chip(
                                          label: const Text('حذف شده'),
                                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                    ],
                                  ),
                                  trailing: !isDeleted
                                      ? PopupMenuButton<void>(
                                          icon: const Icon(LucideIcons.moreVertical),
                                          itemBuilder: (context) => [
                                            PopupMenuItem<void>(
                                              child: Row(
                                                children: [
                                                  const Icon(LucideIcons.trash2,
                                                      size: 18, color: Colors.red),
                                                  SizedBox(width: 8.w),
                                                  const Text(
                                                    'حذف',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                              onTap: () => _deleteWorkoutProgram(
                                                program['id'] as String,
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
              // تب برنامه‌های رژیمی
              if (_mealPlans.isEmpty) Center(
                      child: Text(
                        'برنامه رژیمی یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ) else RefreshIndicator(
                      onRefresh: _loadMealPlans,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _mealPlans.length,
                        itemBuilder: (context, index) {
                          final plan = _mealPlans[index];
                          final user = plan['user'] as Map<String, dynamic>?;
                          final trainer = plan['trainer'] as Map<String, dynamic>?;
                          final isDeleted = plan['is_deleted'] as bool? ?? false;

                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            color: isDark
                                ? AppTheme.darkCardColor
                                : AppTheme.lightCardColor,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.goldColor.withValues(alpha: 0.2),
                                child: const Icon(LucideIcons.utensils),
                              ),
                              title: Text(
                                plan['name'] as String? ?? 'بدون نام',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextColor
                                      : AppTheme.lightTextColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: isDeleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'کاربر: ${_getUserName(user)}',
                                    style: TextStyle(
                                      color: isDeleted
                                          ? Colors.grey
                                          : (isDark
                                              ? AppTheme.darkTextColor
                                                  .withValues(alpha: 0.7)
                                              : AppTheme.lightTextSecondary),
                                    ),
                                  ),
                                  if (trainer != null)
                                    Text(
                                      'مربی: ${_getUserName(trainer)}',
                                      style: TextStyle(
                                        color: isDeleted
                                            ? Colors.grey
                                            : (isDark
                                                ? AppTheme.darkTextColor
                                                    .withValues(alpha: 0.7)
                                                : AppTheme.lightTextSecondary),
                                      ),
                                    ),
                                  if (isDeleted)
                                    Chip(
                                      label: const Text('حذف شده'),
                                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                              trailing: !isDeleted
                                  ? PopupMenuButton<void>(
                                      icon: const Icon(LucideIcons.moreVertical),
                                      itemBuilder: (context) => [
                                        PopupMenuItem<void>(
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.trash2,
                                                  size: 18, color: Colors.red),
                                              SizedBox(width: 8.w),
                                              const Text(
                                                'حذف',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ],
                                          ),
                                          onTap: () => _deleteMealPlan(
                                            plan['id'] as String,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

