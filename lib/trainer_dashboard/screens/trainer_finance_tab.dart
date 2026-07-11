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
import 'package:shamsi_date/shamsi_date.dart';
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
  Map<String, dynamic> _data = const {};

  static const _serviceNames = {
    'training': 'برنامه تمرینی',
    'diet': 'برنامه غذایی',
    'consulting': 'مشاوره و نظارت',
    'package': 'بسته کامل',
  };

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
        final overview = await _finance.getTrainerFinanceOverview(user.id);
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () => _data = overview);
        }
      }
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _loading = false);
      }
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

    final rawAmount = controller.text.trim();
    controller.dispose();

    if (confirmed != true || !mounted) return;

    final amountToman = int.tryParse(rawAmount);
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
      if (!mounted) return;
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

    final int withdrawable = _data['withdrawable'] as int? ?? 0;
    final int onHold = _data['onHold'] as int? ?? 0;
    final int frozen = _data['frozen'] as int? ?? 0;
    final int totalVisible = _data['total'] as int? ?? 0;
    final int pendingProgram = _data['pendingProgram'] as int? ?? 0;
    final int pendingProgramCount = _data['pendingProgramCount'] as int? ?? 0;
    final int inEditWindow = _data['inEditWindow'] as int? ?? 0;
    final int inEditWindowCount = _data['inEditWindowCount'] as int? ?? 0;
    final int pendingPayouts = _data['pendingPayouts'] as int? ?? 0;
    final int holdDays = _data['holdDays'] as int? ?? 3;
    final int editWindowDays = _data['editWindowDays'] as int? ?? 3;
    final double commissionPct =
        (_data['commissionPercentage'] as num?)?.toDouble() ?? 0.0;
    final int lifetimeNet = _data['lifetimeNetEarnings'] as int? ?? 0;
    final int lifetimeCommission = _data['lifetimeCommission'] as int? ?? 0;
    final Map<String, int> monthly = Map<String, int>.from(
      (_data['monthly'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
          ) ??
          {},
    );
    final List<Map<String, dynamic>> allEarnings =
        (_data['allEarnings'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final holdOnly = (onHold - frozen).clamp(0, onHold);
    final hasPipeline = pendingProgramCount > 0 || inEditWindowCount > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.goldColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          children: [
            _hintCard(
              isDark,
              'درآمد پس از پرداخت شاگرد ثبت می‌شود. پس از ارسال برنامه و '
              'پایان دوره‌های انتظار، در «قابل برداشت» نمایش داده می‌شود.',
            ),
            SizedBox(height: 16.h),

            _heroBalanceCard(withdrawable, isDark),
            if (pendingPayouts > 0) ...[
              SizedBox(height: 8.h),
              _hintCard(
                isDark,
                '${PaymentConstants.formatAmount(pendingPayouts)} در '
                'درخواست برداشت در جریان است و از موجودی قابل برداشت کسر شده.',
              ),
            ],

            if (withdrawable > 0) ...[
              SizedBox(height: 12.h),
              _withdrawActions(withdrawable),
            ],

            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _metricTile(
                    'در انتظار آزادسازی',
                    holdOnly,
                    LucideIcons.clock,
                    AppTheme.fatColor,
                    isDark,
                    subtitle: '$holdDays روز پس از ارسال برنامه',
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _metricTile(
                    'موجودی قابل مشاهده',
                    totalVisible,
                    LucideIcons.eye,
                    Colors.blue,
                    isDark,
                    subtitle: 'قابل برداشت + در انتظار',
                  ),
                ),
              ],
            ),

            if (frozen > 0) ...[
              SizedBox(height: 10.h),
              _metricTile(
                'مسدود شده',
                frozen,
                LucideIcons.lock,
                AppTheme.errorColor,
                isDark,
                subtitle: 'توسط پشتیبانی — برای پیگیری تماس بگیرید',
                fullWidth: true,
              ),
            ],

            if (hasPipeline) ...[
              SizedBox(height: 24.h),
              _sectionHeader('در صف (هنوز قابل برداشت نیست)', LucideIcons.listOrdered, isDark),
              SizedBox(height: 12.h),
              if (pendingProgramCount > 0)
                _pipelineRow(
                  isDark,
                  LucideIcons.fileQuestion,
                  'منتظر ارسال برنامه',
                  '$pendingProgramCount مورد',
                  PaymentConstants.formatAmount(pendingProgram),
                  'پس از ارسال برنامه، $editWindowDays روز فرصت ویرایش دارید.',
                ),
              if (pendingProgramCount > 0 && inEditWindowCount > 0)
                SizedBox(height: 8.h),
              if (inEditWindowCount > 0)
                _pipelineRow(
                  isDark,
                  LucideIcons.pencil,
                  'دوره ویرایش برنامه',
                  '$inEditWindowCount مورد',
                  PaymentConstants.formatAmount(inEditWindow),
                  'پس از پایان ویرایش، دوره نگه‌داری $holdDays روزه شروع می‌شود.',
                ),
            ],

            SizedBox(height: 24.h),
            _sectionHeader('خلاصه کل', LucideIcons.barChart3, isDark),
            SizedBox(height: 12.h),
            _groupedCard(
              isDark: isDark,
              children: [
                _summaryRow(
                  'کل درآمد شما (پرداخت‌شده)',
                  lifetimeNet,
                  LucideIcons.trendingUp,
                  isDark,
                ),
                _groupDivider(isDark),
                _summaryRow(
                  'کمیسیون پلتفرم${commissionPct > 0 ? ' (${commissionPct.toStringAsFixed(commissionPct % 1 == 0 ? 0 : 1)}%)' : ''}',
                  lifetimeCommission,
                  LucideIcons.percent,
                  isDark,
                ),
              ],
            ),

            if (monthly.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _sectionHeader('درآمد ماهانه', LucideIcons.calendar, isDark),
              SizedBox(height: 12.h),
              ..._sortedMonthlyEntries(monthly).take(6).map(
                    (e) => _monthlyRow(e.key, e.value, isDark),
                  ),
            ],

            SizedBox(height: 24.h),
            _lifecycleGuide(isDark, editWindowDays, holdDays),

            SizedBox(height: 24.h),
            _sectionHeader('لیست درآمدها', LucideIcons.history, isDark),
            SizedBox(height: 12.h),
            if (allEarnings.isEmpty)
              _emptyState(isDark)
            else
              ...allEarnings.map((e) => _earningTile(e, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _heroBalanceCard(int withdrawable, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppTheme.successColor.withValues(alpha: 0.25),
                  AppTheme.successColor.withValues(alpha: 0.1),
                ]
              : [
                  AppTheme.successColor.withValues(alpha: 0.16),
                  AppTheme.successColor.withValues(alpha: 0.06),
                ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wallet, color: AppTheme.successColor, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'قابل برداشت',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            PaymentConstants.formatAmount(withdrawable),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          if (withdrawable == 0) ...[
            SizedBox(height: 8.h),
            Text(
              'هنوز مبلغی برای برداشت آزاد نشده. پس از ارسال برنامه و '
              'پایان دوره انتظار، اینجا نمایش داده می‌شود.',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.5.sp,
                height: 1.5,
                color: context.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _withdrawActions(int withdrawable) {
    return Column(
      children: [
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
    );
  }

  Widget _metricTile(
    String title,
    int amount,
    IconData icon,
    Color color,
    bool isDark, {
    String? subtitle,
    bool fullWidth = false,
  }) {
    final tile = Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: color),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            PaymentConstants.formatAmount(amount),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.sp,
                color: context.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
    return fullWidth ? tile : tile;
  }

  Widget _pipelineRow(
    bool isDark,
    IconData icon,
    String title,
    String countLabel,
    String amountLabel,
    String hint,
  ) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: AppTheme.goldColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$countLabel · $amountLabel',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  hint,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.5.sp,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifecycleGuide(bool isDark, int editDays, int holdDays) {
    final steps = [
      'شاگرد پرداخت می‌کند — درآمد ثبت می‌شود (اینجا نمایش داده نمی‌شود)',
      'شما برنامه را ارسال می‌کنید — $editDays روز فرصت ویرایش',
      'پایان ویرایش — $holdDays روز «در انتظار آزادسازی»',
      'پس از پایان انتظار — «قابل برداشت»',
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
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
              Icon(LucideIcons.info, size: 18.sp, color: AppTheme.goldColor),
              SizedBox(width: 8.w),
              Text(
                'مسیر آزادسازی درآمد',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...List.generate(steps.length, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 10.h : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22.w,
                    height: 22.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        height: 1.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _earningTile(Map<String, dynamic> e, bool isDark) {
    final buyer = e['buyer'] as Map<String, dynamic>?;
    final first = (buyer?['first_name'] as String?)?.trim() ?? '';
    final last = (buyer?['last_name'] as String?)?.trim() ?? '';
    final name = '$first $last'.trim().isNotEmpty
        ? '$first $last'.trim()
        : (buyer?['username'] as String? ?? 'کاربر');
    final amount = e['amount'] as int? ?? 0;
    final status = e['status'] as String? ?? '';
    final statusLabel = e['status_label'] as String? ?? status;
    final isFrozen = e['is_frozen'] == true;
    final isAvailable = e['is_available'] == true && !isFrozen;
    final isPendingProgram = e['is_pending_program'] == true;
    final isEditWindow = e['is_edit_window'] == true;
    final serviceType = e['service_type'] as String?;
    final serviceName = _serviceNames[serviceType] ?? serviceType ?? 'سرویس';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isFrozen) {
      statusColor = AppTheme.errorColor;
      statusIcon = LucideIcons.lock;
      statusText = 'مسدود شده';
    } else if (isAvailable) {
      statusColor = AppTheme.successColor;
      statusIcon = LucideIcons.checkCircle;
      statusText = 'قابل برداشت';
    } else if (isPendingProgram) {
      statusColor = Colors.grey;
      statusIcon = LucideIcons.fileQuestion;
      statusText = 'منتظر ارسال برنامه';
    } else if (isEditWindow) {
      statusColor = Colors.blue;
      statusIcon = LucideIcons.pencil;
      statusText = _editWindowSubtitle(e);
    } else if (status == 'hold') {
      statusColor = AppTheme.fatColor;
      statusIcon = LucideIcons.clock;
      statusText = _holdSubtitle(e);
    } else {
      statusColor = AppTheme.fatColor;
      statusIcon = LucideIcons.clock;
      statusText = statusLabel;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  serviceName,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            PaymentConstants.formatAmount(amount),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _holdSubtitle(Map<String, dynamic> e) {
    final until = _parseDate(e['hold_until'] as String?);
    if (until != null) {
      return 'آزادسازی تا ${_formatJalali(until)}';
    }
    return 'در انتظار آزادسازی';
  }

  String _editWindowSubtitle(Map<String, dynamic> e) {
    final until = _parseDate(e['edit_until'] as String?);
    if (until != null) {
      return 'ویرایش تا ${_formatJalali(until)}';
    }
    return 'دوره ویرایش برنامه';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatJalali(DateTime dt) {
    final j = Jalali.fromDateTime(dt.toLocal());
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
    return '${j.day} ${months[j.month]}';
  }

  Widget _emptyState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? AppTheme.darkGreySeparator
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.wallet, size: 56.sp, color: context.textSecondary),
          SizedBox(height: 12.h),
          Text(
            'هنوز درآمدی ثبت نشده',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'پس از اولین پرداخت موفق شاگرد، درآمدها اینجا نمایش داده می‌شوند.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.sp,
              color: context.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, int>> _sortedMonthlyEntries(Map<String, int> monthly) {
    final entries = monthly.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  Widget _monthlyRow(String monthKey, int amount, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.calendar, size: 16.sp, color: AppTheme.goldColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _formatMonthKey(monthKey),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.sp,
                color: context.textColor,
              ),
            ),
          ),
          Text(
            PaymentConstants.formatAmount(amount),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return key;
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
    if (month < 1 || month > 12) return key;
    return '${months[month]} $year';
  }

  Widget _sectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppTheme.goldColor),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
      ],
    );
  }

  Widget _hintCard(bool isDark, String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.08 : 0.06),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.info,
            size: 16.sp,
            color: AppTheme.goldColor.withValues(alpha: 0.9),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 11.sp,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupedCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : AppTheme.lightSurfaceColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.15),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _groupDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 14.w,
      endIndent: 14.w,
      color: isDark ? AppTheme.darkGreySeparator : AppTheme.lightDividerColor,
    );
  }

  Widget _summaryRow(
    String label,
    int amount,
    IconData icon,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppTheme.goldColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5.sp,
                color: context.textSecondary,
              ),
            ),
          ),
          Text(
            PaymentConstants.formatAmount(amount),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
