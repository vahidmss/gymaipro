import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/discount_code.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentSummary extends StatelessWidget {
  const PaymentSummary({
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    super.key,
    this.appliedDiscount,
  });
  final int originalAmount;
  final int discountAmount;
  final int finalAmount;
  final DiscountCode? appliedDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calculator,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
              const SizedBox(width: 8),
              Text(
                'خلاصه پرداخت',
                style: GoogleFonts.vazirmatn(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // مبلغ اصلی
          _buildSummaryRow(
            'مبلغ اصلی:',
            PaymentConstants.formatAmount(originalAmount),
            isOriginal: true,
          ),

          // تخفیف
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'تخفیف:',
              '- ${PaymentConstants.formatAmount(discountAmount)}',
              isDiscount: true,
            ),
            if (appliedDiscount != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'کد: ${appliedDiscount!.code}',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 12.sp,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(color: Colors.white24),
          ],
          const SizedBox(height: 8),

          // مبلغ نهایی
          _buildSummaryRow(
            'مبلغ قابل پرداخت:',
            PaymentConstants.formatAmount(finalAmount),
            isFinal: true,
          ),

          // درصد تخفیف
          if (discountAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.percent, color: Colors.green, size: 16.sp),
                  const SizedBox(width: 6),
                  Text(
                    'شما ${_calculateDiscountPercentage()}% صرفه‌جویی کرده‌اید',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String amount, {
    bool isOriginal = false,
    bool isDiscount = false,
    bool isFinal = false,
  }) {
    Color textColor = Colors.white70;
    FontWeight fontWeight = FontWeight.normal;
    double fontSize = 14;

    if (isDiscount) {
      textColor = Colors.green;
      fontWeight = FontWeight.w500;
    } else if (isFinal) {
      textColor = AppTheme.goldColor;
      fontWeight = FontWeight.bold;
      fontSize = 16;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.vazirmatn(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.vazirmatn(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _calculateDiscountPercentage() {
    if (originalAmount == 0) return '0';
    final percentage = (discountAmount / originalAmount) * 100;
    return percentage.toStringAsFixed(0);
  }
}
