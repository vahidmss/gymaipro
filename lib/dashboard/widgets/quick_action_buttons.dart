import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/achievements/screens/achievements_screen.dart';
import 'package:gymaipro/ranking/screens/leaderboard_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/screens/trainer_ranking_screen.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ردیف اول: مربیان و درخواست برنامه
        Row(
          children: [
            Expanded(child: _buildTrainersButton(context)),
            SizedBox(width: 12.w),
            Expanded(child: _buildQuickProgramButton(context)),
          ],
        ),
        SizedBox(height: 12.h),
        // ردیف دوم: دستاوردها و رتبه‌بندی
        Row(
          children: [
            Expanded(child: _buildAchievementsButton(context)),
            SizedBox(width: 12.w),
            Expanded(child: _buildLeaderboardButton(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickProgramButton(BuildContext context) {
    return _TapScaleButton(
      onTap: () {
        Navigator.pushNamed(context, '/program-type-selection');
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth / 2 - 6.w).clamp(
            140.0,
            180.0,
          );
          return Container(
            width: buttonWidth,
            height: 72.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [context.backgroundColor, context.backgroundColor]
                    : [
                        context.goldGradientColors[0],
                        context.goldGradientColors[1],
                      ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.3
                      : 0.4,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.3
                        : 0.4,
                  ),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 48.h,
                    child: Image.asset(
                      'images/ai_robot.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'درخواست برنامه',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5.sp,
                        height: 1.611,
                        color: context.buttonText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrainersButton(BuildContext context) {
    return _TapScaleButton(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const TrainerRankingScreen(),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth / 2 - 6.w).clamp(
            140.0,
            180.0,
          );
          return Container(
            width: buttonWidth,
            height: 72.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [context.backgroundColor, context.backgroundColor]
                    : [
                        context.goldGradientColors[0],
                        context.goldGradientColors[1],
                      ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.3
                      : 0.4,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.3
                        : 0.4,
                  ),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'مربیان برتر',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5.sp,
                            height: 1.3,
                            color: context.buttonText,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Padding(
                        padding: EdgeInsets.only(right: 22.w),
                        child: Container(
                          width: 36.w,
                          height: 36.h,
                          child: Image.asset(
                            'images/trainer_icon.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 1.5.w),
                        child: Image.asset(
                          'images/star_icon.png',
                          width: 10.w,
                          height: 10.h,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardButton(BuildContext context) {
    return _TapScaleButton(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const LeaderboardScreen(),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth / 2 - 6.w).clamp(
            140.0,
            180.0,
          );
          return Container(
            width: buttonWidth,
            height: 73.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [context.backgroundColor, context.backgroundColor]
                    : [
                        context.goldGradientColors[0],
                        context.goldGradientColors[1],
                      ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.3
                      : 0.4,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.3
                        : 0.4,
                  ),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'رتبه‌بندی',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5.sp,
                        height: 1.3,
                        color: context.buttonText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.emoji_events,
                    size: 24.sp,
                    color: context.buttonText,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsButton(BuildContext context) {
    return _TapScaleButton(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const AchievementsScreen(),
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth / 2 - 6.w).clamp(
            140.0,
            180.0,
          );
          return Container(
            width: buttonWidth,
            height: 73.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [context.veryDarkBackground, context.veryDarkBackground]
                    : [
                        context.goldGradientColors[0],
                        context.goldGradientColors[1],
                      ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.goldColor.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.3
                      : 0.4,
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.3
                        : 0.4,
                  ),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'دستاوردها',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5.sp,
                        height: 1.3,
                        color: context.buttonText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    width: 36.w,
                    height: 36.h,
                    child: Image.asset(
                      'images/achievement_icon.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ویجت دکمه با افکت فشار (scale) برای بازخورد لمسی
class _TapScaleButton extends StatefulWidget {
  const _TapScaleButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
