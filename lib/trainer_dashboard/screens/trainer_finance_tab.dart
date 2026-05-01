import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/trainer_dashboard/screens/trainer_payout_request_screen.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_finance_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerFinanceTab extends StatefulWidget {
  const TrainerFinanceTab({super.key});

  @override
  State<TrainerFinanceTab> createState() => _TrainerFinanceTabState();
}

class _TrainerFinanceTabState extends State<TrainerFinanceTab> {
  final _finance = TrainerFinanceService();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
        ),
      );
    }

    final int available = _balances['available'] as int? ?? 0;
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
                      fontSize: 20.sp,
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
                    ? [const Color(0xFF2B2E3A), const Color(0xFF232736)]
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
                    ? [const Color(0xFF1E3A2B), const Color(0xFF193024)]
                    : [
                        const Color(0xFFE8F5E9),
                        const Color(0xFFC8E6C9),
                      ],
                isDark,
              ),
              SizedBox(height: 12.h),
              
              // دکمه درخواست برداشت
              if (withdrawable > 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      WidgetSafetyUtils.safeNavigate(
                        context,
                        () => const TrainerPayoutRequestScreen(),
                      );
                      // Reload after navigation returns
                      Future<void>.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          _load();
                        }
                      });
                    },
                    icon: const Icon(LucideIcons.arrowUpCircle),
                    label: Text(
                      'درخواست برداشت',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 12.h),
              _summaryCard(
                context,
                'در انتظار آزادسازی',
                onHold,
                LucideIcons.clock,
                isDark
                    ? [const Color(0xFF3A2B2B), const Color(0xFF2F2323)]
                    : [
                        const Color(0xFFFFF3E0),
                        const Color(0xFFFFE0B2),
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
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'مبالغ پس از ثبت برنامه توسط مربی، به مدت ۳ روز نگه‌داری شده و سپس قابل برداشت می‌شوند. برای برداشت، دکمه "درخواست برداشت" را بزنید.',
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
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
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
                  : Colors.white.withValues(alpha: 0.4),
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
                    fontSize: 22.sp,
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
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: available
                  ? AppTheme.successColor.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              available ? LucideIcons.checkCircle : LucideIcons.clock,
              color: available ? AppTheme.successColor : Colors.orange,
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
                          : Colors.orange,
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
                            : Colors.orange,
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
                  fontSize: 16.sp,
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
                fontSize: 16.sp,
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
