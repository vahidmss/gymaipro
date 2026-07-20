import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نیم‌صفحهٔ وضعیت ساخت برنامه با پیام‌های مرحله‌ای (مثل نسخه قدیمی).
class WorkoutProgramBuildProgress extends StatefulWidget {
  const WorkoutProgramBuildProgress({
    required this.status,
    this.error,
    this.onDismissError,
    super.key,
  });

  /// `building` | `success` | `error`
  final String status;
  final String? error;
  final VoidCallback? onDismissError;

  @override
  State<WorkoutProgramBuildProgress> createState() =>
      _WorkoutProgramBuildProgressState();
}

class _WorkoutProgramBuildProgressState
    extends State<WorkoutProgramBuildProgress>
    with SingleTickerProviderStateMixin {
  static const List<String> _stages = <String>[
    'در حال جمع‌آوری داده‌های تو…',
    'تحلیل هدف، تجهیزات و سطح تجربه…',
    'طراحی جلسات تمرینی شخصی‌سازی‌شده…',
    'انتخاب حرکات مناسب از کاتالوگ…',
    'بهینه‌سازی ست‌ها و ترتیب تمرین…',
    'داره برنامه نهایی آماده می‌شه…',
  ];

  late final AnimationController _pulse;
  int _stageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _startStageRotation();
  }

  @override
  void didUpdateWidget(covariant WorkoutProgramBuildProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != 'building') {
      _timer?.cancel();
    } else if (oldWidget.status != 'building') {
      _startStageRotation();
    }
  }

  void _startStageRotation() {
    _timer?.cancel();
    _stageIndex = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (!mounted || widget.status != 'building') return;
      setState(() {
        if (_stageIndex < _stages.length - 1) {
          _stageIndex++;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuilding = widget.status == 'building';
    final isError = widget.status == 'error';
    final message = isError
        ? (widget.error ?? 'ساخت برنامه ممکن نشد.')
        : isBuilding
        ? _stages[_stageIndex.clamp(0, _stages.length - 1)]
        : 'برنامه تمرینی‌ات آماده‌ست!';

    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.52,
          ),
          decoration: BoxDecoration(
            color: context.gymCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            border: Border.all(
              color: context.gymPrimary.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.gymTextSecondary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final scale = isBuilding
                          ? 0.94 + (_pulse.value * 0.08)
                          : 1.0;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 88.w,
                      height: 88.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isError
                              ? [
                                  Colors.red.shade400,
                                  Colors.red.shade700,
                                ]
                              : [
                                  AppTheme.goldColor,
                                  context.gymPrimary,
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isError ? Colors.red : AppTheme.goldColor)
                                .withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        isError
                            ? LucideIcons.circleAlert
                            : isBuilding
                            ? LucideIcons.bot
                            : LucideIcons.circleCheck,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    isError
                        ? 'یه مشکلی پیش اومد'
                        : isBuilding
                        ? 'جیم‌آی داره برات برنامه می‌سازه'
                        : 'آماده شد',
                    textAlign: TextAlign.center,
                    style: context.gymTextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.gymTextPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    child: Text(
                      message,
                      key: ValueKey<String>(message),
                      textAlign: TextAlign.center,
                      style: context.gymTextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: context.gymTextSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                  if (isBuilding) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6.h,
                        backgroundColor: context.gymPrimary.withValues(
                          alpha: 0.12,
                        ),
                        color: AppTheme.goldColor,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      'ممکنه کمی طول بکشه — صفحه رو نبند.',
                      textAlign: TextAlign.center,
                      style: context.gymTextStyle(
                        fontSize: 12,
                        color: context.gymTextTertiary,
                      ),
                    ),
                  ] else if (isError) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onDismissError,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.gymPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('باشه'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
