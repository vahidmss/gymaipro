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

    // استخراج آمارهای مالی
    final int totalRevenue = _stats['totalRevenue'] as int? ?? 0;
    final int totalCommission = _stats['totalCommission'] as int? ?? 0;
    final int netEarnings = _stats['netEarnings'] as int? ?? 0;
    final int onHold = _stats['onHold'] as int? ?? 0;
    final int withdrawable = _stats['withdrawable'] as int? ?? 0;
    
    // استخراج آمارهای مشتریان و اشتراک‌ها
    final int totalClients = _stats['totalClients'] as int? ?? 0;
    final int activeClients = _stats['activeClients'] as int? ?? 0;
    final int totalSubscriptions = _stats['totalSubscriptions'] as int? ?? 0;
    final int activeSubscriptions = _stats['activeSubscriptions'] as int? ?? 0;
    final int completedSubscriptions = _stats['completedSubscriptions'] as int? ?? 0;
    final int delayedSubscriptions = _stats['delayedSubscriptions'] as int? ?? 0;
    
    // استخراج آمارهای عملکرد
    final double responseRate = (_stats['responseRate'] as num?)?.toDouble() ?? 0.0;
    final double averageResponseTimeHours = (_stats['averageResponseTimeHours'] as num?)?.toDouble() ?? 0.0;
    final double averageResponseTimeDays = (_stats['averageResponseTimeDays'] as num?)?.toDouble() ?? 0.0;
    final double onTimeDeliveryRate = (_stats['onTimeDeliveryRate'] as num?)?.toDouble() ?? 0.0;
    
    // استخراج تفکیک سرویس
    final Map<String, dynamic> byService = Map<String, dynamic>.from(
      _stats['byService'] as Map? ?? {},
    );
    final Map<String, dynamic> byServiceRevenue = Map<String, dynamic>.from(
      _stats['byServiceRevenue'] as Map? ?? {},
    );
    final Map<String, dynamic> byServiceCommission = Map<String, dynamic>.from(
      _stats['byServiceCommission'] as Map? ?? {},
    );
    final Map<String, dynamic> byServiceCount = Map<String, dynamic>.from(
      _stats['byServiceCount'] as Map? ?? {},
    );
    
    // استخراج آمار ماهانه
    final Map<String, dynamic> monthly = Map<String, dynamic>.from(
      _stats['monthly'] as Map? ?? {},
    );
    final Map<String, dynamic> monthlyRevenue = Map<String, dynamic>.from(
      _stats['monthlyRevenue'] as Map? ?? {},
    );
    final Map<String, dynamic> monthlyCommission = Map<String, dynamic>.from(
      _stats['monthlyCommission'] as Map? ?? {},
    );
    final Map<String, dynamic> monthlySubscriptions = Map<String, dynamic>.from(
      _stats['monthlySubscriptions'] as Map? ?? {},
    );

    final serviceNames = {
      'training': 'برنامه تمرینی',
      'diet': 'برنامه غذایی',
      'consulting': 'مشاوره و نظارت',
      'package': 'بسته کامل',
    };

    final monthlyEntries = monthly.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // جدیدترین اول

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.goldColor,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _sectionHeader('نمای کلی', LucideIcons.layoutDashboard, isDark),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _overviewTile(
                    'درآمد خالص',
                    _formatToman(netEarnings),
                    LucideIcons.trendingUp,
                    AppTheme.goldColor,
                    isDark,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _overviewTile(
                    'مشتریان فعال',
                    activeClients.toString(),
                    LucideIcons.userCheck,
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
                    'اشتراک فعال',
                    activeSubscriptions.toString(),
                    LucideIcons.activity,
                    Colors.blue,
                    isDark,
                  ),
                ),
              ],
            ),

            SizedBox(height: 28.h),

            _sectionHeader('خلاصه مالی', LucideIcons.wallet, isDark),
            SizedBox(height: 12.h),
            _groupedCard(
              isDark: isDark,
              children: [
                _compactMetricRow(
                  'کل درآمد',
                  totalRevenue,
                  LucideIcons.dollarSign,
                  Colors.blue,
                  subtitle: 'پرداخت‌های اشتراک',
                ),
                _groupDivider(isDark),
                _compactMetricRow(
                  'کمیسیون پلتفرم',
                  totalCommission,
                  LucideIcons.percent,
                  Colors.orange,
                  subtitle: 'سهم پلتفرم',
                ),
                _groupDivider(isDark),
                _compactMetricRow(
                  'درآمد خالص',
                  netEarnings,
                  LucideIcons.trendingUp,
                  AppTheme.goldColor,
                  subtitle: 'بعد از کسر کمیسیون',
                ),
                _groupDivider(isDark),
                _compactMetricRow(
                  'قابل برداشت',
                  withdrawable,
                  LucideIcons.checkCircle,
                  Colors.green,
                  subtitle: 'آماده برداشت',
                ),
                _groupDivider(isDark),
                _compactMetricRow(
                  'در انتظار',
                  onHold,
                  LucideIcons.clock,
                  Colors.orange,
                  subtitle: 'تا آزادسازی',
                  isLast: true,
                ),
              ],
            ),

            SizedBox(height: 28.h),

            _sectionHeader('مشتریان و اشتراک‌ها', LucideIcons.users, isDark),
          SizedBox(height: 16.h),
          
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
                  'کل اشتراک‌ها',
                  totalSubscriptions.toString(),
                  LucideIcons.shoppingBag,
                  AppTheme.goldColor,
                  isDark,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statCard(
                  'اشتراک‌های فعال',
                  activeSubscriptions.toString(),
                  LucideIcons.activity,
                  Colors.green,
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
                subtitle: 'برنامه‌های ارسال‌شده',
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
                subtitle: 'از زمان ثبت تا ارسال',
              ),
              _groupDivider(isDark),
              _compactPerformanceRow(
                'تحویل به موقع',
                onTimeDeliveryRate,
                '%',
                LucideIcons.checkCircle2,
                Colors.green,
                subtitle: 'بدون تاخیر',
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  'برنامه‌های تکمیل شده',
                  completedSubscriptions.toString(),
                  LucideIcons.checkCircle,
                  Colors.green,
                  isDark,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _statCard(
                  'برنامه‌های تاخیردار',
                  delayedSubscriptions.toString(),
                  LucideIcons.alertCircle,
                  Colors.orange,
                  isDark,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 28.h),

          _sectionHeader('تفکیک سرویس', LucideIcons.layers, isDark),
          SizedBox(height: 12.h),
          
          ...byService.entries.map((e) {
            final serviceName = serviceNames[e.key] ?? e.key;
            final earnings = e.value as int? ?? 0;
            final revenue = (byServiceRevenue[e.key] as int?) ?? 0;
            final commission = (byServiceCommission[e.key] as int?) ?? 0;
            final count = (byServiceCount[e.key] as int?) ?? 0;
            return _serviceRow(
              serviceName,
              earnings,
              revenue,
              commission,
              count,
              isDark,
            );
          }),
          
          if (byService.isEmpty)
            _emptyState('هنوز فروشی ثبت نشده', isDark),
          
          SizedBox(height: 28.h),

          _sectionHeader('درآمد ماهانه', LucideIcons.calendarDays, isDark),
          SizedBox(height: 12.h),
          
          ...monthlyEntries.take(12).map((e) {
            final monthName = _formatMonthKey(e.key);
            final earnings = e.value as int? ?? 0;
            final revenue = (monthlyRevenue[e.key] as int?) ?? 0;
            final commission = (monthlyCommission[e.key] as int?) ?? 0;
            final subscriptions = (monthlySubscriptions[e.key] as int?) ?? 0;
            return _monthlyRow(
              monthName,
              earnings,
              revenue,
              commission,
              subscriptions,
              isDark,
            );
          }),
          
          if (monthlyEntries.isEmpty)
            _emptyState('هنوز درآمد ماهانه‌ای ثبت نشده', isDark),
          ],
        ),
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

  Widget _compactMetricRow(
    String title,
    int amount,
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
            _formatToman(amount),
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

  Widget _serviceRow(
    String serviceName,
    int earnings,
    int revenue,
    int commission,
    int count,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark
            ? context.veryDarkBackground
            : AppTheme.lightSurfaceColor,
        border: Border.all(
          color: AppTheme.goldColor.withValues(
            alpha: isDark ? 0.15 : 0.2,
          ),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$count عدد',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'درآمد شما',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatToman(earnings),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: AppTheme.goldColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'کمیسیون',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatToman(commission),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: Colors.orange,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthlyRow(
    String monthName,
    int earnings,
    int revenue,
    int commission,
    int subscriptions,
    bool isDark,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark
            ? context.veryDarkBackground
            : AppTheme.lightSurfaceColor,
        border: Border.all(
          color: AppTheme.goldColor.withValues(
            alpha: isDark ? 0.15 : 0.2,
          ),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: context.textColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$subscriptions اشتراک',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: AppTheme.goldColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کل درآمد',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatToman(revenue),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: Colors.blue,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'درآمد خالص',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatToman(earnings),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: AppTheme.goldColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'کمیسیون',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: context.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatToman(commission),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: Colors.orange,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  String _formatToman(int amountInRial) {
    // تبدیل از ریال به تومان
    final amountInToman = amountInRial ~/ 10;
    final s = amountInToman.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write(',');
    }
    return '${buf.toString().split('').reversed.join()} تومان';
  }

  String _formatMonthKey(String key) {
    // کلید ماهانه به‌صورت yyyy-MM شمسی از سرویس مالی می‌آید
    try {
      final parts = key.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]) ?? 0;
        final month = int.tryParse(parts[1]) ?? 0;
        const monthNames = [
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
        if (year > 0 && month >= 1 && month <= 12) {
          return '${monthNames[month]} $year';
        }
      }
    } catch (_) {}
    return key;
  }
}
