import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/responsive_breakpoints.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Standard page scaffold — uses main app theme (transparent over shell gradient).
class GymPageScaffold extends StatelessWidget {
  const GymPageScaffold({
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.useSafeArea = true,
    this.centerContent = true,
    this.padding,
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;
  final bool centerContent;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (padding != null) {
      content = GymPagePadding(padding: padding, child: content);
    }

    if (centerContent) {
      final maxWidth = GymBreakpoints.contentMaxWidth(
        MediaQuery.sizeOf(context).width,
      );
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: content,
        ),
      );
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Directionality(
      textDirection: GymTypography.direction,
      child: Scaffold(
        backgroundColor: context.gymBackground,
        appBar: title == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: context.gymTextPrimary,
                elevation: 0,
                title: Text(
                  title!,
                  style: context.gymTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: actions,
              ),
        body: content,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
