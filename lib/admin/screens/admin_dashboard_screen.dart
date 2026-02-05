import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/screens/admin_chat_management_screen.dart';
import 'package:gymaipro/admin/screens/admin_discount_codes_screen.dart';
import 'package:gymaipro/admin/screens/admin_financial_screen.dart';
import 'package:gymaipro/admin/screens/admin_images_screen.dart';
import 'package:gymaipro/admin/screens/admin_payments_screen.dart';
import 'package:gymaipro/admin/screens/admin_programs_screen.dart';
import 'package:gymaipro/admin/screens/admin_stats_screen.dart';
import 'package:gymaipro/admin/screens/admin_trainer_clients_screen.dart';
import 'package:gymaipro/admin/screens/admin_users_screen.dart';
import 'package:gymaipro/admin/screens/admin_wallet_actions_screen.dart';
import 'package:gymaipro/admin/screens/admin_wallets_screen.dart';
import 'package:gymaipro/admin/screens/admin_certificates_screen.dart';
import 'package:gymaipro/admin/screens/admin_commission_settings_screen.dart';
import 'package:gymaipro/admin/screens/admin_payout_requests_screen.dart';
import 'package:gymaipro/admin/screens/admin_broadcast_screen.dart';
import 'package:gymaipro/admin/screens/admin_exercise_sync_screen.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحه اصلی پنل ادمین
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  bool _isAdmin = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 16, vsync: this);
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('کاربر احراز هویت نشده است'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final isAdmin = await _adminService.isAdmin();

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isChecking = false;
        });

        if (!isAdmin) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('شما دسترسی به پنل ادمین ندارید'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isChecking = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بررسی دسترسی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isChecking) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.darkBackgroundColor
            : AppTheme.lightBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.goldColor),
        ),
      );
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundColor
          : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text(
          'میز کار ادمین',
          style: TextStyle(
            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: isDark
            ? AppTheme.darkCardColor
            : AppTheme.lightCardColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldColor,
          labelColor: AppTheme.goldColor,
          unselectedLabelColor: isDark
              ? AppTheme.darkTextColor.withValues(alpha: 0.6)
              : AppTheme.lightTextSecondary,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          unselectedLabelStyle: TextStyle(fontSize: 13.sp),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(LucideIcons.barChart3), text: 'آمار'),
            Tab(icon: Icon(LucideIcons.users), text: 'کاربران'),
            Tab(icon: Icon(LucideIcons.dumbbell), text: 'برنامه‌ها'),
            Tab(icon: Icon(LucideIcons.userCheck), text: 'مربی-شاگرد'),
            Tab(icon: Icon(LucideIcons.creditCard), text: 'پرداخت‌ها'),
            Tab(icon: Icon(LucideIcons.wallet), text: 'کیف پول'),
            Tab(icon: Icon(LucideIcons.ticket), text: 'کد تخفیف'),
            Tab(icon: Icon(LucideIcons.messageSquare), text: 'چت خصوصی'),
            Tab(icon: Icon(LucideIcons.image), text: 'عکس‌ها'),
            Tab(icon: Icon(LucideIcons.trendingUp), text: 'گزارش مالی'),
            Tab(icon: Icon(LucideIcons.history), text: 'تاریخچه کیف پول'),
            Tab(icon: Icon(LucideIcons.award), text: 'مدارک مربی'),
            Tab(icon: Icon(LucideIcons.percent), text: 'تنظیمات کمیسیون'),
            Tab(icon: Icon(LucideIcons.arrowUpCircle), text: 'درخواست‌های برداشت'),
            Tab(icon: Icon(LucideIcons.send), text: 'نوتیفیکیشن همگانی'),
            Tab(icon: Icon(LucideIcons.refreshCw), text: 'Sync تمرین‌ها'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminStatsScreen(),
          AdminUsersScreen(),
          AdminProgramsScreen(),
          AdminTrainerClientsScreen(),
          AdminPaymentsScreen(),
          AdminWalletsScreen(),
          AdminDiscountCodesScreen(),
          AdminChatManagementScreen(),
          AdminImagesScreen(),
          AdminFinancialScreen(),
          AdminWalletActionsScreen(),
          AdminCertificatesScreen(),
          AdminCommissionSettingsScreen(),
          AdminPayoutRequestsScreen(),
          AdminBroadcastScreen(),
          AdminExerciseSyncScreen(),
        ],
      ),
    );
  }
}
