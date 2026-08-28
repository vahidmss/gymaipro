import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// پس‌زمینهٔ تخت و سبک برای صفحات احراز هویت — بدون گرادیان چندلایه و radial.
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: context.backgroundColor);
  }
}

/// لوگو بدون glow (blur بزرگ = لگ روی دستگاه‌های ضعیف).
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 120.h;
    return Image.asset(
      'images/GYMAI_logo_transparent.png',
      height: s,
      width: s,
      fit: BoxFit.contain,
      cacheWidth: (s * MediaQuery.devicePixelRatioOf(context)).round(),
      cacheHeight: (s * MediaQuery.devicePixelRatioOf(context)).round(),
    );
  }
}

/// کارت فرم تمیز — بوردر نرم، بدون گلو طلایی.
class AuthCard extends StatelessWidget {
  const AuthCard({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.separatorColor),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(22.w),
        child: child,
      ),
    );
  }
}

/// دکمهٔ طلایی تخت — بدون گرادیان و بدون BoxShadow سنگین.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.goldColor,
          disabledBackgroundColor: AppTheme.goldColor.withValues(alpha: 0.45),
          foregroundColor: AppTheme.onGoldColor,
          disabledForegroundColor: AppTheme.onGoldColor.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.onGoldColor,
                  ),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

InputDecoration authFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
}) {
  final radius = BorderRadius.circular(14.r);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(
      color: context.textSecondary,
      fontSize: 13.sp,
      fontFamily: AppTheme.fontFamily,
    ),
    hintStyle: TextStyle(
      color: context.textSecondary.withValues(alpha: 0.65),
      fontSize: 13.sp,
      fontFamily: AppTheme.fontFamily,
    ),
    prefixIcon: icon == null
        ? null
        : Icon(icon, color: AppTheme.goldColor, size: 20.sp),
    filled: true,
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? context.surfaceElevated
        : context.backgroundColor.withValues(alpha: 0.7),
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: context.separatorColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.goldColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
    ),
  );
}

/// دکمهٔ بازگشت سبک برای صفحات OTP.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'بازگشت',
      onPressed: onPressed,
      icon: Icon(LucideIcons.arrowRight, color: context.textColor, size: 22.sp),
    );
  }
}

String formatAuthPhoneDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  var normalized = digits;
  if (normalized.startsWith('98') && normalized.length >= 12) {
    normalized = '0${normalized.substring(2)}';
  } else if (normalized.length == 10) {
    normalized = '0$normalized';
  }
  if (normalized.length != 11) return raw;
  final spaced =
      '${normalized.substring(0, 4)} ${normalized.substring(4, 7)} ${normalized.substring(7)}';
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  final buf = StringBuffer();
  for (final c in spaced.split('')) {
    final i = en.indexOf(c);
    buf.write(i >= 0 ? fa[i] : c);
  }
  return buf.toString();
}

/// بدنهٔ مشترک صفحهٔ OTP — تمیز، سبک، بدون نوار سفید و بدون دکمهٔ برگشت تکراری.
class AuthOtpBody extends StatelessWidget {
  const AuthOtpBody({
    required this.phoneNumber,
    required this.otpController,
    required this.onChanged,
    required this.onVerify,
    required this.verifyLabel,
    required this.loading,
    required this.canResend,
    required this.remainingTime,
    required this.onResend,
    super.key,
    this.errorMessage,
    this.enabled = true,
  });

  final String phoneNumber;
  final TextEditingController otpController;
  final ValueChanged<String> onChanged;
  final VoidCallback onVerify;
  final String verifyLabel;
  final bool loading;
  final bool canResend;
  final int remainingTime;
  final VoidCallback onResend;
  final String? errorMessage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 16.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!keyboardOpen) ...[
                  SizedBox(height: 12.h),
                  Center(
                    child: Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.shieldCheck,
                        size: 28.sp,
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 22.h),
                ],
                Text(
                  'کد تایید را وارد کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: context.textColor,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 10.h),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 13.5.sp,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'کد ۶ رقمی به '),
                      TextSpan(
                        text: formatAuthPhoneDisplay(phoneNumber),
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' ارسال شد'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: keyboardOpen ? 22.h : 32.h),
                AuthCard(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 18.h,
                  ),
                  child: AutofillGroup(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        enabled: enabled && !loading,
                        autoFocus: true,
                        // مهم: وگرنه PinCodeTextField کنترلر والد را dispose می‌کند
                        // و autofill/SMS دیگر به کادرها نمی‌نشیند.
                        autoDisposeControllers: false,
                        enablePinAutofill: true,
                        cursorColor: AppTheme.goldColor,
                        enableActiveFill: true,
                        textStyle: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: context.textColor,
                          height: 1,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12.r),
                          fieldHeight: 54.h,
                          fieldWidth: 44.w,
                          borderWidth: 1.2,
                          activeFillColor: context.surfaceElevated,
                          selectedFillColor: AppTheme.goldColor.withValues(
                            alpha: 0.1,
                          ),
                          inactiveFillColor: context.surfaceElevated,
                          activeColor: AppTheme.goldColor,
                          selectedColor: AppTheme.goldColor,
                          inactiveColor: context.separatorColor,
                          disabledColor: context.separatorColor,
                          errorBorderColor: AppTheme.errorColor,
                        ),
                        animationDuration: const Duration(milliseconds: 140),
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        onChanged: onChanged,
                        beforeTextPaste: (text) {
                          final digits = text?.replaceAll(RegExp(r'\D'), '');
                          return digits != null && digits.length == 6;
                        },
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: errorMessage == null
                      ? SizedBox(height: 18.h)
                      : Padding(
                          padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.circleAlert,
                                size: 16.sp,
                                color: AppTheme.errorColor,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    color: AppTheme.errorColor,
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                SizedBox(height: 10.h),
                AuthPrimaryButton(
                  label: verifyLabel,
                  loading: loading,
                  onPressed: onVerify,
                ),
                SizedBox(height: 14.h),
                Center(
                  child: canResend
                      ? TextButton(
                          onPressed: loading ? null : onResend,
                          child: Text(
                            'ارسال مجدد کد',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: AppTheme.goldColor,
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: context.separatorColor),
                          ),
                          child: Text(
                            'ارسال مجدد تا $_remainingFa ثانیه',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: context.textSecondary,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
                SizedBox(height: keyboardOpen ? 8.h : 24.h),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _remainingFa {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    return remainingTime
        .toString()
        .split('')
        .map((c) {
          final i = en.indexOf(c);
          return i >= 0 ? fa[i] : c;
        })
        .join();
  }
}
