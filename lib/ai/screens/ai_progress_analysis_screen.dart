import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/screens/progress_analysis_history_screen.dart';
import 'package:gymaipro/ai/services/ai_progress_analysis_service.dart';
import 'package:gymaipro/ai/services/progress_analysis_limit_service.dart';
import 'package:gymaipro/ai/services/progress_analysis_storage_service.dart';
import 'package:gymaipro/ai/widgets/analysis_result_display.dart';
import 'package:gymaipro/payment/utils/payment_integration_helper.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AIProgressAnalysisScreen extends StatefulWidget {
  const AIProgressAnalysisScreen({super.key});

  @override
  State<AIProgressAnalysisScreen> createState() =>
      _AIProgressAnalysisScreenState();
}

class _AIProgressAnalysisScreenState extends State<AIProgressAnalysisScreen>
    with TickerProviderStateMixin {
  final AIProgressAnalysisService _analysisService =
      AIProgressAnalysisService();
  final ProgressAnalysisLimitService _limitService =
      ProgressAnalysisLimitService();
  final ProgressAnalysisStorageService _storageService =
      ProgressAnalysisStorageService();
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _errorMessage;
  int _selectedDays = 30;
  DateTime? _analysisDate;
  ProgressAnalysisLimitStats? _usageStats;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeController.safeForward();
    _slideController.safeForward();
    _loadUsageStats();
    _loadLatestAnalysisForPeriod(_selectedDays);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // به‌روزرسانی آمار استفاده وقتی صفحه دوباره باز می‌شود
    _loadUsageStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUsageStats() async {
    final stats = await _limitService.getUsageStats();
    SafeSetState.call(this, () {
      _usageStats = stats;
    });
  }

  String _getPeriodLabel() {
    switch (_selectedDays) {
      case 7:
        return 'تحلیل هفتگی';
      case 30:
        return 'تحلیل ماهانه';
      case 90:
        return 'تحلیل سه‌ماهه';
      default:
        return 'تحلیل پیشرفت';
    }
  }

  String _formatPersianDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);
    final monthNames = [
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
    return '${jalali.day} ${monthNames[jalali.month]} ${jalali.year}';
  }

  Future<void> _loadLatestAnalysisForPeriod(int periodDays) async {
    try {
      final latestAnalysis = await _storageService.getLatestAnalysisByPeriod(
        periodDays,
      );
      SafeSetState.call(this, () {
        if (latestAnalysis != null) {
          _analysisResult = latestAnalysis.analysisResult;
          _analysisDate = latestAnalysis.analysisDate;
          _errorMessage = null;
        } else {
          _analysisResult = null;
          _analysisDate = null;
          _errorMessage = null;
        }
      });
    } catch (e) {
      // در صورت خطا، فقط لاگ می‌کنیم و ادامه می‌دهیم
      if (mounted) {
        SafeSetState.call(this, () {
          _analysisResult = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? context.backgroundColor : Colors.transparent,
        elevation: 0,
        title: Text(
          'تحلیل پیشرفت',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.goldColor : context.textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.history,
              color: isDark ? AppTheme.goldColor : context.textColor,
              size: 22.sp,
            ),
            tooltip: 'مشاهده تحلیل‌های گذشته',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ProgressAnalysisHistoryScreen(),
                ),
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              SizedBox(height: 16.h),
              if (_usageStats != null) _buildUsageStats(isDark),
              SizedBox(height: 16.h),
              _buildPeriodSelector(isDark),
              SizedBox(height: 24.h),
              if (_isAnalyzing) _buildLoadingState(isDark),
              if (!_isAnalyzing &&
                  _analysisResult == null &&
                  _errorMessage == null)
                _buildEmptyState(isDark),
              if (!_isAnalyzing && _analysisResult != null)
                _buildAnalysisResult(isDark),
              if (!_isAnalyzing && _errorMessage != null)
                _buildErrorState(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.15),
                      context.cardColor,
                      AppTheme.goldColor.withValues(alpha: 0.08),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.goldColor.withValues(alpha: 0.2),
                      context.cardColor,
                      AppTheme.goldColor.withValues(alpha: 0.12),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.6),
              width: 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.4),
                blurRadius: 20.r,
                offset: Offset(0.w, 8.h),
                spreadRadius: 2.r,
              ),
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.6)
                    : context.textColor.withValues(alpha: 0.1),
                blurRadius: 10.r,
                offset: Offset(0.w, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.goldColor, AppTheme.darkGold],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.4),
                      blurRadius: 12.r,
                      offset: Offset(0.w, 4.h),
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.barChart3,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحلیل هوشمند پیشرفت',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.textColor,
                        height: 1.2.h,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'با استفاده از هوش مصنوعی پیشرفته، پیشرفت شما را تحلیل می‌کنم و راهکارهای عملی برای بهبود ارائه می‌دهم',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                        height: 1.6.h,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    context.cardColor.withValues(alpha: 0.95),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    AppTheme.goldColor.withValues(alpha: 0.03),
                  ],
                ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.55),
            width: 2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.1 : 0.15),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 0.r,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'دوره زمانی تحلیل',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildPeriodOption(isDark, 7, 'هفته گذشته')),
                SizedBox(width: 10.w),
                Expanded(child: _buildPeriodOption(isDark, 30, 'ماه گذشته')),
                SizedBox(width: 10.w),
                Expanded(child: _buildPeriodOption(isDark, 90, '۳ ماه گذشته')),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _startAnalysis,
                icon: Icon(LucideIcons.sparkles, size: 22.sp),
                label: Text(
                  'شروع تحلیل',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 6,
                  shadowColor: AppTheme.goldColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(bool isDark, int days, String label) {
    final isSelected = _selectedDays == days;
    return GestureDetector(
      onTap: () {
        SafeSetState.call(this, () {
          _selectedDays = days;
        });
        _loadLatestAnalysisForPeriod(days);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? (isDark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.25),
                          AppTheme.goldColor.withValues(alpha: 0.15),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.15),
                          AppTheme.goldColor.withValues(alpha: 0.08),
                        ],
                      ))
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppTheme.goldColor
                : AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.4),
            width: isSelected ? 2.5.w : 1.5.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(
                      alpha: isDark ? 0.2 : 0.15,
                    ),
                    blurRadius: 8.r,
                    offset: Offset(0.w, 2.h),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
            color: isSelected ? AppTheme.goldColor : context.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 40.w),
        child: Column(
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.goldColor, AppTheme.darkGold],
                ),
                borderRadius: BorderRadius.circular(60.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.4),
                    blurRadius: 24.r,
                    spreadRadius: 3.r,
                    offset: Offset(0.w, 8.h),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.barChart3,
                color: Colors.white,
                size: 60.sp,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'آماده تحلیل پیشرفت شما',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'دوره زمانی را انتخاب کنید و دکمه "شروع تحلیل" را بزنید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
                height: 1.6.h,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 40.w),
      child: Column(
        children: [
          Container(
            width: 100.w,
            height: 100.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.goldColor, AppTheme.darkGold],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 60.w,
                height: 60.h,
                child: CircularProgressIndicator(
                  strokeWidth: 5.w,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'در حال تحلیل پیشرفت شما...',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لطفاً صبر کنید، این فرآیند ممکن است چند لحظه طول بکشد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: context.textSecondary,
              height: 1.6.h,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    AppTheme.goldColor.withValues(alpha: 0.08),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.cardColor,
                    AppTheme.goldColor.withValues(alpha: 0.08),
                    context.cardColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.6),
            width: 2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.2),
              blurRadius: 20.r,
              offset: Offset(0.w, 8.h),
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : context.textColor.withValues(alpha: 0.08),
              blurRadius: 10.r,
              offset: Offset(0.w, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  color: AppTheme.goldColor,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نتیجه تحلیل',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: context.textColor,
                        ),
                      ),
                      if (_analysisDate != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          '${_getPeriodLabel()} • ${_formatPersianDate(_analysisDate!)}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            AnalysisResultDisplay(content: _analysisResult ?? ''),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startAnalysis,
                icon: Icon(LucideIcons.refreshCw, size: 20.sp),
                label: Text(
                  'تحلیل مجدد',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  side: BorderSide(color: AppTheme.goldColor, width: 2.w),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.5),
          width: 1.5.w,
        ),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.alertCircle, color: Colors.red, size: 48.sp),
          SizedBox(height: 16.h),
          Text(
            'خطا در تحلیل',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _errorMessage ?? 'خطای نامشخص',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14.sp,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startAnalysis,
              icon: Icon(LucideIcons.refreshCw, size: 18.sp),
              label: Text(
                'تلاش مجدد',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(bool isDark) {
    if (_usageStats == null) return const SizedBox.shrink();

    final stats = _usageStats!;
    final isNearLimit = !stats.hasSubscription && stats.remainingFree <= 1;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: stats.hasSubscription
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.2),
                    AppTheme.goldColor.withValues(alpha: 0.1),
                  ],
                )
              : isNearLimit
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withValues(alpha: isDark ? 0.25 : 0.15),
                    Colors.orange.withValues(alpha: isDark ? 0.15 : 0.08),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    AppTheme.goldColor.withValues(alpha: isDark ? 0.08 : 0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: stats.hasSubscription
                ? AppTheme.goldColor.withValues(alpha: 0.5)
                : isNearLimit
                ? Colors.orange.withValues(alpha: 0.5)
                : AppTheme.goldColor.withValues(alpha: 0.4),
            width: 2.w,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (stats.hasSubscription
                          ? AppTheme.goldColor
                          : isNearLimit
                          ? Colors.orange
                          : AppTheme.goldColor)
                      .withValues(alpha: 0.15),
              blurRadius: 12.r,
              offset: Offset(0.w, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color:
                    (stats.hasSubscription
                            ? AppTheme.goldColor
                            : isNearLimit
                            ? Colors.orange
                            : AppTheme.goldColor)
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                stats.hasSubscription
                    ? LucideIcons.crown
                    : isNearLimit
                    ? LucideIcons.alertCircle
                    : LucideIcons.info,
                color: stats.hasSubscription
                    ? AppTheme.goldColor
                    : isNearLimit
                    ? Colors.orange
                    : AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.hasSubscription
                        ? 'اشتراک فعال - استفاده نامحدود'
                        : 'استفاده رایگان: ${stats.freeUsed}/${stats.freeLimit}',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: stats.hasSubscription
                          ? AppTheme.goldColor
                          : isNearLimit
                          ? Colors.orange.shade700
                          : context.textColor,
                    ),
                  ),
                  if (!stats.hasSubscription) ...[
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: stats.freeUsagePercent / 100,
                        minHeight: 6.h,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isNearLimit ? Colors.orange : AppTheme.goldColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAnalysis() async {
    // جلوگیری از شروع چند تحلیل همزمان
    if (_isAnalyzing) {
      return;
    }

    // بررسی محدودیت قبل از شروع
    final limitCheck = await _analysisService.checkLimit();
    if (!mounted) return;
    if (!limitCheck.canUse) {
      // نمایش دیالوگ پرداخت
      PaymentIntegrationHelper.showAccessLimitDialog(
        context,
        featureName: 'progress_analysis',
        customMessage:
            limitCheck.message ??
            'شما از استفاده رایگان خود استفاده کرده‌اید. برای استفاده نامحدود، اشتراک تهیه کنید.',
      );
      return;
    }

    SafeSetState.call(this, () {
      _isAnalyzing = true;
      _analysisResult = null;
      _analysisDate = null;
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.analyzeProgress(
        days: _selectedDays,
      );

      SafeSetState.call(this, () {
        _isAnalyzing = false;
        _analysisResult = result.analysisResult;
        _analysisDate = result.analysisDate;
      });

      // به‌روزرسانی آمار استفاده
      await _loadUsageStats();
    } catch (e) {
      SafeSetState.call(this, () {
        _isAnalyzing = false;
        if (e.toString().contains('محدودیت')) {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          // نمایش دیالوگ پرداخت در صورت محدودیت
          PaymentIntegrationHelper.showAccessLimitDialog(
            context,
            featureName: 'progress_analysis',
            customMessage: _errorMessage,
          );
        } else {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        }
      });
    }
  }
}
