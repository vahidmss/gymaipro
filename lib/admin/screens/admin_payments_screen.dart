import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه مدیریت پرداخت‌ها
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _adminService.getAllPaymentTransactions(
        statusFilter: _selectedStatusFilter == 'all' ? null : _selectedStatusFilter,
      );
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری تراکنش‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refundTransaction(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بازپرداخت تراکنش'),
        content: const Text('آیا مطمئن هستید که می‌خواهید این تراکنش را بازپرداخت کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بازپرداخت'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _adminService.refundTransaction(transactionId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تراکنش با موفقیت بازپرداخت شد'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTransactions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطا در بازپرداخت تراکنش'),
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'در انتظار';
      case 'completed':
        return 'تکمیل شده';
      case 'failed':
        return 'ناموفق';
      case 'refunded':
        return 'بازپرداخت شده';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatusFilter,
            decoration: InputDecoration(
              labelText: 'فیلتر وضعیت',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('همه')),
              DropdownMenuItem(value: 'pending', child: Text('در انتظار')),
              DropdownMenuItem(value: 'completed', child: Text('تکمیل شده')),
              DropdownMenuItem(value: 'failed', child: Text('ناموفق')),
              DropdownMenuItem(value: 'refunded', child: Text('بازپرداخت شده')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedStatusFilter = value);
                _loadTransactions();
              }
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _transactions.isEmpty
                  ? Center(
                      child: Text(
                        'تراکنشی یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          final user = transaction['user'] as Map<String, dynamic>?;
                          final amount = transaction['amount'] as int? ?? 0;
                          final status = transaction['status'] as String? ?? 'pending';

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                                child: const Icon(LucideIcons.creditCard),
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
                                    PaymentConstants.formatAmount(amount),
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Chip(
                                    label: Text(_getStatusLabel(status)),
                                    backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                                    labelStyle: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 12.sp,
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              trailing: status == 'completed'
                                  ? PopupMenuButton<void>(
                                      icon: const Icon(LucideIcons.moreVertical),
                                      itemBuilder: (context) => [
                                        PopupMenuItem<void>(
                                          child: const Row(
                                            children: [
                                              Icon(LucideIcons.rotateCcw, size: 18),
                                              SizedBox(width: 8),
                                              Text('بازپرداخت'),
                                            ],
                                          ),
                                          onTap: () => _refundTransaction(
                                            transaction['id'] as String,
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
        ),
      ],
    );
  }
}

