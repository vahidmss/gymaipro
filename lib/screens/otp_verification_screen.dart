import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/screens/profile_completion_screen.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/debug/database_debug_service.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:responsive_framework/responsive_framework.dart';
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
  String? _appSignature;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _initSmsAutofill();
  }

  Future<void> _initSmsAutofill() async {
    try {
      // دریافت app signature برای Android SMS Retriever API
      _appSignature = await sms.SmsAutoFill().getAppSignature;
      if (_appSignature != null && mounted) {
        debugPrint('📱 App Signature: $_appSignature');
      }

      // گوش دادن به SMS های دریافتی
      listenForCode();
    } catch (e) {
      debugPrint('⚠️ SMS Autofill initialization error: $e');
      // اگر خطا داشت، ادامه می‌دهیم بدون autofill
    }
  }

  @override
  void codeUpdated() {
    // زمانی که کد OTP از SMS دریافت شد
    if (code != null &&
        code!.length == 6 &&
        mounted &&
        _isActive &&
        !_isDisposed) {
      if (_otpController.isSafe) {
        _otpController.safeSetText(code!);
        // خودکار تایید می‌کنیم
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isActive && !_isDisposed) {
            _verifyAndNavigate();
          }
        });
      }
    }
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

      final otpCode = OTPService.generateOTP();
      await OTPService.sendOTP(widget.phoneNumber, otpCode);

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

      // اجرای diagnostics قبل از ثبت نام
      debugPrint('=== OTP VERIFICATION: Running database diagnostics ===');
      try {
        await DatabaseDebugService.runFullDiagnostics();
        debugPrint('=== OTP VERIFICATION: Database diagnostics completed ===');
      } catch (diagError) {
        debugPrint(
          '=== OTP VERIFICATION: Database diagnostics failed: $diagError ===',
        );
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
        backgroundColor: context.cardColor,
        elevation: 0,
        title: Text(
          'تایید کد پیامک',
          style: TextStyle(
            fontSize: ResponsiveValue(
              context,
              defaultValue: 18.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 16.sp),
                Condition.largerThan(name: TABLET, value: 20.sp),
              ],
            ).value,
            color: context.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.goldColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40.h),
              Text(
                'کد تایید ارسال شده را وارد کنید',
                style: TextStyle(
                  fontSize: ResponsiveValue(
                    context,
                    defaultValue: 18.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 16.sp),
                      Condition.largerThan(name: TABLET, value: 20.sp),
                    ],
                  ).value,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                widget.phoneNumber,
                style: TextStyle(
                  fontSize: ResponsiveValue(
                    context,
                    defaultValue: 16.sp,
                    conditionalValues: [
                      Condition.smallerThan(name: MOBILE, value: 14.sp),
                      Condition.largerThan(name: TABLET, value: 18.sp),
                    ],
                  ).value,
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Directionality(
                textDirection: TextDirection.ltr, // اجبار LTR برای اعداد
                child: _isDisposed || !_otpController.isSafe
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
                              Condition.smallerThan(name: MOBILE, value: 50.h),
                              Condition.largerThan(name: TABLET, value: 60.h),
                            ],
                          ).value,
                          fieldWidth: ResponsiveValue(
                            context,
                            defaultValue: 45.w,
                            conditionalValues: [
                              Condition.smallerThan(name: MOBILE, value: 40.w),
                              Condition.largerThan(name: TABLET, value: 50.w),
                            ],
                          ).value,
                          activeFillColor: Theme.of(context).brightness == Brightness.dark
                              ? context.cardColor
                              : Colors.white.withValues(alpha: 0.95),
                          selectedFillColor: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.goldColor.withValues(alpha: 0.2)
                              : AppTheme.goldColor.withValues(alpha: 0.1),
                          inactiveFillColor: Theme.of(context).brightness == Brightness.dark
                              ? context.cardColor.withValues(alpha: 0.5)
                              : Colors.grey.shade50,
                          activeColor: AppTheme.goldColor,
                          selectedColor: AppTheme.goldColor,
                          inactiveColor: Theme.of(context).brightness == Brightness.dark
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
                              Condition.smallerThan(name: MOBILE, value: 18.sp),
                              Condition.largerThan(name: TABLET, value: 22.sp),
                            ],
                          ).value,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                        onChanged: (value) {
                          if (_isDisposed || !mounted || !_otpController.isSafe) {
                            return;
                          }

                          if (_errorMessage != null) {
                            WidgetSafetyUtils.safeSetState(this, () {
                              _errorMessage = null;
                            });
                          }
                          // اگر کد کامل شد، خودکار تایید می‌کنیم
                          if (value.length == 6 &&
                              _isActive &&
                              !_isLoading &&
                              !_isDisposed) {
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                if (mounted && _isActive && !_isDisposed) {
                                  _verifyAndNavigate();
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
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: ResponsiveValue(
                        context,
                        defaultValue: 14.sp,
                        conditionalValues: [
                          Condition.smallerThan(name: MOBILE, value: 12.sp),
                          Condition.largerThan(name: TABLET, value: 16.sp),
                        ],
                      ).value,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndNavigate,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2416),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'تایید و ادامه',
                          style: TextStyle(
                            fontSize: ResponsiveValue(
                              context,
                              defaultValue: 16.sp,
                              conditionalValues: [
                                Condition.smallerThan(
                                  name: MOBILE,
                                  value: 14.sp,
                                ),
                                Condition.largerThan(
                                  name: TABLET,
                                  value: 18.sp,
                                ),
                              ],
                            ).value,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: (_canResend && !_isLoading) ? _resendOTP : null,
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            WidgetSafetyUtils.safePop(context);
                          },
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
    );
  }
}
