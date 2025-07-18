import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AchievementBadge extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final double progress;
  final Color? color;
  final VoidCallback? onTap;

  const AchievementBadge({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.color,
    this.onTap,
  }) : super(key: key);

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _controller.value = 0.0;

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.repeat(
              reverse: true,
              min: 0.0,
              max: 1.0,
              period: const Duration(milliseconds: 1200));
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AchievementBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUnlocked != oldWidget.isUnlocked) {
      if (widget.isUnlocked) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = widget.color ?? AppTheme.goldColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: widget.isUnlocked ? _rotationAnimation.value : 0,
            child: Transform.scale(
              scale: widget.isUnlocked ? _scaleAnimation.value : 1.0,
              child: child,
            ),
          );
        },
        child: Card(
          elevation: 4,
          color: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color:
                  widget.isUnlocked ? badgeColor : badgeColor.withOpacity(0.3),
              width: widget.isUnlocked ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 45,
                  width: 45,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isUnlocked
                              ? badgeColor.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          border: Border.all(
                            color: widget.isUnlocked
                                ? badgeColor
                                : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            widget.icon,
                            color: widget.isUnlocked
                                ? badgeColor
                                : Colors.grey.withOpacity(0.5),
                            size: 20,
                          ),
                        ),
                      ),
                      if (!widget.isUnlocked && widget.progress > 0)
                        CircularProgressIndicator(
                          value: widget.progress,
                          strokeWidth: 2,
                          color: badgeColor,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                        ),
                      if (!widget.isUnlocked)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.lock,
                              size: 6,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isUnlocked ? badgeColor : Colors.grey,
                    fontSize: 10,
                    fontWeight:
                        widget.isUnlocked ? FontWeight.bold : FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isUnlocked
                      ? 'تکمیل شده'
                      : '${(widget.progress * 100).toInt()}٪',
                  style: TextStyle(
                    color: widget.isUnlocked
                        ? badgeColor
                        : Colors.white.withOpacity(0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
