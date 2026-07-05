import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/payment/widgets/wallet_colors.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    required this.wallet,
    super.key,
    this.onCharge,
    this.onViewHistory,
  });

  final Wallet wallet;
  final VoidCallback? onCharge;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    final isDark = WalletColors.isDark(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: WalletColors.cardSurface(context),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: WalletColors.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'موجودی کیف پول',
            style: WalletColors.captionStyle(context),
          ),
          SizedBox(height: 8.h),
          Text(
            PaymentConstants.formatAmount(wallet.availableBalance),
            style: WalletColors.balanceStyle(context).copyWith(fontSize: 34.sp),
          ),
          if (wallet.blockedBalance > 0) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 14.sp,
                  color: WalletColors.secondaryText(context),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '${PaymentConstants.formatAmount(wallet.blockedBalance)} مسدود',
                    style: WalletColors.captionStyle(context),
                  ),
                ),
              ],
            ),
          ],
          if (onCharge != null) ...[
            SizedBox(height: 20.h),
            SizedBox(
              height: 48.h,
              child: FilledButton.icon(
                onPressed: onCharge,
                icon: Icon(LucideIcons.plus, size: 18.sp),
                label: Text(
                  'شارژ کیف پول',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: WalletColors.accent(context),
                  foregroundColor: AppTheme.onGoldColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
          if (onViewHistory != null) ...[
            SizedBox(height: 8.h),
            TextButton(
              onPressed: onViewHistory,
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppTheme.goldColor.withValues(alpha: 0.9)
                    : AppTheme.darkGold,
                padding: EdgeInsets.symmetric(vertical: 4.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تاریخچه تراکنش‌ها',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(LucideIcons.chevronLeft, size: 16.sp),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
