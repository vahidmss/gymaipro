import 'package:flutter/material.dart';

/// یک تیتر بخش ساده و قابل استفاده در کل داشبورد
class SectionTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;

  const SectionTitle({
    Key? key,
    required this.title,
    this.style,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 0),
      child: Text(
        title,
        style: style ??
            const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// نسخه عمومی QuickActionsSection (بدون وابستگی به workout)
class QuickActionsSection extends StatelessWidget {
  final List<Widget> actions;
  final String? title;
  final EdgeInsetsGeometry? padding;

  const QuickActionsSection({
    Key? key,
    required this.actions,
    this.title,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            SectionTitle(title: title!),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions,
          ),
        ],
      ),
    );
  }
}
