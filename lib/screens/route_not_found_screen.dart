import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shown for unknown routes or when required navigation arguments are missing.
/// Never returns an empty widget — user always sees a message and a way back.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({
    this.title = 'صفحه پیدا نشد',
    this.message = 'این مسیر در دسترس نیست. به صفحه قبل برگردید.',
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.darkBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: canPop
              ? IconButton(
                  icon: const Icon(LucideIcons.arrowRight),
                  color: Colors.white.withValues(alpha: 0.9),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.goldColor.withValues(alpha: 0.06),
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.circleAlert,
                      size: 32,
                      color: AppTheme.goldColor.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (canPop) {
                          Navigator.of(context).pop();
                        } else {
                          unawaited(
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/main',
                              (route) => false,
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: AppTheme.onGoldColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        canPop ? 'بازگشت' : 'رفتن به خانه',
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
