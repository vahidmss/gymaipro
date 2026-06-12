import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/onboarding_page.dart';
import 'package:gymaipro/guide/services/onboarding_service.dart';
import 'package:gymaipro/guide/widgets/onboarding_page_widget.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// صفحه Onboarding
class OnboardingScreen extends StatefulWidget {

  const OnboardingScreen({
    required this.pages, required this.onComplete, super.key,
  });
  final List<OnboardingPage> pages;
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _dontShowAgain = false;

  // Animation controllers برای هر صفحه
  final Map<int, AnimationController> _pageAnimations = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // ساخت animation controller برای صفحه اول
    _createAnimationController(0);
    _pageAnimations[0]?.forward();
  }

  AnimationController _createAnimationController(int index) {
    if (!_pageAnimations.containsKey(index)) {
      _pageAnimations[index] = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    }
    return _pageAnimations[index]!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _pageAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });

    // شروع انیمیشن برای صفحه جدید
    final controller = _createAnimationController(index);
    controller.reset();
    controller.forward();
  }

  void _nextPage() {
    if (_currentPage < widget.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    final onboardingService = Provider.of<OnboardingService>(
      context,
      listen: false,
    );
    onboardingService.completeOnboarding(dontShowAgain: _dontShowAgain);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == widget.pages.length - 1;
    final currentPage = widget.pages[_currentPage];

    double clampDouble(double value, double min, double max) {
      return value.clamp(min, max);
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final horizontalPadding = clampDouble(w * 0.06, 16, 28);
          final verticalPadding = clampDouble(h * 0.018, 10, 18);

          final dotSize = clampDouble(w * 0.014, 5, 8);
          final dotSpacing = clampDouble(w * 0.012, 4, 10);

          final buttonVerticalPadding = clampDouble(h * 0.016, 10, 16);
          final buttonRadius = clampDouble(w * 0.03, 10, 14);
          final buttonFontSize = clampDouble(w * 0.042, 14, 18);
          final buttonIconSize = clampDouble(w * 0.055, 18, 22);
          final bottomGap = clampDouble(h * 0.018, 10, 18);

          final skipFontSize = clampDouble(w * 0.038, 12, 15);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: currentPage.hasGradient
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        currentPage.gradientStartColor!,
                        currentPage.gradientEndColor!,
                      ],
                    ),
                  )
                : BoxDecoration(
                    color: isDark ? AppTheme.backgroundColor : Colors.white,
                  ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar (Skip)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: SizedBox(
                      height: clampDouble(h * 0.045, 36, 44),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: isLastPage
                            ? const SizedBox.shrink()
                            : TextButton(
                                onPressed: _skipOnboarding,
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : AppTheme.lightTextSecondary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(44, 44),
                                ),
                                child: Text(
                                  'رد کردن',
                                  style: TextStyle(
                                    fontSize: skipFontSize,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: widget.pages.length,
                      itemBuilder: (context, index) {
                        final page = widget.pages[index];
                        final animation = _createAnimationController(index);

                        return OnboardingPageWidget(
                          page: page,
                          animation: animation,
                        );
                      },
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      clampDouble(h * 0.02, 12, 22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: widget.pages.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: currentPage.primaryColor,
                            dotColor: currentPage.primaryColor.withValues(
                              alpha: 0.25,
                            ),
                            dotHeight: dotSize,
                            dotWidth: dotSize,
                            expansionFactor: 2.5,
                            spacing: dotSpacing,
                          ),
                        ),
                        SizedBox(height: bottomGap),

                        if (isLastPage)
                          Padding(
                            padding: EdgeInsets.only(bottom: bottomGap * 0.7),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _dontShowAgain,
                                  onChanged: (value) {
                                    setState(() {
                                      _dontShowAgain = value ?? false;
                                    });
                                  },
                                  activeColor: currentPage.primaryColor,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                Flexible(
                                  child: Text(
                                    'دیگه نشون نده',
                                    style: TextStyle(
                                      fontSize: clampDouble(
                                        w * 0.038,
                                        12,
                                        15,
                                      ),
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : AppTheme.lightTextSecondary,
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentPage.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: buttonVerticalPadding,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(buttonRadius),
                              ),
                              elevation: 2,
                              shadowColor: currentPage.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    isLastPage ? 'شروع کنیم!' : 'بعدی',
                                    style: TextStyle(
                                      fontSize: buttonFontSize,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppTheme.fontFamily,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: clampDouble(w * 0.018, 6, 10)),
                                Icon(
                                  isLastPage
                                      ? Icons.check_circle_outline
                                      : Icons.arrow_back,
                                  size: buttonIconSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

