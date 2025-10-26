import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/trainer_ranking/models/certificate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CertificateCarousel extends StatelessWidget {
  const CertificateCarousel({
    required this.title,
    required this.certificates,
    this.onCertificateTap,
    super.key,
  });

  final String title;
  final List<Certificate> certificates;
  final void Function(Certificate)? onCertificateTap;

  @override
  Widget build(BuildContext context) {
    if (certificates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple Header
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Carousel
          SizedBox(
            height: 120.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: certificates.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 120.h,
                  width: 140.w,
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == certificates.length - 1 ? 0 : 8.w,
                    ),
                    child: _CertificateCard(
                      certificate: certificates[index],
                      onTap: () => onCertificateTap?.call(certificates[index]),
                    ),
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

class _CertificateCard extends StatefulWidget {
  const _CertificateCard({required this.certificate, this.onTap});

  final Certificate certificate;
  final VoidCallback? onTap;

  @override
  State<_CertificateCard> createState() => _CertificateCardState();
}

class _CertificateCardState extends State<_CertificateCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _hoverAnimation;
  bool _isPressed = false;
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

    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
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
        onTap: widget.onTap,
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
                    colors: [
                      widget.certificate.typeColor.withValues(alpha: 0.8),
                      widget.certificate.typeColor.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: widget.certificate.typeColor.withValues(
                        alpha: 0.2,
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
                        color: widget.certificate.typeColor.withValues(
                          alpha: 0.3,
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
                    // Image area
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.r),
                          topRight: Radius.circular(12.r),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.certificate.certificateUrl != null)
                              Image.network(
                                widget.certificate.certificateUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        widget.certificate.typeColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        widget.certificate.typeColor.withValues(
                                          alpha: 0.6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      widget.certificate.typeIcon,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 32.sp,
                                    ),
                                  ),
                                ),
                              )
                            else
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      widget.certificate.typeColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      widget.certificate.typeColor.withValues(
                                        alpha: 0.6,
                                      ),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    widget.certificate.typeIcon,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 32.sp,
                                  ),
                                ),
                              ),
                            // Status indicator
                            Positioned(
                              top: 8.h,
                              right: 8.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.certificate.statusColor
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.certificate.status ==
                                              CertificateStatus.approved
                                          ? LucideIcons.checkCircle
                                          : widget.certificate.status ==
                                                CertificateStatus.rejected
                                          ? LucideIcons.xCircle
                                          : LucideIcons.clock,
                                      color: Colors.white,
                                      size: 10.sp,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      widget.certificate.statusDisplayName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Hover shine effect
                            if (_isHovered)
                              Positioned(
                                top: 0.h,
                                left: 0.w,
                                right: 0.w,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 2.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.3),
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
                    // Caption area
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: _isPressed ? 0.6 : 0.4,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12.r),
                          bottomRight: Radius.circular(12.r),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.certificate.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                              height: 1.2.h,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            widget.certificate.typeDisplayName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
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
      ),
    );
  }
}
