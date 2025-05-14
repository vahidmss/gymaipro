import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/otp_service.dart';
import '../services/supabase_service.dart';

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
  String? error;
  bool success = false;
  bool _isLoading = false;
  int _timerSeconds = 60;
  late final ValueNotifier<int> _timerNotifier;
  bool _canResend = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _timerNotifier = ValueNotifier(_timerSeconds);
    _startTimer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _otpController.dispose();
    _timerNotifier.dispose();
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _timerNotifier.value = _timerSeconds;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isDisposed || !mounted) return false;
      if (_timerNotifier.value > 0) {
        _timerNotifier.value--;
        return true;
      } else {
        _canResend = true;
        return false;
      }
    });
  }

  Future<void> _resendOTP() async {
    if (_isDisposed || !mounted) return;
    setState(() {
      _canResend = false;
      _timerNotifier.value = _timerSeconds;
    });
    final otpCode = OTPService.generateOTP();
    await OTPService.sendOTP(widget.phoneNumber, otpCode);
    if (_isDisposed || !mounted) return;
    _startTimer();
    if (_isDisposed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کد جدید ارسال شد (در لاگ)')),
    );
  }

  Future<void> _verifyOTP() async {
    if (_isDisposed || !mounted) return;
    setState(() => _isLoading = true);
    final code = _otpController.text.trim();
    final normalizedPhone =
        SupabaseService().normalizePhoneNumber(widget.phoneNumber);
    final isValid = await OTPService.verifyOTP(normalizedPhone, code);
    if (_isDisposed || !mounted) return;
    if (isValid) {
      try {
        await SupabaseService().createProfile(
          widget.username,
          normalizedPhone,
        );
        if (_isDisposed || !mounted) return;
        setState(() {
          error = null;
          success = true;
          _isLoading = false;
        });
        // تأخیر کوچک برای اطمینان از اتمام رندر قبل از تغییر مسیر
        await Future.delayed(const Duration(milliseconds: 100));
        if (_isDisposed || !mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } catch (e) {
        if (_isDisposed || !mounted) return;
        setState(() {
          error = 'خطا در ثبت‌نام: ${e.toString()}';
          success = false;
          _isLoading = false;
        });
      }
    } else {
      if (_isDisposed || !mounted) return;
      setState(() {
        error = 'کد وارد شده صحیح نیست یا منقضی شده است.';
        success = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تایید کد پیامک')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'کد ارسال شده را وارد کنید',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(8),
                    fieldHeight: 50,
                    fieldWidth: 40,
                    activeFillColor: Colors.white,
                    selectedFillColor: Colors.blue.shade50,
                    inactiveFillColor: Colors.grey.shade200,
                    activeColor: Colors.blue,
                    selectedColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  enableActiveFill: true,
                  onChanged: (value) {},
                  onCompleted: (value) {
                    if (!_isDisposed && mounted) {
                      _verifyOTP();
                    }
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                if (success) ...[
                  const SizedBox(height: 8),
                  const Text('کد تایید شد!',
                      style: TextStyle(color: Colors.green)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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
                            color: Colors.white,
                          ),
                        )
                      : const Text('تایید'),
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<int>(
                  valueListenable: _timerNotifier,
                  builder: (context, value, child) {
                    return Column(
                      children: [
                        Text(
                          value > 0
                              ? 'ارسال مجدد کد تا ${value} ثانیه دیگر'
                              : 'کد دریافت نکردید؟',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed:
                              value == 0 && !_isLoading ? _resendOTP : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text('ارسال مجدد کد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                value == 0 ? Colors.blue : Colors.grey,
                            minimumSize: const Size(160, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
