import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/utils/otp_autofill_helper.dart';
import 'package:gymaipro/auth/screens/login_otp_verification_screen.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/auth/utils/phone_utils.dart';
import 'package:gymaipro/auth/widgets/auth_gradient_background.dart';
import 'package:gymaipro/core/web_interaction.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // برای انیمیشن ورود
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Focus nodes for better field management
  final _phoneFocusNode = FocusNode();

  // Flag to track if controllers are disposed
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // بهینه‌سازی: کاهش زمان انیمیشن برای سرعت بیشتر
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ), // بهینه‌سازی: کاهش از 500ms به 300ms
    );

    // تنظیم مقدار اولیه به 0.0 برای اطمینان از شروع صحیح
    _animationController.value = 0.0;

    // بهینه‌سازی: استفاده از curve سریع‌تر
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // شروع انیمیشن بدون تأخیر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.safeForward();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    // فقط AnimationController و FocusNode ها را dispose می‌کنیم
    // TextEditingController ها را dispose نمی‌کنیم چون Flutter/TextField ممکن است
    // هنوز در حال استفاده از آنها باشد و این باعث خطا می‌شود
    // آنها توسط garbage collector پاک می‌شوند
    try {
      _animationController.dispose();
      _phoneFocusNode.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }

    super.dispose();
  }

  // Method to handle field focus changes
  void _onPhoneFieldTap() {
    if (_isDisposed || !mounted) return;
    // Ensure phone field can be focused
    try {
      if (!_phoneFocusNode.hasFocus) {
        _phoneFocusNode.requestFocus();
      }
    } catch (e) {
      // FocusNode may be disposed
      debugPrint('Error requesting focus: $e');
    }
  }


  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    WidgetSafetyUtils.safeSetState(this, () {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!_phoneController.isSafe) {
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () {
            _isLoading = false;
            _error = 'خطا در پردازش شماره موبایل';
          });
        }
        return;
      }
      // Normalize phone number
      final normalizedPhone = PhoneUtils.normalize(_phoneController.safeText);
      if (!_isDisposed && _phoneController.isSafe && mounted) {
        _phoneController.safeSetText(normalizedPhone);
      }

      // بررسی وجود کاربر با شماره موبایل
      if (!mounted) return;
      final supabaseService = SupabaseService();
      final userExists = await supabaseService.doesUserExist(normalizedPhone);

      if (!mounted) return;
      if (!userExists) {
        WidgetSafetyUtils.safeSetState(this, () {
          _error =
              'کاربری با این شماره موبایل یافت نشد. لطفاً ابتدا ثبت‌نام کنید';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      await OtpAutofillHelper.primeNativeListener();
      final success = await OTPService.sendOTP(normalizedPhone);

      if (!mounted) return;
      if (success) {
        // هدایت به صفحه OTP verification مخصوص لاگین - استفاده از push برای امکان بازگشت
        if (mounted && !_isDisposed) {
          _isDisposed = true;
          WidgetSafetyUtils.safeSetState(this, () {});

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // استفاده از push به جای pushReplacement تا بتوان به صفحه لاگین برگشت
              WidgetSafetyUtils.safeNavigate(
                context,
                () => LoginOTPVerificationScreen(
                  phoneNumber: normalizedPhone,
                ),
              );
            }
          });
        }
      } else {
        WidgetSafetyUtils.safeSetState(this, () {
          _error = 'خطا در ارسال کد تایید. لطفاً دوباره تلاش کنید';
        });
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در ارسال کد تایید',
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error in _sendOTP: $e');
      WidgetSafetyUtils.safeSetState(this, () {
        _error = 'خطا در ارسال کد تایید: $e';
      });
      WidgetSafetyUtils.safeShowSnackBar(
        context,
        'خطا در ارسال کد تایید',
      );
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
      }
    }
  }

  // This function initiates the OTP process and navigates to OTP verification screen
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _error = null; // پاک کردن خطای قبلی
      await _sendOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isDisposed) return;

        _isDisposed = true;
        WidgetSafetyUtils.safeSetState(this, () {});

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            WidgetSafetyUtils.safePushReplacementNamed(
              context,
              '/welcome',
              arguments: {'jumpToLastPage': true},
            );
          }
        });
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const AuthGradientBackground(),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboardHeight =
                        MediaQuery.of(context).viewInsets.bottom;
                    final isKeyboardOpen = keyboardHeight > 0;

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: WebInteraction.listScrollPhysics,
                      padding: EdgeInsets.only(
                        left: 24.w,
                        right: 24.w,
                        top: isKeyboardOpen ? 12.h : 28.h,
                        bottom: isKeyboardOpen ? 16.h : 28.h,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 400.w,
                          minHeight: constraints.maxHeight -
                              (isKeyboardOpen ? 28.h : 56.h),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isKeyboardOpen) ...[
                              const AuthLogo(),
                              SizedBox(height: 28.h),
                            ],
                            AuthCard(child: _buildLoginForm()),
                            SizedBox(height: 18.h),
                            TextButton(
                              onPressed: () {
                                if (_isDisposed) return;
                                _isDisposed = true;
                                WidgetSafetyUtils.safeSetState(this, () {});
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) {
                                    WidgetSafetyUtils
                                        .safePushReplacementNamed(
                                      context,
                                      '/register',
                                    );
                                  }
                                });
                              },
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontFamily: AppTheme.fontFamily,
                                    color: context.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'حساب کاربری ندارید؟ ',
                                    ),
                                    TextSpan(
                                      text: 'ثبت‌نام کنید',
                                      style: TextStyle(
                                        color: AppTheme.goldColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _onPhoneFieldTap,
            child: _isDisposed || !_phoneController.isSafe
                ? const SizedBox.shrink()
                : TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 14.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    decoration: authFieldDecoration(
                      context,
                      label: 'شماره موبایل',
                      hint: 'مثلاً ۰۹۱۲۳۴۵۶۷۸۹',
                      icon: Icons.phone_android,
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) _login();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً شماره موبایل را وارد کنید';
                      }
                      if (!PhoneUtils.isValid(PhoneUtils.normalize(value))) {
                        return 'شماره موبایل معتبر نیست';
                      }
                      return null;
                    },
                  ),
          ),
          if (_error != null) ...[
            SizedBox(height: 12.h),
            Text(
              _error!,
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 12.sp,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 18.h),
          AuthPrimaryButton(
            label: 'دریافت کد تایید',
            loading: _isLoading,
            onPressed: _login,
          ),
        ],
      ),
    );
  }
}
