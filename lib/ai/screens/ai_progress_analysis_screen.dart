import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/screens/progress_analysis_history_screen.dart';
import 'package:gymaipro/ai/services/ai_progress_analysis_service.dart';
import 'package:gymaipro/ai/services/progress_analysis_limit_service.dart';
import 'package:gymaipro/ai/services/progress_analysis_storage_service.dart';
import 'package:gymaipro/ai/widgets/analysis_result_display.dart';
import 'package:gymaipro/ai/widgets/ai_hub_ui.dart';
import 'package:gymaipro/ai/widgets/progress_analysis_ui.dart';
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
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              SizedBox(height: 14.h),
              if (_usageStats != null) ProgressUsageBanner(stats: _usageStats!),
              SizedBox(height: 14.h),
              _buildPeriodSelector(isDark),
              SizedBox(height: 16.h),
              if (_isAnalyzing) _buildLoadingState(),
              if (!_isAnalyzing &&
                  _analysisResult == null &&
                  _errorMessage == null)
                _buildEmptyState(),
              if (!_isAnalyzing && _analysisResult != null)
                _buildAnalysisResult(isDark),
              if (!_isAnalyzing && _errorMessage != null) _buildErrorState(),
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
        child: ProgressAnalysisCard(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiHubIconBadge(
                icon: LucideIcons.lineChart,
                gradientColors: aiHubAccentGradient(kProgressAccent),
                size: 52.w,
                iconSize: 24.sp,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: kProgressAccent.withValues(alpha: 0.1),
                        border: Border.all(
                          color: kProgressAccent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        child: Text(
                          'هوش مصنوعی · تحلیل داده',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: kProgressAccent,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'تحلیل هوشمند پیشرفت',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'لاگ تمرین، تغذیه و اهدافت را بررسی می‌کنم و پیشنهادهای عملی می‌دهم.',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        height: 1.5,
                        color: context.textSecondary.withValues(alpha: 0.92),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        const ProgressInsightTile(
                          icon: LucideIcons.dumbbell,
                          label: 'تمرین',
                        ),
                        SizedBox(width: 8.w),
                        const ProgressInsightTile(
                          icon: LucideIcons.apple,
                          label: 'تغذیه',
                        ),
                        SizedBox(width: 8.w),
                        const ProgressInsightTile(
                          icon: LucideIcons.target,
                          label: 'اهداف',
                        ),
                      ],
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
      child: ProgressAnalysisCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AiHubSectionTitle(title: 'دورهٔ زمانی'),
            Row(
              children: [
                Expanded(
                  child: ProgressPeriodChip(
                    label: 'هفتگی',
                    subtitle: '۷ روز',
                    icon: LucideIcons.calendarDays,
                    selected: _selectedDays == 7,
                    onTap: () => _onPeriodChanged(7),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ProgressPeriodChip(
                    label: 'ماهانه',
                    subtitle: '۳۰ روز',
                    icon: LucideIcons.calendar,
                    selected: _selectedDays == 30,
                    onTap: () => _onPeriodChanged(30),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ProgressPeriodChip(
                    label: 'فصلی',
                    subtitle: '۹۰ روز',
                    icon: LucideIcons.calendarRange,
                    selected: _selectedDays == 90,
                    onTap: () => _onPeriodChanged(90),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ProgressGradientButton(
              label: 'شروع تحلیل',
              icon: LucideIcons.sparkles,
              isLoading: _isAnalyzing,
              onPressed: _isAnalyzing ? null : _startAnalysis,
            ),
          ],
        ),
      ),
    );
  }

  void _onPeriodChanged(int days) {
    SafeSetState.call(this, () {
      _selectedDays = days;
    });
    _loadLatestAnalysisForPeriod(days);
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ProgressAnalysisCard(
        child: const ProgressEmptyState(
          icon: LucideIcons.lineChart,
          title: 'آمادهٔ تحلیل پیشرفت',
          subtitle: 'دوره را انتخاب کن و «شروع تحلیل» را بزن تا گزارش شخصی‌ات ساخته شود.',
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ProgressAnalysisCard(
      child: Column(
        children: [
          SizedBox(
            width: 44.w,
            height: 44.w,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(kProgressAccent),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'در حال تحلیل پیشرفت…',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'چند لحظه صبر کن — داده‌های تمرین و تغذیه در حال بررسی‌اند.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              height: 1.5,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ProgressAnalysisCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AiHubIconBadge(
                  icon: LucideIcons.check,
                  gradientColors: aiHubAccentGradient(kProgressAccent),
                  size: 40.w,
                  iconSize: 18.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نتیجهٔ تحلیل',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: context.textColor,
                        ),
                      ),
                      if (_analysisDate != null)
                        Text(
                          '${_getPeriodLabel()} • ${_formatPersianDate(_analysisDate!)}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
                            color: context.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            AnalysisResultDisplay(content: _analysisResult ?? ''),
            SizedBox(height: 14.h),
            OutlinedButton.icon(
              onPressed: _startAnalysis,
              icon: Icon(LucideIcons.refreshCw, size: 18.sp),
              label: Text(
                'تحلیل مجدد',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kProgressAccent,
                side: BorderSide(
                  color: kProgressAccent.withValues(alpha: 0.55),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ProgressAnalysisCard(
      accent: Colors.red,
      child: Column(
        children: [
          AiHubIconBadge(
            icon: LucideIcons.alertCircle,
            gradientColors: aiHubAccentGradient(Colors.red.shade600),
            size: 48.w,
            iconSize: 22.sp,
          ),
          SizedBox(height: 14.h),
          Text(
            'خطا در تحلیل',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Colors.red.shade700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            _errorMessage ?? 'خطای نامشخص',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13.sp,
              height: 1.45,
              color: context.textColor,
            ),
          ),
          SizedBox(height: 14.h),
          ProgressGradientButton(
            label: 'تلاش مجدد',
            icon: LucideIcons.refreshCw,
            accent: Colors.red.shade600,
            onPressed: _startAnalysis,
          ),
        ],
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
