import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.1),
            AppTheme.cardColor,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر کیف پول
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  LucideIcons.wallet,
                  color: AppTheme.goldColor,
                  size: 24.sp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کیف پول',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldColor,
                      ),
                    ),
                    Text(
                      wallet.statusText,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (wallet.needsCharge)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'نیاز به شارژ',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 10.sp,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // موجودی اصلی
          Center(
            child: Column(
              children: [
                Text(
                  'موجودی',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wallet.formattedAvailableBalance,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // آمار کیف پول
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'کل شارژ',
                  wallet.formattedTotalCharged,
                  LucideIcons.trendingUp,
                  Colors.green,
                ),
              ),
              Container(width: 1.w, height: 40.h, color: Colors.white24),
              Expanded(
                child: _buildStatItem(
                  'کل خرج',
                  wallet.formattedTotalSpent,
                  LucideIcons.trendingDown,
                  Colors.red,
                ),
              ),
            ],
          ),

          if (wallet.blockedBalance > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.lock, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'موجودی مسدود: ${wallet.formattedBlockedBalance}',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 12.sp,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // دکمه‌های عملیات
          Row(
            children: [
              if (onCharge != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCharge,
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text(
                      'شارژ کیف پول',
                      style: GoogleFonts.vazirmatn(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],

              if (onCharge != null && onViewHistory != null)
                const SizedBox(width: 8),

              if (onViewHistory != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewHistory,
                    icon: const Icon(LucideIcons.history, size: 16),
                    label: Text(
                      'تاریخچه',
                      style: GoogleFonts.vazirmatn(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldColor,
                      side: const BorderSide(color: AppTheme.goldColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.vazirmatn(fontSize: 11.sp, color: Colors.white54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.vazirmatn(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
