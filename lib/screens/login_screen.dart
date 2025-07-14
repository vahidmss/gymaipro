import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/auth_state_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    // Remove any spaces or special characters
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    // Ensure it starts with 0
    if (!normalized.startsWith('0')) {
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

    setState(() {
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

      if (success && mounted) {
        setState(() => _isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کد تایید ارسال شد')),
        );
      } else if (mounted) {
        setState(() {
          _error = 'خطا در ارسال کد تایید. لطفاً دوباره تلاش کنید';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ارسال کد تایید')),
        );
      }
    } catch (e) {
      print('Error in _sendOTP: $e');
      if (mounted) {
        setState(() {
          _error = 'خطا در ارسال کد تایید: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ارسال کد تایید')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
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
            await AuthStateService()
                .saveAuthState(session, phoneNumber: normalizedPhone);
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
            Navigator.pushNamedAndRemoveUntil(
                context, '/dashboard', (route) => false);
          }
        } else {
          setState(() {
            _error = 'خطا در ورود کاربر';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در ورود کاربر')),
          );
        }
      } else if (mounted) {
        setState(() {
          _error = 'کد تایید اشتباه است';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کد تایید اشتباه است')),
        );
      }
    } catch (e) {
      print('Error in _verifyOTP: $e');
      if (mounted) {
        setState(() {
          _error = 'خطا در بررسی کد تایید: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در بررسی کد تایید')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'به جیم‌ای خوش آمدید',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isOtpSent
                          ? 'کد تایید را وارد کنید'
                          : 'لطفاً برای ورود شماره موبایل خود را وارد کنید',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _isOtpSent
                            ? _buildOTPVerificationForm()
                            : _buildLoginForm(),
                      ),
                    ),
                  ],
                ),
              ),
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
            decoration: InputDecoration(
              labelText: 'شماره موبایل',
              hintText: 'شماره موبایل خود را وارد کنید',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'دریافت کد تایید',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/register');
            },
            child: const Text(
              'حساب کاربری ندارید؟ ثبت‌نام کنید',
              style: TextStyle(fontSize: 14),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PinCodeTextField(
            appContext: context,
            length: 6,
            controller: _otpController,
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            enabled: !_isVerifying,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 50,
              fieldWidth: 40,
              activeFillColor: Colors.white,
              selectedFillColor: Colors.blue.shade50,
              inactiveFillColor: Colors.grey.shade100,
              activeColor: Colors.blue,
              selectedColor: Colors.blue,
              inactiveColor: Colors.grey,
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
            animationDuration: const Duration(milliseconds: 150),
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'ورود',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoading ? null : _sendOTP,
                child: Text(
                  'ارسال مجدد کد',
                  style: TextStyle(
                    color: _isLoading ? Colors.grey : AppTheme.goldColor,
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
                child: const Text('بازگشت'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
