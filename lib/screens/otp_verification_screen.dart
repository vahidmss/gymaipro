import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/debug/database_debug_service.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
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
  }

  @override
  void dispose() {
    _isActive = false;
    _cancelTimer();
    _otpController.dispose();
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

    if (!mounted) return;
    setState(() {});

    _cancelTimer();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isActive || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // پاک کردن کد قبلی
      _otpController.clear();

      final otpCode = OTPService.generateOTP();
      await OTPService.sendOTP(widget.phoneNumber, otpCode);

      if (!_isActive || !mounted) return;

      _startResendTimer();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کد جدید ارسال شد')));
    } catch (e) {
      if (!_isActive || !mounted) return;
      _showError('خطا در ارسال مجدد کد');
    } finally {
      if (_isActive && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndNavigate() async {
    if (!_isActive || !mounted || _isLoading) return;

    FocusScope.of(context).unfocus();
    final otpCode = _otpController.text.trim();
    if (otpCode.isEmpty) {
      _showError('لطفاً کد تایید را وارد کنید');
      return;
    }
    if (otpCode.length != 6) {
      _showError('کد تایید باید ۶ رقم باشد');
      return;
    }
    setState(() {
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

      // اجرای diagnostics قبل از ثبت نام
      print('=== OTP VERIFICATION: Running database diagnostics ===');
      try {
        await DatabaseDebugService.runFullDiagnostics();
        print('=== OTP VERIFICATION: Database diagnostics completed ===');
      } catch (diagError) {
        print(
          '=== OTP VERIFICATION: Database diagnostics failed: $diagError ===',
        );
      }

      // ثبت نام مستقیم کاربر در Supabase
      print('=== OTP VERIFICATION: Starting user registration ===');
      print('=== OTP VERIFICATION: normalizedPhone=$normalizedPhone ===');
      print('=== OTP VERIFICATION: username=${widget.username} ===');

      final session = await supabaseService.signUpWithPhone(
        normalizedPhone,
        widget.username,
      );

      print('=== OTP VERIFICATION: signUpWithPhone completed ===');
      print('=== OTP VERIFICATION: session result: ${session != null} ===');

      if (session == null) {
        print('=== OTP VERIFICATION: session is null, registration failed ===');
        _showError('خطا در ثبت نام. لطفاً دوباره تلاش کنید');
        return;
      }

      print(
        '=== OTP VERIFICATION: User registered successfully, saving session... ===',
      );
      print(
        '=== OTP VERIFICATION: Session details: ${session.accessToken.substring(0, 10)}... ===',
      );
      print('=== OTP VERIFICATION: User ID: ${session.user.id} ===');

      try {
        await AuthStateService().saveAuthState(session);
        print('=== OTP VERIFICATION: Session saved after registration ===');

        // بررسی مجدد وضعیت لاگین برای اطمینان
        final isLoggedIn = await AuthStateService().isLoggedIn();
        print(
          '=== OTP VERIFICATION: Login status after registration and session save: $isLoggedIn ===',
        );

        // بررسی session در Supabase client
        final currentSession = Supabase.instance.client.auth.currentSession;
        print(
          '=== OTP VERIFICATION: Current Supabase session: ${currentSession != null ? "exists" : "null"} ===',
        );
        if (currentSession != null) {
          print(
            '=== OTP VERIFICATION: Supabase session user ID: ${currentSession.user.id} ===',
          );
        }
      } catch (e) {
        print(
          '=== OTP VERIFICATION: Error saving session after registration: $e ===',
        );
      }

      // ابتدا انیمیشن‌ها و تایمرها را متوقف می‌کنیم
      _isActive = false;
      _cancelTimer();

      if (mounted) {
        // مطمئن می‌شویم که ابتدا صفحه Dashboard بارگذاری شود و سپس انیمیشن‌ها شروع شوند
        try {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/main', (route) => false);
        } catch (e) {
          debugPrint('Error in OTP navigation: $e');
        }
      }
    } catch (e) {
      if (!_isActive || !mounted) return;
      _showError('خطا در فرآیند تایید یا ایجاد پروفایل: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در فرآیند تایید: $e')));
    } finally {
      if (_isActive && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!_isActive || !mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
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
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Directionality(
                textDirection: TextDirection.ltr, // اجبار LTR برای اعداد
                child: PinCodeTextField(
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
                    activeFillColor: Colors.white,
                    selectedFillColor: Colors.blue.shade50,
                    inactiveFillColor: Colors.grey.shade100,
                    activeColor: Colors.blue,
                    selectedColor: Colors.blue,
                    inactiveColor: Colors.grey,
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
                    color: Colors.black,
                  ),
                  onChanged: (value) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                  beforeTextPaste: (text) =>
                      text?.length == 6 && text!.contains(RegExp(r'^\d+$')),
                  autoDisposeControllers: false,
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
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
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
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
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
                            Navigator.of(context).pop();
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
