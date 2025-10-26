import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/widgets/wallet_balance_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final wallet = await _walletService.getUserWallet();
      final transactions = await _walletService.getWalletTransactions(
        limit: 20,
      );

      setState(() {
        _wallet = wallet;
        _transactions = transactions;
      });
    } catch (e) {
      debugPrint('خطا در بارگذاری داده‌های کیف پول: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onChargeWallet() {
    // TODO: Navigate to wallet charge screen
    Navigator.pushNamed(context, '/wallet-charge');
  }

  void _onViewHistory() {
    // TODO: Navigate to full transaction history
    Navigator.pushNamed(context, '/payment-history');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'کیف پول',
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
                        ),
                      const SizedBox(height: 24),

                      // تراکنش‌های اخیر
                      _buildRecentTransactions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تراکنش‌های اخیر',
              style: GoogleFonts.vazirmatn(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldColor,
              ),
            ),
            if (_transactions.isNotEmpty)
              TextButton(
                onPressed: _onViewHistory,
                child: Text(
                  'مشاهده همه',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 14.sp,
                    color: AppTheme.goldColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_transactions.isEmpty) ...[
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.fileText,
                    color: Colors.white54,
                    size: 48.sp,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'هنوز تراکنشی انجام نداده‌اید',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 16.sp,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ..._transactions.map(_buildTransactionItem),
        ],
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
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
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Color(
                int.parse('0xFF${transaction.color.substring(1)}'),
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                transaction.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeText,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.description,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(transaction.createdAt),
                  style: GoogleFonts.vazirmatn(
                    fontSize: 11.sp,
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
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(
                    int.parse('0xFF${transaction.color.substring(1)}'),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'موجودی: ${transaction.formattedBalanceAfter}',
                style: GoogleFonts.vazirmatn(
                  fontSize: 11.sp,
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
