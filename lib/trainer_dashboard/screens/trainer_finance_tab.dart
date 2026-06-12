import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/services/payout_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_payout_request_screen.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_finance_service.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerFinanceTab extends StatefulWidget {
  const TrainerFinanceTab({super.key});

  @override
  State<TrainerFinanceTab> createState() => _TrainerFinanceTabState();
}

class _TrainerFinanceTabState extends State<TrainerFinanceTab> {
  final _finance = TrainerFinanceService();
  final _payoutService = PayoutService();
  bool _loading = true;
  Map<String, dynamic> _balances = const {};
  List<Map<String, dynamic>> _earnings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    WidgetSafetyUtils.safeSetState(this, () => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final b = await _finance.getTrainerBalances(user.id);
        final e = await _finance.getRecentEarnings(user.id, limit: 20);
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () {
            _balances = b;
            _earnings = e;
          });
        }
      } else {
        if (mounted) {
          WidgetSafetyUtils.safeSetState(
            this,
            () => _balances = const {'available': 0, 'onHold': 0, 'total': 0},
          );
        }
      }
    } finally {
      if (mounted) WidgetSafetyUtils.safeSetState(this, () => _loading = false);
    }
  }

  Future<void> _showTransferToWalletDialog(int maxWithdrawable) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
          title: Text(
            'انتقال به کیف پول شخصی',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'حداکثر قابل انتقال: ${PaymentConstants.formatAmount(maxWithdrawable)}',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5.sp,
                  color: context.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'مبلغ (تومان)',
                  hintText: 'مثلاً ۵۰۰۰۰۰',
                  labelStyle: TextStyle(fontFamily: AppTheme.fontFamily),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'مبلغ به کیف پول شخصی می‌رود و برای خرید در اپ قابل استفاده است.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.sp,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.onGoldColor,
              ),
              child: const Text('انتقال'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final amountToman = int.tryParse(controller.text.trim());
    if (amountToman == null || amountToman <= 0) {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'مبلغ معتبر وارد کنید',
        backgroundColor: AppTheme.errorColor,
      );
      return;
    }

    final amountRial = amountToman * 10;

    if (!mounted) return;
    WidgetSafetyUtils.safeShowSnackBar(
      context,
      'در حال انتقال...',
      backgroundColor: AppTheme.goldColor,
    );

    final result = await _payoutService.transferEarningsToPersonalWallet(
      trainerId: user.id,
      amount: amountRial,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await _load();
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        result['message'] as String? ?? 'انتقال انجام شد',
        backgroundColor: AppTheme.successColor,
      );
    } else {
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        result['error'] as String? ?? 'خطا در انتقال',
        backgroundColor: AppTheme.errorColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
        ),
      );
    }

    final int onHold = _balances['onHold'] as int? ?? 0;
    final int total = _balances['total'] as int? ?? 0;
    final int withdrawable = _balances['withdrawable'] as int? ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.goldColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // هدر بخش خلاصه مالی
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      color: AppTheme.goldColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'خلاصه مالی',
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // کارت‌های خلاصه مالی
              _summaryCard(
                context,
                'موجودی کل',
                total,
                LucideIcons.trendingUp,
                isDark
                    ? [
                        context.cardColor,
                        context.veryDarkBackground,
                      ]
                    : [
                        AppTheme.lightGradientStart,
                        AppTheme.lightGradientEnd,
                      ],
                isDark,
              ),
              SizedBox(height: 12.h),
              _summaryCard(
                context,
                'قابل برداشت',
                withdrawable,
                LucideIcons.checkCircle,
                isDark
                    ? [
                        AppTheme.successColor.withValues(alpha: 0.22),
                        AppTheme.successColor.withValues(alpha: 0.12),
                      ]
                    : [
                        AppTheme.successColor.withValues(alpha: 0.14),
                        AppTheme.successColor.withValues(alpha: 0.08),
                      ],
                isDark,
              ),
              SizedBox(height: 12.h),
              
              if (withdrawable > 0) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showTransferToWalletDialog(withdrawable),
                    icon: Icon(LucideIcons.wallet, size: 18.sp),
                    label: Text(
                      'انتقال به کیف پول شخصی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.onGoldColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      WidgetSafetyUtils.safeNavigate(
                        context,
                        () => const TrainerPayoutRequestScreen(),
                      );
                      Future<void>.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) _load();
                      });
                    },
                    icon: Icon(LucideIcons.landmark, size: 18.sp),
                    label: Text(
                      'برداشت به حساب بانکی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldColor,
                      side: BorderSide(
                        color: AppTheme.goldColor.withValues(alpha: 0.45),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              _summaryCard(
                context,
                'در انتظار آزادسازی',
                onHold,
                LucideIcons.clock,
                isDark
                    ? [
                        AppTheme.fatColor.withValues(alpha: 0.18),
                        AppTheme.fatColor.withValues(alpha: 0.1),
                      ]
                    : [
                        AppTheme.fatColor.withValues(alpha: 0.12),
                        AppTheme.fatColor.withValues(alpha: 0.06),
                      ],
                isDark,
              ),

              SizedBox(height: 32.h),

              // بخش توضیحات
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCardColor
                      : AppTheme.lightCardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkGreySeparator
                        : AppTheme.lightDividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 18.sp,
                          color: AppTheme.goldColor,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'سیاست نگه‌داری',
                          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'پس از ثبت برنامه، درآمد ۳ روز نگه‌داری می‌شود. سپس می‌توانید به کیف پول شخصی (برای خرید در اپ) منتقل کنید یا به حساب بانکی برداشت کنید. درآمد مربی در تب کیف پول نمایش داده نمی‌شود.',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        height: 1.7,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // بخش تراکنش‌های اخیر
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
                ],
              ),
              SizedBox(height: 16.h),

              // لیست تراکنش‌ها
              if (_earnings.isEmpty)
                _buildEmptyState(context, isDark)
              else
                ..._earnings.map((e) => _buildEarningTile(context, e, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String title,
    int amount,
    IconData icon,
    List<Color> gradientColors,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? context.textColor.withValues(alpha: 0.1)
              : AppTheme.goldColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppTheme.veryDarkBackground.withValues(alpha: 0.3)
                : AppTheme.veryDarkBackground.withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0.w, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isDark
                  ? context.textColor.withValues(alpha: 0.15)
                  : context.cardColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: isDark ? context.textColor : AppTheme.goldColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: isDark
                        ? context.textColor.withValues(alpha: 0.85)
                        : context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  PaymentConstants.formatAmount(amount),
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? context.textColor : context.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningTile(
    BuildContext context,
    Map<String, dynamic> e,
    bool isDark,
  ) {
    final buyer = e['buyer'] as Map<String, dynamic>?;
    final first = (buyer?['first_name'] as String?)?.trim() ?? '';
    final last = (buyer?['last_name'] as String?)?.trim() ?? '';
    final name = '$first $last'.trim().isNotEmpty
        ? '$first $last'.trim()
        : (buyer?['username'] as String? ?? 'کاربر');
    final amount = e['amount'] as int? ?? 0;
    final available = e['is_available'] == true;
    final holdUntilStr = e['hold_until'] as String?;
    DateTime? holdUntil;
    if (holdUntilStr != null) {
      try {
        holdUntil = DateTime.parse(holdUntilStr);
      } catch (_) {}
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppTheme.veryDarkBackground.withValues(alpha: 0.2)
                : AppTheme.veryDarkBackground.withValues(alpha: 0.04),
            blurRadius: 8.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: available
                  ? AppTheme.successColor.withValues(alpha: 0.15)
                  : AppTheme.fatColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              available ? LucideIcons.checkCircle : LucideIcons.clock,
              color: available ? AppTheme.successColor : AppTheme.fatColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      available ? LucideIcons.check : LucideIcons.clock,
                      size: 14.sp,
                      color: available
                          ? AppTheme.successColor
                        : AppTheme.fatColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      available
                          ? 'قابل برداشت'
                          : 'آزادسازی تا ${holdUntil != null ? _formatDate(holdUntil) : '-'}',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: available
                            ? AppTheme.successColor
                            : AppTheme.fatColor,
                        fontWeight: FontWeight.w500,
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
              Text(
                PaymentConstants.formatAmount(amount),
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'درآمد',
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
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.fileText,
              size: 64.sp,
              color: context.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'هنوز تراکنشی ثبت نشده',
              style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'پس از ثبت اولین برنامه، تراکنش‌های شما اینجا نمایش داده می‌شوند',
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
    );
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month]}';
  }
}
