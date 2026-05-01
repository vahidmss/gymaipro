import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_finance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
      return Center(
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

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.goldColor,
      child: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // خلاصه مالی
          _sectionTitle('خلاصه مالی', isDark),
          SizedBox(height: 16.h),
          
          // کل درآمد (قبل از کمیسیون)
          _metric(
            'کل درآمد',
            totalRevenue,
            isDark,
            icon: LucideIcons.dollarSign,
            color: Colors.blue,
            subtitle: 'کل پول‌های پرداخت شده بابت اشتراک‌ها',
          ),
          SizedBox(height: 12.h),
          
          // کل کمیسیون
          _metric(
            'کل کمیسیون پلتفرم',
            totalCommission,
            isDark,
            icon: LucideIcons.percent,
            color: Colors.orange,
            subtitle: 'کمیسیونی که از مربی کسر می‌شود',
          ),
          SizedBox(height: 12.h),
          
          // درآمد خالص
          _metric(
            'درآمد خالص',
            netEarnings,
            isDark,
            icon: LucideIcons.trendingUp,
            color: AppTheme.goldColor,
            subtitle: 'کل درآمد منهای کمیسیون',
          ),
          SizedBox(height: 12.h),
          
          // قابل برداشت
          _metric(
            'قابل برداشت',
            withdrawable,
            isDark,
            icon: LucideIcons.checkCircle,
            color: Colors.green,
            subtitle: 'بعد از 3 روز انتظار و بدون برداشت‌های قبلی',
          ),
          SizedBox(height: 12.h),
          
          // در انتظار
          _metric(
            'در انتظار',
            onHold,
            isDark,
            icon: LucideIcons.clock,
            color: Colors.orange,
            subtitle: 'تا رسیدن به زمان برداشت',
          ),
          
          SizedBox(height: 32.h),
          
          // آمار مشتریان و اشتراک‌ها
          _sectionTitle('آمار مشتریان و اشتراک‌ها', isDark),
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
          
          SizedBox(height: 32.h),
          
          // آمار عملکرد
          _sectionTitle('آمار عملکرد', isDark),
          SizedBox(height: 16.h),
          
          _performanceCard(
            'نرخ پاسخ',
            responseRate,
            '%',
            LucideIcons.target,
            Colors.purple,
            isDark,
            subtitle: 'درصد برنامه‌هایی که ارسال شده',
          ),
          SizedBox(height: 12.h),
          
          _performanceCard(
            'میانگین زمان پاسخ',
            averageResponseTimeDays > 0 ? averageResponseTimeDays : averageResponseTimeHours,
            averageResponseTimeDays > 0 ? 'روز' : 'ساعت',
            LucideIcons.clock,
            Colors.blue,
            isDark,
            subtitle: averageResponseTimeDays > 0 
                ? 'میانگین زمان ارسال برنامه'
                : 'میانگین زمان ارسال برنامه',
          ),
          SizedBox(height: 12.h),
          
          _performanceCard(
            'نرخ تحویل به موقع',
            onTimeDeliveryRate,
            '%',
            LucideIcons.checkCircle2,
            Colors.green,
            isDark,
            subtitle: 'درصد برنامه‌های بدون تاخیر',
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
          
          SizedBox(height: 32.h),
          
          // تفکیک سرویس
          _sectionTitle('تفکیک سرویس', isDark),
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
          
          SizedBox(height: 32.h),
          
          // درآمد ماهانه
          _sectionTitle('درآمد ماهانه', isDark),
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
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
        color: context.textColor,
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _metric(
    String title,
    int amount,
    bool isDark, {
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.cardColor,
                  context.cardColor.withValues(alpha: 0.95),
                  context.veryDarkBackground,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.cardColor,
                  context.cardColor.withValues(alpha: 0.98),
                  AppTheme.lightGradientStart.withValues(alpha: 0.1),
                ],
              ),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.4),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.25),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
            spreadRadius: 1.r,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
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
                    color: context.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                Text(
                  _formatToman(amount),
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18.sp,
                  ),
                ),
              ],
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

  Widget _performanceCard(
    String title,
    double value,
    String unit,
    IconData icon,
    Color color,
    bool isDark, {
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.cardColor,
                  context.cardColor.withValues(alpha: 0.95),
                  context.veryDarkBackground,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.cardColor,
                  context.cardColor.withValues(alpha: 0.98),
                  AppTheme.lightGradientStart.withValues(alpha: 0.1),
                ],
              ),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.4),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.25),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
            spreadRadius: 1.r,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
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
                    color: context.textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                      color: context.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value.toStringAsFixed(value < 1 ? 2 : 1),
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Text(
                        unit,
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                serviceName,
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName,
                style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                  color: context.textColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    // تبدیل yyyy-MM به نام ماه فارسی
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
        if (month >= 1 && month <= 12) {
          return '$monthNames[month] $year';
        }
      }
    } catch (_) {}
    return key;
  }
}
