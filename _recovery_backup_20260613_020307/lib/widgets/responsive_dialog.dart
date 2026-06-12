import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// Helper برای نمایش AlertDialog های رسپانسیو و مینیمال
class ResponsiveDialog {
  /// نمایش یک AlertDialog ساده و رسپانسیو
  static Future<T?> showAlert<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
    Color? accentColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: true, // جلوگیری از conflict با overlay
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final safePadding = mediaQuery.padding;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        // محاسبه insetPadding به صورت responsive (مینیمال‌تر)
        final horizontalInset = screenWidth > 600 
            ? screenWidth * 0.12 // کاهش از 0.15
            : screenWidth * 0.06.clamp(10.0, 20.0); // کاهش از 0.08
        final verticalInset = screenHeight * 0.08.clamp(12.0, 32.0); // کاهش از 0.1
        
        // محاسبه maxWidth به صورت responsive
        final maxWidth = screenWidth > 600 
            ? screenWidth * 0.7.clamp(400.0, 600.0)
            : screenWidth * 0.9.clamp(280.0, 400.0);
        
        final effectiveAccentColor = accentColor ?? AppTheme.goldColor;
        final cornerRadius = screenWidth * 0.045.clamp(14.0, 22.0); // کاهش از 0.05
        final padding = screenWidth * 0.035.clamp(10.0, 16.0); // کاهش از 0.04
        final titleSize = screenWidth * 0.045.clamp(16.0, 18.0);
        final contentSize = screenWidth * 0.038.clamp(13.0, 15.0);
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            top: safePadding.top + verticalInset,
            bottom: safePadding.bottom + verticalInset,
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardColor : Colors.white,
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(
                color: effectiveAccentColor.withValues(alpha: 0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                  blurRadius: screenWidth * 0.04.clamp(16.0, 24.0),
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        effectiveAccentColor.withValues(alpha: 0.12),
                        effectiveAccentColor.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(cornerRadius),
                      topRight: Radius.circular(cornerRadius),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.lightTextColor,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: contentSize,
                      height: 1.5,
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.lightTextSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.justify,
                  ),
                ),
                
                // Actions
                if (confirmText != null || cancelText != null)
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      padding * 0.9, // کاهش از 1.0
                      padding * 0.4, // کاهش از 0.5
                      padding * 0.9, // کاهش از 1.0
                      padding * 0.85, // کاهش از 1.0
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (cancelText != null)
                          TextButton(
                            onPressed: onCancel ?? () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding * 1.2,
                                vertical: padding * 0.6,
                              ),
                            ),
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                fontSize: contentSize,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppTheme.lightTextSecondary,
                                fontFamily: AppTheme.fontFamily,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        if (cancelText != null && confirmText != null)
                          SizedBox(width: padding * 0.5),
                        if (confirmText != null)
                          ElevatedButton(
                            onPressed: onConfirm ?? () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: effectiveAccentColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: padding * 1.2,
                                vertical: padding * 0.6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(cornerRadius * 0.5),
                              ),
                              elevation: 1,
                            ),
                            child: Text(
                              confirmText,
                              style: TextStyle(
                                fontSize: contentSize,
                                fontWeight: FontWeight.w600,
                                fontFamily: AppTheme.fontFamily,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

