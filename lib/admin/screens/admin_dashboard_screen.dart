import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/screens/admin_ai_plan_prices_screen.dart';
import 'package:gymaipro/admin/screens/admin_announcements_screen.dart';
import 'package:gymaipro/admin/screens/admin_app_access_control_screen.dart';
import 'package:gymaipro/admin/screens/admin_broadcast_screen.dart';
import 'package:gymaipro/admin/screens/admin_certificates_screen.dart';
import 'package:gymaipro/admin/screens/admin_chat_management_screen.dart';
import 'package:gymaipro/admin/screens/admin_commission_settings_screen.dart';
import 'package:gymaipro/admin/screens/admin_crash_reports_screen.dart';
import 'package:gymaipro/admin/screens/admin_discount_codes_screen.dart';
import 'package:gymaipro/admin/screens/admin_exercise_sync_screen.dart';
import 'package:gymaipro/admin/screens/admin_financial_screen.dart';
import 'package:gymaipro/admin/screens/admin_images_screen.dart';
import 'package:gymaipro/admin/screens/admin_payments_screen.dart';
import 'package:gymaipro/admin/screens/admin_payout_requests_screen.dart';
import 'package:gymaipro/admin/screens/admin_programs_screen.dart';
import 'package:gymaipro/admin/screens/admin_public_chat_screen.dart';
import 'package:gymaipro/admin/screens/admin_stats_screen.dart';
import 'package:gymaipro/admin/screens/admin_trainer_clients_screen.dart';
import 'package:gymaipro/admin/screens/admin_trainer_escrow_screen.dart';
import 'package:gymaipro/admin/screens/admin_users_screen.dart';
import 'package:gymaipro/admin/screens/admin_wallet_actions_screen.dart';
import 'package:gymaipro/admin/screens/admin_wallets_screen.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحه اصلی پنل ادمین
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({this.initialIndex = 0, super.key});

  static const int payoutRequestsIndex = 16;
  static const int accessControlIndex = 20;

  final int initialIndex;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  late final List<Widget> _screens;
  final Set<int> _builtIndices = <int>{};
  late int _selectedIndex;
  bool _isAdmin = false;
  bool _isChecking = true;

  static const List<_AdminDestination> _destinations = [
    _AdminDestination('آمار', LucideIcons.barChart3, _AdminGroup.users),
    _AdminDestination('کاربران', LucideIcons.users, _AdminGroup.users),
    _AdminDestination('برنامه‌ها', LucideIcons.dumbbell, _AdminGroup.content),
    _AdminDestination('مربی و شاگرد', LucideIcons.userCheck, _AdminGroup.users),
    _AdminDestination('پرداخت‌ها', LucideIcons.creditCard, _AdminGroup.finance),
    _AdminDestination('کیف پول‌ها', LucideIcons.wallet, _AdminGroup.finance),
    _AdminDestination('کدهای تخفیف', LucideIcons.ticket, _AdminGroup.finance),
    _AdminDestination('چت خصوصی', LucideIcons.messageSquare, _AdminGroup.users),
    _AdminDestination('چت عمومی', LucideIcons.messageCircle, _AdminGroup.users),
    _AdminDestination('تصاویر', LucideIcons.image, _AdminGroup.content),
    _AdminDestination(
      'گزارش مالی',
      LucideIcons.trendingUp,
      _AdminGroup.finance,
    ),
    _AdminDestination('امانی مربی', LucideIcons.shield, _AdminGroup.finance),
    _AdminDestination('گردش کیف پول', LucideIcons.history, _AdminGroup.finance),
    _AdminDestination('مدارک مربیان', LucideIcons.award, _AdminGroup.users),
    _AdminDestination('کمیسیون', LucideIcons.percent, _AdminGroup.finance),
    _AdminDestination(
      'هزینه هوش مصنوعی',
      LucideIcons.sparkles,
      _AdminGroup.finance,
    ),
    _AdminDestination(
      'درخواست‌های برداشت',
      LucideIcons.arrowUpCircle,
      _AdminGroup.finance,
    ),
    _AdminDestination('ارسال همگانی', LucideIcons.send, _AdminGroup.content),
    _AdminDestination(
      'اخبار داخل اپ',
      LucideIcons.megaphone,
      _AdminGroup.content,
    ),
    _AdminDestination(
      'همگام‌سازی تمرین‌ها',
      LucideIcons.refreshCw,
      _AdminGroup.system,
    ),
    _AdminDestination(
      'کنترل دسترسی اپ',
      LucideIcons.toggleLeft,
      _AdminGroup.system,
    ),
    _AdminDestination(
      'گزارش کرش',
      LucideIcons.alertTriangle,
      _AdminGroup.system,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _destinations.length - 1);
    _builtIndices.add(_selectedIndex);
    _screens = const [
      AdminStatsScreen(),
      AdminUsersScreen(),
      AdminProgramsScreen(),
      AdminTrainerClientsScreen(),
      AdminPaymentsScreen(),
      AdminWalletsScreen(),
      AdminDiscountCodesScreen(),
      AdminChatManagementScreen(),
      AdminPublicChatScreen(),
      AdminImagesScreen(),
      AdminFinancialScreen(),
      AdminTrainerEscrowScreen(),
      AdminWalletActionsScreen(),
      AdminCertificatesScreen(),
      AdminCommissionSettingsScreen(),
      AdminAiPlanPricesScreen(),
      AdminPayoutRequestsScreen(),
      AdminBroadcastScreen(),
      AdminAnnouncementsScreen(),
      AdminExerciseSyncScreen(),
      AdminAppAccessControlScreen(),
      AdminCrashReportsScreen(),
    ];
    unawaited(_checkAdminStatus());
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
              behavior: SnackBarBehavior.floating,
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
              behavior: SnackBarBehavior.floating,
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
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return DecoratedBox(
        decoration: context.pageDecoration,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.goldColor),
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    final selected = _destinations[_selectedIndex];
    return DecoratedBox(
      decoration: context.pageDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'پنل مدیریت',
            style: TextStyle(
              color: context.textColor,
              fontWeight: FontWeight.w800,
              fontSize: 19.sp,
            ),
          ),
          backgroundColor: context.cardColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: context.textColor),
        ),
        body: Column(
          children: [
            _SelectedDestinationCard(
              destination: selected,
              onTap: _showDestinationSelector,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: List<Widget>.generate(
                  _screens.length,
                  (index) => _builtIndices.contains(index)
                      ? _screens[index]
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDestinationSelector() async {
    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AdminDestinationSheet(
        destinations: _destinations,
        selectedIndex: _selectedIndex,
      ),
    );
    if (selectedIndex == null || !mounted) return;
    setState(() {
      _selectedIndex = selectedIndex;
      _builtIndices.add(selectedIndex);
    });
  }
}

enum _AdminGroup {
  users('کاربران', LucideIcons.users),
  finance('مالی', LucideIcons.wallet),
  content('محتوا', LucideIcons.megaphone),
  system('سیستم', LucideIcons.settings);

  const _AdminGroup(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _AdminDestination {
  const _AdminDestination(this.label, this.icon, this.group);

  final String label;
  final IconData icon;
  final _AdminGroup group;
}

class _SelectedDestinationCard extends StatelessWidget {
  const _SelectedDestinationCard({
    required this.destination,
    required this.onTap,
  });

  final _AdminDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: 64.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.separatorColor)),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  destination.icon,
                  color: AppTheme.goldColor,
                  size: 21.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${destination.group.label} · تغییر بخش',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronDown,
                color: context.textSecondary,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDestinationSheet extends StatelessWidget {
  const _AdminDestinationSheet({
    required this.destinations,
    required this.selectedIndex,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Material(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 28.h),
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.separatorColor,
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'انتخاب بخش مدیریت',
              style: TextStyle(
                color: context.textColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 14.h),
            for (final group in _AdminGroup.values) ...[
              Row(
                children: [
                  Icon(group.icon, color: AppTheme.goldColor, size: 18.sp),
                  SizedBox(width: 7.w),
                  Text(
                    group.label,
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              for (final indexed in destinations.indexed)
                if (indexed.$2.group == group)
                  _DestinationTile(
                    destination: indexed.$2,
                    selected: indexed.$1 == selectedIndex,
                    onTap: () => Navigator.pop(context, indexed.$1),
                  ),
              SizedBox(height: 14.h),
            ],
          ],
        ),
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Material(
        color: selected
            ? AppTheme.goldColor.withValues(alpha: 0.13)
            : context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            constraints: BoxConstraints(minHeight: 52.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: selected ? AppTheme.goldColor : context.separatorColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  destination.icon,
                  color: selected ? AppTheme.goldColor : context.textSecondary,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      color: context.textColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    LucideIcons.check,
                    color: AppTheme.goldColor,
                    size: 18.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
