import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/payment_history_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final PaymentHistoryService _paymentHistoryService = PaymentHistoryService();

  late TabController _tabController;
  List<WalletTransaction> _walletTransactions = [];
  List<PaymentTransaction> _paymentTransactions = [];
  bool _isLoading = true;

  // Pagination & filters for wallet transactions
  final ScrollController _walletScrollController = ScrollController();
  static const int _pageSize = 20;
  int _walletOffset = 0;
  bool _isLoadingMoreWallet = false;
  bool _hasMoreWallet = true;
  WalletTransactionType? _selectedWalletType;

  // Pagination for direct payments
  final ScrollController _paymentScrollController = ScrollController();
  int _paymentOffset = 0;
  bool _isLoadingMorePayments = false;
  bool _hasMorePayments = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _walletScrollController.addListener(_onWalletScroll);
    _paymentScrollController.addListener(_onPaymentScroll);
    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _walletScrollController.dispose();
    _paymentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // initial load for wallet transactions with pagination
      _walletOffset = 0;
      _hasMoreWallet = true;
      final walletTransactions = await _walletService.getWalletTransactions(
        limit: _pageSize,
        offset: _walletOffset,
        type: _selectedWalletType,
      );
      _walletOffset += walletTransactions.length;
      _hasMoreWallet = walletTransactions.length == _pageSize;
      // initial load for direct payments
      _paymentOffset = 0;
      _hasMorePayments = true;
      final payments = await _paymentHistoryService.getDirectPayments(
        offset: _paymentOffset,
      );
      _paymentOffset += payments.length;
      _hasMorePayments = payments.length == _pageSize;

      setState(() {
        _walletTransactions = walletTransactions;
        _paymentTransactions = payments;
      });
    } catch (e) {
      debugPrint('خطا در بارگذاری تاریخچه تراکنش‌ها: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onWalletScroll() {
    if (_isLoadingMoreWallet || !_hasMoreWallet) return;
    if (_walletScrollController.position.pixels >=
        _walletScrollController.position.maxScrollExtent - 200) {
      _loadMoreWalletTransactions();
    }
  }

  Future<void> _loadMoreWalletTransactions() async {
    if (_isLoadingMoreWallet || !_hasMoreWallet) return;
    setState(() {
      _isLoadingMoreWallet = true;
    });
    try {
      final next = await _walletService.getWalletTransactions(
        limit: _pageSize,
        offset: _walletOffset,
        type: _selectedWalletType,
      );
      setState(() {
        _walletTransactions = [..._walletTransactions, ...next];
        _walletOffset += next.length;
        _hasMoreWallet = next.length == _pageSize;
      });
    } catch (e) {
      debugPrint('خطا در بارگذاری بیشتر تراکنش‌های کیف پول: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreWallet = false;
        });
      }
    }
  }

  Future<void> _onSelectWalletType(WalletTransactionType? type) async {
    setState(() {
      _selectedWalletType = type;
    });
    await _loadTransactionHistory();
  }

  void _onPaymentScroll() {
    if (_isLoadingMorePayments || !_hasMorePayments) return;
    if (_paymentScrollController.position.pixels >=
        _paymentScrollController.position.maxScrollExtent - 200) {
      _loadMorePayments();
    }
  }

  Future<void> _loadMorePayments() async {
    if (_isLoadingMorePayments || !_hasMorePayments) return;
    setState(() {
      _isLoadingMorePayments = true;
    });
    try {
      final next = await _paymentHistoryService.getDirectPayments(
        offset: _paymentOffset,
      );
      setState(() {
        _paymentTransactions = [..._paymentTransactions, ...next];
        _paymentOffset += next.length;
        _hasMorePayments = next.length == _pageSize;
      });
    } catch (e) {
      debugPrint('خطا در بارگذاری بیشتر پرداخت‌های مستقیم: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMorePayments = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'تاریخچه پرداخت‌ها',
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.goldColor,
            labelColor: AppTheme.goldColor,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.vazirmatn(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.vazirmatn(fontSize: 14),
            tabs: const [
              Tab(icon: Icon(LucideIcons.wallet), text: 'کیف پول'),
              Tab(icon: Icon(LucideIcons.creditCard), text: 'پرداخت‌ها'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  // تراکنش‌های کیف پول
                  _buildWalletTransactionsList(),

                  // تراکنش‌های پرداخت
                  _buildPaymentTransactionsList(),
                ],
              ),
      ),
    );
  }

  Widget _buildWalletTransactionsList() {
    return RefreshIndicator(
      onRefresh: _loadTransactionHistory,
      color: AppTheme.goldColor,
      child: Column(
        children: [
          _buildWalletFilters(),
          Expanded(
            child: _walletTransactions.isEmpty
                ? _buildEmptyState('تراکنش کیف پول')
                : ListView.builder(
                    controller: _walletScrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount:
                        _walletTransactions.length + (_hasMoreWallet ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _walletTransactions.length) {
                        return _buildLoadMoreIndicator();
                      }
                      final transaction = _walletTransactions[index];
                      return _buildWalletTransactionItem(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Text(
            'فیلتر:',
            style: GoogleFonts.vazirmatn(
              fontSize: 13.sp,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<WalletTransactionType?>(
              value: _selectedWalletType,
              dropdownColor: AppTheme.cardColor,
              style: GoogleFonts.vazirmatn(color: Colors.white),
              iconEnabledColor: AppTheme.goldColor,
              items: [
                const DropdownMenuItem<WalletTransactionType?>(
                  child: Text('همه'),
                ),
                ...WalletTransactionType.values.map(
                  (t) => DropdownMenuItem<WalletTransactionType>(
                    value: t,
                    child: Text(_typeToText(t)),
                  ),
                ),
              ],
              onChanged: _onSelectWalletType,
            ),
          ),
          const Spacer(),
          if (_selectedWalletType != null)
            TextButton(
              onPressed: () => _onSelectWalletType(null),
              child: Text(
                'حذف فیلتر',
                style: GoogleFonts.vazirmatn(color: AppTheme.goldColor),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMoreWallet
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
                        color: Colors.white38,
                      ),
                    )
                  : const SizedBox.shrink()),
      ),
    );
  }

  Widget _buildPaymentTransactionsList() {
    return RefreshIndicator(
      onRefresh: _loadTransactionHistory,
      color: AppTheme.goldColor,
      child: _paymentTransactions.isEmpty
          ? _buildEmptyState('تراکنش پرداخت')
          : ListView.builder(
              controller: _paymentScrollController,
              padding: EdgeInsets.all(16.w),
              itemCount:
                  _paymentTransactions.length + (_hasMorePayments ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _paymentTransactions.length) {
                  return _buildPaymentLoadMoreIndicator();
                }
                final transaction = _paymentTransactions[index];
                return _buildPaymentTransactionItem(transaction);
              },
            ),
    );
  }

  Widget _buildPaymentLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMorePayments
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : (!_hasMorePayments
                  ? Text(
                      'همه پرداخت‌ها بارگذاری شد',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.sp,
                        color: Colors.white38,
                      ),
                    )
                  : const SizedBox.shrink()),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.fileText, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            'هنوز $type ندارید',
            style: GoogleFonts.vazirmatn(
              fontSize: 18.sp,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletTransactionItem(WalletTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: Color(
                int.parse('0xFF${transaction.color.substring(1)}'),
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                transaction.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeText,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.description,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(transaction.createdAt),
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.changeText,
                style: GoogleFonts.vazirmatn(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(
                    int.parse('0xFF${transaction.color.substring(1)}'),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'موجودی: ${transaction.formattedBalanceAfter}',
                style: GoogleFonts.vazirmatn(
                  fontSize: 12.sp,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTransactionItem(PaymentTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(
                      '0xFF${PaymentConstants.getStatusColor(transaction.status.toString()).substring(1)}',
                    ),
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    PaymentConstants.getStatusIcon(
                      transaction.status.toString(),
                    ),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.statusText,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 14.sp,
                        color: Color(
                          int.parse(
                            '0xFF${PaymentConstants.getStatusColor(transaction.status.toString()).substring(1)}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                transaction.formattedFinalAmount,
                style: GoogleFonts.vazirmatn(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(LucideIcons.hash, size: 14.sp, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                'شناسه: ${transaction.id}',
                style: GoogleFonts.vazirmatn(
                  fontSize: 12.sp,
                  color: Colors.white54,
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(transaction.createdAt),
                style: GoogleFonts.vazirmatn(
                  fontSize: 12.sp,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
