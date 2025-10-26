import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/screens/otp_verification_screen.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/safe_set_state.dart';
import 'package:responsive_framework/responsive_framework.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Reduced from 800ms
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

    // Listen to focus changes to handle keyboard
    _usernameFocusNode.addListener(_onFocusChange);
    _phoneFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // Handle focus changes for better UX
    if (mounted) {
      setState(() {
        // Trigger rebuild to handle layout changes
      });
    }
  }

  @override
  void dispose() {
    debugPrint('RegisterScreen: dispose called');
    _usernameController.dispose();
    _phoneController.dispose();
    _usernameFocusNode.removeListener(_onFocusChange);
    _phoneFocusNode.removeListener(_onFocusChange);
    _usernameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Normalize phone number format
  String _normalizePhoneNumber(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }
    return normalized;
  }

  bool _isValidIranianPhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^09[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _checkUsername() async {
    if (_usernameController.text.isEmpty) return;

    // Minimum length check to avoid unnecessary API calls
    if (_usernameController.text.length < 3) {
      setState(() {
        _usernameError = null; // Clear previous error
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isUnique = await SupabaseService().isUsernameUnique(
        _usernameController.text,
      );
      if (!isUnique && mounted) {
        setState(() {
          _usernameError = 'این نام کاربری قبلاً استفاده شده است';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usernameError = 'خطا در بررسی نام کاربری';
        });
      }
    } finally {
      SafeSetState.call(this, () => _isCheckingUsername = false);
    }
  }

  void _onUsernameChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear previous error if user is typing
    if (_usernameError != null && mounted) {
      setState(() {
        _usernameError = null;
      });
    }

    // Don't check short usernames
    if (value.length < 3) return;

    // Set a new timer
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        _checkUsername();
      }
    });
  }

  // Method to handle field focus changes
  void _onPhoneFieldTap() {
    // Ensure phone field can be focused
    if (!_phoneFocusNode.hasFocus) {
      _phoneFocusNode.requestFocus();
    }
  }

  // Method to handle username field tap
  void _onUsernameFieldTap() {
    if (!_usernameFocusNode.hasFocus) {
      _usernameFocusNode.requestFocus();
    }
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null) return;

    if (!mounted) return;
    SafeSetState.call(this, () => _isLoading = true);
    try {
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);
      final username = _usernameController.text;

      // بررسی اولیه وجود کاربر با این شماره موبایل
      final userExists = await SupabaseService().doesUserExist(normalizedPhone);
      if (userExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('کاربر با این شماره موبایل قبلا ثبت‌نام کرده است'),
            ),
          );
          SafeSetState.call(this, () => _isLoading = false);
          return;
        }
      }

      // تولید و ارسال کد OTP
      final otpCode = OTPService.generateOTP();
      final success = await OTPService.sendOTP(normalizedPhone, otpCode);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطا در ارسال کد تایید. لطفا دوباره تلاش کنید'),
            ),
          );
          SafeSetState.call(this, () => _isLoading = false);
          return;
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => OTPVerificationScreen(
              phoneNumber: normalizedPhone,
              username: username,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('RegisterScreen: Error in _sendOTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ارسال کد تایید: $e')));
      }
    } finally {
      SafeSetState.call(this, () => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Only clear fields if both are empty, otherwise just pop
        if (_usernameController.text.isEmpty && _phoneController.text.isEmpty) {
          return true;
        }

        // Show confirmation dialog if user has entered data
        final shouldPop = await showDialog<bool>(
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
                  _usernameController.clear();
                  _phoneController.clear();
                  Navigator.of(context).pop(true);
                },
                child: const Text('خروج'),
              ),
            ],
          ),
        );

        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppTheme.darkGold.withValues(alpha: 0.08),
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
                          SizedBox(height: 20.h),
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
                                  'لطفاً اطلاعات خود را وارد کنید',
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
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GestureDetector(
                                  onTap: _onUsernameFieldTap,
                                  child: TextFormField(
                                    controller: _usernameController,
                                    focusNode: _usernameFocusNode,
                                    decoration:
                                        AppTheme.textFieldDecoration(
                                          'نام کاربری',
                                          hint: 'نام کاربری خود را وارد کنید',
                                        ).copyWith(
                                          errorText: _usernameError,
                                          prefixIcon: const Icon(
                                            Icons.person_outline,
                                            color: AppTheme.goldColor,
                                          ),
                                          suffixIcon: _isCheckingUsername
                                              ? SizedBox(
                                                  width: 20.w,
                                                  height: 20.h,
                                                  child: const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(AppTheme.goldColor),
                                                  ),
                                                )
                                              : null,
                                        ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'لطفاً نام کاربری را وارد کنید';
                                      }
                                      return null;
                                    },
                                    onChanged: _onUsernameChanged,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      _phoneFocusNode.requestFocus();
                                    },
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                GestureDetector(
                                  onTap: _onPhoneFieldTap,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
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
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!_isLoading && !_isCheckingUsername) {
                                        _sendOTP();
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'لطفاً شماره موبایل را وارد کنید';
                                      }
                                      if (!_isValidIranianPhoneNumber(
                                        _normalizePhoneNumber(value),
                                      )) {
                                        return 'شماره موبایل معتبر نیست';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                ElevatedButton(
                                  onPressed: _isLoading || _isCheckingUsername
                                      ? null
                                      : _sendOTP,
                                  style: AppTheme.primaryButtonStyle,
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20.h,
                                          width: 20.w,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                        )
                                      : Text(
                                          'ارسال کد تایید',
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
                                SizedBox(height: 8.h),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    );
                                  },
                                  child: Text(
                                    'قبلاً ثبت‌نام کرده‌اید؟ وارد شوید',
                                    style: TextStyle(
                                      fontSize: ResponsiveValue(
                                        context,
                                        defaultValue: 14.sp,
                                        conditionalValues: [
                                          Condition.smallerThan(
                                            name: MOBILE,
                                            value: 12.sp,
                                          ),
                                          Condition.largerThan(
                                            name: TABLET,
                                            value: 16.sp,
                                          ),
                                        ],
                                      ).value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                        : 100.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.backgroundColor.withValues(alpha: 0),
                            AppTheme.backgroundColor.withValues(alpha: 0.8),
                            AppTheme.backgroundColor,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'images/mainlogo_no_bg.png',
                          height: 60.h,
                          width: 60.w,
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
      ),
    );
  }
}
