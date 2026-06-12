import 'package:flutter/material.dart';

/// Utility widgets and helpers to prevent overflow issues across all devices
/// These widgets automatically handle overflow scenarios gracefully

/// A safe Row widget that prevents horizontal overflow
/// Automatically wraps children in Flexible/Expanded when needed
class SafeRow extends StatelessWidget {
  const SafeRow({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.children = const <Widget>[],
    this.wrapChildren = true, // Auto-wrap children in Flexible
  });

  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Widget> children;
  final bool wrapChildren;

  @override
  Widget build(BuildContext context) {
    if (!wrapChildren) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        textBaseline: textBaseline,
        children: children,
      );
    }

    // Auto-wrap children to prevent overflow
    final safeChildren = children.map((child) {
      // Don't wrap Expanded, Flexible, or SizedBox widgets
      if (child is Expanded ||
          child is Flexible ||
          child is SizedBox ||
          child is Spacer) {
        return child;
      }
      // Wrap Text widgets in Flexible
      if (child is Text) {
        return Flexible(child: child);
      }
      // Wrap other widgets in Flexible
      return Flexible(child: child);
    }).toList();

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: safeChildren,
    );
  }
}

/// A safe Column widget that prevents vertical overflow
/// Automatically makes content scrollable when needed
class SafeColumn extends StatelessWidget {
  const SafeColumn({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.children = const <Widget>[],
    this.scrollable = false,
    this.scrollController,
  });

  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Widget> children;
  final bool scrollable;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: children,
    );

    if (scrollable) {
      return SingleChildScrollView(controller: scrollController, child: column);
    }

    return column;
  }
}

/// A safe Text widget that automatically handles overflow
class SafeText extends StatelessWidget {
  const SafeText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow = TextOverflow.ellipsis,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.strutStyle,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  final StrutStyle? strutStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap ?? true,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines ?? 1,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
      strutStyle: strutStyle,
    );
  }
}

/// A widget that wraps content and prevents overflow
/// Automatically makes content scrollable if it exceeds available space
class OverflowSafe extends StatelessWidget {
  const OverflowSafe({
    required this.child, super.key,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.scrollController,
  });

  final Widget child;
  final Axis scrollDirection;
  final bool reverse;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: scrollDirection,
          reverse: reverse,
          controller: scrollController,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension methods for safe widget building
extension SafeWidgetExtensions on BuildContext {
  /// Get safe width that accounts for padding
  double get safeWidth {
    final mediaQuery = MediaQuery.of(this);
    return mediaQuery.size.width - mediaQuery.padding.horizontal;
  }

  /// Get safe height that accounts for padding
  double get safeHeight {
    final mediaQuery = MediaQuery.of(this);
    return mediaQuery.size.height - mediaQuery.padding.vertical;
  }

  /// Check if current screen is small
  bool get isSmallScreen {
    return MediaQuery.of(this).size.width < 360;
  }

  /// Check if current screen is large
  bool get isLargeScreen {
    return MediaQuery.of(this).size.width > 600;
  }
}

/// Helper function to wrap text in Flexible to prevent overflow
Widget flexibleText(
  String text, {
  TextStyle? style,
  int? maxLines,
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

/// Helper function to wrap widget in Expanded to prevent overflow
Widget expandedWidget(Widget child) {
  return Expanded(child: child);
}

/// Helper function to create a safe Row with text that won't overflow
Widget safeRowWithText({
  required List<String> texts,
  List<Widget>? otherWidgets,
  TextStyle? textStyle,
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  TextDirection? textDirection,
}) {
  final children = <Widget>[];

  // Add text widgets wrapped in Flexible
  for (final text in texts) {
    children.add(
      Flexible(
        child: Text(
          text,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  // Add other widgets
  if (otherWidgets != null) {
    children.addAll(otherWidgets);
  }

  return Row(
    mainAxisAlignment: mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    children: children,
  );
}
