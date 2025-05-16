import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/otp_service.dart';
import '../services/supabase_service.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_state_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String username;
  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.username,
  });

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
      if (_otpController.hasListeners) {
        _otpController.clear();
      }

      final otpCode = OTPService.generateOTP();
      await OTPService.sendOTP(widget.phoneNumber, otpCode);

      if (!_isActive || !mounted) return;

      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد جدید ارسال شد')),
      );
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
      final normalizedPhone =
          supabaseService.normalizePhoneNumber(widget.phoneNumber);
      final isValid = await OTPService.verifyOTP(normalizedPhone, otpCode);
      if (!_isActive || !mounted) return;
      if (!isValid) {
        _showError('کد وارد شده صحیح نیست');
        return;
      }
      // تلاش برای دریافت کاربر فعلی
      var user = Supabase.instance.client.auth.currentUser;
      // اگر کاربر لاگین نیست، ثبت‌نام و لاگین کن
      if (user == null) {
        // ثبت‌نام در Supabase Auth
        final session = await supabaseService.signUpWithPhone(
            normalizedPhone, widget.username);
        if (session == null) {
          _showError('خطا در ثبت‌نام کاربر. لطفاً دوباره تلاش کنید.');
          return;
        }

        print('User signed up successfully, saving session...');
        try {
          await AuthStateService().saveAuthState(session);
          print('Session saved after registration');

          // بررسی مجدد وضعیت لاگین برای اطمینان
          final isLoggedIn = await AuthStateService().isLoggedIn();
          print(
              'Login status after registration and session save: $isLoggedIn');
        } catch (e) {
          print('Error saving session after registration: $e');
        }

        user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          _showError('خطا در ورود کاربر. لطفاً دوباره تلاش کنید.');
          return;
        }
      }
      // ایجاد پروفایل کاربر
      final userProfile = await supabaseService.createInitialProfile(
        user,
        normalizedPhone,
        username: widget.username,
      );
      if (userProfile == null) {
        _showError('خطا در ایجاد پروفایل کاربری. لطفاً دوباره تلاش کنید.');
        return;
      }

      // ابتدا انیمیشن‌ها و تایمرها را متوقف می‌کنیم
      _isActive = false;
      _cancelTimer();

      if (mounted) {
        // اضافه کردن تأخیر طولانی‌تر برای اطمینان از اینکه همه چیز آماده است
        await Future.delayed(const Duration(milliseconds: 800));

        // مطمئن می‌شویم که ابتدا صفحه Dashboard بارگذاری شود و سپس انیمیشن‌ها شروع شوند
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (!_isActive || !mounted) return;
      _showError('خطا در فرآیند تایید یا ایجاد پروفایل: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در فرآیند تایید: ${e.toString()}')),
      );
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
        title: const Text('تایید کد پیامک'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'کد تایید ارسال شده را وارد کنید',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                enabled: !_isLoading,
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
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
                beforeTextPaste: (text) =>
                    text?.length == 6 && text!.contains(RegExp(r'^\d+$')),
                autoDisposeControllers: false,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndNavigate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'تایید',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  Text(
                    _remainingTime > 0
                        ? 'ارسال مجدد کد تا $_remainingTime ثانیه دیگر'
                        : 'کد را دریافت نکردید؟',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: (_canResend && !_isLoading) ? _resendOTP : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ارسال مجدد کد'),
                    style: TextButton.styleFrom(
                      foregroundColor: _canResend ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
