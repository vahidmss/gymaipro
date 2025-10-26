import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class SectionNavList extends StatelessWidget {
  const SectionNavList({required this.title, required this.items, super.key});
  final String title;
  final List<SectionNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          Divider(height: 1.h, color: Colors.white24),
          ...items.map((item) => _NavTile(item: item)),
        ],
      ),
    );
  }
}

class SectionNavItem {
  SectionNavItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.color,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item});
  final SectionNavItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: (item.color ?? AppTheme.goldColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          item.icon,
          color: item.color ?? AppTheme.goldColor,
          size: 20.sp,
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
            )
          : null,
      trailing: Icon(
        Icons.chevron_left,
        color: Colors.white.withValues(alpha: 0.1),
      ),
      onTap: item.onTap,
    );
  }
}
