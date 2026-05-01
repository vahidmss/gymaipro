import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/widgets/wallet_balance_card.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen>
    with AutomaticKeepAliveClientMixin {
  final WalletService _walletService = WalletService();

  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

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
    Navigator.pushNamed(context, '/wallet-charge');
  }

  void _onViewHistory() {
    Navigator.pushNamed(context, '/payment-history');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                      _buildRecentTransactions(context, isDark),
                    ],
                  ),
                ),
              ),
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
            if (_transactions.isNotEmpty)
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
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),

        if (_transactions.isEmpty) ...[
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
          ..._transactions.map(
            (t) => _buildTransactionItem(t, context, isDark),
          ),
        ],
      ],
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

    return Container(
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
                    Text(
                      _formatDateTime(transaction.createdAt),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        color: context.textSecondary,
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
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: transactionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  transaction.changeText,
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
                children: [
                  Icon(
                    LucideIcons.wallet,
                    size: 11.sp,
                    color: context.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    transaction.formattedBalanceAfter,
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 11.sp,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'همین الان';
        }
        return '${difference.inMinutes} دقیقه پیش';
      }
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else {
      return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}

