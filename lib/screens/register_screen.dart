import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/otp_service.dart';
import 'otp_verification_screen.dart';

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
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isOtpSent = false;
  bool _isVerifying = false;
  String? _usernameError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
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

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final isUnique =
          await SupabaseService().isUsernameUnique(_usernameController.text);
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
      if (mounted) {
        setState(() => _isCheckingUsername = false);
      }
    }
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null) return;

    setState(() => _isLoading = true);
    try {
      // Normalize phone number
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);
      _phoneController.text = normalizedPhone;

      final otpCode = OTPService.generateOTP();
      final success = await OTPService.sendOTP(normalizedPhone, otpCode);

      if (success && mounted) {
        setState(() => _isOtpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کد تایید ارسال شد')),
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                  phoneNumber: normalizedPhone,
                  username: _usernameController.text),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ارسال کد تایید')),
        );
      }
    } catch (e) {
      print('Error in _sendOTP: $e');
      if (mounted) {
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

    setState(() => _isVerifying = true);
    try {
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

      final isValid = await OTPService.verifyOTP(
        normalizedPhone,
        _otpController.text,
      );

      if (isValid) {
        await _register();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کد تایید اشتباه است')),
        );
      }
    } catch (e) {
      print('Error in _verifyOTP: $e');
      if (mounted) {
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

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

      final profile = await SupabaseService().createProfile(
        _usernameController.text,
        normalizedPhone,
      );

      if (mounted) {
        // TODO: Navigate to home screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ثبت نام با موفقیت انجام شد')),
        );
      }
    } catch (e) {
      print('Error in _register: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ثبت نام')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _directRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameError != null) return;

    setState(() => _isLoading = true);
    try {
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

      final success = await SupabaseService().registerUserDirectly(
        _usernameController.text,
        normalizedPhone,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ثبت‌نام مستقیم با موفقیت انجام شد')),
        );
        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ثبت‌نام مستقیم')),
        );
      }
    } catch (e) {
      print('Error in direct registration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت‌نام مستقیم: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    const Text(
                      'لطفاً اطلاعات خود را وارد کنید',
                      style: TextStyle(
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'نام کاربری',
                                  hintText: 'نام کاربری خود را وارد کنید',
                                  errorText: _usernameError,
                                  prefixIcon: const Icon(Icons.person_outline),
                                  suffixIcon: _isCheckingUsername
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'لطفاً نام کاربری را وارد کنید';
                                  }
                                  return null;
                                },
                                onChanged: (_) {
                                  Future.delayed(
                                      const Duration(milliseconds: 500),
                                      _checkUsername);
                                },
                              ),
                              const SizedBox(height: 20),
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
                                    return 'لطفاً شماره موبایل را وارد کنید';
                                  }
                                  if (!_isValidIranianPhoneNumber(
                                      _normalizePhoneNumber(value))) {
                                    return 'شماره موبایل معتبر نیست';
                                  }
                                  return null;
                                },
                              ),
                              if (_isOtpSent) ...[
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _otpController,
                                  decoration: InputDecoration(
                                    labelText: 'کد تایید',
                                    hintText: 'کد تایید ارسال شده را وارد کنید',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'لطفاً کد تایید را وارد کنید';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: _isLoading ||
                                        _isVerifying ||
                                        _isCheckingUsername
                                    ? null
                                    : (_isOtpSent ? _verifyOTP : _sendOTP),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading || _isVerifying
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isOtpSent
                                            ? 'تایید کد'
                                            : 'ارسال کد تایید',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                      context, '/login');
                                },
                                child: const Text(
                                  'قبلاً ثبت‌نام کرده‌اید؟ وارد شوید',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
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
    );
  }
}
