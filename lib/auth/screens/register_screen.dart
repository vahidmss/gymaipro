import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/utils/otp_autofill_helper.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/auth/utils/phone_utils.dart';
import 'package:gymaipro/auth/widgets/auth_gradient_background.dart';
import 'package:gymaipro/screens/otp_verification_screen.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';
import 'package:gymaipro/utils/username_validator.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/widgets/safe_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  // _otpController removed - not used
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Focus nodes for better field management
  final _usernameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  // Debounce timer for username check
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  /// Message shown when username check times out or fails (user can tap to retry).
  static const String _kUsernameCheckRetryMessage =
      'اتصال طول کشید یا خطا در بررسی. لمس کنید برای تلاش مجدد';

  StreamSubscription<bool>? _connectivitySub;

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

    // وقتی نت برمی‌گردد، اگر قبلاً خطای اتصال داشتیم خودکار دوباره بررسی می‌کنیم
    _connectivitySub =
        ConnectivityService.instance.isConnectedStream.listen((online) {
      if (online &&
          mounted &&
          !_isDisposed &&
          !_isCheckingUsername &&
          _usernameError == _kUsernameCheckRetryMessage &&
          _usernameController.isSafe &&
          _usernameController.safeText.length >= 3) {
        _checkUsername();
      }
    });
  }

  @override
  void dispose() {
    debugPrint('RegisterScreen: dispose called');
    _isDisposed = true;
    _debounceTimer?.cancel();
    _connectivitySub?.cancel();

    // فقط AnimationController را dispose می‌کنیم
    // TextEditingController ها را dispose نمی‌کنیم چون Flutter/TextField ممکن است
    // هنوز در حال استفاده از آنها باشد و این باعث خطا می‌شود
    // آنها توسط garbage collector پاک می‌شوند
    try {
      _animationController.dispose();
    } catch (e) {
      debugPrint('Error disposing animation controller: $e');
    }

    super.dispose();
  }

  Future<void> _checkUsername() async {
    if (_isDisposed || !mounted || !_usernameController.isSafe) return;
    if (_usernameController.safeText.isEmpty) return;

    // Minimum length check to avoid unnecessary API calls
    final username = _usernameController.safeText;
    if (username.length < 3) {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _usernameError = null; // Clear previous error
        });
      }
      return;
    }

    if (mounted) {
      WidgetSafetyUtils.safeSetState(this, () {
        _isCheckingUsername = true;
        _usernameError = null;
      });
    }

    try {
      if (_isDisposed || !mounted || !_usernameController.isSafe) return;
      final isUnique = await SupabaseService()
          .isUsernameUnique(_usernameController.safeText)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw TimeoutException('Username check'),
          );
      if (!isUnique && mounted && !_isDisposed) {
        WidgetSafetyUtils.safeSetState(this, () {
          _usernameError = 'این نام کاربری قبلاً استفاده شده است';
        });
      }
    } on TimeoutException {
      if (mounted && !_isDisposed) {
        WidgetSafetyUtils.safeSetState(this, () {
          _usernameError = _kUsernameCheckRetryMessage;
        });
      }
    } on SupabaseBackendAuthException catch (e) {
      if (mounted && !_isDisposed) {
        WidgetSafetyUtils.safeSetState(this, () {
          _usernameError = e.message;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        WidgetSafetyUtils.safeSetState(this, () {
          _usernameError = _kUsernameCheckRetryMessage;
        });
      }
    } finally {
      if (!_isDisposed && mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isCheckingUsername = false);
      }
    }
  }

  void _onUsernameChanged(String value) {
    // Check if disposed first
    if (_isDisposed || !mounted) return;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // بررسی اعتبار فرمت نام کاربری
    final formatError = UsernameValidator.validate(value);

    if (formatError != null && mounted && !_isDisposed) {
      WidgetSafetyUtils.safeSetState(this, () {
        _usernameError = formatError;
      });
      return; // اگر فرمت نامعتبر است، بررسی یکتایی را انجام نده
    }

    // Clear previous error if format is valid
    if (_usernameError != null && mounted && !_isDisposed) {
      WidgetSafetyUtils.safeSetState(this, () {
        _usernameError = null;
      });
    }

    // Don't check short usernames
    if (value.length < 3) return;

    // Set a new timer for uniqueness check
    _debounceTimer = Timer(_debounceDuration, () {
      if (!_isDisposed && mounted && _usernameController.isSafe) {
        _checkUsername();
      }
    });
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
      debugPrint('Error requesting phone focus: $e');
    }
  }

  // Method to handle username field tap
  void _onUsernameFieldTap() {
    if (_isDisposed || !mounted) return;
    try {
      if (!_usernameFocusNode.hasFocus) {
        _usernameFocusNode.requestFocus();
      }
    } catch (e) {
      // FocusNode may be disposed
      debugPrint('Error requesting username focus: $e');
    }
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null) return;
    if (!mounted) return;

    WidgetSafetyUtils.safeSetState(this, () => _isLoading = true);
    try {
      if (!_phoneController.isSafe || !_usernameController.isSafe) {
        if (mounted) {
          WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        }
        return;
      }
      final normalizedPhone = PhoneUtils.normalize(_phoneController.safeText);
      final username = _usernameController.safeText;

      // بررسی اولیه وجود کاربر با این شماره موبایل
      if (!mounted) return;
      late final bool userExists;
      try {
        userExists = await SupabaseService().doesUserExist(normalizedPhone);
      } on SupabaseBackendAuthException catch (e) {
        if (!mounted) return;
        WidgetSafetyUtils.safeShowSnackBar(context, e.message);
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        return;
      }
      if (!mounted) return;
      if (userExists) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'کاربر با این شماره موبایل قبلا ثبت‌نام کرده است',
        );
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        return;
      }

      // تولید و ارسال کد OTP
      if (!mounted) return;
      await OtpAutofillHelper.primeNativeListener();
      final success = await OTPService.sendOTP(normalizedPhone);

      if (!mounted) return;
      if (!success) {
        WidgetSafetyUtils.safeShowSnackBar(
          context,
          'خطا در ارسال کد تایید. لطفا دوباره تلاش کنید',
        );
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
        return;
      }

      if (mounted && !_isDisposed) {
        // ابتدا TextField را از درخت UI حذف می‌کنیم تا controller آزاد شود
        _isDisposed = true;
        WidgetSafetyUtils.safeSetState(this, () {});

        // صبر می‌کنیم تا UI به‌روزرسانی شود و TextField حذف شود
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // بهینه‌سازی: استفاده از transition سریع‌تر
            WidgetSafetyUtils.safeNavigateReplacement(
              context,
              () => OTPVerificationScreen(
                phoneNumber: normalizedPhone,
                username: username,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('RegisterScreen: Error in _sendOTP: $e');
      WidgetSafetyUtils.safeShowSnackBar(context, 'خطا در ارسال کد تایید: $e');
    } finally {
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isDisposed) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }

        if ((!_usernameController.isSafe ||
                _usernameController.safeText.isEmpty) &&
            (!_phoneController.isSafe || _phoneController.safeText.isEmpty)) {
          if (context.mounted) Navigator.of(context).pop();
          return;
        }

        final shouldPop = await WidgetSafetyUtils.safeShowDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خروج از ثبت نام'),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید از ثبت نام خارج شوید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('انصراف'),
              ),
              TextButton(
                onPressed: () {
                  if (_usernameController.isSafe) {
                    _usernameController.safeClear();
                  }
                  if (_phoneController.isSafe) _phoneController.safeClear();
                  WidgetSafetyUtils.safePop(context, true);
                },
                child: const Text('خروج'),
              ),
            ],
          ),
        );

        if ((shouldPop ?? false) && context.mounted) {
          Navigator.of(context).pop();
        }
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
                    final isKeyboardOpen =
                        MediaQuery.of(context).viewInsets.bottom > 0;
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: isKeyboardOpen ? 12.h : 28.h,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 400.w,
                          minHeight: constraints.maxHeight -
                              (isKeyboardOpen ? 24.h : 56.h),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isKeyboardOpen) ...[
                              const AuthLogo(),
                              SizedBox(height: 28.h),
                            ],
                            AuthCard(child: _buildRegisterForm()),
                            SizedBox(height: 18.h),
                            TextButton(
                              onPressed: () {
                                if (!mounted) return;
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
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
                                      text: 'قبلاً ثبت‌نام کرده‌اید؟ ',
                                    ),
                                    TextSpan(
                                      text: 'وارد شوید',
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

  Widget _buildRegisterForm() {
    final usernameDeco = authFieldDecoration(
      context,
      label: 'نام کاربری',
      hint: 'نام کاربری خود را وارد کنید',
      icon: Icons.person_outline,
    ).copyWith(
      errorText: _usernameError == _kUsernameCheckRetryMessage
          ? 'اتصال طول کشید.'
          : _usernameError,
      suffixIcon: _isCheckingUsername
          ? Padding(
              padding: EdgeInsets.all(10.w),
              child: SizedBox(
                width: 14.w,
                height: 14.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                ),
              ),
            )
          : null,
    );

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _onUsernameFieldTap,
            child: SafeTextFormField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              style: TextStyle(
                color: context.textColor,
                fontSize: 14.sp,
                fontFamily: AppTheme.fontFamily,
              ),
              decoration: usernameDeco,
              inputFormatters: [
                UsernameInputFormatter(),
                LengthLimitingTextInputFormatter(30),
              ],
              validator: UsernameValidator.validate,
              onChanged: _onUsernameChanged,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _phoneFocusNode.requestFocus(),
            ),
          ),
          if (_usernameError == _kUsernameCheckRetryMessage)
            Padding(
              padding: EdgeInsets.only(top: 6.h, right: 4.w),
              child: InkWell(
                onTap: _isCheckingUsername ? null : _checkUsername,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 4.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 16.sp,
                        color: AppTheme.goldColor,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'تلاش مجدد',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.goldColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SizedBox(height: 14.h),
          GestureDetector(
            onTap: _onPhoneFieldTap,
            child: SafeTextFormField(
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
                if (!_isDisposed && !_isLoading && !_isCheckingUsername) {
                  _sendOTP();
                }
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
          SizedBox(height: 18.h),
          AuthPrimaryButton(
            label: 'ارسال کد تایید',
            loading: _isLoading || _isCheckingUsername,
            onPressed: _sendOTP,
          ),
        ],
      ),
    );
  }
}
