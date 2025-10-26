import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isVerifying = false;
  String? _error;

  // برای انیمیشن ورود
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // تنظیم مقدار اولیه به 0.0 برای اطمینان از شروع صحیح
    _animationController.value = 0.0;

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // شروع انیمیشن بدون تأخیر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Normalize phone number format
  String _normalizePhoneNumber(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^\d]'), '');
    if (normalized.startsWith('+98')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('98')) {
      normalized = '0${normalized.substring(2)}';
    } else if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }
    return normalized;
  }

  bool _isValidIranianPhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^09[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    SafeSetState.call(this, () {
      _isLoading = true;
      _error = null;
    });

    try {
      // Normalize phone number
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);
      _phoneController.text = normalizedPhone;

      // بررسی وجود کاربر با شماره موبایل
      final supabaseService = SupabaseService();
      final userExists = await supabaseService.doesUserExist(normalizedPhone);

      if (!userExists) {
        setState(() {
          _error =
              'کاربری با این شماره موبایل یافت نشد. لطفاً ابتدا ثبت‌نام کنید';
          _isLoading = false;
        });
        return;
      }

      final otpCode = OTPService.generateOTP();
      final success = await OTPService.sendOTP(normalizedPhone, otpCode);

      if (success) {
        SafeSetState.call(this, () => _isOtpSent = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('کد تایید ارسال شد')));
      } else {
        SafeSetState.call(this, () {
          _error = 'خطا در ارسال کد تایید. لطفاً دوباره تلاش کنید';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('خطا در ارسال کد تایید')));
      }
    } catch (e) {
      print('Error in _sendOTP: $e');
      SafeSetState.call(this, () {
        _error = 'خطا در ارسال کد تایید: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطا در ارسال کد تایید')));
    } finally {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    SafeSetState.call(this, () {
      _isVerifying = true;
      _error = null; // پاک کردن خطای قبلی
    });

    try {
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

      final isValid = await OTPService.verifyOTP(
        normalizedPhone,
        _otpController.text,
      );

      if (isValid) {
        // بعد از تایید OTP، اقدام به ورود کن
        final supabaseService = SupabaseService();

        // ورود با supabase
        final session = await supabaseService.signInWithPhone(normalizedPhone);

        if (session != null) {
          print('Login successful, saving session...');
          // ذخیره وضعیت لاگین
          try {
            await AuthStateService().saveAuthState(
              session,
              phoneNumber: normalizedPhone,
            );
            print('Session saved after login');

            // بررسی مجدد وضعیت لاگین برای اطمینان
            final isLoggedIn = await AuthStateService().isLoggedIn();
            print('Login status after session save: $isLoggedIn');

            // بررسی وجود کاربر در Supabase client
            final currentUser = Supabase.instance.client.auth.currentUser;
            if (currentUser == null) {
              print('Warning: User logged in but currentUser is null!');
            } else {
              print('Logged in user ID: ${currentUser.id}');
            }
          } catch (e) {
            print('Error saving session: $e');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ورود با موفقیت انجام شد')),
            );
            try {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
              );
            } catch (e) {
              debugPrint('Error in login navigation: $e');
            }
          }
        } else {
          setState(() {
            _error = 'خطا در ورود کاربر';
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('خطا در ورود کاربر')));
        }
      } else if (mounted) {
        setState(() {
          _error = 'کد تایید اشتباه است';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('کد تایید اشتباه است')));
      }
    } catch (e) {
      print('Error in _verifyOTP: $e');
      SafeSetState.call(this, () {
        _error = 'خطا در بررسی کد تایید: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطا در بررسی کد تایید')));
    } finally {
      SafeSetState.call(this, () => _isVerifying = false);
    }
  }

  // This function is now just for initiating the OTP process, not direct login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _error = null; // پاک کردن خطای قبلی
      await _sendOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppTheme.darkGold.withValues(alpha: 0.1),
              AppTheme.backgroundColor,
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Main content with flexible space
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 40.h),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'به GymAI خوش آمدید',
                                style: AppTheme.headingStyle.copyWith(
                                  fontSize: ResponsiveValue(
                                    context,
                                    defaultValue: 24.sp,
                                    conditionalValues: [
                                      Condition.smallerThan(
                                        name: MOBILE,
                                        value: 20.sp,
                                      ),
                                      Condition.largerThan(
                                        name: TABLET,
                                        value: 28.sp,
                                      ),
                                    ],
                                  ).value,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _isOtpSent
                                    ? 'کد تایید را وارد کنید'
                                    : 'لطفاً برای ورود شماره موبایل خود را وارد کنید',
                                style: AppTheme.bodyStyle.copyWith(
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
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28.h),
                        Container(
                          decoration: AppTheme.cardDecoration,
                          padding: EdgeInsets.all(20.w),
                          child: _isOtpSent
                              ? _buildOTPVerificationForm()
                              : _buildLoginForm(),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
                // Logo at bottom - only visible when keyboard is not open
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: MediaQuery.of(context).viewInsets.bottom > 0
                      ? 0
                      : 120.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundColor.withValues(alpha: 0.1),
                          AppTheme.backgroundColor.withValues(alpha: 0.1),
                          AppTheme.backgroundColor,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'images/mainlogo_no_bg.png',
                        height: 80.h,
                        width: 80.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phoneController,
            decoration:
                AppTheme.textFieldDecoration(
                  'شماره موبایل',
                  hint: 'شماره موبایل خود را وارد کنید',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.phone_android,
                    color: AppTheme.goldColor,
                  ),
                ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'لطفاً شماره موبایل خود را وارد کنید';
              }
              if (!_isValidIranianPhoneNumber(_normalizePhoneNumber(value))) {
                return 'لطفاً یک شماره موبایل معتبر وارد کنید';
              }
              return null;
            },
          ),
          if (_error != null) ...[
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red,
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
          ],
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: AppTheme.primaryButtonStyle,
            child: _isLoading
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'دریافت کد تایید',
                    style: TextStyle(
                      fontSize: ResponsiveValue(
                        context,
                        defaultValue: 16.sp,
                        conditionalValues: [
                          Condition.smallerThan(name: MOBILE, value: 14.sp),
                          Condition.largerThan(name: TABLET, value: 18.sp),
                        ],
                      ).value,
                    ),
                  ),
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/register');
            },
            child: Text(
              'حساب کاربری ندارید؟ ثبت‌نام کنید',
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
    );
  }

  Widget _buildOTPVerificationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'کد تایید به شماره ${_phoneController.text} ارسال شد',
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveValue(
                context,
                defaultValue: 16.sp,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 14.sp),
                  Condition.largerThan(name: TABLET, value: 18.sp),
                ],
              ).value,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _otpController,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            enabled: !_isVerifying,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12.r),
              fieldHeight: ResponsiveValue(
                context,
                defaultValue: 54.h,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 48.h),
                  Condition.largerThan(name: TABLET, value: 60.h),
                ],
              ).value,
              fieldWidth: ResponsiveValue(
                context,
                defaultValue: 44.w,
                conditionalValues: [
                  Condition.smallerThan(name: MOBILE, value: 38.w),
                  Condition.largerThan(name: TABLET, value: 50.w),
                ],
              ).value,
              activeFillColor: AppTheme.cardColor,
              selectedFillColor: AppTheme.cardColor,
              inactiveFillColor: AppTheme.cardColor,
              activeColor: AppTheme.goldColor,
              selectedColor: AppTheme.goldColor,
              inactiveColor: AppTheme.goldColor.withValues(alpha: 0.1),
            ),
            enableActiveFill: true,
            onChanged: (value) {
              if (_error != null) {
                setState(() {
                  _error = null;
                });
              }
            },
            beforeTextPaste: (text) =>
                text?.length == 6 && text!.contains(RegExp(r'^\d+$')),
            autoDisposeControllers: false,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          if (_error != null) ...[
            SizedBox(height: 16.h),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red,
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
          ],
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOTP,
              style: AppTheme.primaryButtonStyle,
              child: _isVerifying
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'ورود',
                      style: TextStyle(
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 16.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 14.sp),
                            Condition.largerThan(name: TABLET, value: 18.sp),
                          ],
                        ).value,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoading ? null : _sendOTP,
                child: Text(
                  'ارسال مجدد کد',
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : AppTheme.goldColor,
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
                onPressed: () {
                  setState(() {
                    _isOtpSent = false;
                    _otpController.clear();
                    _error = null;
                  });
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
        ],
      ),
    );
  }
}
