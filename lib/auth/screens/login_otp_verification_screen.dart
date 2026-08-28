import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/auth/utils/otp_autofill_helper.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/auth/widgets/auth_gradient_background.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
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
      await OtpAutofillHelper.fetchAppSignature();
      listenForCode(
        smsCodeRegexPattern: OtpAutofillHelper.smsCodeRegexPattern,
      );
    } catch (e) {
      debugPrint('SMS Autofill error: $e');
    }
  }

  Future<void> _restartSmsAutofill() async {
    await OtpAutofillHelper.restartNativeListener(cancel, listenForCode);
  }

  @override
  void codeUpdated() {
    final digits = OtpAutofillHelper.extractDigits(code);
    if (digits == null || digits.length != OtpAutofillHelper.codeLength) {
      return;
    }
    if (!mounted || !_isActive) return;
    if (!_otpController.isSafe) return;

    // TextEditingValue + selection تا PinCodeTextField listener حتماً UI را آپدیت کند
    _otpController.value = TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
    WidgetSafetyUtils.safeSetState(this, () {
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _isActive) {
        _verifyAndLogin();
      }
    });
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
      await _restartSmsAutofill();

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
          backgroundColor: context.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AuthBackButton(onPressed: _handleBack),
          // عنوان تکراری با تیتر بدنه حذف شد — فقط برگشت
          title: const SizedBox.shrink(),
        ),
        body: SafeArea(
          child: AuthOtpBody(
            phoneNumber: widget.phoneNumber,
            otpController: _otpController,
            errorMessage: _errorMessage,
            loading: _isLoading,
            canResend: _canResend,
            remainingTime: _remainingTime,
            verifyLabel: 'تایید و ورود',
            onResend: _resendOTP,
            onVerify: _verifyAndLogin,
            onChanged: (value) {
              if (!mounted || !_otpController.isSafe) return;
              if (_errorMessage != null) {
                WidgetSafetyUtils.safeSetState(this, () {
                  _errorMessage = null;
                });
              }
              if (value.length == 6 && _isActive && !_isLoading) {
                Future.delayed(const Duration(milliseconds: 280), () {
                  if (mounted && _isActive) {
                    _verifyAndLogin();
                  }
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
