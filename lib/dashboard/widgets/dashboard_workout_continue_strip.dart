import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_store.dart';
import 'package:gymaipro/features/product_experience/active_workout_session_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// ردیف شخصی زیر Hero تمرین: ادامهٔ جلسه یا آخرین تمرین ثبت‌شده.
/// بدون داده مخفی می‌شود — نه empty state کاتالوگی.
class DashboardWorkoutContinueStrip extends StatefulWidget {
  const DashboardWorkoutContinueStrip({this.refreshToken = 0, super.key});

  final int refreshToken;

  @override
  State<DashboardWorkoutContinueStrip> createState() =>
      _DashboardWorkoutContinueStripState();
}

class _DashboardWorkoutContinueStripState
    extends State<DashboardWorkoutContinueStrip> {
  final LiveWorkoutSessionStore _draftStore = LiveWorkoutSessionStore();
  final WorkoutDailyLogService _logService = WorkoutDailyLogService();

  _ContinueStripData? _data;
  bool _busy = false;
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(DashboardWorkoutContinueStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final id = ++_loadId;
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        if (mounted && id == _loadId) setState(() => _data = null);
        return;
      }

      final draft = await _draftStore.loadDraft(userId);
      if (id != _loadId) return;

      if (draft != null &&
          ActiveWorkoutSessionService.draftHasProgress(draft.session)) {
        final session = draft.session;
        final focus = session.focus.trim().isNotEmpty
            ? session.focus.trim()
            : session.title.trim();
        if (!mounted || id != _loadId) return;
        setState(() {
          _data = _ContinueStripData(
            kind: _ContinueKind.resume,
            title: 'ادامه جلسه',
            subtitle: focus.isNotEmpty
                ? '$focus · ${session.completedSets}/${session.totalSets} ست'
                : '${session.completedSets}/${session.totalSets} ست',
            route: '/live-workout',
            icon: LucideIcons.play,
            emphasize: true,
          );
        });
        return;
      }

      final logs = await _logService.getUserDailyLogs(userId);
      if (id != _loadId) return;

      WorkoutDailyLog? last;
      for (final log in logs) {
        if (log.hasMeaningfulLoggedSets) {
          last = log;
          break;
        }
      }
      if (last == null) {
        if (mounted && id == _loadId) setState(() => _data = null);
        return;
      }

      final session = last.sessions.isNotEmpty ? last.sessions.last : null;
      final day = (session?.day ?? '').trim();
      final when = _relativeDayLabel(last.logDate);
      final subtitle = [
        if (day.isNotEmpty) day,
        when,
      ].join(' · ');

      if (!mounted || id != _loadId) return;
      setState(() {
        _data = _ContinueStripData(
          kind: _ContinueKind.last,
          title: 'آخرین تمرین',
          subtitle: subtitle.isNotEmpty ? subtitle : when,
          route: '/workout-log',
          icon: LucideIcons.history,
          emphasize: false,
        );
      });
    } catch (_) {
      if (mounted && id == _loadId) setState(() => _data = null);
    }
  }

  static String _relativeDayLabel(DateTime date) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(date.year, date.month, date.day);
    final diff = a.difference(b).inDays;
    if (diff <= 0) return 'امروز';
    if (diff == 1) return 'دیروز';
    if (diff < 7) return '$diff روز پیش';
    return '${date.month}/${date.day}';
  }

  Future<void> _open() async {
    final data = _data;
    if (data == null || _busy) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _busy = true);
    try {
      if (!mounted) return;
      await Navigator.pushNamed(context, data.route);
      if (mounted) unawaited(_load());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = context.textColor;
    final muted = context.textSecondary;
    final radius = BorderRadius.circular(14.r);
    final fill = data.emphasize
        ? (isDark
            ? AppTheme.goldColor.withValues(alpha: 0.14)
            : AppTheme.goldColor.withValues(alpha: 0.12))
        : context.cardColor;
    final border = data.emphasize
        ? AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.4)
        : context.separatorColor;
    final splash = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppTheme.lightTextColor.withValues(alpha: 0.12);

    return AbsorbPointer(
      absorbing: _busy,
      child: Opacity(
        opacity: _busy ? 0.7 : 1,
        child: Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          // رنگ روی Material — نه روی Ink؛ وگرنه ریپل زیر fill دفن می‌شود.
          child: Material(
            color: fill,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _open,
              borderRadius: radius,
              splashColor: splash,
              highlightColor: splash.withValues(alpha: isDark ? 0.08 : 0.06),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 52.h),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: border),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(data.icon, size: 16.sp, color: ink),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                data.title,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                data.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11.sp,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronLeft,
                          size: 16.sp,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ContinueKind { resume, last }

class _ContinueStripData {
  const _ContinueStripData({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.emphasize,
  });

  final _ContinueKind kind;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final bool emphasize;
}
