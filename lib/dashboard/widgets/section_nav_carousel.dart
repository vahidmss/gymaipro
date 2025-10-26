import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SectionNavCarousel extends StatelessWidget {
  const SectionNavCarousel({
    required this.title,
    required this.items,
    this.onHeaderAction,
    super.key,
  });
  final String title;
  final List<SectionCardItem> items;
  final VoidCallback? onHeaderAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Minimal header with smaller size
          Container(
            margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5.w,
              ),
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                // Smaller animated scroll hint
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.1),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: onHeaderAction,
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 0.5.w,
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 14.sp,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Smaller decorative line
                Container(
                  width: 2.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 4.r,
                        spreadRadius: 0.5.r,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Smaller title
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0.w, 1.h),
                            blurRadius: 2.r,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Smaller carousel
          SizedBox(
            height: 120.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 120.h,
                  width: 140.w,
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == items.length - 1 ? 0 : 12.w,
                    ),
                    child: _SectionCard(item: items[index], index: index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SectionCardItem {
  // optional background image for preview cards

  SectionCardItem({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradientColors,
    this.subtitle,
    this.iconColor,
    this.imageUrl,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Color? iconColor;
  final String? imageUrl;
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.item, required this.index});
  final SectionCardItem item;
  final int index;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _hoverAnimation;
  bool _isPressed = false; // kept for future press feedback; currently unused
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 1, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _hoverAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.item.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_animationController, _hoverController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.item.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: widget.item.gradientColors.first.withValues(
                        alpha: 0.1,
                      ),
                      blurRadius: 12 * _shadowAnimation.value,
                      offset: Offset(0, 4 * _shadowAnimation.value),
                      spreadRadius: 1 * _shadowAnimation.value,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4.r,
                      offset: Offset(0.w, 2.h),
                    ),
                    // Hover glow effect
                    if (_isHovered)
                      BoxShadow(
                        color: widget.item.gradientColors.first.withValues(
                          alpha: 0.1,
                        ),
                        blurRadius: 15 * _hoverAnimation.value,
                        spreadRadius: 2 * _hoverAnimation.value,
                      ),
                  ],
                ),
                constraints: BoxConstraints.expand(height: 120.h, width: 140.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image/top area
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.item.imageUrl != null)
                              Image.network(
                                widget.item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    const SizedBox.shrink(),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: widget.item.gradientColors,
                                  ),
                                ),
                              ),
                            // optional hover shine
                            Positioned(
                              top: 0.h,
                              left: 0.w,
                              right: 0.w,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: _isHovered ? 2 : 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Caption bottom area
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: _isPressed ? 0.45 : 0.35,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20.r),
                          bottomRight: Radius.circular(20.r),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.item.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                              height: 1.2.h,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                          ),
                          // subtitle removed per design
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
