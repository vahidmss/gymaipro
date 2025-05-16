import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class GoldDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData? icon;
  final List<Widget>? additionalContent;
  final List<Widget>? actions;
  final Color? accentColor;
  final bool showCloseButton;
  final double maxWidth;

  const GoldDialog({
    Key? key,
    required this.title,
    required this.message,
    this.icon,
    this.additionalContent,
    this.actions,
    this.accentColor,
    this.showCloseButton = true,
    this.maxWidth = 340,
  }) : super(key: key);

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
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
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

    Future.delayed(const Duration(milliseconds: 50), () {
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
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.7),
            accentColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showCloseButton)
            IconButton(
              icon: const Icon(
                LucideIcons.x,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // پیام اصلی
            Text(
              widget.message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: widget.actions!,
      ),
    );
  }
}
