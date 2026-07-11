import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_finance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TrainerStatsTab extends StatefulWidget {
  const TrainerStatsTab({super.key});

  @override
  State<TrainerStatsTab> createState() => _TrainerStatsTabState();
}

class _TrainerStatsTabState extends State<TrainerStatsTab> {
  final _finance = TrainerFinanceService();
  bool _loading = true;
  Map<String, dynamic> _stats = const {};

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
        final s = await _finance.getTrainerStats(user.id);
        WidgetSafetyUtils.safeSetState(this, () => _stats = s);
      }
    } finally {
      WidgetSafetyUtils.safeSetState(this, () => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.goldColor,
        ),
      );
    }

    // آمار عملکرد و مشتریان (بدون مبالغ مالی)
    final int totalClients = _stats['totalClients'] as int? ?? 0;
    final int activeClients = _stats['activeClients'] as int? ?? 0;
    final int totalSubscriptions = _stats['totalSubscriptions'] as int? ?? 0;
    final int paidSubscriptions = _stats['paidSubscriptions'] as int? ?? 0;
    final int activeSubscriptions = _stats['activeSubscriptions'] as int? ?? 0;
    final int completedSubscriptions = _stats['completedSubscriptions'] as int? ?? 0;
    final int delayedSubscriptions = _stats['delayedSubscriptions'] as int? ?? 0;
    final int subscriptionsWithProgram =
        _stats['subscriptionsWithProgram'] as int? ?? 0;
    final int subscriptionsWithoutProgram =
        _stats['subscriptionsWithoutProgram'] as int? ?? 0;

    final double responseRate = (_stats['responseRate'] as num?)?.toDouble() ?? 0.0;
    final double averageResponseTimeHours =
        (_stats['averageResponseTimeHours'] as num?)?.toDouble() ?? 0.0;
    final double averageResponseTimeDays =
        (_stats['averageResponseTimeDays'] as num?)?.toDouble() ?? 0.0;
    final double onTimeDeliveryRate =
        (_stats['onTimeDeliveryRate'] as num?)?.toDouble() ?? 0.0;

    final Map<String, dynamic> byServiceCount = Map<String, dynamic>.from(
      _stats['byServiceCount'] as Map? ?? {},
    );

    final serviceNames = {
      'training': 'برنامه تمرینی',
      'diet': 'برنامه غذایی',
      'consulting': 'مشاوره و نظارت',
      'package': 'بسته کامل',
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.goldColor,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _hintCard(
              isDark,
              'خلاصه عملکرد کاری شما: سرعت پاسخ، تحویل برنامه و وضعیت مشتریان. '
              'برای درآمد، موجودی و برداشت به تب «مالی» بروید.',
            ),
            SizedBox(height: 16.h),
            _sectionHeader('نمای کلی', LucideIcons.layoutDashboard, isDark),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _overviewTile(
                    'نرخ پاسخ',
                    '${responseRate.toStringAsFixed(responseRate < 10 ? 1 : 0)}%',
                    LucideIcons.target,
                    Colors.purple,
                    isDark,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _overviewTile(
                    'تحویل به موقع',
                    '${onTimeDeliveryRate.toStringAsFixed(onTimeDeliveryRate < 10 ? 1 : 0)}%',
                    LucideIcons.checkCircle2,
                    Colors.green,
                    isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: _overviewTile(
                    'مشتریان فعال',
                    activeClients.toString(),
                    LucideIcons.userCheck,
                    Colors.blue,
                    isDark,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _overviewTile(
                    'منتظر برنامه',
                    subscriptionsWithoutProgram.toString(),
                    LucideIcons.hourglass,
                    Colors.orange,
                    isDark,
                  ),
                ),
              ],
            ),

            SizedBox(height: 28.h),

            _sectionHeader('عملکرد', LucideIcons.gauge, isDark),
            SizedBox(height: 12.h),
            _groupedCard(
              isDark: isDark,
              children: [
                _compactPerformanceRow(
                  'نرخ پاسخ',
                  responseRate,
                  '%',
                  LucideIcons.target,
                  Colors.purple,
                  subtitle: 'برنامه‌های ارسال‌شده از کل اشتراک‌های پرداخت‌شده',
                ),
                _groupDivider(isDark),
                _compactPerformanceRow(
                  'میانگین زمان پاسخ',
                  averageResponseTimeDays > 0
                      ? averageResponseTimeDays
                      : averageResponseTimeHours,
                  averageResponseTimeDays > 0 ? 'روز' : 'ساعت',
                  LucideIcons.clock,
                  Colors.blue,
                  subtitle: 'از زمان ثبت درخواست تا ارسال برنامه',
                ),
                _groupDivider(isDark),
                _compactPerformanceRow(
                  'تحویل به موقع',
                  onTimeDeliveryRate,
                  '%',
                  LucideIcons.checkCircle2,
                  Colors.green,
                  subtitle: 'برنامه‌های بدون تأخیر',
                  isLast: true,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'برنامه‌های تکمیل‌شده',
                    completedSubscriptions.toString(),
                    LucideIcons.checkCircle,
                    Colors.green,
                    isDark,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _statCard(
                    'برنامه‌های تأخیردار',
                    delayedSubscriptions.toString(),
                    LucideIcons.alertCircle,
                    Colors.orange,
                    isDark,
                  ),
                ),
              ],
            ),

            SizedBox(height: 28.h),

            _sectionHeader('مشتریان و اشتراک‌ها', LucideIcons.users, isDark),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'کل مشتریان',
                    totalClients.toString(),
                    LucideIcons.users,
                    Colors.blue,
                    isDark,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _statCard(
                    'مشتریان فعال',
                    activeClients.toString(),
                    LucideIcons.userCheck,
                    Colors.green,
                    isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'اشتراک پرداخت‌شده',
                    paidSubscriptions.toString(),
                    LucideIcons.shoppingBag,
                    AppTheme.goldColor,
                    isDark,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _statCard(
                    'اشتراک فعال',
                    activeSubscriptions.toString(),
                    LucideIcons.activity,
                    Colors.green,
                    isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'برنامه ارسال شده',
                    subscriptionsWithProgram.toString(),
                    LucideIcons.send,
                    Colors.teal,
                    isDark,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _statCard(
                    'منتظر ارسال',
                    subscriptionsWithoutProgram.toString(),
                    LucideIcons.clock4,
                    Colors.orange,
                    isDark,
                  ),
                ),
              ],
            ),

            if (totalSubscriptions > paidSubscriptions) ...[
              SizedBox(height: 12.h),
              _hintCard(
                isDark,
                'تعداد کل رکورد اشتراک: $totalSubscriptions (شامل موارد در انتظار پرداخت)',
              ),
            ],

            SizedBox(height: 28.h),

            _sectionHeader('تفکیک سرویس', LucideIcons.layers, isDark),
            SizedBox(height: 12.h),
            ...byServiceCount.entries.map((e) {
              final serviceName = serviceNames[e.key] ?? e.key;
              final count = (e.value as int?) ?? 0;
              return _serviceCountRow(serviceName, count, isDark);
            }),
            if (byServiceCount.isEmpty)
              _emptyState('هنوز اشتراکی ثبت نشده', isDark),
          ],
        ),
      ),
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

  Widget _serviceCountRow(String serviceName, int count, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: isDark ? context.veryDarkBackground : AppTheme.lightSurfaceColor,
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              serviceName,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$count اشتراک',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.goldColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 18.sp),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textColor,
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _overviewTile(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: isDark ? context.veryDarkBackground : AppTheme.lightSurfaceColor,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 11.sp,
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
        borderRadius: BorderRadius.circular(16.r),
        color: isDark ? context.veryDarkBackground : AppTheme.lightSurfaceColor,
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.2),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _groupDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.12),
    );
  }

  Widget _compactPerformanceRow(
    String title,
    double value,
    String unit,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, isLast ? 12.h : 0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${value.toStringAsFixed(value < 10 && unit == '%' ? 1 : value < 1 ? 2 : 0)} $unit',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark
            ? context.veryDarkBackground
            : AppTheme.lightSurfaceColor,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.2 : 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
    fontFamily: AppTheme.fontFamily,
              color: context.textSecondary,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, bool isDark) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark
            ? context.veryDarkBackground
            : AppTheme.lightSurfaceColor,
        border: Border.all(
          color: AppTheme.goldColor.withValues(
            alpha: isDark ? 0.15 : 0.2,
          ),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
