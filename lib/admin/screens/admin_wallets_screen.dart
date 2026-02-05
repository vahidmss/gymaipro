import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// صفحه مدیریت کیف پول‌ها
class AdminWalletsScreen extends StatefulWidget {
  const AdminWalletsScreen({super.key});

  @override
  State<AdminWalletsScreen> createState() => _AdminWalletsScreenState();
}

class _AdminWalletsScreenState extends State<AdminWalletsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _wallets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => _isLoading = true);
    try {
      final wallets = await _adminService.getAllWallets();
      if (mounted) {
        setState(() {
          _wallets = wallets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری کیف پول‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _chargeWallet(String userId) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('شارژ دستی کیف پول'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'مبلغ (تومان)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('شارژ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final amount = int.tryParse(amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مبلغ باید بیشتر از صفر باشد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _adminService.chargeWalletManually(
      userId,
      amount,
      descriptionController.text.isEmpty
          ? 'شارژ دستی توسط ادمین'
          : descriptionController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کیف پول با موفقیت شارژ شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWallets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در شارژ کیف پول'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _adjustWalletBalance(String userId, int currentAvailableBalance) async {
    final balanceController = TextEditingController(text: currentAvailableBalance.toString());
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اصلاح موجودی کیف پول'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'موجودی قابل استفاده فعلی: ${PaymentConstants.formatAmount(currentAvailableBalance)}',
              style: TextStyle(
                color: AppTheme.goldColor,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(
                labelText: 'موجودی جدید (تومان)',
                border: OutlineInputBorder(),
                helperText: 'مثلاً برای تغییر از 500 به 300، عدد 300 را وارد کنید',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              if (balanceController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.goldColor),
            child: const Text('اصلاح'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newBalance = int.tryParse(balanceController.text) ?? 0;
    if (newBalance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('موجودی نمی‌تواند منفی باشد'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _adminService.updateWalletBalanceDirectly(
      userId,
      newBalance,
      descriptionController.text.isEmpty
          ? 'اصلاح موجودی توسط ادمین'
          : descriptionController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'موجودی با موفقیت به ${PaymentConstants.formatAmount(newBalance)} تغییر یافت',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadWallets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در اصلاح موجودی'),
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
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(
              color: AppTheme.goldColor,
            ),
          )
        : _wallets.isEmpty
            ? Center(
                child: Text(
                  'کیف پولی یافت نشد',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadWallets,
                color: AppTheme.goldColor,
                child: ListView.builder(
                  itemCount: _wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = _wallets[index];
                    final user = wallet['user'] as Map<String, dynamic>?;
                    // استفاده از available_balance به جای balance
                    final availableBalance = wallet['available_balance'] as int? ?? 0;
                    final totalCharged = wallet['total_charged'] as int? ?? 0;
                    final totalSpent = wallet['total_spent'] as int? ?? 0;
                    final userId = wallet['user_id'] as String? ?? '';

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                          child: const Icon(LucideIcons.wallet),
                        ),
                        title: Text(
                          _getUserName(user),
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'موجودی قابل استفاده: ${PaymentConstants.formatAmount(availableBalance)}',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                    : AppTheme.lightTextSecondary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'کل شارژ: ${PaymentConstants.formatAmount(totalCharged)}',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                    : AppTheme.lightTextSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              'کل خرج: ${PaymentConstants.formatAmount(totalSpent)}',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                    : AppTheme.lightTextSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<void>(
                          icon: const Icon(LucideIcons.moreVertical),
                          itemBuilder: (context) => [
                            PopupMenuItem<void>(
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.plus, size: 18, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('شارژ دستی'),
                                ],
                              ),
                              onTap: () => _chargeWallet(userId),
                            ),
                            PopupMenuItem<void>(
                              child: Row(
                                children: [
                                  Icon(LucideIcons.edit, size: 18, color: AppTheme.goldColor),
                                  SizedBox(width: 8.w),
                                  const Text('اصلاح موجودی'),
                                ],
                              ),
                              onTap: () => _adjustWalletBalance(userId, availableBalance),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }
}

