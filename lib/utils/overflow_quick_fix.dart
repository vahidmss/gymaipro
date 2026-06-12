/// Quick reference for fixing overflow issues
///
/// این فایل شامل توابع helper برای رفع سریع overflow است
///
/// مثال استفاده:
/// ```dart
/// import 'package:gymaipro/utils/overflow_quick_fix.dart';
///
/// // در Row
/// Row(
///   children: [
///     safeText('متن طولانی'),
///     Icon(Icons.star),
///   ],
/// )
/// ```
library;

import 'package:flutter/material.dart';

/// Wrap text in Flexible to prevent overflow in Row
Widget safeText(
  String text, {
  TextStyle? style,
  int? maxLines = 1,
  TextOverflow overflow = TextOverflow.ellipsis,
  TextAlign? textAlign,
}) {
  return Flexible(
    child: Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    ),
  );
}

/// Wrap text in Expanded to prevent overflow in Row
Widget expandedText(
  String text, {
  TextStyle? style,
  int? maxLines = 1,
  TextOverflow overflow = TextOverflow.ellipsis,
  TextAlign? textAlign,
}) {
  return Expanded(
    child: Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    ),
  );
}

/// Create a safe Row with text that won't overflow
Widget safeRow({
  required List<Widget> children,
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  TextDirection? textDirection,
}) {
  return Row(
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    children: children.map((child) {
      // Don't wrap Expanded, Flexible, SizedBox, Spacer
      if (child is Expanded ||
          child is Flexible ||
          child is SizedBox ||
          child is Spacer) {
        return child;
      }
      // Wrap Text in Flexible
      if (child is Text) {
        return Flexible(
          child: Text(
            child.data ?? '',
            style: child.style,
            maxLines: child.maxLines ?? 1,
            overflow: child.overflow ?? TextOverflow.ellipsis,
          ),
        );
      }
      return child;
    }).toList(),
  );
}

/// Create a scrollable Column
Widget scrollableColumn({
  required List<Widget> children,
  EdgeInsetsGeometry? padding,
  ScrollController? controller,
}) {
  return SingleChildScrollView(
    controller: controller,
    padding: padding,
    child: Column(children: children),
  );
}

/// Extension for easy overflow-safe text in Row
extension SafeTextExtension on String {
  Widget toSafeText({
    TextStyle? style,
    int? maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Flexible(
      child: Text(this, style: style, maxLines: maxLines, overflow: overflow),
    );
  }
}
