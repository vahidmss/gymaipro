import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/progress_analysis.dart';
import 'package:gymaipro/ai/services/progress_analysis_storage_service.dart';
import 'package:gymaipro/ai/widgets/analysis_result_display.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ProgressAnalysisHistoryScreen extends StatefulWidget {
  const ProgressAnalysisHistoryScreen({super.key});

  @override
  State<ProgressAnalysisHistoryScreen> createState() =>
      _ProgressAnalysisHistoryScreenState();
}

class _ProgressAnalysisHistoryScreenState
    extends State<ProgressAnalysisHistoryScreen>
    with TickerProviderStateMixin {
  final ProgressAnalysisStorageService _storageService =
      ProgressAnalysisStorageService();
  List<ProgressAnalysis> _analyses = [];
  bool _isLoading = true;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.safeForward();
    _loadAnalyses();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyses() async {
    SafeSetState.call(this, () {
      _isLoading = true;
    });

    try {
      final analyses = await _storageService.getAllAnalyses();
      SafeSetState.call(this, () {
        _analyses = analyses;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در بارگذاری تحلیل‌ها: $e',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      SafeSetState.call(this, () {
        _isLoading = false;
      });
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
          'تاریخچه تحلیل‌ها',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.goldColor : context.textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              )
            : _analyses.isEmpty
            ? _buildEmptyState(isDark)
            : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: _analyses.length,
                itemBuilder: (context, index) {
                  final analysis = _analyses[index];
                  return _buildAnalysisCard(analysis, isDark);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeTransition(
      opacity: _fadeController,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.2),
                    AppTheme.goldColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(50.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 2.w,
                ),
              ),
              child: Icon(
                LucideIcons.fileText,
                size: 50.sp,
                color: AppTheme.goldColor,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'تحلیل‌ای ثبت نشده است',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: context.textColor,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'اولین تحلیل خود را ایجاد کنید',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildAnalysisCard(ProgressAnalysis analysis, bool isDark) {
    final dateStr = _formatPersianDate(analysis.analysisDate);

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(20.w),
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
                    AppTheme.goldColor.withValues(alpha: 0.06),
                    context.cardColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.6),
            width: 2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.18),
              blurRadius: 16.r,
              offset: Offset(0.w, 6.h),
              spreadRadius: 0.r,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : context.textColor.withValues(alpha: 0.06),
              blurRadius: 8.r,
              offset: Offset(0.w, 3.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.goldColor, AppTheme.darkGold],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0.w, 3.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.barChart3,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحلیل ${analysis.periodDays} روزه',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 14.sp,
                            color: context.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              constraints: BoxConstraints(maxHeight: 300.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: SingleChildScrollView(
                  child: AnalysisResultDisplay(
                    content: analysis.analysisResult.length > 300
                        ? '${analysis.analysisResult.substring(0, 300)}...'
                        : analysis.analysisResult,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showFullAnalysis(analysis, isDark),
                icon: Icon(LucideIcons.eye, size: 18.sp),
                label: Text(
                  'مشاهده کامل',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.goldColor,
                  side: BorderSide(color: AppTheme.goldColor, width: 2.w),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullAnalysis(ProgressAnalysis analysis, bool isDark) {
    final dateStr = _formatPersianDate(analysis.analysisDate);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [context.cardColor, context.backgroundColor],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.cardColor,
                    AppTheme.goldColor.withValues(alpha: 0.02),
                  ],
                ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border(
            top: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.4),
              width: 2.w,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.goldColor, AppTheme.darkGold],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      LucideIcons.fileText,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحلیل کامل',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 19.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.x,
                      color: context.textColor,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: AnalysisResultDisplay(content: analysis.analysisResult),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
