import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/app_remote_image.dart';
import 'package:gymaipro/widgets/exercise_muscle_heatmap_widget.dart';
import 'package:gymaipro/workout_log/viewmodels/workout_log_viewmodel.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نقشهٔ عضلانی یک جلسه — از AppBar ثبت تمرین باز می‌شود.
class SessionMuscleHeatmapSheet extends StatelessWidget {
  const SessionMuscleHeatmapSheet({
    required this.viewModel,
    super.key,
  });

  final WorkoutLogViewModel viewModel;

  static Future<void> show(
    BuildContext context, {
    required WorkoutLogViewModel viewModel,
  }) {
    final snap = viewModel.sessionHeatmapSnapshot;
    if (snap.hasHeatmapData) {
      HapticFeedback.lightImpact();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SessionMuscleHeatmapSheet(viewModel: viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF12141A) : const Color(0xFFFFFBF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: viewModel.sessionHeatmapTick,
            builder: (context, _, __) {
              final liveSnap = viewModel.sessionHeatmapSnapshot;
              final liveSession = viewModel.selectedSession;
              final liveCopy =
                  _SessionHeatmapCopy.forSnapshot(liveSnap, liveSession?.day);

              return ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
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
                  Row(
                    children: [
                      Icon(
                        LucideIcons.flame,
                        color: AppTheme.goldColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          liveSession != null
                              ? 'نقشهٔ ${liveSession.day}'
                              : 'نقشهٔ این جلسه',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color:
                                isDark ? Colors.white : AppTheme.lightTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (liveSnap.hasHeatmapData && liveCopy.heroLine.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    _SessionHeroBanner(
                      line: liveCopy.heroLine,
                      isDark: isDark,
                    ),
                  ] else ...[
                    SizedBox(height: 4.h),
                    Text(
                      liveCopy.subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: isDark
                            ? Colors.white54
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                  if (liveSnap.hasHeatmapData) ...[
                    SizedBox(height: 12.h),
                    ExerciseMuscleHeatmapWidget(
                      key: ValueKey(
                        liveSnap.targets.entries
                            .map((e) => '${e.key}:${e.value}')
                            .join(','),
                      ),
                      muscleTargets: liveSnap.targets,
                      compact: true,
                      mapHeight: 220.h,
                    ),
                    if (liveSnap.topMuscles.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _TopMuscleChips(
                        muscles: liveSnap.topMuscles,
                        isDark: isDark,
                      ),
                    ],
                  ] else
                    _EmptySessionBody(
                      isDark: isDark,
                      headline: liveCopy.emptyHeadline,
                      sub: liveCopy.emptySub,
                    ),
                  if (liveCopy.tip.isNotEmpty) ...[
                    SizedBox(height: 14.h),
                    _TipLine(text: liveCopy.tip, isDark: isDark),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _TopMuscleChips extends StatelessWidget {
  const _TopMuscleChips({required this.muscles, required this.isDark});

  final List<MapEntry<String, int>> muscles;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: muscles.map((e) {
        final color = MuscleTargets.heatColor(e.value, isDark: isDark);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            MuscleTargets.label(e.key),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.lightTextColor,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptySessionBody extends StatelessWidget {
  const _EmptySessionBody({
    required this.isDark,
    required this.headline,
    required this.sub,
  });

  final bool isDark;
  final String headline;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Row(
        children: [
          SizedBox(
            width: 72.w,
            height: 100.h,
            child: Opacity(
              opacity: 0.25,
              child: AppRemoteImage(
                path: 'images/gymai_body_front_premium.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : AppTheme.lightTextColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  sub,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: isDark ? Colors.white38 : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.goldColor.withValues(alpha: isDark ? 0.08 : 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(
              LucideIcons.lightbulb,
              size: 16.sp,
              color: AppTheme.goldColor.withValues(alpha: 0.9),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11.sp,
                  color: isDark ? Colors.white60 : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHeroBanner extends StatelessWidget {
  const _SessionHeroBanner({required this.line, required this.isDark});

  final String line;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withValues(alpha: isDark ? 0.2 : 0.16),
            AppTheme.goldColor.withValues(alpha: isDark ? 0.06 : 0.05),
          ],
        ),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(
              LucideIcons.sparkles,
              color: AppTheme.goldColor,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                line,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  color: isDark ? Colors.white : AppTheme.lightTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHeatmapCopy {
  const _SessionHeatmapCopy({
    required this.subtitle,
    required this.heroLine,
    required this.emptyHeadline,
    required this.emptySub,
    required this.tip,
  });

  final String subtitle;
  final String heroLine;
  final String emptyHeadline;
  final String emptySub;
  final String tip;

  static int get _seed => DateTime.now().day;

  static String _pick(List<String> lines) => lines[_seed % lines.length];

  static _SessionHeatmapCopy forSnapshot(
    MuscleHeatmapSnapshot snap,
    String? sessionDay,
  ) {
    if (snap.hasHeatmapData) {
      final parts = <String>[];
      if (sessionDay != null && sessionDay.isNotEmpty) {
        parts.add(sessionDay);
      }
      parts.add('${snap.completedSets} ست');
      if (snap.exercisesWithSets > 0) {
        parts.add('${snap.exercisesWithSets} حرکت');
      }
      final hero = snap.topMuscleLabel != null
          ? 'این جلسه بیشتر روی ${snap.topMuscleLabel} فشار آورد'
          : 'نقشهٔ این جلسه روشن شد';

      return _SessionHeatmapCopy(
        subtitle: parts.join(' · '),
        heroLine: hero,
        emptyHeadline: '',
        emptySub: '',
        tip: _pick(const [
          'همین‌طور ادامه بده — نقشه با هر ست پرتر می‌شود',
          'خوبه؛ بعد از جلسه همین نقشه توی داشبورد هفته می‌آید',
          'تمرینت داره شکل می‌گیره — روی ثبت ست‌ها تمرکز کن',
        ]),
      );
    }

    if (snap.hasAnySets) {
      return _SessionHeatmapCopy(
        subtitle: '${snap.completedSets} ست · نقشه در راه',
        heroLine: '',
        emptyHeadline: 'حرکاتت نقشه ندارن',
        emptySub: 'با حرکات دارای نقشه عضلانی، اینجا رنگی می‌شه',
        tip: 'از بخش تمرینات، حرکت‌های با نقشه عضلانی انتخاب کن',
      );
    }

    return _SessionHeatmapCopy(
      subtitle: sessionDay ?? 'جلسهٔ امروز',
      heroLine: '',
      emptyHeadline: _pick(const [
        'هنوز ست‌ای نزدی',
        'نقشه خاموشه',
        'منتظر اولین ست',
      ]),
      emptySub: 'تکرار یا زمان را وارد کن — نقشه زنده می‌شود',
      tip: _pick(const [
        'هر ست ثبت‌شده، نقشه را روشن‌تر می‌کند',
        'اولین ست = اولین رنگ روی بدن',
        'لاگ کن؛ نقشه خودش می‌آید',
      ]),
    );
  }
}
