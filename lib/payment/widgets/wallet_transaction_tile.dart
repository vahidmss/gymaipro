import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/payment/widgets/wallet_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.isCredit,
    super.key,
    this.onTap,
    this.icon,
  });

  factory WalletTransactionTile.fromWallet(
    WalletTransaction transaction, {
    required String dateLabel,
    VoidCallback? onTap,
  }) {
    return WalletTransactionTile(
      title: transaction.typeText,
      subtitle: dateLabel,
      amountText: (transaction.isPositive ? '+' : '-') +
          PaymentConstants.formatAmount(transaction.amount),
      isCredit: transaction.isPositive,
      icon: _walletIcon(transaction.type),
      onTap: onTap,
    );
  }

  factory WalletTransactionTile.fromPayment(
    PaymentTransaction transaction, {
    required String dateLabel,
    VoidCallback? onTap,
  }) {
    final completed = transaction.status == TransactionStatus.completed;
    return WalletTransactionTile(
      title: transaction.description,
      subtitle: completed ? dateLabel : transaction.statusText,
      amountText: PaymentConstants.formatAmount(transaction.finalAmount),
      isCredit: completed,
      icon: completed ? LucideIcons.circleCheck : LucideIcons.clock,
      onTap: onTap,
    );
  }

  final String title;
  final String subtitle;
  final String amountText;
  final bool isCredit;
  final IconData? icon;
  final VoidCallback? onTap;

  static IconData _walletIcon(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.charge:
        return LucideIcons.arrowDownToLine;
      case WalletTransactionType.payment:
        return LucideIcons.arrowUpFromLine;
      case WalletTransactionType.refund:
        return LucideIcons.rotateCcw;
      case WalletTransactionType.bonus:
      case WalletTransactionType.cashback:
        return LucideIcons.gift;
      case WalletTransactionType.transferIn:
        return LucideIcons.download;
      case WalletTransactionType.transferOut:
        return LucideIcons.upload;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountColor =
        isCredit ? WalletColors.positive(context) : WalletColors.negative(context);
    final iconColor = WalletColors.accent(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon ?? LucideIcons.wallet,
                  size: 18.sp,
                  color: iconColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: WalletColors.primaryText(context),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: WalletColors.captionStyle(context)
                          .copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                amountText,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
