import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GoldDialog extends StatefulWidget {
  const GoldDialog({
    required this.title,
    required this.message,
    super.key,
    this.icon,
    this.additionalContent,
    this.actions,
    this.accentColor,
    this.showCloseButton = true,
    this.maxWidth,
  });
  final String title;
  final String message;
  final IconData? icon;
  final List<Widget>? additionalContent;
  final List<Widget>? actions;
  final Color? accentColor;
  final bool showCloseButton;
  final double? maxWidth;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    List<Widget>? additionalContent,
    List<Widget>? actions,
    Color? accentColor,
    bool barrierDismissible = true,
    bool showCloseButton = true,
    double? maxWidth,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      useRootNavigator: true, // جلوگیری از conflict با overlay
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(curvedAnimation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, _, __) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final safePadding = mediaQuery.padding;
        
        // محاسبه insetPadding به صورت responsive (مینیمال‌تر)
        final horizontalInset = screenWidth > 600 
            ? screenWidth * 0.12 // 12% برای تبلت (کاهش از 15%)
            : screenWidth * 0.06.clamp(10.0, 20.0); // 6% برای موبایل (کاهش از 8%)
        final verticalInset = screenHeight * 0.08.clamp(12.0, 32.0); // کاهش از 10%
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            top: safePadding.top + verticalInset,
            bottom: safePadding.bottom + verticalInset,
          ),
          elevation: 0,
          child: GoldDialog(
            title: title,
            message: message,
            icon: icon,
            additionalContent: additionalContent,
            actions: actions,
            accentColor: accentColor,
            showCloseButton: showCloseButton,
            maxWidth: maxWidth,
          ),
        );
      },
    );
  }

  @override
  State<GoldDialog> createState() => _GoldDialogState();
}

class _GoldDialogState extends State<GoldDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controller.value = 0.0;

    _contentAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.safeForward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = widget.accentColor ?? AppTheme.goldColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        // محاسبه maxWidth به صورت responsive
        final effectiveMaxWidth = widget.maxWidth ??
            (constraints.maxWidth > 600 
                ? constraints.maxWidth * 0.7.clamp(400.0, 600.0)
                : constraints.maxWidth * 0.9.clamp(280.0, 400.0));
        
        // محاسبه corner radius به صورت responsive
        final cornerRadius = constraints.maxWidth * 0.05.clamp(16.0, 24.0);
        
        return Container(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: constraints.maxWidth * 0.04.clamp(16.0, 24.0),
                spreadRadius: 0.5,
              ),
            ],
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(accentColor, constraints),
                _buildBody(accentColor, constraints),
                if (widget.actions != null && widget.actions!.isNotEmpty)
                  _buildActions(constraints),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color accentColor, BoxConstraints constraints) {
    final headerPadding = constraints.maxWidth * 0.035.clamp(10.0, 16.0); // کاهش از 0.04
    final iconSize = constraints.maxWidth * 0.055.clamp(16.0, 22.0); // کاهش از 0.06
    final fontSize = constraints.maxWidth * 0.042.clamp(14.0, 17.0); // کاهش از 0.045
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: headerPadding * 0.5, // کاهش از 0.6
        horizontal: headerPadding * 0.9, // کاهش از 1.0
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Container(
              padding: EdgeInsets.all(headerPadding * 0.5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: Colors.white, size: iconSize),
            ),
            SizedBox(width: headerPadding * 0.75),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 1.5,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showCloseButton)
            IconButton(
              icon: Icon(
                LucideIcons.x,
                color: Colors.white.withValues(alpha: 0.9),
                size: iconSize * 0.85,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.all(headerPadding * 0.3),
              constraints: BoxConstraints(
                minWidth: iconSize * 1.2,
                minHeight: iconSize * 1.2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(Color accentColor, BoxConstraints constraints) {
    final bodyPadding = constraints.maxWidth * 0.035.clamp(10.0, 16.0); // کاهش از 0.04
    final fontSize = constraints.maxWidth * 0.036.clamp(12.5, 14.5); // کاهش از 0.038
    final spacing = constraints.maxWidth * 0.025.clamp(8.0, 12.0); // کاهش از 0.03
    
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _contentAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - _contentAnimation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(bodyPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // پیام اصلی
            Text(
              widget.message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: fontSize,
                height: 1.5,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.justify,
            ),

            // محتوای اضافی
            if (widget.additionalContent != null) ...[
              SizedBox(height: spacing),
              ...widget.additionalContent!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BoxConstraints constraints) {
    final actionPadding = constraints.maxWidth * 0.035.clamp(10.0, 16.0); // کاهش از 0.04
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        actionPadding * 0.9, // کاهش از 1.0
        actionPadding * 0.4, // کاهش از 0.5
        actionPadding * 0.9, // کاهش از 1.0
        actionPadding * 0.85, // کاهش از 1.0
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: widget.actions!,
      ),
    );
  }
}
