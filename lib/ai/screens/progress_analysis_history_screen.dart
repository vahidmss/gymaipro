import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/ai/models/progress_analysis.dart';
import 'package:gymaipro/ai/services/progress_analysis_storage_service.dart';
import 'package:gymaipro/ai/widgets/analysis_result_display.dart';
import 'package:gymaipro/ai/widgets/ai_hub_ui.dart';
import 'package:gymaipro/ai/widgets/progress_analysis_ui.dart';
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
            : ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: _analyses.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
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
        child: ProgressAnalysisCard(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
          child: const ProgressEmptyState(
            icon: LucideIcons.fileText,
            title: 'تحلیلی ثبت نشده',
            subtitle: 'اولین گزارش پیشرفتت را از صفحهٔ تحلیل بساز.',
          ),
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
      child: ProgressAnalysisCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AiHubIconBadge(
                  icon: LucideIcons.lineChart,
                  gradientColors: aiHubAccentGradient(kProgressAccent),
                  size: 44.w,
                  iconSize: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحلیل ${analysis.periodDays} روزه',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: context.textColor,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 13.sp,
                            color: context.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.sp,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              constraints: BoxConstraints(maxHeight: 260.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: SingleChildScrollView(
                  child: AnalysisResultDisplay(
                    content: analysis.analysisResult.length > 300
                        ? '${analysis.analysisResult.substring(0, 300)}...'
                        : analysis.analysisResult,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            OutlinedButton.icon(
              onPressed: () => _showFullAnalysis(analysis, isDark),
              icon: Icon(LucideIcons.eye, size: 17.sp),
              label: Text(
                'مشاهدهٔ کامل',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kProgressAccent,
                side: BorderSide(
                  color: kProgressAccent.withValues(alpha: 0.5),
                ),
                minimumSize: Size(double.infinity, 44.h),
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

  void _showFullAnalysis(ProgressAnalysis analysis, bool isDark) {
    final dateStr = _formatPersianDate(analysis.analysisDate);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          border: Border(
            top: BorderSide(
              color: kProgressAccent.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 14.h),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.separatorColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              child: Row(
                children: [
                  AiHubIconBadge(
                    icon: LucideIcons.fileText,
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
                          'تحلیل کامل',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: context.textColor,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12.sp,
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
                      color: context.textSecondary,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: AnalysisResultDisplay(content: analysis.analysisResult),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
