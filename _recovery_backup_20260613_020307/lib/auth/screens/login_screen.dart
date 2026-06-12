import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/screens/login_otp_verification_screen.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/auth/utils/phone_utils.dart';
import 'package:gymaipro/auth/widgets/auth_gradient_background.dart';
import 'package:gymaipro/services/otp_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/utils/text_controller_utils.dart';

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
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _cardSlideAnimation;

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
        curve: Curves.easeOut, // سریع‌تر از easeIn
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut), // سریع‌تر
      ),
    );

    _cardSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut), // سریع‌تر
      ),
    );

    // شروع انیمیشن بدون تأخیر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.safeForward();
      }
    });

    // بهینه‌سازی: حذف listener غیرضروری که باعث rebuild می‌شود
    // Focus handling توسط Flutter به صورت خودکار انجام می‌شود
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
      final otpCode = OTPService.generateOTP();
      final success = await OTPService.sendOTP(normalizedPhone, otpCode);

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
      print('Error in _sendOTP: $e');
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
    return WillPopScope(
      onWillPop: () async {
        if (_isDisposed) return false;

        // ابتدا TextField را از درخت UI حذف می‌کنیم
        _isDisposed = true;
        WidgetSafetyUtils.safeSetState(this, () {});

        // صبر می‌کنیم تا UI به‌روزرسانی شود
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // همیشه به welcome با آخرین اسلاید برو
            WidgetSafetyUtils.safePushReplacementNamed(
              context,
              '/welcome',
              arguments: {'jumpToLastPage': true},
            );
          }
        });
        return false; // جلوگیری از pop خودکار
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // دریافت ارتفاع keyboard برای مدیریت بهتر layout
                      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                      final isKeyboardOpen = keyboardHeight > 0;
                      
                      return SingleChildScrollView(
                        // بهینه‌سازی: بهبود رفتار کیبورد
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 20.w,
                          right: 20.w,
                          top: 24.h,
                          bottom: isKeyboardOpen ? 16.h : 24.h,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 360.w,
                            minHeight: constraints.maxHeight - 48.h,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  // نمایش لوگو فقط وقتی keyboard باز نیست
                                  if (!isKeyboardOpen)
                                    RepaintBoundary(
                                      child: ScaleTransition(
                                        scale: _logoScaleAnimation,
                                        child: Padding(
                                          padding: EdgeInsets.only(bottom: 28.h),
                                          child: Container(
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
                                            // بهینه‌سازی: cache تصویر
                                            filterQuality: FilterQuality
                                                .medium, // تعادل بین کیفیت و عملکرد
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // کاهش فاصله لوگو وقتی keyboard باز است
                                  if (isKeyboardOpen) SizedBox(height: 16.h),
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
                                                      Colors.white.withValues(
                                                        alpha: 0.95,
                                                      ),
                                                      context
                                                          .goldGradientColors[0]
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      Colors.white.withValues(
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
                                                    ? Colors.black.withValues(
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
                                          child: _buildLoginForm(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  TextButton(
                                    onPressed: () {
                                      if (_isDisposed) return;

                                      // ابتدا TextField را از درخت UI حذف می‌کنیم
                                      _isDisposed = true;
                                      WidgetSafetyUtils.safeSetState(this, () {});

                                      // صبر می‌کنیم تا UI به‌روزرسانی شود
                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        if (mounted) {
                                          // بهینه‌سازی: استفاده از transition سریع‌تر
                                          WidgetSafetyUtils.safePushReplacementNamed(
                                            context,
                                            '/register',
                                          );
                                        }
                                      });
                                    },
                                    child: Text(
                                      'حساب کاربری ندارید؟ ثبت‌نام کنید',
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
                      );
                    },
                  ),
                ),
              ),
            ],
          ), // بستن RepaintBoundary
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
                      fontSize: 12.sp,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    decoration: InputDecoration(
                      labelText: 'شماره موبایل',
                      hintText: 'شماره موبایل خود را وارد کنید',
                      labelStyle: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      hintStyle: TextStyle(
                        color: context.textSecondary.withValues(alpha: 0.6),
                        fontSize: 12.sp,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: context.separatorColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppTheme.goldColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppTheme.errorColor,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppTheme.errorColor,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? context.cardColor
                          : Colors.white.withValues(alpha: 0.7),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      prefixIcon: Icon(
                        Icons.phone_android,
                        color: AppTheme.goldColor,
                        size: 20.sp,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _login();
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
          if (_error != null) ...[
            SizedBox(height: 12.h),
            Text(
              _error!,
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 11.sp,
                fontFamily: AppTheme.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 20.h),
          // دکمه دریافت کد تایید - با استایل حرفه‌ای مشابه صفحه ثبت‌نام
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.goldColor,
                  AppTheme.darkGold,
                  AppTheme.goldColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  blurRadius: 16.r,
                  offset: Offset(0.w, 8.h),
                  spreadRadius: 2.r,
                ),
                BoxShadow(
                  color: AppTheme.darkGold.withValues(alpha: 0.3),
                  blurRadius: 24.r,
                  offset: Offset(0.w, 4.h),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2416),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
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
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF2C2416),
                        ),
                      ),
                    )
                  : Text(
                      'دریافت کد تایید',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
