import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/payment_history_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/payment/widgets/wallet_balance_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/date_utils.dart' as app_date_utils;
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// آیتم تراکنش اخیر: یا کیف‌پول یا پرداخت درگاهی
class _RecentEntry {
  _RecentEntry({required this.date, this.wallet, this.payment})
    : assert(wallet != null || payment != null);
  final DateTime date;
  final WalletTransaction? wallet;
  final PaymentTransaction? payment;
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final PaymentHistoryService _paymentHistoryService = PaymentHistoryService();

  Wallet? _wallet;
  List<_RecentEntry> _recentEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
    });

    try {
      final wallet = await _walletService.getUserWallet();
      final walletTx = await _walletService.getWalletTransactions(limit: 20);
      final paymentTx = await _paymentHistoryService.getDirectPayments(
        
      );
      final List<_RecentEntry> merged = [
        ...walletTx.map((t) => _RecentEntry(date: t.createdAt, wallet: t)),
        ...paymentTx.map((t) => _RecentEntry(date: t.createdAt, payment: t)),
      ];
      merged.sort((a, b) => b.date.compareTo(a.date));
      final recent = merged.take(20).toList();

      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _wallet = wallet;
          _recentEntries = recent;
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _wallet = null;
          _recentEntries = [];
        });
      }
      debugPrint('خطا در بارگذاری داده‌های کیف پول: $e');
    } finally {
      WidgetSafetyUtils.safeSetState(this, () {
        _isLoading = false;
      });
    }
  }

  void _onChargeWallet() {
    if (context.mounted) {
      Navigator.pushNamed(context, '/wallet-charge');
    }
  }

  void _onViewHistory() {
    if (context.mounted) {
      Navigator.pushNamed(context, '/payment-history');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          title: Text(
            'کیف پول',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldColor,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
            onPressed: () => WidgetSafetyUtils.safePop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                LucideIcons.refreshCw,
                color: AppTheme.goldColor,
              ),
              onPressed: _loadWalletData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadWalletData,
                color: AppTheme.goldColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // کارت موجودی کیف پول
                      if (_wallet != null)
                        WalletBalanceCard(
                          wallet: _wallet!,
                          onCharge: _onChargeWallet,
                          onViewHistory: _onViewHistory,
                        )
                      else
                        _buildNoWalletState(context, isDark),
                      SizedBox(height: 24.h),

                      // تراکنش‌های اخیر
                      _buildRecentTransactions(context, isDark),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// حالت عدم وجود کیف پول (کاربر وارد نشده یا کیف پول یافت نشد)
  Widget _buildNoWalletState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.wallet,
            size: 56.sp,
            color: AppTheme.goldColor.withValues(alpha: 0.6),
          ),
          SizedBox(height: 16.h),
          Text(
            'کیف پول یافت نشد',
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'لطفاً وارد شوید یا دوباره تلاش کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: context.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.history,
                  size: 20.sp,
                  color: AppTheme.goldColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'تراکنش‌های اخیر',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            if (_recentEntries.isNotEmpty)
              TextButton.icon(
                onPressed: _onViewHistory,
                icon: Icon(
                  LucideIcons.arrowLeft,
                  size: 16.sp,
                  color: AppTheme.goldColor,
                ),
                label: Text(
                  'مشاهده همه',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),

        if (_recentEntries.isEmpty) ...[
          Container(
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkGreySeparator
                    : AppTheme.lightDividerColor,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.fileText,
                      color: AppTheme.goldColor,
                      size: 48.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'هنوز تراکنشی انجام نداده‌اید',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 16.sp,
                      color: context.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'پس از انجام اولین تراکنش، تاریخچه آن اینجا نمایش داده می‌شود',
                    textAlign: TextAlign.center,
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                      color: context.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ..._recentEntries.map(
            (e) => e.wallet != null
                ? _buildTransactionItem(e.wallet!, context, isDark)
                : _buildPaymentTransactionItem(e.payment!, context, isDark),
          ),
        ],
      ],
    );
  }

  /// تاریخ شمسی کامل برای دیالوگ: «۲۶ مهر ۱۴۰۴، ۱۸:۵۷»
  String _formatDateTimeFull(DateTime dateTime) {
    final j = Jalali.fromDateTime(dateTime);
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '${j.day} ${months[j.month]} ${j.year}، $h:$m';
  }

  void _showTransactionDetailDialog(
    BuildContext context,
    WalletTransaction transaction,
    bool isDark,
  ) {
    final transactionColor = Color(
      int.parse('0xFF${transaction.color.substring(1)}'),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: transactionColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        transaction.icon,
                        style: TextStyle(fontSize: 28.sp),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.typeText,
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            (transaction.isPositive ? '+' : '-') +
                                PaymentConstants.formatAmount(
                                  transaction.amount,
                                ),
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: transactionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(ctx).pop(),
                      color: context.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _detailRow(ctx, 'توضیحات', transaction.description),
                _detailRow(
                  ctx,
                  'تاریخ و ساعت',
                  _formatDateTimeFull(transaction.createdAt),
                ),
                _detailRow(
                  ctx,
                  'موجودی قبل',
                  PaymentConstants.formatAmount(transaction.balanceBefore),
                ),
                _detailRow(
                  ctx,
                  'موجودی بعد',
                  PaymentConstants.formatAmount(transaction.balanceAfter),
                ),
                if (transaction.referenceId != null &&
                    transaction.referenceId!.isNotEmpty)
                  _detailRow(ctx, 'شناسه مرجع', transaction.referenceId!),
                SizedBox(height: 16.h),
                Align(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'بستن',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                color: context.textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    WalletTransaction transaction,
    BuildContext context,
    bool isDark,
  ) {
    final transactionColor = Color(
      int.parse('0xFF${transaction.color.substring(1)}'),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTransactionDetailDialog(context, transaction, isDark),
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkGreySeparator
                  : AppTheme.lightDividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: transactionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    transaction.icon,
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.typeText,
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      transaction.description,
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 12.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            _formatDateTime(transaction.createdAt),
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: transactionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      (transaction.isPositive ? '+' : '-') +
                          PaymentConstants.formatAmount(transaction.amount),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: transactionColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.wallet,
                        size: 11.sp,
                        color: context.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          'موجودی: ${PaymentConstants.formatAmount(transaction.balanceAfter)}',
                          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                            fontSize: 11.sp,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetailDialog(
    BuildContext context,
    PaymentTransaction transaction,
    bool isDark,
  ) {
    final statusKey = transaction.status.name;
    final statusColor = Color(
      int.parse(
        '0xFF${PaymentConstants.getStatusColor(statusKey).substring(1)}',
      ),
    );
    // مبلغِ «پرداخت موفق» با طلایی تا با «ورود پول» (سبز) اشتباه نشود
    final amountColor = transaction.status == TransactionStatus.completed
        ? AppTheme.goldColor
        : statusColor;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(
                        PaymentConstants.getStatusIcon(statusKey),
                        style: TextStyle(fontSize: 28.sp),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description,
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            PaymentConstants.formatAmount(
                              transaction.finalAmount,
                            ),
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: amountColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(ctx).pop(),
                      color: context.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _detailRow(ctx, 'وضعیت', transaction.statusText),
                _detailRow(
                  ctx,
                  'مبلغ نهایی',
                  PaymentConstants.formatAmount(transaction.finalAmount),
                ),
                if (transaction.discountAmount > 0)
                  _detailRow(
                    ctx,
                    'مبلغ تخفیف',
                    PaymentConstants.formatAmount(transaction.discountAmount),
                  ),
                if (transaction.amount != transaction.finalAmount)
                  _detailRow(
                    ctx,
                    'مبلغ اولیه',
                    PaymentConstants.formatAmount(transaction.amount),
                  ),
                _detailRow(
                  ctx,
                  'تاریخ و ساعت',
                  _formatDateTimeFull(transaction.createdAt),
                ),
                _detailRow(ctx, 'شناسه', transaction.id),
                if (transaction.completedAt != null)
                  _detailRow(
                    ctx,
                    'تاریخ تکمیل',
                    _formatDateTimeFull(transaction.completedAt!),
                  ),
                SizedBox(height: 16.h),
                Align(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'بستن',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTransactionItem(
    PaymentTransaction transaction,
    BuildContext context,
    bool isDark,
  ) {
    final statusKey = transaction.status.name;
    final statusColor = Color(
      int.parse(
        '0xFF${PaymentConstants.getStatusColor(statusKey).substring(1)}',
      ),
    );
    // مبلغِ «پرداخت موفق» با طلایی تا با «ورود پول» (سبز) اشتباه نشود
    final amountColor = transaction.status == TransactionStatus.completed
        ? AppTheme.goldColor
        : statusColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPaymentDetailDialog(context, transaction, isDark),
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkGreySeparator
                  : AppTheme.lightDividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8.r,
                offset: Offset(0.w, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    PaymentConstants.getStatusIcon(statusKey),
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      transaction.statusText,
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 12.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            _formatDateTime(transaction.createdAt),
                            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                              fontSize: 11.sp,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: amountColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      PaymentConstants.formatAmount(transaction.finalAmount),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تاریخ به سبک شمسی در لیست: «۲۶ مهر» یا «امروز، ۱۸:۵۷» / «دیروز، ۱۸:۵۷»
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diffDays = today.difference(dtDay).inDays;
    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (diffDays == 0) {
      final diff = now.difference(dateTime);
      if (diff.inMinutes < 1) return 'همین الان';
      if (diff.inHours < 1) return '${diff.inMinutes} دقیقه پیش';
      return 'امروز، $timeStr';
    }
    if (diffDays == 1) return 'دیروز، $timeStr';
    return app_date_utils.toJalali(dateTime);
  }
}
