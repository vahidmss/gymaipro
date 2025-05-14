import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../services/supabase_service.dart';
import 'dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameController =
      TextEditingController(); // For direct registration
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isVerifying = false;
  bool _showDirectRegistration = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
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

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Normalize phone number
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);
      _phoneController.text = normalizedPhone;

      // بررسی وجود کاربر با شماره موبایل
      final supabaseService = SupabaseService();
      print('Checking if user exists with phone: $normalizedPhone');

      // نمایش همه پروفایل‌ها برای دیباگ
      final allProfiles = await supabaseService.getAllProfiles();
      print('All profiles for debugging:');
      for (var profile in allProfiles) {
        print(
            '- ${profile['username'] ?? 'No name'}: ${profile['phone_number'] ?? 'No phone'}');
      }

      // بررسی با روش‌های مختلف
      bool userExists = false;

      // روش 1: بررسی مستقیم
      final directCheck = await supabaseService.doesUserExist(normalizedPhone);
      print('Direct check result: $directCheck');

      // روش 2: بررسی با RPC (اگر تابع RPC ایجاد شده باشد)
      try {
        final rpcCheck =
            await supabaseService.checkUserExistsRPC(normalizedPhone);
        print('RPC check result: $rpcCheck');
        userExists = directCheck || rpcCheck;
      } catch (e) {
        print('RPC check failed: $e');
        userExists = directCheck;
      }

      // روش 3: بررسی دستی در لیست پروفایل‌ها
      if (!userExists) {
        for (var profile in allProfiles) {
          if (profile['phone_number'] == normalizedPhone) {
            userExists = true;
            print('Found user in manual check: ${profile['username']}');
            break;
          }
        }
      }

      print('Final user exists check result: $userExists');

      if (!userExists) {
        setState(() {
          _error = 'کاربری با این شماره موبایل یافت نشد';
          _isLoading = false;
          _showDirectRegistration = true; // Show direct registration option
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

    setState(() => _isVerifying = true);
    try {
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

      final isValid = await OTPService.verifyOTP(
        normalizedPhone,
        _otpController.text,
      );

      if (isValid) {
        // بعد از تایید OTP، فقط پروفایل را چک کن و اگر بود، وارد شو
        final supabaseService = SupabaseService();
        final profile =
            await supabaseService.getProfileByPhoneNumber(normalizedPhone);
        if (profile != null) {
          // ورود موفق
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ورود با موفقیت انجام شد')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          setState(() {
            _error = 'پروفایل کاربر پیدا نشد!';
          });
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

  Future<void> _login() async {
    try {
      final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

      // دریافت ایمیل ساختگی با استفاده از شماره موبایل
      final supabaseService = SupabaseService();
      print('Getting fake email for phone number: $normalizedPhone');
      final email =
          await supabaseService.getFakeEmailFromPhoneNumber(normalizedPhone);
      print('Got fake email: $email');

      // بررسی وجود کاربر قبل از تلاش برای ورود
      final userExists = await supabaseService.doesUserExist(normalizedPhone);
      if (!userExists) {
        setState(() {
          _error = 'کاربر یافت نشد';
        });
        return;
      }

      // ورود با استفاده از ایمیل و شماره موبایل
      print(
          'Attempting to sign in with email: $email and password: $normalizedPhone');
      final client = Supabase.instance.client;
      final response = await client.auth.signInWithPassword(
        email: email,
        password: normalizedPhone,
      );
      print(
          'Sign in response: ${response.user != null ? 'Success' : 'Failed'}');

      if (response.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ورود با موفقیت انجام شد')),
          );
          // انتقال به داشبورد
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'خطا در ورود: کاربر یافت نشد';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا در ورود: کاربر یافت نشد')),
          );
        }
      }
    } catch (e) {
      print('Error in _login: $e');
      if (mounted) {
        setState(() {
          _error = 'خطا در ورود: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در ورود')),
        );
      }
    }
  }

  // Direct registration function for debugging
  Future<void> _directRegister() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً نام کاربری را وارد کنید')),
      );
      return;
    }

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
        // Try to login immediately
        await _login();
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

  // Show detailed debugging information
  void _showDebugInfo() async {
    final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

    // Get profile information
    final profile =
        await SupabaseService().getProfileByPhoneNumber(normalizedPhone);

    // Get all profiles
    final allProfiles = await SupabaseService().getAllProfiles();

    String debugInfo = '';
    debugInfo += 'Phone number: $normalizedPhone\n';
    debugInfo += 'Normalized phone number: $normalizedPhone\n';
    debugInfo += 'Profile found: ${profile != null ? 'Yes' : 'No'}\n\n';

    if (profile != null) {
      debugInfo += 'Profile details:\n';
      debugInfo += 'Username: ${profile['username']}\n';
      debugInfo += 'Phone: ${profile['phone_number']}\n';
      debugInfo += 'ID: ${profile['id']}\n\n';
    }

    debugInfo += 'All profiles (${allProfiles.length}):\n';
    for (var p in allProfiles) {
      debugInfo += '- ${p['username']} (${p['phone_number']})\n';
    }

    // Show dialog with debug information
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug Information'),
          content: SingleChildScrollView(
            child: Text(debugInfo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود'),
        actions: [
          // Debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _phoneController.text.isNotEmpty ? _showDebugInfo : null,
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل',
                    hintText: 'شماره موبایل خود را وارد کنید',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'لطفاً شماره موبایل را وارد کنید';
                    }
                    return null;
                  },
                ),
                if (_isOtpSent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'کد تایید',
                      hintText: 'کد تایید ارسال شده را وارد کنید',
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
                if (_showDirectRegistration) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'کاربری با این شماره موبایل یافت نشد. می‌توانید ثبت‌نام کنید:',
                    style: TextStyle(color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'نام کاربری',
                      hintText: 'نام کاربری خود را وارد کنید',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _directRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('ثبت‌نام مستقیم'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading || _isVerifying
                      ? null
                      : (_isOtpSent ? _verifyOTP : _sendOTP),
                  child: _isLoading || _isVerifying
                      ? const CircularProgressIndicator()
                      : Text(_isOtpSent ? 'تایید کد' : 'ارسال کد تایید'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text('ثبت‌نام نکرده‌اید؟ ثبت‌نام کنید'),
                ),
                // دکمه بررسی وجود پروفایل (برای دیباگ)
                if (_phoneController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final normalizedPhone =
                          _normalizePhoneNumber(_phoneController.text);
                      final profile = await SupabaseService()
                          .getProfileByPhoneNumber(normalizedPhone);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'نتیجه بررسی پروفایل: ${profile != null ? 'پیدا شد' : 'پیدا نشد'}')),
                      );
                    },
                    child: const Text('بررسی وجود پروفایل'),
                  ),
                ],
                // دکمه بررسی دقیق برای شماره 09367851894
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    const specificPhone = '09367851894';
                    final supabaseService = SupabaseService();

                    // بررسی با روش‌های مختلف
                    final directCheck =
                        await supabaseService.doesUserExist(specificPhone);
                    bool rpcCheck = false;
                    try {
                      rpcCheck = await supabaseService
                          .checkUserExistsRPC(specificPhone);
                    } catch (e) {
                      print('RPC check failed: $e');
                    }

                    // بررسی دستی
                    final allProfiles = await supabaseService.getAllProfiles();
                    bool manualCheck = false;
                    for (var profile in allProfiles) {
                      if (profile['phone_number'] == specificPhone) {
                        manualCheck = true;
                        break;
                      }
                    }

                    // نمایش نتایج
                    String result = 'بررسی شماره ثابت (09367851894):\n';
                    result +=
                        'بررسی مستقیم: ${directCheck ? 'یافت شد' : 'یافت نشد'}\n';
                    result +=
                        'بررسی RPC: ${rpcCheck ? 'یافت شد' : 'یافت نشد'}\n';
                    result +=
                        'بررسی دستی: ${manualCheck ? 'یافت شد' : 'یافت نشد'}\n';
                    result += 'تعداد پروفایل‌ها: ${allProfiles.length}';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result),
                        duration: const Duration(seconds: 10),
                      ),
                    );
                  },
                  child: const Text('بررسی شماره ثابت (09367851894)'),
                ),
                // دکمه نمایش همه پروفایل‌ها (برای دیباگ)
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    final profiles = await SupabaseService().getAllProfiles();
                    if (profiles.isNotEmpty) {
                      String profilesInfo = '';
                      for (var profile in profiles) {
                        profilesInfo +=
                            'نام کاربری: ${profile['username']}, موبایل: ${profile['phone_number']}\n';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('پروفایل‌ها: $profilesInfo'),
                          duration: const Duration(seconds: 10),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('هیچ پروفایلی یافت نشد')),
                      );
                    }
                  },
                  child: const Text('نمایش همه پروفایل‌ها'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
