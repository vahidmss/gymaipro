import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_remote_image.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:gymaipro/workout_log/screens/workout_log_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// نقشهٔ تمرین ۷ روز اخیر — مینیمال، بصری، بدون توصیهٔ تخصصی.
class WeeklyMuscleHeatmapSection extends StatefulWidget {
  const WeeklyMuscleHeatmapSection({this.refreshToken = 0, super.key});

  /// با تغییر (مثلاً بعد از رفرش داشبورد) دوباره از سرور بارگذاری می‌شود.
  final int refreshToken;

  @override
  State<WeeklyMuscleHeatmapSection> createState() =>
      _WeeklyMuscleHeatmapSectionState();
}

class _WeeklyMuscleHeatmapSectionState
    extends State<WeeklyMuscleHeatmapSection> {
  final WeeklyMuscleHeatmapService _service = WeeklyMuscleHeatmapService();

  WeeklyMuscleHeatmapResult? _result;
  bool _isLoading = true;
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(WeeklyMuscleHeatmapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final requestId = ++_loadRequestId;
    if (mounted && !_isLoading) {
      setState(() => _isLoading = true);
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _service.loadForUser(userId);
      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && requestId == _loadRequestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCardTap() {
    final result = _result;
    if (result == null) return;

    if (result.hasHeatmapData) {
      _openDetailSheet();
      return;
    }

    unawaited(HapticFeedback.lightImpact());
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const WorkoutLogScreen())),
    );
  }

  void _openDetailSheet() {
    final result = _result;
    if (result == null || !result.hasHeatmapData) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (_, scrollController) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF12141A)
                      : const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
                  children: [
                    Center(
                      child: Container(
                        width: 36.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'نقشهٔ ۷ روز اخیر',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.lightTextColor,
                      ),
                    ),
                    if (result.activityLine.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        result.activityLine,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.white54
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                    ..._sheetInsightLines(result, isDark),
                    SizedBox(height: 10.h),
                    ExerciseMuscleHeatmapWidget(muscleTargets: result.targets),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton(context);

    final result = _result;
    if (result == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final copy = _HeatmapCopy.forResult(result);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onCardTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.65),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.32),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopRow(isDark, result, copy),
                if (_hasInsightLines(result)) ...[
                  SizedBox(height: 6.h),
                  _buildInsightRow(isDark, result),
                ],
                SizedBox(height: 8.h),
                if (result.hasHeatmapData)
                  ExerciseMuscleHeatmapWidget(
                    muscleTargets: result.targets,
                    compact: true,
                    embedded: true,
                    mapHeight: 148.h,
                  )
                else
                  _buildEmptyStrip(isDark, copy),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(
    bool isDark,
    WeeklyMuscleHeatmapResult result,
    _HeatmapDisplayCopy copy,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.title,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.lightTextColor,
                ),
              ),
              if (copy.subtitle.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  copy.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    height: 1.35,
                    color: isDark
                        ? Colors.white54
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (result.hasHeatmapData && result.topMuscleLabel != null)
          Container(
            margin: EdgeInsets.only(left: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              result.topMuscleLabel!,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldColor,
              ),
            ),
          ),
        Icon(
          result.hasHeatmapData ? LucideIcons.chevronLeft : LucideIcons.plus,
          size: 18.sp,
          color: AppTheme.goldColor.withValues(alpha: 0.75),
        ),
      ],
    );
  }

  Widget _buildEmptyStrip(bool isDark, _HeatmapDisplayCopy copy) {
    return SizedBox(
      height: 72.h,
      child: Row(
        children: [
          SizedBox(
            width: 52.w,
            child: Opacity(
              opacity: 0.28,
              child: AppRemoteImage(
                path: 'images/gymai_body_front_premium.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  copy.emptyHeadline,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : AppTheme.lightTextColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  copy.emptySub,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10.sp,
                    color: isDark
                        ? Colors.white38
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasInsightLines(WeeklyMuscleHeatmapResult result) {
    return (result.balanceLine?.isNotEmpty ?? false) ||
        (result.weekTrendLine?.isNotEmpty ?? false) ||
        (result.programGapLine?.isNotEmpty ?? false);
  }

  List<Widget> _sheetInsightLines(
    WeeklyMuscleHeatmapResult result,
    bool isDark,
  ) {
    final lines = <String>[
      if (result.balanceLine != null) result.balanceLine!,
      if (result.weekTrendLine != null) result.weekTrendLine!,
      if (result.programGapLine != null) result.programGapLine!,
    ];
    if (lines.isEmpty) return const [];

    return [
      SizedBox(height: 8.h),
      ...lines.map(
        (line) => Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              height: 1.4,
              color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildInsightRow(bool isDark, WeeklyMuscleHeatmapResult result) {
    final chips = <Widget>[];

    if (result.weekTrendLine != null) {
      final up =
          result.weekTrendLine!.contains('فعال‌تر') ||
          result.weekTrendLine!.contains('اولین');
      chips.add(
        _InsightChip(
          icon: up ? LucideIcons.trendingUp : LucideIcons.minus,
          label: result.weekTrendLine!,
          isDark: isDark,
          accent: true,
        ),
      );
    }
    if (result.balanceLine != null) {
      chips.add(
        _InsightChip(
          icon: LucideIcons.activity,
          label: result.balanceLine!,
          isDark: isDark,
        ),
      );
    }
    if (result.programGapLine != null) {
      chips.add(
        _InsightChip(
          icon: LucideIcons.circleDashed,
          label: result.programGapLine!,
          isDark: isDark,
        ),
      );
    }

    return Wrap(spacing: 6.w, runSpacing: 4.h, children: chips);
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
      ),
      child: SizedBox(
        height: 88.h,
        child: Center(
          child: SizedBox(
            width: 22.w,
            height: 22.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.goldColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapDisplayCopy {
  const _HeatmapDisplayCopy({
    required this.title,
    required this.subtitle,
    required this.emptyHeadline,
    required this.emptySub,
  });

  final String title;
  final String subtitle;
  final String emptyHeadline;
  final String emptySub;
}

/// متن‌های کوتاه — روزانه یکی از چند گزینه (ثابت در همان روز).
abstract final class _HeatmapCopy {
  static final int _seed = DateTime.now().day + DateTime.now().month * 31;

  static String _pick(List<String> lines) => lines[_seed % lines.length];

  static _HeatmapDisplayCopy forResult(WeeklyMuscleHeatmapResult result) {
    if (result.hasHeatmapData) {
      return _HeatmapDisplayCopy(
        title: 'نقشهٔ تمرین',
        subtitle: result.activityLine.isEmpty
            ? '۷ روز اخیر'
            : result.activityLine,
        emptyHeadline: '',
        emptySub: '',
      );
    }

    if (result.hasAnyWorkout) {
      return _HeatmapDisplayCopy(
        title: 'نقشهٔ تمرین',
        subtitle: result.activityLine,
        emptyHeadline: _pick(const [
          'تمرینت ثبت شد',
          'خوب پیش رفتی',
          'لاگ داری، نقشه نزدیکه',
        ]),
        emptySub: _pick(const [
          'حرکات با نقشه عضلانی، اینجا روشن می‌شن',
          'چند حرکت با نقشه داشته باش، بدنت رنگی می‌شه',
          'همین مسیر — نقشه به‌زودی پر می‌شه',
        ]),
      );
    }

    return _HeatmapDisplayCopy(
      title: 'نقشهٔ تمرین',
      subtitle: '۷ روز اخیر',
      emptyHeadline: _pick(const [
        'بدنت خاموشه',
        'هنوز جرقه‌ای نزدی',
        'نقشه منتظرته',
        'این هفته خالیه',
        'وقت اولین رنگه',
      ]),
      emptySub: _pick(const [
        'یک تمرین ثبت کن — نقشه زنده می‌شه',
        'بزن بریم لاگ تمرین؛ بدنت روشن می‌شه',
        'همین‌جا بزن، هفته‌ات رنگ می‌گیره',
        'تمرین اول = اولین نقشه روی بدن',
        'ثبت کن؛ بقیه‌اش با ماست',
      ]),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 280.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent
            ? AppTheme.goldColor.withValues(alpha: isDark ? 0.14 : 0.12)
            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: accent
              ? AppTheme.goldColor.withValues(alpha: 0.35)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: accent
                ? AppTheme.goldColor
                : (isDark ? Colors.white54 : AppTheme.lightTextSecondary),
          ),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 9.5.sp,
                fontWeight: accent ? FontWeight.w700 : FontWeight.w500,
                height: 1.25,
                color: isDark ? Colors.white70 : AppTheme.lightTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
