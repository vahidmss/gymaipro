import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/notification/providers/notification_provider.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/notification_icon.dart';
import 'package:provider/provider.dart';

/// اپ‌بار Home — برند GymAI + نوتیف.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  static const _logoLight = 'images/logoforlightmode.png';
  static const _logoDark = 'images/logofordarkmode.png';

  @override
  Size get preferredSize => Size.fromHeight(48.h);

  @override
  Widget build(BuildContext context) {
    final logoAsset = context.isDark ? _logoDark : _logoLight;

    return AppBar(
      backgroundColor: context.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 48.h,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsetsDirectional.only(start: 16.w),
        child: Image.asset(
          logoAsset,
          height: 26.h,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          alignment: AlignmentDirectional.centerStart,
        ),
      ),
      actions: [
        NotificationIcon(
          onTap: () async {
            await Navigator.pushNamed(context, '/notifications');
            if (context.mounted) {
              unawaited(
                context.read<NotificationProvider>().refreshUnreadCount(),
              );
            }
          },
        ),
        SizedBox(width: 12.w),
      ],
    );
  }
}
