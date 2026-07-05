import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/payment_history_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/widgets/wallet_balance_card.dart';
import 'package:gymaipro/payment/widgets/wallet_colors.dart';
import 'package:gymaipro/payment/utils/wallet_refresh_notifier.dart';
import 'package:gymaipro/payment/widgets/wallet_top_up_sheet.dart';
import 'package:gymaipro/payment/widgets/wallet_transaction_tile.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/date_utils.dart' as app_date_utils;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _RecentEntry {
  _RecentEntry({required this.date, this.wallet, this.payment})
    : assert(wallet != null || payment != null);

  final DateTime date;
  final WalletTransaction? wallet;
  final PaymentTransaction? payment;
}

/// بدنهٔ مشترک کیف پول — برای تب باشگاه من و صفحهٔ مستقل.
class WalletOverview extends StatefulWidget {
  const WalletOverview({
    super.key,
    this.includeGatewayPayments = true,
    this.openChargeOnStart = false,
  });

  /// وقتی از مسیر یکپارچه `/wallet-charge` به تب مالی می‌رویم.
  static bool pendingChargeSheet = false;

  final bool includeGatewayPayments;
  final bool openChargeOnStart;

  @override
  State<WalletOverview> createState() => WalletOverviewState();
}

class WalletOverviewState extends State<WalletOverview> {
  final WalletService _walletService = WalletService();
  final PaymentHistoryService _paymentHistoryService = PaymentHistoryService();

  Wallet? _wallet;
  List<_RecentEntry> _recentEntries = [];
  bool _isLoading = true;
  late final void Function(WalletRefreshSignal) _refreshListener;

  @override
  void initState() {
    super.initState();
    _refreshListener = (WalletRefreshSignal signal) {
      if (mounted) {
        unawaited(reload(
          refreshBalance: !signal.balanceAlreadyRefreshed,
        ));
      }
    };
    WalletRefreshNotifier.listen(_refreshListener);
    _load();
    final shouldOpenCharge =
        widget.openChargeOnStart || WalletOverview.pendingChargeSheet;
    if (WalletOverview.pendingChargeSheet) {
      WalletOverview.pendingChargeSheet = false;
    }
    if (shouldOpenCharge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openChargeSheet());
    }
  }

  @override
  void dispose() {
    WalletRefreshNotifier.unlisten(_refreshListener);
    super.dispose();
  }

  Future<void> reload({bool refreshBalance = false}) async {
    if (refreshBalance) {
      await _walletService.refreshUserWallet();
    }
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final overview = await _walletService.loadWalletOverview();
      final wallet = overview.wallet;

      List<_RecentEntry> entries = overview.transactions
          .map((t) => _RecentEntry(date: t.createdAt, wallet: t))
          .toList();

      if (widget.includeGatewayPayments && wallet != null) {
        final payments = await _paymentHistoryService.getDirectPayments(
          limit: 10,
        );
        entries = [
          ...entries,
          ...payments.map((p) => _RecentEntry(date: p.createdAt, payment: p)),
        ];
        entries.sort((a, b) => b.date.compareTo(a.date));
        entries = entries.take(12).toList();
      }

      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _recentEntries = entries;
      });
    } catch (e) {
      debugPrint('خطا در بارگذاری کیف پول: $e');
      if (!mounted) return;
      setState(() {
        _wallet = null;
        _recentEntries = [];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openChargeSheet() async {
    await WalletTopUpSheet.show(context);
    // موجودی بعد از بازگشت از درگاه (deeplink) به‌روز می‌شود.
  }

  void _openHistory() {
    Navigator.pushNamed(context, '/payment-history');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => reload(refreshBalance: true),
      color: WalletColors.accent(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_wallet != null)
              WalletBalanceCard(
                wallet: _wallet!,
                onCharge: _openChargeSheet,
                onViewHistory: _openHistory,
              )
            else
              _emptyWalletCard(context),
            SizedBox(height: 20.h),
            _recentSection(context),
          ],
        ),
      ),
    );
  }

  Widget _emptyWalletCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: WalletColors.cardSurface(context),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: WalletColors.cardBorder(context)),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.wallet,
            size: 40.sp,
            color: WalletColors.accent(context).withValues(alpha: 0.7),
          ),
          SizedBox(height: 12.h),
          Text(
            'کیف پول در دسترس نیست',
            style: WalletColors.titleStyle(context),
          ),
          SizedBox(height: 6.h),
          Text(
            'لطفاً دوباره وارد شوید یا صفحه را تازه‌سازی کنید.',
            textAlign: TextAlign.center,
            style: WalletColors.captionStyle(context),
          ),
        ],
      ),
    );
  }

  Widget _recentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تراکنش‌های اخیر',
          style: WalletColors.titleStyle(context).copyWith(fontSize: 15.sp),
        ),
        SizedBox(height: 8.h),
        if (_recentEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: WalletColors.cardSurface(context),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: WalletColors.cardBorder(context)),
            ),
            child: Text(
              'هنوز تراکنشی ثبت نشده',
              textAlign: TextAlign.center,
              style: WalletColors.captionStyle(context),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: WalletColors.cardSurface(context),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: WalletColors.cardBorder(context)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: Column(
              children: [
                for (var i = 0; i < _recentEntries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: WalletColors.cardBorder(context),
                    ),
                  _buildEntry(_recentEntries[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEntry(_RecentEntry entry) {
    final dateLabel = _formatDateTime(entry.date);
    if (entry.wallet != null) {
      return WalletTransactionTile.fromWallet(
        entry.wallet!,
        dateLabel: dateLabel,
      );
    }
    return WalletTransactionTile.fromPayment(
      entry.payment!,
      dateLabel: dateLabel,
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
}
