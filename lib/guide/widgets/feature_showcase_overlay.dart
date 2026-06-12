import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/guide_step.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Overlay برای نمایش feature showcase با spotlight روی المنت هدف
class FeatureShowcaseOverlay extends StatefulWidget {

  const FeatureShowcaseOverlay({
    required this.step, required this.onNext, required this.onSkip, required this.currentIndex, required this.totalSteps, required this.isFirstStep, required this.isLastStep, super.key,
    this.onPrevious,
  });
  final GuideStep step;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final void Function({bool dontShowAgain}) onSkip;
  final int currentIndex;
  final int totalSteps;
  final bool isFirstStep;
  final bool isLastStep;

  @override
  State<FeatureShowcaseOverlay> createState() => _FeatureShowcaseOverlayState();
}

class _FeatureShowcaseOverlayState extends State<FeatureShowcaseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Rect? _targetRect;
  bool _dontShowAgain = false;

  double _clamp(double value, double min, double max) {
    return value.clamp(min, max);
  }

  double _safeClamp(double value, double min, double max) {
    if (!value.isFinite || !min.isFinite || !max.isFinite) return value;
    if (max < min) return min; // جلوگیری از crash در double.clamp
    return value.clamp(min, max);
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _scrollToTarget();
      // تاخیر کوتاه برای اطمینان از کامل شدن اسکرول و render شدن
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        // محاسبه موقعیت چند بار برای اطمینان
        _calculateTargetPosition();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _calculateTargetPosition(); // دوباره محاسبه برای اطمینان
          _animationController.forward();
        }
      }
    });
  }

  @override
  void didUpdateWidget(FeatureShowcaseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      _animationController.reset();
      _scrollToTargetAndShow();
    }
  }

  /// اسکرول به المنت مقصد و سپس نمایش tooltip
  Future<void> _scrollToTargetAndShow() async {
    await _scrollToTarget();
    // کاهش delay برای smooth‌تر شدن
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      // محاسبه موقعیت
      _calculateTargetPosition();
      // کاهش delay برای smooth‌تر شدن
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _calculateTargetPosition(); // دوباره محاسبه برای اطمینان
        _animationController.forward();
      }
    }
  }

  /// اسکرول به المنت مقصد
  Future<void> _scrollToTarget() async {
    if (widget.step.targetKey?.currentContext == null) return;

    try {
      final context = widget.step.targetKey!.currentContext!;
      final renderObject = context.findRenderObject();
      
      // اگر المنت در viewport قابل مشاهده است، اسکرول نکن
      if (renderObject is RenderBox) {
        final box = renderObject;
        final position = box.localToGlobal(Offset.zero);
        final size = box.size;
        final mediaQuery = MediaQuery.of(context);
        final screenHeight = mediaQuery.size.height;
        final safePadding = mediaQuery.padding;
        final viewportTop = safePadding.top;
        final viewportBottom = screenHeight - safePadding.bottom;
        
        // بررسی اینکه آیا المنت در viewport قابل مشاهده است
        final targetTop = position.dy;
        final targetBottom = position.dy + size.height;
        
        // اگر المنت کاملاً در viewport است، اسکرول نکن
        if (targetTop >= viewportTop && targetBottom <= viewportBottom) {
          return;
        }
      }
      
      // استفاده از Scrollable.ensureVisible برای اسکرول خودکار
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300), // کاهش بیشتر duration
        curve: Curves.easeOutCubic, // استفاده از curve نرم‌تر
        alignment: 0.2, // المنت در 20% بالای صفحه نمایش داده شود
      );
      // صبر کردن تا اسکرول کامل شود (کمتر از duration برای smooth‌تر شدن)
      await Future<void>.delayed(const Duration(milliseconds: 350));
    } catch (e) {
      debugPrint('Error scrolling to target: $e');
    }
  }

  void _calculateTargetPosition() {
    if (widget.step.targetKey?.currentContext == null) return;

    try {
      final BuildContext? targetContext = widget.step.targetKey!.currentContext;
      if (targetContext == null) return;

      final RenderObject? renderObject = targetContext.findRenderObject();
      if (renderObject == null || renderObject is! RenderBox) {
        // اگر renderBox آماده نیست، دوباره تلاش کن
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _calculateTargetPosition();
          }
        });
        return;
      }

      final RenderBox renderBox = renderObject;

      if (!renderBox.hasSize || renderBox.size.isEmpty) {
        // اگر size آماده نیست، دوباره تلاش کن
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _calculateTargetPosition();
          }
        });
        return;
      }

      // محاسبه offset نسبت به Overlay خودش (نه کل صفحه)
      // این کار مشکل mismatch روی DevicePreview/Transform/SafeArea را حل می‌کند.
      final RenderObject? overlayRenderObject = context.findRenderObject();
      final RenderBox? overlayBox = overlayRenderObject is RenderBox
          ? overlayRenderObject
          : null;

      final Offset offset = overlayBox != null
          ? renderBox.localToGlobal(Offset.zero, ancestor: overlayBox)
          : renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      // بررسی اعتبار مقادیر
      if (size.width <= 0 || size.height <= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _calculateTargetPosition();
          }
        });
        return;
      }

      // ایجاد rect با استفاده از offset و size
      // استفاده از & operator برای ایجاد Rect از Offset و Size
      final targetRect = offset & size;

      // بررسی نهایی اعتبار rect
      if (targetRect.width > 0 &&
          targetRect.height > 0 &&
          targetRect.isFinite) {
        setState(() {
          _targetRect = targetRect;
        });
      } else {
        // اگر rect نامعتبر است، دوباره تلاش کن
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _calculateTargetPosition();
          }
        });
      }
    } catch (e) {
      debugPrint('Error calculating target position: $e');
      // در صورت خطا، دوباره تلاش کن
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateTargetPosition();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // UNIFY SIZE SOURCE: استفاده از constraints برای skip button
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final mediaQuery = MediaQuery.of(context);
          final safeAreaTop = mediaQuery.padding.top;
          final skipTop = safeAreaTop + _clamp(screenHeight * 0.02, 8, 16);
          final skipLeft = _clamp(screenWidth * 0.04, 12, 24);
          return Stack(
            children: [
              // Backdrop با blur (برای modal center بهتر blur کنیم)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  // اگر tooltip در center است، blur بیشتری اعمال کن
                  final isCenter =
                      _targetRect == null ||
                      widget.step.tooltipPosition == TooltipPosition.center;
                  final blurAmount = isCenter ? 3.0 : 1.5;
                  final backdropOpacity = isCenter ? 0.7 : 0.5;

                  return Opacity(
                    opacity: _fadeAnimation.value * 0.9,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurAmount * _fadeAnimation.value,
                        sigmaY: blurAmount * _fadeAnimation.value,
                      ),
                      child: Container(
                        color: Colors.black.withValues(alpha: backdropOpacity),
                      ),
                    ),
                  );
                },
              ),

              // Spotlight روی target (اگر وجود دارد)
              if (_targetRect != null)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: SpotlightPainter(
                        targetRect: _targetRect!,
                        progress: _fadeAnimation.value,
                        usePulse: widget.step.usePulseAnimation,
                        pulseValue: _animationController.value,
                      ),
                      child: Container(),
                    );
                  },
                ),

              // محتوای tooltip
              _positionTooltip(constraints),

              // دکمه skip در گوشه (Positioned مستقیماً در Stack)
              Positioned(
                top: skipTop,
                left: skipLeft,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(opacity: _fadeAnimation.value, child: child);
                  },
                  child: _buildSkipButton(_dontShowAgain),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _positionTooltip(BoxConstraints constraints) {
    // Validate constraints
    if (constraints.maxWidth.isNaN ||
        constraints.maxHeight.isNaN ||
        constraints.maxWidth <= 0 ||
        constraints.maxHeight <= 0 ||
        !constraints.maxWidth.isFinite ||
        !constraints.maxHeight.isFinite) {
      return const SizedBox.shrink();
    }

    // اگر target نداریم یا tooltipPosition center است، tooltip را وسط صفحه نشان بده
    if (_targetRect == null ||
        widget.step.tooltipPosition == TooltipPosition.center) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 600
                  ? constraints.maxWidth *
                        0.65 // 65% برای تبلت (به جای 400.w)
                  : constraints.maxWidth * 0.9, // 90% برای موبایل
              maxHeight: constraints.maxHeight * 0.6,
            ),
            child: _buildTooltipCard(),
          ),
        ),
      );
    }

    // UNIFY SIZE SOURCE: استفاده فقط از BoxConstraints
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    // فقط MediaQuery برای safe area و keyboard insets
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    final viewInsetsBottom =
        mediaQuery.viewInsets.bottom; // KEYBOARD & INSETS AWARENESS
    final effectiveBottom = safeAreaBottom + viewInsetsBottom;

    // محاسبه عرض tooltip بر اساس عرض صفحه (responsive با درصد)
    final hardMaxTooltipWidth = screenWidth > 1200
        ? 560.0
        : screenWidth > 900
        ? 520.0
        : screenWidth > 600
        ? 480.0
        : 420.0;
    final tooltipMaxWidth = (screenWidth * (screenWidth > 600 ? 0.55 : 0.92))
        .clamp(0.0, hardMaxTooltipWidth)
        ;

    // محاسبه ارتفاع tooltip بر اساس ارتفاع صفحه (responsive)
    final hardMaxTooltipHeight = screenHeight > 1000 ? 460.0 : 520.0;
    final tooltipMaxHeight = (screenHeight * (screenHeight > 800 ? 0.42 : 0.52))
        .clamp(0.0, hardMaxTooltipHeight)
        ;

    double top = 0;
    double left = 0;
    // فاصله از target (responsive)
    final spacing = _clamp(screenHeight * 0.02, 8, 16);

    // محاسبه safe area margins (responsive) - شامل keyboard
    final edgePadX = _clamp(screenWidth * 0.04, 12, 24);
    final edgePadY = _clamp(screenHeight * 0.02, 8, 18);
    final minTop = safeAreaTop + edgePadY;
    final minBottom = effectiveBottom + edgePadY; // شامل keyboard
    final minLeft = edgePadX;
    final minRight = edgePadX;

    // فضای واقعی قابل استفاده (اگر این فضا کم باشد clamp(min,max) کرش می‌کند)
    final availableWidth = screenWidth - minLeft - minRight;
    final availableHeight = screenHeight - minTop - minBottom;
    if (availableWidth <= 0 || availableHeight <= 0) {
      return const SizedBox.shrink();
    }

    // Tooltip باید حتما داخل فضای قابل استفاده جا شود
    final effectiveTooltipMaxWidth = tooltipMaxWidth.clamp(0.0, availableWidth);
    final effectiveTooltipMaxHeight = tooltipMaxHeight.clamp(
      0.0,
      availableHeight,
    );

    switch (widget.step.tooltipPosition) {
      case TooltipPosition.bottom:
        top = _targetRect!.bottom + spacing;
        left = (screenWidth - effectiveTooltipMaxWidth) / 2;
        // اگر tooltip از صفحه خارج میشه، بالای target قرار بده
        if (top + effectiveTooltipMaxHeight > screenHeight - minBottom) {
          top = _targetRect!.top - effectiveTooltipMaxHeight - spacing;
          // اگر باز هم جا نداره، center کن
          if (top < minTop) {
            top = (screenHeight - effectiveTooltipMaxHeight) / 2;
          }
        }
      case TooltipPosition.top:
        top = _targetRect!.top - effectiveTooltipMaxHeight - spacing;
        left = (screenWidth - effectiveTooltipMaxWidth) / 2;
        // اگر tooltip از صفحه خارج میشه، پایین target قرار بده
        if (top < minTop) {
          top = _targetRect!.bottom + spacing;
          // اگر باز هم جا نداره، center کن
          if (top + effectiveTooltipMaxHeight > screenHeight - minBottom) {
            top = (screenHeight - effectiveTooltipMaxHeight) / 2;
          }
        }
      case TooltipPosition.left:
        // TARGET-RELATIVE POSITIONING: نسبت به targetRect
        top =
            _targetRect!.top +
            (_targetRect!.height - effectiveTooltipMaxHeight) / 2;
        left =
            _targetRect!.left - effectiveTooltipMaxWidth - spacing; // چپ target

        // اگر overflow شد، راست target قرار بده (fallback)
        if (left < minLeft) {
          left = _targetRect!.right + spacing; // راست target
          // اگر باز هم overflow شد، به edge clamp کن
          if (left + effectiveTooltipMaxWidth > screenWidth - minRight) {
            left = screenWidth - effectiveTooltipMaxWidth - minRight;
          }
        }

        // اگر tooltip از بالا یا پایین خارج میشه، clamp کن
        if (top < minTop) top = minTop;
        if (top + effectiveTooltipMaxHeight > screenHeight - minBottom) {
          top = screenHeight - effectiveTooltipMaxHeight - minBottom;
        }
      case TooltipPosition.right:
        // TARGET-RELATIVE POSITIONING: نسبت به targetRect
        top =
            _targetRect!.top +
            (_targetRect!.height - effectiveTooltipMaxHeight) / 2;
        left = _targetRect!.right + spacing; // راست target

        // اگر overflow شد، چپ target قرار بده (fallback)
        if (left + effectiveTooltipMaxWidth > screenWidth - minRight) {
          left =
              _targetRect!.left -
              effectiveTooltipMaxWidth -
              spacing; // چپ target
          // اگر باز هم overflow شد، به edge clamp کن
          if (left < minLeft) {
            left = minLeft;
          }
        }

        // اگر tooltip از بالا یا پایین خارج میشه، clamp کن
        if (top < minTop) top = minTop;
        if (top + effectiveTooltipMaxHeight > screenHeight - minBottom) {
          top = screenHeight - effectiveTooltipMaxHeight - minBottom;
        }
      case TooltipPosition.center:
        // این case قبلاً در ابتدای تابع handle شده
        return const SizedBox.shrink();
    }

    // FINAL GUARANTEES: بررسی نهایی برای عدم overflow/clipping
    final maxTop = screenHeight - effectiveTooltipMaxHeight - minBottom;
    final maxLeft = screenWidth - effectiveTooltipMaxWidth - minRight;
    
    // Clamp نهایی برای اطمینان از قرارگیری در safe area
    top = _safeClamp(top, minTop, maxTop);
    left = _safeClamp(left, minLeft, maxLeft);

    return Positioned(
      top: top,
      left: left,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: effectiveTooltipMaxWidth,
            maxHeight: effectiveTooltipMaxHeight,
          ),
          child: _buildTooltipCard(),
        ),
      ),
    );
  }

  Widget _buildTooltipCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Validate constraints
        if (constraints.maxWidth.isNaN ||
            constraints.maxHeight.isNaN ||
            constraints.maxWidth <= 0 ||
            constraints.maxHeight <= 0 ||
            !constraints.maxWidth.isFinite ||
            !constraints.maxHeight.isFinite) {
          return const SizedBox.shrink();
        }

        // محاسبه padding و spacing بر اساس constraints (responsive)
        final padding = _clamp(constraints.maxWidth * 0.04, 12, 22);
        final spacing = _clamp(constraints.maxHeight * 0.015, 8, 14);
        final cornerRadius = _clamp(constraints.maxWidth * 0.04, 12, 20);
        final borderWidth = _clamp(constraints.maxWidth * 0.005, 1, 2);
        final shadowBlur = _clamp(constraints.maxWidth * 0.03, 12, 20);
        final shadowSpread = _clamp(constraints.maxWidth * 0.0025, 1, 3);
        final shadowOffsetY = _clamp(constraints.maxWidth * 0.01, 4, 10);
        final horizontalMargin = _clamp(constraints.maxWidth * 0.04, 10, 20);

        return Container(
          // margin فقط برای non-center tooltips
          margin:
              (_targetRect == null ||
                  widget.step.tooltipPosition == TooltipPosition.center)
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(horizontal: horizontalMargin),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(
              color:
                  widget.step.primaryColor ??
                  AppTheme.goldColor.withValues(alpha: 0.4),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                blurRadius: shadowBlur,
                spreadRadius: shadowSpread,
                offset: Offset(0, shadowOffsetY),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                SizedBox(height: spacing),

                // آیکون و عنوان
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    if (widget.step.icon != null)
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(padding * 0.5),
                          decoration: BoxDecoration(
                            color:
                                (widget.step.primaryColor ?? AppTheme.goldColor)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              _clamp(constraints.maxWidth * 0.02, 10, 14),
                            ),
                          ),
                          child: Icon(
                            widget.step.icon,
                            color:
                                widget.step.primaryColor ?? AppTheme.goldColor,
                            size: _clamp(constraints.maxWidth * 0.045, 18, 28),
                          ),
                        ),
                      ),
                    if (widget.step.icon != null)
                      SizedBox(width: padding * 0.4), // کاهش از 0.5
                    Expanded(
                      child: Text(
                        widget.step.title,
                        style: TextStyle(
                          fontSize: _clamp(constraints.maxWidth * 0.04, 16, 22),
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : AppTheme.lightTextColor,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 0.6), // کاهش از 0.8

                // توضیحات
                Text(
                  widget.step.description,
                  style: TextStyle(
                    fontSize: _clamp(constraints.maxWidth * 0.033, 13, 17),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.lightTextSecondary,
                    height: 1.5,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),

                // دکمه عمل اختیاری
                if (widget.step.action != null) ...[
                  SizedBox(height: spacing),
                  _buildActionButton(),
                ],

                // Checkbox "دیگه نشون نده" (فقط در مرحله آخر)
                if (widget.isLastStep) ...[
                  SizedBox(height: spacing),
                  _buildDontShowAgainCheckbox(),
                ],

                SizedBox(height: spacing * 1.2),
                // دکمه‌های ناوبری
                _buildNavigationButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Validate constraints
        if (constraints.maxWidth.isNaN ||
            constraints.maxWidth <= 0 ||
            !constraints.maxWidth.isFinite) {
          return const SizedBox.shrink();
        }

        final dotSize = _clamp(constraints.maxWidth * 0.015, 4, 7);
        final activeDotSize = _clamp(constraints.maxWidth * 0.05, 18, 28);
        final dotSpacing = _clamp(constraints.maxWidth * 0.006, 2, 6);

        return Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.totalSteps, (index) {
            final isActive = index == widget.currentIndex;
            final isPassed = index < widget.currentIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: dotSpacing),
              width: isActive ? activeDotSize : dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: isActive || isPassed
                    ? (widget.step.primaryColor ?? AppTheme.goldColor)
                    : (widget.step.primaryColor ?? AppTheme.goldColor)
                          .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(
                  constraints.maxWidth * 0.0075,
                ), // 0.75% از عرض
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Validate constraints
        if (constraints.maxWidth.isNaN ||
            constraints.maxWidth <= 0 ||
            !constraints.maxWidth.isFinite) {
          return const SizedBox.shrink();
        }

        final buttonPadding = _clamp(constraints.maxWidth * 0.025, 10, 16);
        final borderRadius = _clamp(constraints.maxWidth * 0.025, 10, 14);
        final fontSize = _clamp(constraints.maxWidth * 0.033, 13, 17);

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.step.action?.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.step.primaryColor ?? AppTheme.goldColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: 1,
            ),
            child: Text(
              widget.step.action!.label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDontShowAgainCheckbox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Validate constraints
        if (constraints.maxWidth.isNaN ||
            constraints.maxWidth <= 0 ||
            !constraints.maxWidth.isFinite) {
          return const SizedBox.shrink();
        }

        final fontSize = _clamp(constraints.maxWidth * 0.03, 12, 15);

        return Row(
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
              activeColor: widget.step.primaryColor ?? AppTheme.goldColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Flexible(
              child: Text(
                'دیگه نشون نده',
                style: TextStyle(
                  fontSize: fontSize,
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
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Validate constraints
        if (constraints.maxWidth.isNaN ||
            constraints.maxWidth <= 0 ||
            !constraints.maxWidth.isFinite) {
          return const SizedBox.shrink();
        }

        final buttonPadding = _clamp(constraints.maxWidth * 0.025, 10, 16);
        final buttonSpacing = _clamp(constraints.maxWidth * 0.03, 10, 18);
        final fontSize = _clamp(constraints.maxWidth * 0.033, 13, 17);

        return Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // دکمه قبلی
            if (!widget.isFirstStep)
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onPrevious,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.step.primaryColor ?? AppTheme.goldColor,
                      width: _clamp(constraints.maxWidth * 0.00375, 1, 2),
                    ),
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        _clamp(constraints.maxWidth * 0.025, 10, 14),
                      ),
                    ),
                  ),
                  child: Text(
                    'قبلی',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: widget.step.primaryColor ?? AppTheme.goldColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (!widget.isFirstStep) SizedBox(width: buttonSpacing),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // اگر آخرین مرحله است و checkbox تیک خورده، skip کن با dontShowAgain
                  if (widget.isLastStep && _dontShowAgain) {
                    widget.onSkip(dontShowAgain: true);
                  } else {
                    // در غیر این صورت، next رو صدا بزن
                    widget.onNext();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      widget.step.primaryColor ?? AppTheme.goldColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      _clamp(constraints.maxWidth * 0.025, 10, 14),
                    ),
                  ),
                  elevation: 1,
                ),
                child: Text(
                  widget.isLastStep ? 'متوجه شدم!' : 'بعدی',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTheme.fontFamily,
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkipButton(bool dontShowAgain) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // UNIFY SIZE SOURCE: استفاده از constraints
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Validate constraints
        if (screenWidth.isNaN ||
            screenHeight.isNaN ||
            screenWidth <= 0 ||
            screenHeight <= 0 ||
            !screenWidth.isFinite ||
            !screenHeight.isFinite) {
          return const SizedBox.shrink();
        }

        final borderRadius = _clamp(screenWidth * 0.05, 14, 22);
        final horizontalPadding = _clamp(screenWidth * 0.04, 12, 20);
        final verticalPadding = _clamp(screenHeight * 0.01, 8, 12);
        final fontSize = _clamp(screenWidth * 0.03, 12, 15);
        final iconSize = _clamp(screenWidth * 0.045, 18, 22);
        final spacing = _clamp(screenWidth * 0.015, 6, 10);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onSkip(dontShowAgain: dontShowAgain),
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'رد کردن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(width: spacing),
                  Icon(Icons.close, color: Colors.white, size: iconSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter برای رسم spotlight روی target
class SpotlightPainter extends CustomPainter {

  SpotlightPainter({
    required this.targetRect,
    required this.progress,
    this.usePulse = true,
    this.pulseValue = 0,
  });
  final Rect targetRect;
  final double progress;
  final bool usePulse;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    // SPOTLIGHT CANVAS SAFETY: Validate canvas size
    if (size.width <= 0 ||
        size.height <= 0 ||
        !size.width.isFinite ||
        !size.height.isFinite) {
      return; // Graceful no-op
    }

    // Validate targetRect نسبت به canvas
    if (targetRect.left >= size.width ||
        targetRect.top >= size.height ||
        targetRect.right <= 0 ||
        targetRect.bottom <= 0) {
      // Target کاملاً خارج canvas است - فقط backdrop رسم کن
      final backgroundPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5 * progress);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        backgroundPaint,
      );
      return;
    }

    // پس‌زمینه تیره (کمتر برای وضوح بیشتر)
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5 * progress);

    // ایجاد hole برای target
    final holePath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    double clampDouble(double value, double min, double max) {
      return value.clamp(min, max);
    }

    final shortest = size.width < size.height ? size.width : size.height;

    // محاسبه padding برای spotlight (clamped برای نمایشگرهای بزرگ)
    final basePadding = clampDouble(shortest * 0.018, 6, 18);
    final pulsePadding = clampDouble(shortest * 0.006, 0, 8);
    final padding = basePadding + (usePulse ? pulseValue * pulsePadding : 0);

    // SPOTLIGHT CANVAS SAFETY: Clamp targetRect نسبت به canvas size
    final left = (targetRect.left - padding).clamp(0.0, size.width);
    final top = (targetRect.top - padding).clamp(0.0, size.height);
    final right = (targetRect.right + padding).clamp(0.0, size.width);
    final bottom = (targetRect.bottom + padding).clamp(0.0, size.height);

    // اطمینان از اینکه right > left و bottom > top
    final spotlightRect = Rect.fromLTRB(
      left,
      top,
      right > left ? right : left + 1,
      bottom > top ? bottom : top + 1,
    );

    // ایجاد hole با گوشه‌های گرد (clamped)
    final borderRadius = clampDouble(shortest * 0.035, 10, 22);
    final spotlightPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(spotlightRect, Radius.circular(borderRadius)),
      );

    holePath.addPath(spotlightPath, Offset.zero);
    holePath.fillType = PathFillType.evenOdd;

    canvas.drawPath(holePath, backgroundPaint);

    // رسم border دور target (clamped)
    final strokeWidth = clampDouble(shortest * 0.008, 1.5, 4);
    final borderPaint = Paint()
      ..color = AppTheme.goldColor.withValues(alpha: 0.9 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlightRect, Radius.circular(borderRadius)),
      borderPaint,
    );

    // افکت glow (کمتر blur برای وضوح بیشتر)
    if (usePulse) {
      // blur radius (clamped)
      final blurRadius = clampDouble(shortest * 0.02, 8, 18);

      final glowPaint = Paint()
        ..color = AppTheme.goldColor
            .withValues(
              alpha: 0.25 * progress * pulseValue,
            ) // کاهش از 0.3 به 0.25
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          blurRadius,
        ); // blur بر اساس درصد

      final glowBorderRadius = clampDouble(shortest * 0.04, 12, 26);

      final inflateAmount = clampDouble(shortest * 0.012, 3, 10);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          spotlightRect.inflate(inflateAmount),
          Radius.circular(glowBorderRadius),
        ),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SpotlightPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.targetRect != targetRect;
  }
}
