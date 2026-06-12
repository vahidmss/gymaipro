import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _cardSlideAnimation;

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
        curve: Curves.easeOut, // سریع‌تر از easeIn
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut), // سریع‌تر
      ),
    );

    _cardSlideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1, curve: Curves.easeOut), // سریع‌تر
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
      final otpCode = OTPService.generateOTP();
      final success = await OTPService.sendOTP(normalizedPhone, otpCode);

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
        // بهینه‌سازی: بهبود عملکرد کیبورد
        resizeToAvoidBottomInset: true,
        body: RepaintBoundary(
          child: Stack(
            children: [
              const AuthGradientBackground(),
              // Content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Main content with flexible space
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            // بهینه‌سازی: بهبود رفتار کیبورد
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            physics:
                                const BouncingScrollPhysics(), // بهینه‌سازی: scroll روان‌تر
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 24.h,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 360.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RepaintBoundary(
                                    child: ScaleTransition(
                                      scale: _logoScaleAnimation,
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 28.h),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            // بهینه‌سازی: کاهش shadow برای عملکرد بهتر
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.goldColor
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 32.r,
                                                spreadRadius: 6.r,
                                              ),
                                            ],
                                          ),
                                          child: Image.asset(
                                            'images/GYMAI_logo_transparent.png',
                                            height: 140.h,
                                            width: 140.w,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  RepaintBoundary(
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(
                                          0,
                                          0.08,
                                        ), // بهینه‌سازی: کاهش حرکت
                                        end: Offset.zero,
                                      ).animate(_cardSlideAnimation),
                                      child: FadeTransition(
                                        opacity: _cardSlideAnimation,
                                        child: Container(
                                          padding: EdgeInsets.all(24.w),
                                          decoration: BoxDecoration(
                                            gradient:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      context.cardColor,
                                                      AppTheme.darkGold
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      context.cardColor,
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.5,
                                                      1.0,
                                                    ],
                                                  )
                                                : LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      AppTheme.darkTextColor.withValues(
                                                        alpha: 0.95,
                                                      ),
                                                      context
                                                          .goldGradientColors[0]
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      AppTheme.darkTextColor.withValues(
                                                        alpha: 0.98,
                                                      ),
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.5,
                                                      1.0,
                                                    ],
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              28.r,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.goldColor
                                                  .withValues(
                                                    alpha:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? 0.7
                                                        : 0.8,
                                                  ),
                                              width: 2.5.w,
                                            ),
                                            // بهینه‌سازی: کاهش تعداد shadow برای عملکرد بهتر
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.goldColor
                                                    .withValues(
                                                      alpha:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? 0.35
                                                          : 0.5,
                                                    ),
                                                blurRadius: 32.r,
                                                offset: Offset(0.w, 12.h),
                                                spreadRadius: 3.r,
                                              ),
                                              BoxShadow(
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? AppTheme.veryDarkBackground.withValues(
                                                        alpha: 0.4,
                                                      )
                                                    : AppTheme.lightTextColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                blurRadius: 20.r,
                                                offset: Offset(0.w, 6.h),
                                                spreadRadius: 1.r,
                                              ),
                                            ],
                                          ),
                                          child: Form(
                                            key: _formKey,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                GestureDetector(
                                                  onTap: _onUsernameFieldTap,
                                                  child: SafeTextFormField(
                                                    controller:
                                                        _usernameController,
                                                    focusNode:
                                                        _usernameFocusNode,
                                                    style: TextStyle(
                                                      color: context.textColor,
                                                      fontSize: 12.sp,
                                                      fontFamily:
                                                          AppTheme.fontFamily,
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: 'نام کاربری',
                                                      hintText:
                                                          'نام کاربری خود را وارد کنید',
                                                      labelStyle: TextStyle(
                                                        color: context
                                                            .textSecondary,
                                                        fontSize: 12.sp,
                                                        fontFamily:
                                                            AppTheme.fontFamily,
                                                      ),
                                                      hintStyle: TextStyle(
                                                        color: context
                                                            .textSecondary
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                        fontSize: 12.sp,
                                                        fontFamily:
                                                            AppTheme.fontFamily,
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: context
                                                              .separatorColor,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.r,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: AppTheme
                                                                      .goldColor,
                                                                  width: 2,
                                                                ),
                                                          ),
                                                      errorBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: AppTheme
                                                                  .errorColor,
                                                            ),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.r,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: AppTheme
                                                                      .errorColor,
                                                                  width: 2,
                                                                ),
                                                          ),
                                                      filled: true,
                                                      fillColor:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? context.cardColor
                                                          : AppTheme.darkTextColor
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                ),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 14.w,
                                                            vertical: 10.h,
                                                          ),
                                                      errorText:
                                                          _usernameError ==
                                                                  _kUsernameCheckRetryMessage
                                                              ? 'اتصال طول کشید.'
                                                              : _usernameError,
                                                      prefixIcon: Icon(
                                                        Icons.person_outline,
                                                        color:
                                                            AppTheme.goldColor,
                                                        size: 20.sp,
                                                      ),
                                                      suffixIcon:
                                                          _isCheckingUsername
                                                          ? Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    10.w,
                                                                  ),
                                                              child: SizedBox(
                                                                width: 14.w,
                                                                height: 14.h,
                                                                child: const CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<
                                                                        Color
                                                                      >(
                                                                        AppTheme
                                                                            .goldColor,
                                                                      ),
                                                                ),
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                    inputFormatters: [
                                                      UsernameInputFormatter(),
                                                      // محدود کردن طول به 30 کاراکتر
                                                      LengthLimitingTextInputFormatter(
                                                        30,
                                                      ),
                                                    ],
                                                    validator: UsernameValidator.validate,
                                                    onChanged:
                                                        _onUsernameChanged,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    onFieldSubmitted: (_) {
                                                      _phoneFocusNode
                                                          .requestFocus();
                                                    },
                                                  ),
                                                ),
                                                if (_usernameError ==
                                                    _kUsernameCheckRetryMessage)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      top: 6.h,
                                                      right: 4.w,
                                                    ),
                                                    child: InkWell(
                                                      onTap: _isCheckingUsername
                                                          ? null
                                                          : _checkUsername,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                          vertical: 6.h,
                                                          horizontal: 4.w,
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .refresh_rounded,
                                                              size: 16.sp,
                                                              color: AppTheme
                                                                  .goldColor,
                                                            ),
                                                            SizedBox(
                                                              width: 6.w,
                                                            ),
                                                            Text(
                                                              'تلاش مجدد',
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    AppTheme
                                                                        .fontFamily,
                                                                fontSize:
                                                                    12.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppTheme
                                                                    .goldColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                SizedBox(height: 16.h),
                                                GestureDetector(
                                                  onTap: _onPhoneFieldTap,
                                                  child: SafeTextFormField(
                                                    controller:
                                                        _phoneController,
                                                    focusNode: _phoneFocusNode,
                                                    style: TextStyle(
                                                      color: context.textColor,
                                                      fontSize: 12.sp,
                                                      fontFamily:
                                                          AppTheme.fontFamily,
                                                    ),
                                                    decoration: InputDecoration(
                                                      labelText: 'شماره موبایل',
                                                      hintText:
                                                          'شماره موبایل خود را وارد کنید',
                                                      labelStyle: TextStyle(
                                                        color: context
                                                            .textSecondary,
                                                        fontSize: 12.sp,
                                                        fontFamily:
                                                            AppTheme.fontFamily,
                                                      ),
                                                      hintStyle: TextStyle(
                                                        color: context
                                                            .textSecondary
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                        fontSize: 12.sp,
                                                        fontFamily:
                                                            AppTheme.fontFamily,
                                                      ),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: context
                                                              .separatorColor,
                                                        ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.r,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: AppTheme
                                                                      .goldColor,
                                                                  width: 2,
                                                                ),
                                                          ),
                                                      errorBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12.r,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: AppTheme
                                                                  .errorColor,
                                                            ),
                                                      ),
                                                      focusedErrorBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12.r,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: AppTheme
                                                                      .errorColor,
                                                                  width: 2,
                                                                ),
                                                          ),
                                                      filled: true,
                                                      fillColor:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? context.cardColor
                                                          : AppTheme.darkTextColor
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                ),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 14.w,
                                                            vertical: 10.h,
                                                          ),
                                                      prefixIcon: Icon(
                                                        Icons.phone_android,
                                                        color:
                                                            AppTheme.goldColor,
                                                        size: 20.sp,
                                                      ),
                                                    ),
                                                    keyboardType:
                                                        TextInputType.phone,
                                                    textInputAction:
                                                        TextInputAction.done,
                                                    onFieldSubmitted: (_) {
                                                      if (!_isDisposed &&
                                                          !_isLoading &&
                                                          !_isCheckingUsername) {
                                                        _sendOTP();
                                                      }
                                                    },
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'لطفاً شماره موبایل را وارد کنید';
                                                      }
                                                      if (!PhoneUtils.isValid(
                                                        PhoneUtils.normalize(
                                                          value,
                                                        ),
                                                      )) {
                                                        return 'شماره موبایل معتبر نیست';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                SizedBox(height: 20.h),
                                                DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        AppTheme.goldColor,
                                                        AppTheme.darkGold,
                                                        AppTheme.goldColor,
                                                      ],
                                                      stops: [
                                                        0.0,
                                                        0.5,
                                                        1.0,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14.r,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppTheme
                                                            .goldColor
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        blurRadius: 16.r,
                                                        offset: Offset(
                                                          0.w,
                                                          8.h,
                                                        ),
                                                        spreadRadius: 2.r,
                                                      ),
                                                      BoxShadow(
                                                        color: AppTheme.darkGold
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 24.r,
                                                        offset: Offset(
                                                          0.w,
                                                          4.h,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed:
                                                        _isLoading ||
                                                            _isCheckingUsername
                                                        ? null
                                                        : _sendOTP,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      shadowColor:
                                                          Colors.transparent,
                                                      foregroundColor:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? AppTheme.darkTextColor
                                                          : const Color(
                                                              0xFF2C2416,
                                                            ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 24.w,
                                                            vertical: 14.h,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14.r,
                                                            ),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: _isLoading
                                                        ? SizedBox(
                                                            height: 18.h,
                                                            width: 18.w,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                                Theme.of(
                                                                          context,
                                                                        ).brightness ==
                                                                        Brightness
                                                                            .dark
                                                                    ? Colors
                                                                          .white
                                                                    : const Color(
                                                                        0xFF2C2416,
                                                                      ),
                                                              ),
                                                            ),
                                                          )
                                                        : Text(
                                                            'ارسال کد تایید',
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontFamily: AppTheme
                                                                  .fontFamily,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  TextButton(
                                    onPressed: () {
                                      if (!mounted) return;
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/login',
                                      );
                                    },
                                    child: Text(
                                      'قبلاً ثبت‌نام کرده‌اید؟ وارد شوید',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: AppTheme.fontFamily,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.light
                                            ? AppTheme.lightTextSecondary
                                            : context.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ), // بستن RepaintBoundary
      ),
    );
  }
}
