import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';

class SectionNavList extends StatelessWidget {
  final String title;
  final List<SectionNavItem> items;

  const SectionNavList({Key? key, required this.title, required this.items})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          ...items.map((item) => _NavTile(item: item)).toList(),
        ],
      ),
    );
  }
}

class SectionNavItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  SectionNavItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });
}

class _NavTile extends StatelessWidget {
  final SectionNavItem item;
  const _NavTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (item.color ?? AppTheme.goldColor).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            Icon(item.icon, color: item.color ?? AppTheme.goldColor, size: 20),
      ),
      title: Text(
        item.title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!,
              style: TextStyle(color: Colors.white.withOpacity(0.7)))
          : null,
      trailing: Icon(Icons.chevron_left, color: Colors.white.withOpacity(0.5)),
      onTap: item.onTap,
    );
  }
}
