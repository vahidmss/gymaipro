import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/auth/utils/otp_autofill_helper.dart';
import 'package:gymaipro/auth/screens/profile_completion_screen.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/auth/widgets/auth_gradient_background.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:sms_autofill/sms_autofill.dart' as sms;

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({
    required this.phoneNumber,
    required this.username,
    super.key,
  });
  final String phoneNumber;
  final String username;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with sms.CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isActive = true;
  bool _isDisposed = false;
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
      debugPrint('⚠️ SMS Autofill initialization error: $e');
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
    if (!mounted || !_isActive || _isDisposed) return;
    if (!_otpController.isSafe) return;

    _otpController.value = TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
    WidgetSafetyUtils.safeSetState(this, () {
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _isActive && !_isDisposed) {
        _verifyAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isActive = false;
    _cancelTimer();

    // TextEditingController را dispose نمی‌کنیم چون PinCodeTextField ممکن است
    // هنوز در حال استفاده از آن باشد و این باعث خطا می‌شود
    // آن توسط garbage collector پاک می‌شود

    // متوقف کردن گوش دادن به SMS
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
    if (!_isActive || !mounted || _isLoading || !_canResend || _isDisposed) {
      return;
    }

    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // پاک کردن کد قبلی
      if (_otpController.isSafe) {
        _otpController.safeClear();
      }

      await OTPService.sendOTP(widget.phoneNumber);
      await _restartSmsAutofill();

      if (!_isActive || !mounted || _isDisposed) return;

      _startResendTimer();

      if (mounted && !_isDisposed) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'کد جدید ارسال شد',
        );
      }
    } catch (e) {
      if (!_isActive || !mounted || _isDisposed) return;
      _showError('خطا در ارسال مجدد کد');
    } finally {
      if (_isActive && mounted && !_isDisposed) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndNavigate() async {
    if (!_isActive || !mounted || _isLoading || _isDisposed) return;

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
      if (!_isActive || !mounted || _isDisposed) return;
      if (!isValid) {
        _showError('کد وارد شده صحیح نیست');
        return;
      }

      // فقط تایید OTP - ثبت‌نام در صفحه تکمیل پروفایل انجام می‌شود
      debugPrint('=== OTP VERIFICATION: OTP verified successfully ===');
      debugPrint('=== OTP VERIFICATION: normalizedPhone=$normalizedPhone ===');
      debugPrint('=== OTP VERIFICATION: username=${widget.username} ===');

      // ابتدا انیمیشن‌ها و تایمرها را متوقف می‌کنیم
      _isActive = false;
      _isDisposed = true;
      _cancelTimer();

      if (mounted) {
        // ابتدا PinCodeTextField را از درخت UI حذف می‌کنیم
        WidgetSafetyUtils.safeSetState(this, () {});

        // صبر می‌کنیم تا UI به‌روزرسانی شود
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // هدایت به صفحه تکمیل پروفایل با اطلاعات phoneNumber و username
            try {
              WidgetSafetyUtils.safeNavigateReplacement(
                context,
                () => ProfileCompletionScreen(
                  phoneNumber: normalizedPhone,
                  username: widget.username,
                ),
              );
            } catch (e) {
              debugPrint('Error in OTP navigation: $e');
            }
          }
        });
      }
    } catch (e) {
      if (!_isActive || !mounted || _isDisposed) return;
      _showError('خطا در فرآیند تایید یا ایجاد پروفایل: $e');
      if (mounted && !_isDisposed) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در فرآیند تایید: $e',
        );
      }
    } finally {
      if (_isActive && mounted && !_isDisposed) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!_isActive || !mounted || _isDisposed) return;
    WidgetSafetyUtils.safeSetState(this, () {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive || _isDisposed || !_otpController.isSafe) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AuthBackButton(
          onPressed: () => WidgetSafetyUtils.safePop(context),
        ),
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
          verifyLabel: 'تایید و ادامه',
          enabled: !_isDisposed,
          onResend: _resendOTP,
          onVerify: _verifyAndNavigate,
          onChanged: (value) {
            if (_isDisposed || !mounted || !_otpController.isSafe) return;
            if (_errorMessage != null) {
              WidgetSafetyUtils.safeSetState(this, () {
                _errorMessage = null;
              });
            }
            if (value.length == 6 &&
                _isActive &&
                !_isLoading &&
                !_isDisposed) {
              Future.delayed(const Duration(milliseconds: 280), () {
                if (mounted && _isActive && !_isDisposed) {
                  _verifyAndNavigate();
                }
              });
            }
          },
        ),
      ),
    );
  }
}
