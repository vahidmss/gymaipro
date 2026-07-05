import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sms_autofill/sms_autofill.dart' as sms;

class LoginOTPVerificationScreen extends StatefulWidget {
  const LoginOTPVerificationScreen({required this.phoneNumber, super.key});
  final String phoneNumber;

  @override
  State<LoginOTPVerificationScreen> createState() =>
      _LoginOTPVerificationScreenState();
}

class _LoginOTPVerificationScreenState extends State<LoginOTPVerificationScreen>
    with sms.CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isActive = true;
  Timer? _resendTimer;
  int _remainingTime = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _initSmsAutofill();
  }

  Future<void> _initSmsAutofill() async {
    try {
      final signature = await sms.SmsAutoFill().getAppSignature;
      if (mounted) {
        debugPrint('📱 Login OTP app signature: $signature');
      }
      listenForCode();
    } catch (e) {
      debugPrint('SMS Autofill error: $e');
    }
  }

  @override
  void codeUpdated() {
    final digits = _extractOtpDigits(code);
    if (digits == null || digits.length != 6) return;
    if (!mounted || !_isActive) return;
    if (!_otpController.isSafe) return;

    _otpController.safeSetText(digits);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isActive) {
        _verifyAndLogin();
      }
    });
  }

  String? _extractOtpDigits(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'\d{6}').firstMatch(raw);
    if (match != null) return match.group(0);
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 6 ? digitsOnly.substring(0, 6) : null;
  }

  @override
  void dispose() {
    _isActive = false;
    _cancelTimer();
    try {
      sms.SmsAutoFill().unregisterListener();
      cancel();
    } catch (e) {
      debugPrint('Error unregistering SMS listener: $e');
    }
    super.dispose();
  }

  void _cancelTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }

  void _startResendTimer() {
    if (!_isActive) return;

    _remainingTime = 60;
    _canResend = false;

    SafeSetState.call(this, () {});

    _cancelTimer();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive || !mounted) {
        timer.cancel();
        return;
      }

      WidgetSafetyUtils.safeSetState(this, () {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOTP() async {
    if (!_isActive || !mounted || _isLoading || !_canResend) return;

    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_otpController.isSafe) {
        _otpController.safeClear();
      }

      await OTPService.sendOTP(widget.phoneNumber);

      if (!_isActive || !mounted) return;

      _startResendTimer();
      WidgetSafetyUtils.safeShowSnackBar(context, 'کد جدید ارسال شد');
    } catch (e) {
      if (!_isActive || !mounted) return;
      _showError('خطا در ارسال مجدد کد');
    } finally {
      if (_isActive && mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndLogin() async {
    if (!_isActive || !mounted || _isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_otpController.isSafe) return;
    final otpCode = _otpController.safeText.trim();
    if (otpCode.isEmpty) {
      _showError('لطفاً کد تایید را وارد کنید');
      return;
    }
    if (otpCode.length != 6) {
      _showError('کد تایید باید ۶ رقم باشد');
      return;
    }

    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService = SupabaseService();
      final normalizedPhone = supabaseService.normalizePhoneNumber(
        widget.phoneNumber,
      );
      final isValid = await OTPService.verifyOTP(normalizedPhone, otpCode);
      if (!_isActive || !mounted) return;
      if (!isValid) {
        _showError('کد وارد شده صحیح نیست');
        return;
      }

      final session = await supabaseService.signInWithPhone(normalizedPhone);
      if (!_isActive || !mounted) return;

      if (session != null) {
        try {
          await AuthStateService().saveAuthState(
            session,
            phoneNumber: normalizedPhone,
          );
        } catch (e) {
          debugPrint('Error saving session: $e');
        }

        _isActive = false;
        _cancelTimer();

        if (mounted) {
          WidgetSafetyUtils.safeShowSnackBar(
            context,
            'ورود با موفقیت انجام شد',
          );
          enterMainAppAfterAuth(context);
        }
      } else {
        if (!_isActive || !mounted) return;
        _showError('خطا در ورود کاربر');
      }
    } catch (e) {
      if (!_isActive || !mounted) return;
      _showError('خطا در فرآیند تایید یا ورود: $e');
    } finally {
      if (_isActive && mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!_isActive || !mounted) return;
    WidgetSafetyUtils.safeSetState(this, () {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _handleBack() {
    // فقط اگر در حال loading است، اجازه بازگشت نده
    if (_isLoading) return;

    _cancelTimer();

    // استفاده از WidgetSafetyUtils برای navigation امن
    WidgetSafetyUtils.safePushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive || !_otpController.isSafe) {
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isLoading) {
          _handleBack();
        } else if (didPop) {
          _cancelTimer();
        }
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.cardColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.goldColor,
                size: 18.sp,
              ),
            ),
            onPressed: _handleBack,
          ),
          title: Text(
            'تایید کد',
            style: TextStyle(
              fontSize: ResponsiveValue(
                context,
                defaultValue: 20.sp,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 18.sp),
                  Condition.largerThan(name: TABLET, value: 22.sp),
                ],
              ).value,
              color: context.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20.h),
                Text(
                  'کد تایید را وارد کنید',
                  style: TextStyle(
                    fontSize: ResponsiveValue(
                      context,
                      defaultValue: 24.sp,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 22.sp),
                        Condition.largerThan(name: TABLET, value: 26.sp),
                      ],
                    ).value,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'کد به شماره ${widget.phoneNumber} ارسال شد',
                  style: TextStyle(
                    fontSize: ResponsiveValue(
                      context,
                      defaultValue: 15.sp,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 14.sp),
                        Condition.largerThan(name: TABLET, value: 16.sp),
                      ],
                    ).value,
                    color: context.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: !_otpController.isSafe
                      ? const SizedBox.shrink()
                      : PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          enabled: !_isLoading,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12.r),
                            fieldHeight: ResponsiveValue(
                              context,
                              defaultValue: 55.h,
                              conditionalValues: [
                                Condition.smallerThan(
                                  name: MOBILE,
                                  value: 50.h,
                                ),
                                Condition.largerThan(name: TABLET, value: 60.h),
                              ],
                            ).value,
                            fieldWidth: ResponsiveValue(
                              context,
                              defaultValue: 45.w,
                              conditionalValues: [
                                Condition.smallerThan(
                                  name: MOBILE,
                                  value: 40.w,
                                ),
                                Condition.largerThan(name: TABLET, value: 50.w),
                              ],
                            ).value,
                            activeFillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? context.cardColor
                                : Colors.white.withValues(alpha: 0.95),
                            selectedFillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.goldColor.withValues(alpha: 0.2)
                                : AppTheme.goldColor.withValues(alpha: 0.1),
                            inactiveFillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? context.cardColor.withValues(alpha: 0.5)
                                : Colors.grey.shade50,
                            activeColor: AppTheme.goldColor,
                            selectedColor: AppTheme.goldColor,
                            inactiveColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.goldColor.withValues(alpha: 0.3)
                                : Colors.grey.shade400,
                            borderWidth: 2,
                          ),
                          enableActiveFill: true,
                          textStyle: TextStyle(
                            fontSize: ResponsiveValue(
                              context,
                              defaultValue: 20.sp,
                              conditionalValues: [
                                Condition.smallerThan(
                                  name: MOBILE,
                                  value: 18.sp,
                                ),
                                Condition.largerThan(
                                  name: TABLET,
                                  value: 22.sp,
                                ),
                              ],
                            ).value,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                          ),
                          onChanged: (value) {
                            if (!mounted || !_otpController.isSafe) return;

                            if (_errorMessage != null) {
                              WidgetSafetyUtils.safeSetState(this, () {
                                _errorMessage = null;
                              });
                            }
                            if (value.length == 6 && _isActive && !_isLoading) {
                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () {
                                  if (mounted && _isActive) {
                                    _verifyAndLogin();
                                  }
                                },
                              );
                            }
                          },
                          beforeTextPaste: (text) =>
                              text?.length == 6 &&
                              text!.contains(RegExp(r'^\d+$')),
                          animationDuration: const Duration(milliseconds: 200),
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: ResponsiveValue(
                                context,
                                defaultValue: 14.sp,
                                conditionalValues: [
                                  Condition.smallerThan(
                                    name: MOBILE,
                                    value: 13.sp,
                                  ),
                                  Condition.largerThan(
                                    name: TABLET,
                                    value: 15.sp,
                                  ),
                                ],
                              ).value,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 40.h),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.goldColor, AppTheme.darkGold],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.4),
                        blurRadius: 20.r,
                        offset: Offset(0, 8.h),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndLogin,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'تایید و ورود',
                            style: TextStyle(
                              fontSize: ResponsiveValue(
                                context,
                                defaultValue: 17.sp,
                                conditionalValues: [
                                  Condition.smallerThan(
                                    name: MOBILE,
                                    value: 16.sp,
                                  ),
                                  Condition.largerThan(
                                    name: TABLET,
                                    value: 18.sp,
                                  ),
                                ],
                              ).value,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: (_canResend && !_isLoading)
                          ? _resendOTP
                          : null,
                      child: Text(
                        _canResend
                            ? 'ارسال مجدد کد'
                            : 'ارسال مجدد کد (${_remainingTime}s)',
                        style: TextStyle(
                          color: (_canResend && !_isLoading)
                              ? AppTheme.goldColor
                              : context.textSecondary,
                          fontSize: ResponsiveValue(
                            context,
                            defaultValue: 14.sp,
                            conditionalValues: [
                              Condition.smallerThan(name: MOBILE, value: 12.sp),
                              Condition.largerThan(name: TABLET, value: 16.sp),
                            ],
                          ).value,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _handleBack,
                      child: Text(
                        'بازگشت',
                        style: TextStyle(
                          fontSize: ResponsiveValue(
                            context,
                            defaultValue: 14.sp,
                            conditionalValues: [
                              Condition.smallerThan(name: MOBILE, value: 12.sp),
                              Condition.largerThan(name: TABLET, value: 16.sp),
                            ],
                          ).value,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
