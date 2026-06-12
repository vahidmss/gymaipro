import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gymaipro/guide/services/guide_service.dart';
import 'package:gymaipro/guide/widgets/feature_tour_widget.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// نتیجهٔ دعوت به تور راهنما
enum GuideTourInviteChoice {
  /// شروع تور
  startTour,

  /// رد کردن برای همیشه (بدون تیک «بعداً بپرس»)
  declinedForever,

  /// رد موقت — دفعهٔ بعد دوباره پیشنهاد می‌شود
  declinedRemindLater,
}

/// نمایش باتم‌شیت دعوت به تور.
/// اگر بدون انتخاب مشخص بسته شود `null` برمی‌گرداند.
Future<GuideTourInviteChoice?> showGuideTourInviteSheet(
  BuildContext context, {
  required String title,
  required String description,
}) {
  return showModalBottomSheet<GuideTourInviteChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppTheme.veryDarkBackground.withValues(alpha: 0.45),
    builder: (sheetContext) {
      return _GuideTourInviteSheetBody(
        title: title,
        description: description,
      );
    },
  );
}

/// اگر راهنما هنوز فعال است یا نباید نمایش داده شود، هیچ کاری نمی‌کند؛
/// وگرنه باتم‌شیت دعوت را نشان می‌دهد و بر اساس انتخاب کاربر عمل می‌کند.
Future<void> offerGuideTourIfEligible(
  BuildContext context, {
  required String guideId,
  required String title,
  required String description,
}) async {
  final guideService = Provider.of<GuideService>(context, listen: false);
  if (!guideService.shouldShowGuide(guideId)) return;
  if (guideService.hasActiveGuide) return;

  final choice = await showGuideTourInviteSheet(
    context,
    title: title,
    description: description,
  );
  if (!context.mounted) return;

  switch (choice) {
    case GuideTourInviteChoice.startTour:
      await startGuide(context, guideId);
    case GuideTourInviteChoice.declinedForever:
      await guideService.suppressGuide(guideId);
    case GuideTourInviteChoice.declinedRemindLater:
    case null:
      break;
  }
}

class _GuideTourInviteSheetBody extends StatefulWidget {
  const _GuideTourInviteSheetBody({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  State<_GuideTourInviteSheetBody> createState() =>
      _GuideTourInviteSheetBodyState();
}

class _GuideTourInviteSheetBodyState extends State<_GuideTourInviteSheetBody>
    with SingleTickerProviderStateMixin {
  /// اگر true باشد، با زدن «فعلاً نه» دفعهٔ بعد دوباره پیشنهاد می‌شود.
  bool _askAgainNextTime = false;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final w = MediaQuery.sizeOf(context).width;

    final surface = isDark
        ? const Color(0xFF161616)
        : AppTheme.lightCardColor;
    final borderColor = isDark
        ? AppTheme.darkTextColor.withValues(alpha: 0.08)
        : AppTheme.goldColor.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface.withValues(alpha: isDark ? 0.94 : 0.92),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.veryDarkBackground.withValues(alpha: isDark ? 0.55 : 0.14),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                  spreadRadius: -8,
                ),
                if (!isDark)
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderArt(isDark: isDark, width: w),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22, 4, 22, 18 + bottomInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScaleTransition(
                            scale: _scale,
                            alignment: Alignment.topCenter,
                            child: _HeroIcon(isDark: isDark),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.title,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: (w * 0.048).clamp(17.0, 22.0),
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              letterSpacing: -0.3,
                              color: isDark
                                  ? AppTheme.darkTextColor
                                  : AppTheme.lightTextColor,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.description,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: (w * 0.038).clamp(13.0, 15.5),
                              height: 1.65,
                              color: isDark
                                  ? AppTheme.darkTextColor.withValues(alpha: 0.72)
                                  : AppTheme.lightTextSecondary,
                              fontFamily: AppTheme.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _RemindLaterTile(
                            isDark: isDark,
                            value: _askAgainNextTime,
                            onChanged: (v) {
                              setState(() => _askAgainNextTime = v);
                            },
                          ),
                          const SizedBox(height: 20),
                          _GradientPrimaryButton(
                            isDark: isDark,
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(GuideTourInviteChoice.startTour);
                            },
                          ),
                          const SizedBox(height: 12),
                          _GhostSecondaryButton(
                            isDark: isDark,
                            onPressed: () {
                              final result = _askAgainNextTime
                                  ? GuideTourInviteChoice.declinedRemindLater
                                  : GuideTourInviteChoice.declinedForever;
                              Navigator.of(context).pop(result);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// نوار کشیدن + گرادیان نرم بالای شیت
class _HeaderArt extends StatelessWidget {
  const _HeaderArt({required this.isDark, required this.width});

  final bool isDark;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = (width * 0.14).clamp(52.0, 64.0);
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? [
                          AppTheme.goldColor.withValues(alpha: 0.18),
                          AppTheme.darkGold.withValues(alpha: 0.06),
                          Colors.transparent,
                        ]
                      : [
                          AppTheme.lightGradientStart.withValues(alpha: 0.9),
                          AppTheme.lightGradientStart.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),
          // هالهٔ تزئینی
          Positioned(
            right: -width * 0.08,
            top: -h * 0.35,
            child: Container(
              width: width * 0.45,
              height: width * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldColor.withValues(
                  alpha: isDark ? 0.07 : 0.14,
                ),
              ),
            ),
          ),
          Positioned(
            left: -width * 0.05,
            bottom: -h * 0.2,
            child: Container(
              width: width * 0.22,
              height: width * 0.22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.darkGold.withValues(alpha: 0.12),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkTextColor.withValues(alpha: 0.22)
                  : AppTheme.veryDarkBackground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.55),
              AppTheme.darkGold.withValues(alpha: isDark ? 0.2 : 0.35),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.veryDarkBackground.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppTheme.darkTextColor.withValues(alpha: isDark ? 0.12 : 0.65),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.auto_awesome_motion_rounded,
          size: 36,
          color: isDark ? AppTheme.darkTextColor : AppTheme.onGoldColor,
        ),
      ),
    );
  }
}

class _RemindLaterTile extends StatelessWidget {
  const _RemindLaterTile({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = isDark
        ? AppTheme.darkTextColor.withValues(alpha: value ? 0.2 : 0.1)
        : AppTheme.goldColor.withValues(alpha: value ? 0.45 : 0.2);
    final fill = value
        ? AppTheme.goldColor.withValues(alpha: isDark ? 0.12 : 0.14)
        : (isDark
              ? AppTheme.darkTextColor.withValues(alpha: 0.04)
              : AppTheme.lightCardColor.withValues(alpha: 0.85));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1.2),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 22,
                color: value
                    ? AppTheme.goldColor
                    : (isDark
                          ? Colors.white54
                          : AppTheme.lightTextSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'دفعهٔ بعد دوباره ازم بپرس',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اگر خاموش باشه، با «فعلاً نه» دیگه '
                      'خودکار پیشنهادش نمی‌دم',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark
                            ? Colors.white54
                            : AppTheme.lightTextSecondary
                                  .withValues(alpha: 0.85),
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.goldColor;
                  }
                  return null;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.goldColor.withValues(alpha: 0.42);
                  }
                  return null;
                }),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientPrimaryButton extends StatelessWidget {
  const _GradientPrimaryButton({
    required this.isDark,
    required this.onPressed,
  });

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldColor,
            AppTheme.goldColor.withValues(alpha: 0.88),
            AppTheme.darkGold,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.35 : 0.42),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: AppTheme.onGoldColor,
                  size: 28,
                ),
                SizedBox(width: 6),
                Text(
                  'بله، بزن بریم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onGoldColor,
                    letterSpacing: -0.2,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostSecondaryButton extends StatelessWidget {
  const _GhostSecondaryButton({
    required this.isDark,
    required this.onPressed,
  });

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = isDark
        ? AppTheme.darkTextColor.withValues(alpha: 0.75)
        : AppTheme.lightTextSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'فعلاً نه',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: fg,
              fontFamily: AppTheme.fontFamily,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}
