import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/onboarding_page.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// ویجت برای نمایش یک صفحه onboarding
class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final Animation<double> animation;

  const OnboardingPageWidget({
    super.key,
    required this.page,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orientation = MediaQuery.of(context).orientation;

    double clampDouble(double value, double min, double max) {
      return value.clamp(min, max).toDouble();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // layout decisions
        final isLandscape = orientation == Orientation.landscape;
        final isCompactHeight = h < 560;
        final useSideBySide = isLandscape && w >= 640;

        // spacing + typography (clamped برای جلوگیری از بزرگ شدن بیش از حد روی تبلت/دسکتاپ)
        final horizontalPadding = clampDouble(w * 0.07, 16, 40);
        final verticalPadding = clampDouble(h * 0.04, 14, 32);
        final gapLg = clampDouble(h * 0.05, 18, 36);
        final gapMd = clampDouble(h * 0.025, 10, 18);

        final titleSize = clampDouble(w * (useSideBySide ? 0.04 : 0.055), 18, 28);
        final bodySize = clampDouble(w * (useSideBySide ? 0.026 : 0.038), 13, 18);

        final textColor = page.hasGradient
            ? Colors.white
            : (isDark ? Colors.white : AppTheme.lightTextColor);
        final subTextColor = page.hasGradient
            ? Colors.white.withValues(alpha: 0.95)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : AppTheme.lightTextSecondary);

        final maxContentWidth = clampDouble(w * 0.92, 0, useSideBySide ? 960 : 560);

        final content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: useSideBySide
                ? Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0.12, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: _buildVisual(isDark, constraints),
                          ),
                        ),
                      ),
                      SizedBox(width: clampDouble(w * 0.05, 16, 32)),
                      Expanded(
                        flex: 7,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTexts(
                              titleSize: titleSize,
                              bodySize: bodySize,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              gapMd: gapMd,
                              isCompactHeight: isCompactHeight,
                            ),
                            if (page.customWidget != null) ...[
                              SizedBox(height: gapLg * 0.8),
                              FadeTransition(
                                opacity: animation,
                                child: page.customWidget!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.22),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                ),
                              ),
                          child: _buildVisual(isDark, constraints),
                        ),
                      ),
                      SizedBox(height: gapLg),
                      _buildTexts(
                        titleSize: titleSize,
                        bodySize: bodySize,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        gapMd: gapMd,
                        isCompactHeight: isCompactHeight,
                      ),
                      if (page.customWidget != null) ...[
                        SizedBox(height: gapLg * 0.8),
                        FadeTransition(
                          opacity: animation,
                          child: page.customWidget!,
                        ),
                      ],
                    ],
                  ),
          ),
        );

        // در ارتفاع کم، اسکرول فعال می‌شود تا هیچ overflowی رخ ندهد
        if (isCompactHeight) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: Center(child: content),
          );
        }

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildTexts({
    required double titleSize,
    required double bodySize,
    required Color textColor,
    required Color subTextColor,
    required double gapMd,
    required bool isCompactHeight,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: Text(
              page.title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: textColor,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: isCompactHeight ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(height: gapMd),
        FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.22),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: bodySize,
                height: 1.6,
                color: subTextColor,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisual(bool isDark, BoxConstraints constraints) {
    double clampDouble(double value, double min, double max) {
      return value.clamp(min, max).toDouble();
    }

    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    final shortest = w < h ? w : h;

    final visualSize = clampDouble(shortest * 0.42, 120, 240);
    final radius = clampDouble(visualSize * 0.1, 12, 18);
    final shadowBlur = clampDouble(visualSize * 0.12, 14, 26);
    final shadowSpread = clampDouble(visualSize * 0.012, 1.5, 3.5);

    if (page.hasImage && page.imagePath != null) {
      return Container(
        width: visualSize,
        height: visualSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: page.primaryColor.withValues(alpha: 0.2),
              blurRadius: shadowBlur,
              spreadRadius: shadowSpread,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(page.imagePath!, fit: BoxFit.cover),
        ),
      );
    }

    if (page.hasIcon && page.icon != null) {
      final iconSize = clampDouble(visualSize * 0.5, 52, 90);
      return Container(
        width: visualSize,
        height: visualSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              page.primaryColor.withValues(alpha: 0.15),
              page.primaryColor.withValues(alpha: 0.08),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: page.primaryColor.withValues(alpha: 0.2),
              blurRadius: shadowBlur,
              spreadRadius: shadowSpread,
            ),
          ],
        ),
        child: Icon(page.icon, size: iconSize, color: page.primaryColor),
      );
    }

    return const SizedBox.shrink();
  }
}
