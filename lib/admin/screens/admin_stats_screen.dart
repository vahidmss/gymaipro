import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه آمار و گزارشات ادمین
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getSystemStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری آمار: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppTheme.goldColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آمار کلی سیستم',
              style: TextStyle(
                color: context.textColor,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),
            _buildStatCard(
              context,
              icon: LucideIcons.users,
              title: 'کل کاربران',
              value: '${_stats['total_users'] ?? 0}',
              color: colors.primary,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.user,
                    title: 'ورزشکاران',
                    value: '${_stats['total_athletes'] ?? 0}',
                    color: AppTheme.successColor,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.userCheck,
                    title: 'مربیان',
                    value: '${_stats['total_trainers'] ?? 0}',
                    color: colors.tertiary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.shield,
                    title: 'ادمین‌ها',
                    value: '${_stats['total_admins'] ?? 0}',
                    color: colors.secondary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.userPlus,
                    title: 'کاربران جدید امروز',
                    value: '${_stats['new_users_today'] ?? 0}',
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'آمار برنامه‌ها',
              style: TextStyle(
                color: context.textColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.dumbbell,
                    title: 'برنامه‌های تمرینی',
                    value: '${_stats['total_workout_programs'] ?? 0}',
                    color: colors.primary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.utensils,
                    title: 'برنامه‌های رژیمی',
                    value: '${_stats['total_meal_plans'] ?? 0}',
                    color: colors.tertiary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildStatCard(
              context,
              icon: LucideIcons.userCheck,
              title: 'روابط مربی-شاگرد',
              value: '${_stats['total_trainer_clients'] ?? 0}',
              color: colors.primary,
            ),
            SizedBox(height: 24.h),
            Text(
              'آمار چت',
              style: TextStyle(
                color: context.textColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.messageSquare,
                    title: 'مکالمات خصوصی',
                    value: '${_stats['total_conversations'] ?? 0}',
                    color: colors.primary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.messageCircle,
                    title: 'پیام‌های چت عمومی',
                    value: '${_stats['total_public_messages'] ?? 0}',
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              'آمار مالی',
              style: TextStyle(
                color: context.textColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.creditCard,
                    title: 'تراکنش‌ها',
                    value: '${_stats['total_transactions'] ?? 0}',
                    color: colors.secondary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.wallet,
                    title: 'کیف پول‌ها',
                    value: '${_stats['total_wallets'] ?? 0}',
                    color: AppTheme.goldColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.trendingUp,
                    title: 'درآمد خالص',
                    value: PaymentConstants.formatAmount(
                      _stats['net_revenue'] as int? ?? 0,
                    ),
                    color: AppTheme.successColor,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: LucideIcons.ticket,
                    title: 'کدهای تخفیف',
                    value: '${_stats['total_discount_codes'] ?? 0}',
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(color: context.textSecondary, fontSize: 14.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
