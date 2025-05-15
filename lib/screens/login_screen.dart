import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';
import 'dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/auth_state_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
        final userProfile = UserProfile.fromJson(profile);
        print(
            '- ${userProfile.firstName ?? 'No name'}: ${userProfile.phoneNumber}');
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
          final userProfile = UserProfile.fromJson(profile);
          if (userProfile.phoneNumber == normalizedPhone) {
            userExists = true;
            print('Found user in manual check: ${userProfile.firstName}');
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
            await AuthStateService().saveAuthState(session);
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
          SnackBar(content: Text('خطا در بررسی کد تایید')),
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
      debugInfo += 'First Name: ${profile.firstName ?? 'Not set'}\n';
      debugInfo += 'Last Name: ${profile.lastName ?? 'Not set'}\n';
      debugInfo += 'Phone: ${profile.phoneNumber}\n';
      debugInfo += 'ID: ${profile.id}\n\n';
    }

    debugInfo += 'All profiles (${allProfiles.length}):\n';
    for (var p in allProfiles) {
      final userProfile = UserProfile.fromJson(p);
      debugInfo +=
          '- ${userProfile.firstName ?? 'No name'} ${userProfile.lastName ?? ''} (${userProfile.phoneNumber})\n';
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
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppTheme.darkGold.withOpacity(0.1),
                  AppTheme.backgroundColor,
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _isOtpSent ? _buildOTPVerificationForm() : _buildLoginForm(),
                  const SizedBox(height: 24),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.cardColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center,
            size: 64,
            color: AppTheme.goldColor,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'خوش آمدید',
          style: AppTheme.headingStyle,
        ),
        const SizedBox(height: 8),
        Text(
          _isOtpSent ? 'کد تایید را وارد کنید' : 'برای ادامه وارد شوید',
          style: AppTheme.bodyStyle,
        ),
      ],
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
            decoration: AppTheme.textFieldDecoration(
              'شماره موبایل',
              hint: '09123456789',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'لطفاً شماره موبایل خود را وارد کنید';
              }
              if (!value.startsWith('09') || value.length != 11) {
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
          const SizedBox(height: 24),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('دریافت کد تایید'),
          ),

          // Debug button (can be removed in production)
          if (!_isOtpSent) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _showDebugInfo,
              child: const Text('نمایش اطلاعات دیباگ',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],

          // Direct registration UI (only shown if user not found)
          if (_showDirectRegistration) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'ثبت‌نام سریع',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: AppTheme.textFieldDecoration(
                'نام کاربری',
                hint: 'نام کاربری خود را وارد کنید',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: AppTheme.secondaryButtonStyle,
              onPressed: _isLoading ? null : _directRegister,
              child: const Text('ثبت‌نام مستقیم'),
            ),
          ],
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
            style: AppTheme.bodyStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _otpController,
            decoration: AppTheme.textFieldDecoration(
              'کد تایید',
              hint: '۶ رقم',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'لطفاً کد تایید را وارد کنید';
              }
              if (value.length != 6) {
                return 'کد تایید باید ۶ رقم باشد';
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
          const SizedBox(height: 24),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: _isVerifying ? null : _verifyOTP,
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('ورود'),
          ),
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'حساب کاربری ندارید؟',
          style: AppTheme.bodyStyle,
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.goldColor,
          ),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
          child: const Text('ثبت‌نام کنید'),
        ),
      ],
    );
  }
}
