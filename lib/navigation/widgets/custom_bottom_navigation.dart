import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/services/chat_unread_notifier.dart';
import 'package:gymaipro/navigation/constants/navigation_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Bottom bar: home | my club/desk | [+] | messages | more
///
/// Hit targets fill each slot (opaque). Unread badge sits on Messages.
class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    required this.onPlusTap,
    this.navKeys,
    this.userRole,
    super.key,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onPlusTap;
  final Map<int, GlobalKey>? navKeys;
  final String? userRole;

  bool get _isTrainer => userRole == 'trainer';

  static double get _barHeight => NavigationConstants.bottomNavHeight.h.clamp(
        72.0,
        104.0,
      );

  static double get _plusSize => 56.w.clamp(48.0, 60.0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.backgroundColor,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          border: Border(
            top: BorderSide(color: context.separatorColor),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _barHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = (_plusSize * 0.95).clamp(48.0, 64.0);
                final plusLeft = (constraints.maxWidth - _plusSize) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _NavSlot(
                            key: navKeys?[NavigationConstants.homeIndex],
                            icon: NavigationConstants.homeIcon,
                            label: NavigationConstants.homeLabel,
                            selected:
                                currentIndex == NavigationConstants.homeIndex,
                            onTap: () => onTap(NavigationConstants.homeIndex),
                          ),
                        ),
                        Expanded(
                          child: _NavSlot(
                            key: navKeys?[NavigationConstants.hubIndex],
                            icon: _isTrainer
                                ? NavigationConstants.deskIcon
                                : NavigationConstants.myClubIcon,
                            label: _isTrainer
                                ? NavigationConstants.deskLabel
                                : NavigationConstants.myClubLabel,
                            selected:
                                currentIndex == NavigationConstants.hubIndex,
                            onTap: () => onTap(NavigationConstants.hubIndex),
                          ),
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: _NavSlot(
                            key: navKeys?[NavigationConstants.roleTabIndex],
                            icon: NavigationConstants.messagesIcon,
                            label: NavigationConstants.messagesLabel,
                            selected: currentIndex ==
                                NavigationConstants.roleTabIndex,
                            onTap: () =>
                                onTap(NavigationConstants.roleTabIndex),
                            showUnreadBadge: true,
                          ),
                        ),
                        Expanded(
                          child: _NavSlot(
                            key: navKeys?[NavigationConstants.moreIndex],
                            icon: NavigationConstants.moreIcon,
                            label: NavigationConstants.moreLabel,
                            selected:
                                currentIndex == NavigationConstants.moreIndex,
                            onTap: () => onTap(NavigationConstants.moreIndex),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -10.h,
                      left: plusLeft,
                      width: _plusSize,
                      child: _PlusButton(onTap: onPlusTap, size: _plusSize),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: context.actionFill,
              shape: BoxShape.circle,
              border: Border.all(color: context.actionFill, width: 2.w),
              boxShadow: [
                BoxShadow(
                  color: context.actionFill.withValues(alpha: 0.35),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.plus,
              size: 26.sp,
              color: context.actionOnFill,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            NavigationConstants.plusLabel,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: NavigationConstants.navItemFontSize.sp,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showUnreadBadge = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showUnreadBadge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.inkAccent : context.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Full slot is tappable — not just the icon pixels.
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: NavigationConstants.navItemIconSize.sp.clamp(
                      20.0,
                      24.0,
                    ),
                  ),
                  if (showUnreadBadge)
                    const Positioned(
                      right: -10,
                      top: -8,
                      child: _UnreadBadge(),
                    ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: NavigationConstants.navItemFontSize.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: AppTheme.fontFamily,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatUnreadNotifier>(
      builder: (context, notifier, _) {
        final count = notifier.unreadCount;
        if (count <= 0) return const SizedBox.shrink();

        final label = count > 99 ? '99+' : count.toString();
        return Container(
          constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
          padding: EdgeInsets.symmetric(
            horizontal: count > 9 ? 5.w : 0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE53E3E),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: context.backgroundColor,
              width: 1.5.w,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
