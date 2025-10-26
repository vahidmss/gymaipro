import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserRoleBadge extends StatelessWidget {
  const UserRoleBadge({
    required this.role,
    super.key,
    this.fontSize,
    this.padding,
    this.showIcon = true,
  });
  final String role;
  final double? fontSize;
  final EdgeInsets? padding;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final roleInfo = _getRoleInfo(role);

    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4),
      decoration: BoxDecoration(
        color: roleInfo.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: roleInfo.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              roleInfo.icon,
              color: roleInfo.color,
              size: (fontSize ?? 10) + 2,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            roleInfo.label,
            style: TextStyle(
              color: roleInfo.color,
              fontSize: fontSize ?? 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  RoleInfo _getRoleInfo(String role) {
    switch (role.toLowerCase()) {
      case 'trainer':
        return RoleInfo(
          label: 'مربی',
          color: Colors.purple,
          icon: LucideIcons.userCheck,
        );
      case 'admin':
        return RoleInfo(
          label: 'ادمین',
          color: Colors.red,
          icon: LucideIcons.shield,
        );
      case 'athlete':
      default:
        return RoleInfo(
          label: 'کاربر',
          color: Colors.green,
          icon: LucideIcons.user,
        );
    }
  }
}

class RoleInfo {
  RoleInfo({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;
}
