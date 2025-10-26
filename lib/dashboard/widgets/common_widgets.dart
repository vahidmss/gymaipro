import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// یک تیتر بخش ساده و قابل استفاده در کل داشبورد
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    super.key,
    this.style,
    this.padding,
  });
  final String title;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(),
      child: Text(
        title,
        style:
            style ??
            TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// نسخه عمومی QuickActionsSection (بدون وابستگی به workout)
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    required this.actions,
    super.key,
    this.title,
    this.padding,
  });
  final List<Widget> actions;
  final String? title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            SectionTitle(title: title!),
            const SizedBox(height: 12),
          ],
          Wrap(spacing: 12, runSpacing: 12, children: actions),
        ],
      ),
    );
  }
}
