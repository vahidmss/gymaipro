import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/payment/services/trainer_escrow_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// صفحه گزارش‌های مالی
class AdminFinancialScreen extends StatefulWidget {
  const AdminFinancialScreen({super.key});

  @override
  State<AdminFinancialScreen> createState() => _AdminFinancialScreenState();
}

class _AdminFinancialScreenState extends State<AdminFinancialScreen> {
  final AdminService _adminService = AdminService();
  final TrainerEscrowService _escrowService = TrainerEscrowService();
  Map<String, dynamic> _report = {};
  Map<String, dynamic> _escrowSummary = {};
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final report = await _adminService.getFinancialReport(
        startDate: _startDate,
        endDate: _endDate,
      );
      final escrow = await _escrowService.getAdminEscrowOverview(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _report = report;
          _escrowSummary = escrow['summary'] as Map<String, dynamic>? ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری گزارش: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator.withValues(alpha: 0.3)
              : AppTheme.lightDividerColor.withValues(alpha: 0.5),
        ),
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
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.7)
                  : AppTheme.lightTextSecondary,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            PaymentConstants.formatAmount(value),
            style: TextStyle(
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(LucideIcons.calendar),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day} - ${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                        : 'انتخاب بازه زمانی',
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _loadReport();
                },
                icon: const Icon(LucideIcons.x),
                tooltip: 'حذف فیلتر',
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.goldColor,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReport,
                  color: AppTheme.goldColor,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'گزارش مالی',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: LucideIcons.arrowDownCircle,
                                title: 'کل درآمد',
                                value: _report['total_revenue'] as int? ?? 0,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: LucideIcons.arrowUpCircle,
                                title: 'کل بازپرداخت',
                                value: _report['total_refunds'] as int? ?? 0,
                                color: Colors.red,
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
                                value: _report['net_revenue'] as int? ?? 0,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: LucideIcons.receipt,
                                title: 'تعداد تراکنش',
                                value: _report['transaction_count'] as int? ?? 0,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Escrow مربیان',
                          style: TextStyle(
                            color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: LucideIcons.shield,
                                title: 'در اختیار پلتفرم',
                                value: _escrowSummary['in_platform'] as int? ?? 0,
                                color: Colors.purple,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: LucideIcons.clock,
                                title: 'در انتظار آزادسازی',
                                value: (_escrowSummary['in_hold'] as int? ?? 0) +
                                    (_escrowSummary['in_edit_window'] as int? ?? 0),
                                color: Colors.orange,
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
                                icon: LucideIcons.percent,
                                title: 'کمیسیون پلتفرم',
                                value: _escrowSummary['total_commission'] as int? ?? 0,
                                color: Colors.teal,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: LucideIcons.wallet,
                                title: 'قابل برداشت مربیان',
                                value: _escrowSummary['withdrawable'] as int? ?? 0,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _buildStatCard(
                          context,
                          icon: LucideIcons.calculator,
                          title: 'میانگین تراکنش',
                          value: _report['average_transaction'] as int? ?? 0,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

