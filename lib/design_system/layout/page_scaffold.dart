import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_back_button.dart';
import 'package:gymaipro/design_system/layout/page_padding.dart';
import 'package:gymaipro/design_system/layout/responsive_breakpoints.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

/// Standard page scaffold — uses main app theme solid page background.
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
    this.resizeToAvoidBottomInset = true,
    this.onBack,
    this.showBack,
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
  final bool resizeToAvoidBottomInset;

  /// Custom back handler (e.g. layered dismiss before pop).
  /// When set, an in-app back button is always shown.
  final VoidCallback? onBack;

  /// Force show/hide the in-app back button.
  /// Default: show when [onBack] is set or the route can pop.
  final bool? showBack;

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

    final wantsBack =
        showBack ?? (onBack != null || GymBackButton.shouldShow(context));

    return Directionality(
      textDirection: GymTypography.direction,
      child: Scaffold(
        backgroundColor: context.gymBackground,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: title == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: context.gymTextPrimary,
                elevation: 0,
                // Explicit leading — Safari system-back is unreliable on web.
                automaticallyImplyLeading: false,
                leading: wantsBack
                    ? GymBackButton(
                        onPressed: onBack,
                        color: context.gymTextPrimary,
                      )
                    : null,
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
