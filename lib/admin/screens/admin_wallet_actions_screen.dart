import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// صفحه تاریخچه عملیات ادمین روی کیف پول‌ها
class AdminWalletActionsScreen extends StatefulWidget {
  const AdminWalletActionsScreen({super.key});

  @override
  State<AdminWalletActionsScreen> createState() =>
      _AdminWalletActionsScreenState();
}

class _AdminWalletActionsScreenState extends State<AdminWalletActionsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _actions = [];
  bool _isLoading = false;
  String? _selectedActionType;
  String? _selectedAdminId;
  String? _selectedTargetUserId;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _isLoading = true);
    try {
      final actions = await _adminService.getAdminWalletActions(
        adminId: _selectedAdminId,
        targetUserId: _selectedTargetUserId,
        actionType: _selectedActionType,
      );
      if (mounted) {
        setState(() {
          _actions = actions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری تاریخچه: $e'),
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'نامشخص';
    try {
      final date = DateTime.parse(dateString);
      final jalali = Jalali.fromDateTime(date.toLocal());
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')} ${jalali.hour.toString().padLeft(2, '0')}:${jalali.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // فیلترها
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedActionType,
                  decoration: InputDecoration(
                    labelText: 'نوع عملیات',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('همه'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'charge',
                      child: Text('شارژ'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'adjustment',
                      child: Text('اصلاح'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedActionType = value);
                    _loadActions();
                  },
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedActionType = null;
                    _selectedAdminId = null;
                    _selectedTargetUserId = null;
                  });
                  _loadActions();
                },
                icon: const Icon(LucideIcons.x),
                tooltip: 'حذف فیلترها',
              ),
            ],
          ),
        ),
        // لیست عملیات
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : _actions.isEmpty
                  ? Center(
                      child: Text(
                        'عملیاتی یافت نشد',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadActions,
                      color: AppTheme.goldColor,
                      child: ListView.builder(
                        itemCount: _actions.length,
                        itemBuilder: (context, index) {
                          final action = _actions[index];
                          final actionType = action['action_type'] as String? ?? '';
                          final amount = action['amount'] as int? ?? 0;
                          final balanceBefore = action['balance_before'] as int? ?? 0;
                          final balanceAfter = action['balance_after'] as int? ?? 0;
                          final availableBalanceBefore = action['available_balance_before'] as int?;
                          final availableBalanceAfter = action['available_balance_after'] as int?;
                          final description = action['description'] as String? ?? '';
                          final createdAt = action['created_at'] as String?;

                          final admin = action['admin'] as Map<String, dynamic>?;
                          final targetUser = action['target_user'] as Map<String, dynamic>?;

                          final isCharge = actionType == 'charge';

                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: isCharge
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : AppTheme.goldColor.withValues(alpha: 0.2),
                                child: Icon(
                                  isCharge ? LucideIcons.plus : LucideIcons.edit,
                                  color: isCharge ? Colors.green : AppTheme.goldColor,
                                  size: 20.sp,
                                ),
                              ),
                              title: Text(
                                isCharge ? 'شارژ کیف پول' : 'اصلاح موجودی',
                                style: TextStyle(
                                  color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4.h),
                                  Text(
                                    'ادمین: ${_getUserName(admin)}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Text(
                                    'کاربر: ${_getUserName(targetUser)}',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(createdAt),
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextColor.withValues(alpha: 0.5)
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(
                                        'مبلغ',
                                        PaymentConstants.formatAmount(amount),
                                        isDark,
                                        isCharge ? Colors.green : AppTheme.goldColor,
                                      ),
                                      SizedBox(height: 8.h),
                                      _buildInfoRow(
                                        'موجودی قبل',
                                        PaymentConstants.formatAmount(balanceBefore),
                                        isDark,
                                      ),
                                      SizedBox(height: 8.h),
                                      _buildInfoRow(
                                        'موجودی بعد',
                                        PaymentConstants.formatAmount(balanceAfter),
                                        isDark,
                                        Colors.blue,
                                      ),
                                      if (availableBalanceBefore != null &&
                                          availableBalanceAfter != null) ...[
                                        SizedBox(height: 8.h),
                                        _buildInfoRow(
                                          'موجودی قابل استفاده قبل',
                                          PaymentConstants.formatAmount(availableBalanceBefore),
                                          isDark,
                                        ),
                                        SizedBox(height: 8.h),
                                        _buildInfoRow(
                                          'موجودی قابل استفاده بعد',
                                          PaymentConstants.formatAmount(availableBalanceAfter),
                                          isDark,
                                          Colors.blue,
                                        ),
                                      ],
                                      if (description.isNotEmpty) ...[
                                        SizedBox(height: 8.h),
                                        Divider(),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'توضیحات:',
                                          style: TextStyle(
                                            color: isDark
                                                ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                                                : AppTheme.lightTextSecondary,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            color: isDark
                                                ? AppTheme.darkTextColor
                                                : AppTheme.lightTextColor,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, [Color? valueColor]) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ??
                (isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor),
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                : AppTheme.lightTextSecondary,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}

