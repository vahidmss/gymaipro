import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/payment_history_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/date_utils.dart' as app_date_utils;
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// یک آیتم در لیست یکپارچه: یا تراکنش کیف‌پول یا تراکنش پرداخت درگاهی
class _HistoryEntry {
  _HistoryEntry({required this.date, this.wallet, this.payment})
    : assert(wallet != null || payment != null);
  final DateTime date;
  final WalletTransaction? wallet;
  final PaymentTransaction? payment;
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final WalletService _walletService = WalletService();
  final PaymentHistoryService _paymentHistoryService = PaymentHistoryService();

  List<WalletTransaction> _walletTransactions = [];
  List<PaymentTransaction> _paymentTransactions = [];
  List<_HistoryEntry> _mergedList = [];
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _walletOffset = 0;
  bool _isLoadingMore = false;
  bool _hasMoreWallet = true;
  WalletTransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _mergeAndFilter() {
    final List<_HistoryEntry> walletEntries = _walletTransactions
        .map((t) => _HistoryEntry(date: t.createdAt, wallet: t))
        .toList();
    final List<_HistoryEntry> paymentEntries = _paymentTransactions
        .map((t) => _HistoryEntry(date: t.createdAt, payment: t))
        .toList();
    List<_HistoryEntry> combined = [...walletEntries, ...paymentEntries];

    if (_selectedType != null) {
      if (_selectedType == WalletTransactionType.payment) {
        combined = combined.where((e) {
          if (e.wallet != null)
            return e.wallet!.type == WalletTransactionType.payment;
          if (e.payment != null) return true; // همهٔ پرداخت‌های درگاهی
          return false;
        }).toList();
      } else {
        combined = combined
            .where((e) => e.wallet != null && e.wallet!.type == _selectedType)
            .toList();
      }
    }

    combined.sort((a, b) => b.date.compareTo(a.date));
    _mergedList = combined;
  }

  Future<void> _loadTransactionHistory() async {
    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
    });

    try {
      _walletOffset = 0;
      _hasMoreWallet = true;
      final walletList = await _walletService.getWalletTransactions(
        limit: _pageSize,
        offset: _walletOffset,
        type: _selectedType,
      );
      final paymentList = await _paymentHistoryService.getDirectPayments(
        limit: 100,
        offset: 0,
      );

      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _walletTransactions = walletList;
          _paymentTransactions = paymentList;
          _walletOffset = walletList.length;
          _hasMoreWallet = walletList.length == _pageSize;
          _mergeAndFilter();
        });
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری تاریخچه تراکنش‌ها: $e');
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _walletTransactions = [];
          _paymentTransactions = [];
          _mergedList = [];
        });
      }
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMoreWallet) return;
    if (_selectedType != null &&
        _selectedType != WalletTransactionType.payment) {
      // وقتی فیلتر غیر از «همه» و «پرداخت» است، ادغام با پرداخت‌ها معنا ندارد؛ فقط کیف‌پول
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreWallet();
      }
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreWallet();
    }
  }

  Future<void> _loadMoreWallet() async {
    if (_isLoadingMore || !_hasMoreWallet) return;
    WidgetSafetyUtils.safeSetState(this, () {
      _isLoadingMore = true;
    });
    try {
      final next = await _walletService.getWalletTransactions(
        limit: _pageSize,
        offset: _walletOffset,
        type: _selectedType,
      );
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _walletTransactions = [..._walletTransactions, ...next];
          _walletOffset += next.length;
          _hasMoreWallet = next.length == _pageSize;
          _mergeAndFilter();
        });
      }
    } catch (e) {
      debugPrint('خطا در بارگذاری بیشتر تراکنش‌ها: $e');
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onSelectType(WalletTransactionType? type) async {
    WidgetSafetyUtils.safeSetState(this, () {
      _selectedType = type;
    });
    await _loadTransactionHistory();
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
            'تاریخچه تراکنش‌ها',
            style: GoogleFonts.vazirmatn(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldColor,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: AppTheme.goldColor),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                LucideIcons.refreshCw,
                color: AppTheme.goldColor,
              ),
              onPressed: _loadTransactionHistory,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadTransactionHistory,
                color: AppTheme.goldColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // هدر بخش مثل صفحه کیف پول
                      Row(
                        children: [
                          Icon(
                            LucideIcons.history,
                            size: 20.sp,
                            color: AppTheme.goldColor,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'تراکنش‌ها',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // نوار فیلتر
                      _buildFilters(context, isDark),
                      SizedBox(height: 16.h),
                      // لیست یا حالت خالی
                      if (_mergedList.isEmpty)
                        _buildEmptyState(context, isDark)
                      else
                        ..._mergedList.map(
                          (e) => e.wallet != null
                              ? _buildWalletTransactionItem(
                                  context,
                                  e.wallet!,
                                  isDark,
                                )
                              : _buildPaymentTransactionItem(
                                  context,
                                  e.payment!,
                                  isDark,
                                ),
                        ),
                      if (_hasMoreWallet && _mergedList.isNotEmpty)
                        _buildLoadMoreIndicator(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Row(
        children: [
          Text(
            'فیلتر:',
            style: GoogleFonts.vazirmatn(
              fontSize: 13.sp,
              color: context.textSecondary,
            ),
          ),
          SizedBox(width: 8.w),
          DropdownButtonHideUnderline(
            child: DropdownButton<WalletTransactionType?>(
              value: _selectedType,
              dropdownColor: context.cardColor,
              style: GoogleFonts.vazirmatn(color: context.textColor),
              iconEnabledColor: AppTheme.goldColor,
              items: [
                const DropdownMenuItem<WalletTransactionType?>(
                  value: null,
                  child: Text('همه'),
                ),
                ...WalletTransactionType.values.map(
                  (t) => DropdownMenuItem<WalletTransactionType>(
                    value: t,
                    child: Text(_typeToText(t)),
                  ),
                ),
              ],
              onChanged: _onSelectType,
            ),
          ),
          const Spacer(),
          if (_selectedType != null)
            TextButton(
              onPressed: () => _onSelectType(null),
              child: Text(
                'حذف فیلتر',
                style: GoogleFonts.vazirmatn(
                  color: AppTheme.goldColor,
                  fontSize: 13.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _typeToText(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.charge:
        return 'شارژ کیف پول';
      case WalletTransactionType.payment:
        return 'پرداخت';
      case WalletTransactionType.refund:
        return 'بازگشت وجه';
      case WalletTransactionType.bonus:
        return 'پاداش';
      case WalletTransactionType.cashback:
        return 'کش‌بک';
      case WalletTransactionType.transferIn:
        return 'واریز';
      case WalletTransactionType.transferOut:
        return 'برداشت';
    }
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: _isLoadingMore
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : (!_hasMoreWallet
                  ? Text(
                      'همه تراکنش‌ها بارگذاری شد',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    )
                  : const SizedBox.shrink()),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
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
              style: GoogleFonts.vazirmatn(
                fontSize: 16.sp,
                color: context.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'پس از انجام اولین تراکنش یا پرداخت، تاریخچه آن اینجا نمایش داده می‌شود',
              textAlign: TextAlign.center,
              style: GoogleFonts.vazirmatn(
                fontSize: 13.sp,
                color: context.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  void _showWalletDetailDialog(
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
                            style: GoogleFonts.vazirmatn(
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
                            style: GoogleFonts.vazirmatn(
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
                      style: GoogleFonts.vazirmatn(
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
    // مبلغِ «پرداخت موفق» با طلایی نمایش داده شود تا با «ورود پول» (سبز) اشتباه نشود
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
                            style: GoogleFonts.vazirmatn(
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
                            style: GoogleFonts.vazirmatn(
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
                      style: GoogleFonts.vazirmatn(
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

  Widget _detailRow(BuildContext ctx, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: GoogleFonts.vazirmatn(
                fontSize: 13.sp,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.vazirmatn(
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

  Widget _buildWalletTransactionItem(
    BuildContext context,
    WalletTransaction transaction,
    bool isDark,
  ) {
    final transactionColor = Color(
      int.parse('0xFF${transaction.color.substring(1)}'),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showWalletDetailDialog(context, transaction, isDark),
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
                      style: GoogleFonts.vazirmatn(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      transaction.description,
                      style: GoogleFonts.vazirmatn(
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
                            style: GoogleFonts.vazirmatn(
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
                      style: GoogleFonts.vazirmatn(
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
                          style: GoogleFonts.vazirmatn(
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

  Widget _buildPaymentTransactionItem(
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
                      style: GoogleFonts.vazirmatn(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      transaction.statusText,
                      style: GoogleFonts.vazirmatn(
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
                            style: GoogleFonts.vazirmatn(
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
                        width: 1,
                      ),
                    ),
                    child: Text(
                      PaymentConstants.formatAmount(transaction.finalAmount),
                      style: GoogleFonts.vazirmatn(
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
}
