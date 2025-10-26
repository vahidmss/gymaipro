import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
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
    this.maxWidth = 340,
  });
  final String title;
  final String message;
  final IconData? icon;
  final List<Widget>? additionalContent;
  final List<Widget>? actions;
  final Color? accentColor;
  final bool showCloseButton;
  final double maxWidth;

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
    double maxWidth = 340,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1).animate(curvedAnimation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
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
      ),
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
        _controller.forward();
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

    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 20.r,
            spreadRadius: 1.r,
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: 0.1),
          width: 1.5.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(accentColor),
            _buildBody(accentColor),
            if (widget.actions != null && widget.actions!.isNotEmpty)
              _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2.r,
                    offset: Offset(0.w, 1.h),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showCloseButton)
            IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(Color accentColor) {
    return AnimatedBuilder(
      animation: _contentAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _contentAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _contentAnimation.value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // پیام اصلی
            Text(
              widget.message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.1),
                fontSize: 14.sp,
                height: 1.5.h,
              ),
              textAlign: TextAlign.justify,
            ),

            // محتوای اضافی
            if (widget.additionalContent != null) ...[
              const SizedBox(height: 16),
              ...widget.additionalContent!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: widget.actions!,
      ),
    );
  }
}
