import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/auth/services/supabase_service.dart' as auth_supabase;
import 'package:gymaipro/auth/widgets/profile_completion_widgets.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart';
import 'package:gymaipro/dashboard/services/dashboard_profile_mapper.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/referral_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({
    required this.phoneNumber,
    required this.username,
    super.key,
  });
  final String phoneNumber;
  final String username;

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late AnimationController _progressAnimationController;

  // Step 1: Name and referral code
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _referralCodeFocusNode = FocusNode();
  String? _firstNameError;
  String? _lastNameError;

  // Referral code validation
  bool _isCheckingReferral = false;
  String? _referrerFirstName;
  String? _referrerLastName;
  String? _referralCodeError;

  // Step 2: Gender
  String? _selectedGender;

  // Step 3: Date of birth (Persian)
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  final List<int> _years = [];
  final List<int> _days = [];

  // Step 4: Height
  final _heightController = TextEditingController();
  final _formKey4 = GlobalKey<FormState>();
  final _heightFocusNode = FocusNode();
  String? _heightError;

  // Step 5: Weight
  final _weightController = TextEditingController();
  final _formKey5 = GlobalKey<FormState>();
  final _weightFocusNode = FocusNode();
  String? _weightError;

  // Step 6: Activity Level
  String? _selectedActivityLevel;

  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeYears();
    _updateDays();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnimationController.safeForward();

    // Clear errors when user types
    _firstNameController.addListener(_clearFirstNameError);
    _lastNameController.addListener(_clearLastNameError);
    _heightController.addListener(_clearHeightError);
    _weightController.addListener(_clearWeightError);
    _referralCodeController.addListener(_clearReferralCodeInfo);
  }

  void _clearFirstNameError() {
    if (_firstNameError != null) {
      setState(() => _firstNameError = null);
    }
  }

  void _clearLastNameError() {
    if (_lastNameError != null) {
      setState(() => _lastNameError = null);
    }
  }

  void _clearHeightError() {
    if (_heightError != null) {
      setState(() => _heightError = null);
    }
  }

  void _clearWeightError() {
    if (_weightError != null) {
      setState(() => _weightError = null);
    }
  }

  void _clearReferralCodeInfo() {
    setState(() {
      if (_referrerFirstName != null ||
          _referrerLastName != null ||
          _referralCodeError != null) {
        _referrerFirstName = null;
        _referrerLastName = null;
        _referralCodeError = null;
      }
    });
  }

  void _initializeYears() {
    final now = Jalali.now();
    for (int year = now.year - 100; year <= now.year; year++) {
      _years.add(year);
    }
    _years.sort((a, b) => b.compareTo(a));
  }

  void _updateDays() {
    if (_selectedYear != null && _selectedMonth != null) {
      _days.clear();
      final daysInMonth = _getDaysInMonth(_selectedYear!, _selectedMonth!);
      for (int day = 1; day <= daysInMonth; day++) {
        _days.add(day);
      }
      if (_selectedDay != null && _selectedDay! > daysInMonth) {
        _selectedDay = null;
      }
    }
  }

  int _getDaysInMonth(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    return Jalali(year).isLeapYear() ? 30 : 29;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _referralCodeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _referralCodeFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _pageController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // بررسی فیلدها و انتقال فوکوس به فیلد بعدی به جای نمایش ارور
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      if (firstName.isEmpty) {
        // اگر نام خالی است، فوکوس به فیلد نام
        _firstNameFocusNode.requestFocus();
        setState(() {
          _firstNameError = 'لطفاً نام خود را وارد کنید';
        });
      } else if (lastName.isEmpty) {
        // اگر نام خانوادگی خالی است، فوکوس به فیلد نام خانوادگی
        _lastNameFocusNode.requestFocus();
        setState(() {
          _lastNameError = 'لطفاً نام خانوادگی خود را وارد کنید';
        });
      } else {
        // هر دو فیلد پر هستند، به step بعدی برو
        _goToStep(1);
      }
    } else if (_currentStep == 1) {
      if (_selectedGender != null) {
        _goToStep(2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً جنسیت خود را انتخاب کنید')),
        );
      }
    } else if (_currentStep == 2) {
      if (_selectedYear != null &&
          _selectedMonth != null &&
          _selectedDay != null) {
        _goToStep(3);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً تاریخ تولد خود را کامل کنید')),
        );
      }
    } else if (_currentStep == 3) {
      // بررسی فیلد قد و انتقال فوکوس به جای نمایش ارور
      final height = _heightController.text.trim();
      if (height.isEmpty) {
        _heightFocusNode.requestFocus();
        setState(() {
          _heightError = 'لطفاً قد خود را وارد کنید';
        });
      } else {
        _goToStep(4);
      }
    } else if (_currentStep == 4) {
      // بررسی فیلد وزن و انتقال فوکوس به جای نمایش ارور
      final weight = _weightController.text.trim();
      if (weight.isEmpty) {
        _weightFocusNode.requestFocus();
        setState(() {
          _weightError = 'لطفاً وزن خود را وارد کنید';
        });
      } else {
        _goToStep(5);
      }
    } else if (_currentStep == 5) {
      if (_selectedActivityLevel != null) {
        _completeRegistration();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً میزان فعالیت خود را انتخاب کنید'),
          ),
        );
      }
    }
  }

  void _goToStep(int step) {
    final nextStepNeedsKeyboard = step == 0 || step == 3 || step == 4;

    setState(() {
      _currentStep = step;
    });
    _progressAnimationController.safeReset();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _progressAnimationController.safeForward();

    // در مراحل بدون ورودی متنی کیبورد را ببند؛ در مراحل متنی فوکوس خودکار نگذار، کاربر خودش تپ می‌کند
    if (!nextStepNeedsKeyboard) {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted && _currentStep == step) {
          FocusScope.of(context).unfocus();
        }
      });
    }
  }

  Future<void> _completeRegistration() async {
    if (_selectedActivityLevel == null) return;

    FocusScope.of(context).unfocus();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => RegistrationLoadingScreen(
            phoneNumber: widget.phoneNumber,
            username: widget.username,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            gender: _selectedGender!,
            birthYear: _selectedYear!,
            birthMonth: _selectedMonth!,
            birthDay: _selectedDay!,
            height: _heightController.text.trim(),
            weight: _weightController.text.trim(),
            activityLevel: _selectedActivityLevel!,
            referralCode: _referrerFirstName != null
                ? _referralCodeController.text.trim()
                : '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      // ui-health: keyboard-inset-ok — PageView steps + manual scroll per step
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              color: AppTheme.goldColor,
              size: 24.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'راه‌اندازی پروفایل',
              style: TextStyle(
                fontSize: ResponsiveValue(
                  context,
                  defaultValue: 20.sp,
                  conditionalValues: [
                    Condition.smallerThan(name: MOBILE, value: 18.sp),
                    Condition.largerThan(name: TABLET, value: 22.sp),
                  ],
                ).value,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldColor,
                fontFamily: AppTheme.fontFamily,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.lightBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.goldColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: RepaintBoundary(
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightGradientStart.withValues(alpha: 0.15),
                      AppTheme.lightCardColor,
                      AppTheme.lightGradientEnd.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildProgressIndicator(),
                    Expanded(
                      child: RepaintBoundary(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildNameStep(),
                            _buildGenderStep(),
                            _buildBirthDateStep(),
                            _buildHeightStep(),
                            _buildWeightStep(),
                            _buildActivityLevelStep(),
                          ],
                        ),
                      ),
                    ),
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      child: Column(
        children: [
          Row(
            children: List.generate(6, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.goldColor
                        : AppTheme.lightDividerColor,
                    borderRadius: BorderRadius.circular(3.r),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.5),
                              blurRadius: 4.r,
                              spreadRadius: 1.r,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8.h),
          Text(
            'مرحله ${_currentStep + 1} از 6',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightTextSecondary,
              fontWeight: FontWeight.w500,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        _goToStep(_currentStep - 1);
                      },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: const BorderSide(color: AppTheme.goldColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 16.sp,
                      color: AppTheme.goldColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'قبلی',
                      style: TextStyle(
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 16.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 14.sp),
                            Condition.largerThan(name: TABLET, value: 18.sp),
                          ],
                        ).value,
                        color: AppTheme.goldColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16.w),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _currentStep == 5
                  ? _completeRegistration
                  : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.veryDarkBackground,
                elevation: 4,
                shadowColor: AppTheme.goldColor.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.veryDarkBackground),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 5 ? 'تکمیل ثبت نام' : 'بعدی',
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
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        if (_currentStep != 5) ...[
                          SizedBox(width: 8.w),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16.sp),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return ProfileCardWrapper(
      child: Form(
        key: _formKey1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            _buildStepHeader(
              Icons.person_add_alt_1_rounded,
              'نام و نام خانوادگی',
              'لطفاً نام و نام خانوادگی خود را وارد کنید',
            ),
            SizedBox(height: 24.h),
            _buildTextField(
              controller: _firstNameController,
              focusNode: _firstNameFocusNode,
              label: 'نام',
              hint: 'نام خود را وارد کنید',
              icon: Icons.person_outline,
              errorText: _firstNameError,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _lastNameFocusNode.requestFocus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  setState(
                    () => _firstNameError = 'لطفاً نام خود را وارد کنید',
                  );
                  return _firstNameError;
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildTextField(
              controller: _lastNameController,
              focusNode: _lastNameFocusNode,
              label: 'نام خانوادگی',
              hint: 'نام خانوادگی خود را وارد کنید',
              icon: Icons.person_outline,
              errorText: _lastNameError,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _referralCodeFocusNode.requestFocus(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  setState(
                    () =>
                        _lastNameError = 'لطفاً نام خانوادگی خود را وارد کنید',
                  );
                  return _lastNameError;
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),
            _buildReferralCodeField(),
            if (_referrerFirstName != null && _referrerLastName != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'معرف شما: $_referrerFirstName $_referrerLastName',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.successColor,
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (_referralCodeError != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  _referralCodeError!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.errorColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderStep() {
    return ProfileCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          _buildStepHeader(
            Icons.people_rounded,
            'جنسیت',
            'لطفاً جنسیت خود را انتخاب کنید',
          ),
          SizedBox(height: 32.h),
          GenderOption(
            value: 'male',
            label: 'مرد',
            icon: Icons.male_rounded,
            isSelected: _selectedGender == 'male',
            onTap: () => setState(() => _selectedGender = 'male'),
          ),
          SizedBox(height: 20.h),
          GenderOption(
            value: 'female',
            label: 'زن',
            icon: Icons.female_rounded,
            isSelected: _selectedGender == 'female',
            onTap: () => setState(() => _selectedGender = 'female'),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateStep() {
    return ProfileCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          _buildStepHeader(
            Icons.cake_rounded,
            'تاریخ تولد',
            'لطفاً تاریخ تولد خود را انتخاب کنید',
          ),
          SizedBox(height: 32.h),
          BirthDateTapField(
            selectedYear: _selectedYear,
            selectedMonth: _selectedMonth,
            selectedDay: _selectedDay,
            onDateSelected: (year, month, day) {
              setState(() {
                _selectedYear = year;
                _selectedMonth = month;
                _selectedDay = day;
                _updateDays();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeightStep() {
    return ProfileCardWrapper(
      child: Form(
        key: _formKey4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            _buildStepHeader(
              Icons.height_rounded,
              'قد',
              'لطفاً قد خود را به سانتی‌متر وارد کنید',
            ),
            SizedBox(height: 24.h),
            _buildTextField(
              controller: _heightController,
              focusNode: _heightFocusNode,
              label: 'قد (سانتی‌متر)',
              hint: 'مثال: 175',
              icon: Icons.height,
              suffixText: 'سانتی‌متر',
              errorText: _heightError,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                // فقط اعداد انگلیسی مجاز
                FilteringTextInputFormatter.digitsOnly,
                // محدود کردن طول
                LengthLimitingTextInputFormatter(3),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  setState(() => _heightError = 'لطفاً قد خود را وارد کنید');
                  return _heightError;
                }
                // تبدیل به double برای هماهنگی با ذخیره‌سازی
                final height = double.tryParse(value.trim());
                if (height == null || height < 50 || height > 250) {
                  setState(
                    () => _heightError = 'قد باید بین 50 تا 250 سانتی‌متر باشد',
                  );
                  return _heightError;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightStep() {
    return ProfileCardWrapper(
      child: Form(
        key: _formKey5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),
            _buildStepHeader(
              Icons.monitor_weight_rounded,
              'وزن',
              'لطفاً وزن خود را به کیلوگرم وارد کنید',
            ),
            SizedBox(height: 24.h),
            _buildTextField(
              controller: _weightController,
              focusNode: _weightFocusNode,
              label: 'وزن (کیلوگرم)',
              hint: 'مثال: 70.5',
              icon: Icons.monitor_weight,
              suffixText: 'کیلوگرم',
              errorText: _weightError,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                // فقط اعداد انگلیسی و نقطه اعشار مجاز
                FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                // محدود کردن طول
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  setState(() => _weightError = 'لطفاً وزن خود را وارد کنید');
                  return _weightError;
                }
                final weight = double.tryParse(value.trim());
                if (weight == null || weight < 20 || weight > 300) {
                  setState(
                    () => _weightError = 'وزن باید بین 20 تا 300 کیلوگرم باشد',
                  );
                  return _weightError;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelStep() {
    return ProfileCardWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          _buildStepHeader(
            Icons.fitness_center_rounded,
            'میزان فعالیت',
            'لطفاً میزان فعالیت روزانه خود را انتخاب کنید',
          ),
          SizedBox(height: 32.h),
          ActivityOption(
            value: 'sedentary',
            label: 'بی‌تحرک',
            description: 'کمتر از 30 دقیقه فعالیت در روز',
            icon: Icons.chair_rounded,
            isSelected: _selectedActivityLevel == 'sedentary',
            onTap: () => setState(() => _selectedActivityLevel = 'sedentary'),
          ),
          SizedBox(height: 16.h),
          ActivityOption(
            value: 'light',
            label: 'کم',
            description: '30 دقیقه تا 1 ساعت فعالیت سبک در روز',
            icon: Icons.directions_walk_rounded,
            isSelected: _selectedActivityLevel == 'light',
            onTap: () => setState(() => _selectedActivityLevel = 'light'),
          ),
          SizedBox(height: 16.h),
          ActivityOption(
            value: 'moderate',
            label: 'متوسط',
            description: '1 تا 2 ساعت فعالیت متوسط در روز',
            icon: Icons.directions_run_rounded,
            isSelected: _selectedActivityLevel == 'moderate',
            onTap: () => setState(() => _selectedActivityLevel = 'moderate'),
          ),
          SizedBox(height: 16.h),
          ActivityOption(
            value: 'active',
            label: 'فعال',
            description: '2 تا 3 ساعت فعالیت شدید در روز',
            icon: Icons.fitness_center_rounded,
            isSelected: _selectedActivityLevel == 'active',
            onTap: () => setState(() => _selectedActivityLevel = 'active'),
          ),
          SizedBox(height: 16.h),
          ActivityOption(
            value: 'very_active',
            label: 'خیلی فعال',
            description: 'بیش از 3 ساعت فعالیت شدید در روز',
            icon: Icons.sports_gymnastics_rounded,
            isSelected: _selectedActivityLevel == 'very_active',
            onTap: () => setState(() => _selectedActivityLevel = 'very_active'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22.sp, color: AppTheme.goldColor),
        ),
        SizedBox(height: 10.h),
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveValue(
              context,
              defaultValue: 17.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 16.sp),
                Condition.largerThan(name: TABLET, value: 19.sp),
              ],
            ).value,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTextColor,
            fontFamily: AppTheme.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveValue(
              context,
              defaultValue: 12.sp,
              conditionalValues: [
                Condition.smallerThan(name: MOBILE, value: 11.sp),
                Condition.largerThan(name: TABLET, value: 13.sp),
              ],
            ).value,
            color: AppTheme.lightTextSecondary,
            fontFamily: AppTheme.fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    String? suffixText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    bool isOptional = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return GestureDetector(
      onTap: () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
      },
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(
          color: AppTheme.lightTextColor,
          fontSize: 14.sp,
          fontFamily: AppTheme.fontFamily,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: AppTheme.lightTextSecondary,
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          hintStyle: TextStyle(
            color: AppTheme.lightTextSecondary.withValues(alpha: 0.6),
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          prefixIcon: Icon(
            icon,
            color: isOptional
                ? AppTheme.goldColor.withValues(alpha: 0.7)
                : AppTheme.goldColor,
            size: 20.sp,
          ),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            color: AppTheme.lightTextSecondary,
            fontSize: 12.sp,
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: AppTheme.lightCardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppTheme.lightDividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
              color: isOptional
                  ? AppTheme.goldColor.withValues(alpha: 0.7)
                  : AppTheme.goldColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppTheme.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
          ),
          errorText: errorText,
          errorStyle: TextStyle(
            color: AppTheme.errorColor,
            fontSize: 11.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: 16.h,
          ),
        ),
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  Widget _buildReferralCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _referralCodeController,
                focusNode: _referralCodeFocusNode,
                label: 'کد معرف (اختیاری)',
                hint: 'در صورت داشتن کد معرف وارد کنید',
                icon: Icons.card_giftcard,
                textInputAction: TextInputAction.done,
                isOptional: true,
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              width: 100.w,
              child: ElevatedButton(
                onPressed:
                    _isCheckingReferral ||
                        _referralCodeController.text.trim().isEmpty
                    ? null
                    : _checkReferralCode,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: AppTheme.veryDarkBackground,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isCheckingReferral
                    ? SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.veryDarkBackground,
                          ),
                        ),
                      )
                    : Text(
                        'بررسی',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTheme.fontFamily,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _checkReferralCode() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _referralCodeError = 'لطفاً کد معرف را وارد کنید';
        _referrerFirstName = null;
        _referrerLastName = null;
      });
      return;
    }

    setState(() {
      _isCheckingReferral = true;
      _referralCodeError = null;
      _referrerFirstName = null;
      _referrerLastName = null;
    });

    try {
      final response =
          await ProfileRepository.instance.fetchProfileByUsername(code);

      if (response == null) {
        setState(() {
          _referralCodeError = 'کد معرف معتبر نیست';
          _isCheckingReferral = false;
        });
        return;
      }

      final firstName = response['first_name'] as String?;
      final lastName = response['last_name'] as String?;

      if (firstName == null ||
          firstName.isEmpty ||
          lastName == null ||
          lastName.isEmpty) {
        setState(() {
          _referralCodeError = 'اطلاعات معرف کامل نیست';
          _isCheckingReferral = false;
        });
        return;
      }

      setState(() {
        _referrerFirstName = firstName;
        _referrerLastName = lastName;
        _referralCodeError = null;
        _isCheckingReferral = false;
      });
    } catch (e) {
      setState(() {
        _referralCodeError = 'خطا در بررسی کد معرف';
        _isCheckingReferral = false;
      });
    }
  }
}

// صفحه لودینگ بعد از تکمیل ثبت نام
class RegistrationLoadingScreen extends StatefulWidget {
  const RegistrationLoadingScreen({
    required this.phoneNumber,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthYear,
    required this.birthMonth,
    required this.birthDay,
    required this.height,
    required this.weight,
    required this.activityLevel,
    this.referralCode = '',
    super.key,
  });

  final String phoneNumber;
  final String username;
  final String firstName;
  final String lastName;
  final String gender;
  final int birthYear;
  final int birthMonth;
  final int birthDay;
  final String height;
  final String weight;
  final String activityLevel;
  final String referralCode;

  @override
  State<RegistrationLoadingScreen> createState() =>
      _RegistrationLoadingScreenState();
}

class _RegistrationLoadingScreenState extends State<RegistrationLoadingScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _pipelineTimeout = Duration(seconds: 40);
  static const Duration _authStepTimeout = Duration(seconds: 18);
  static const Duration _stallWatchdogDelay = Duration(seconds: 18);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = true;
  bool _isSuccess = false;
  bool _showRetryActions = false;
  bool _attemptInFlight = false;
  String? _errorMessage;
  Timer? _stallWatchdog;
  StreamSubscription<bool>? _connectivitySub;
  bool _autoRetryScheduled = false;

  String get _normalizedPhone =>
      auth_supabase.SupabaseService().normalizePhoneNumber(widget.phoneNumber);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.safeForward();
    _listenConnectivity();
    unawaited(_completeRegistration());
  }

  void _listenConnectivity() {
    _connectivitySub =
        ConnectivityService.instance.isConnectedStream.listen((online) {
      if (!online || !mounted || _isSuccess || _attemptInFlight) return;
      if (_isLoading || _showRetryActions) {
        _scheduleAutoRetryOnReconnect();
      }
    });
  }

  void _scheduleAutoRetryOnReconnect() {
    if (_autoRetryScheduled) return;
    _autoRetryScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      _autoRetryScheduled = false;
      if (!mounted || _isSuccess || _attemptInFlight) return;
      unawaited(_completeRegistration());
    });
  }

  void _armStallWatchdog() {
    _stallWatchdog?.cancel();
    _stallWatchdog = Timer(_stallWatchdogDelay, () {
      if (!mounted || !_isLoading || _isSuccess) return;
      unawaited(_handleStall());
    });
  }

  void _cancelStallWatchdog() {
    _stallWatchdog?.cancel();
    _stallWatchdog = null;
  }

  Future<void> _completeRegistration() async {
    if (_attemptInFlight || _isSuccess) return;
    _attemptInFlight = true;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _isSuccess = false;
        _showRetryActions = false;
        _errorMessage = null;
      });
    }
    _armStallWatchdog();

    try {
      if (await _tryFinishIfAlreadyRegistered()) return;

      await _runRegistrationPipeline().timeout(_pipelineTimeout);
    } on TimeoutException {
      await _handleStall(
        message:
            'اتصال طولانی شد. اگر ثبت‌نام انجام شده، «ورود به اپ» را بزنید.',
      );
    } catch (e) {
      debugPrint('Error completing registration: $e');
      await _handleStall(
        message: 'خطا در تکمیل ثبت‌نام. دوباره تلاش کنید یا وارد اپ شوید.',
      );
    } finally {
      _cancelStallWatchdog();
      _attemptInFlight = false;
    }
  }

  Future<void> _runRegistrationPipeline() async {
    final supabaseService = auth_supabase.SupabaseService();
    final normalizedPhone = _normalizedPhone;

    debugPrint('=== REGISTRATION LOADING: Starting registration ===');
    debugPrint('Phone: $normalizedPhone');
    debugPrint('Username: ${widget.username}');

    final session = await supabaseService
        .signUpWithPhone(normalizedPhone, widget.username)
        .timeout(_authStepTimeout);

    if (session == null) {
      throw Exception('signUp returned null session');
    }

    debugPrint('=== REGISTRATION LOADING: Registration successful ===');

    await AuthStateService()
        .saveAuthState(session, phoneNumber: normalizedPhone)
        .timeout(const Duration(seconds: 8));

    final jalali = Jalali(
      widget.birthYear,
      widget.birthMonth,
      widget.birthDay,
    );
    final gregorian = jalali.toGregorian();
    final birthDate = gregorian.toDateTime();

    final heightValue = double.tryParse(widget.height.trim());
    final weightValue = double.tryParse(widget.weight.trim());

    if (heightValue == null || weightValue == null) {
      throw Exception('invalid height/weight');
    }

    final updates = <String, dynamic>{
      'first_name': widget.firstName,
      'last_name': widget.lastName,
      'gender': widget.gender,
      'birth_date': birthDate.toIso8601String().split('T')[0],
      'height': heightValue,
      'weight': weightValue,
      'activity_level': widget.activityLevel,
    };

    final success = await _saveProfileCoreDataWithRetry(
      userId: session.user.id,
      normalizedPhone: normalizedPhone,
      updates: updates,
    );

    if (!success) {
      if (await _isRegistrationCompleteInDb(userId: session.user.id)) {
        await _finishSuccess(session, weightValue: weightValue);
        return;
      }
      throw Exception('profile save failed');
    }

    await _finishSuccess(session, weightValue: weightValue);
  }

  Future<bool> _tryFinishIfAlreadyRegistered() async {
    final supabaseService = auth_supabase.SupabaseService();
    final normalizedPhone = _normalizedPhone;

    Session? session = Supabase.instance.client.auth.currentSession;
    if (session != null &&
        await _isRegistrationCompleteInDb(userId: session.user.id)) {
      await AuthStateService()
          .saveAuthState(session, phoneNumber: normalizedPhone)
          .timeout(const Duration(seconds: 8));
      await _finishSuccess(session);
      return true;
    }

    try {
      session = await supabaseService
          .signInWithPhone(normalizedPhone)
          .timeout(_authStepTimeout);
      if (session != null &&
          await _isRegistrationCompleteInDb(userId: session.user.id)) {
        await AuthStateService()
            .saveAuthState(session, phoneNumber: normalizedPhone)
            .timeout(const Duration(seconds: 8));
        await _finishSuccess(session);
        return true;
      }
    } catch (e) {
      debugPrint('REGISTRATION recovery sign-in: $e');
    }

    final profileByPhone = await _fetchProfileByPhone(normalizedPhone);
    if (profileByPhone != null &&
        _rowIndicatesCompleteRegistration(profileByPhone)) {
      try {
        session = await supabaseService
            .signInWithPhone(normalizedPhone)
            .timeout(_authStepTimeout);
        if (session != null) {
          await AuthStateService()
              .saveAuthState(session, phoneNumber: normalizedPhone)
              .timeout(const Duration(seconds: 8));
          await _finishSuccess(session);
          return true;
        }
      } catch (e) {
        debugPrint('REGISTRATION recovery by phone: $e');
      }
    }

    return false;
  }

  Future<Map<String, dynamic>?> _fetchProfileByPhone(String phone) async {
    try {
      return await Supabase.instance.client
          .from('profiles')
          .select('id, username, first_name, last_name, height, weight')
          .eq('phone_number', phone)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('REGISTRATION fetch profile by phone: $e');
      return null;
    }
  }

  bool _rowIndicatesCompleteRegistration(Map<String, dynamic>? row) {
    if (row == null) return false;
    final username = row['username'] as String?;
    if (username == null ||
        username.isEmpty ||
        username.startsWith('user_')) {
      return false;
    }
    final firstName = row['first_name'] as String?;
    if (firstName == null || firstName.trim().isEmpty) return false;
    return row['height'] != null && row['weight'] != null;
  }

  Future<bool> _isRegistrationCompleteInDb({required String userId}) async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('id, username, first_name, last_name, height, weight')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));
      return _rowIndicatesCompleteRegistration(row);
    } catch (e) {
      debugPrint('REGISTRATION profile completeness check: $e');
      return false;
    }
  }

  Future<void> _finishSuccess(
    Session session, {
    double? weightValue,
  }) async {
    final parsedWeight =
        weightValue ?? double.tryParse(widget.weight.trim()) ?? 0;

    _runPostRegistrationTasks(
      userId: session.user.id,
      weightValue: parsedWeight,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = true;
      _showRetryActions = false;
      _errorMessage = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    SimpleProfileService.invalidateCache();
    DashboardCacheService().invalidateDashboard();
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile != null) {
        DashboardCacheService().setProfileData(
          DashboardProfileMapper.fromRaw(profile),
        );
      }
    } catch (e) {
      debugPrint('REGISTRATION: profile prefetch before main: $e');
    }

    if (!mounted) return;
    enterMainAppAfterAuth(context);
  }

  Future<void> _handleStall({String? message}) async {
    if (await _tryFinishIfAlreadyRegistered()) return;

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = false;
      _showRetryActions = true;
      _errorMessage = message ??
          'اتصال قطع شد یا کند است. ثبت‌نام ممکن است انجام شده باشد.';
    });
  }

  Future<void> _onRetryPressed() async {
    await _completeRegistration();
  }

  Future<void> _onVerifyAndEnterApp() async {
    if (_attemptInFlight) return;
    _attemptInFlight = true;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _showRetryActions = false;
        _errorMessage = null;
      });
    }
    try {
      final recovered = await _tryFinishIfAlreadyRegistered();
      if (!recovered && mounted) {
        setState(() {
          _isLoading = false;
          _showRetryActions = true;
          _errorMessage =
              'هنوز نتوانستیم حساب را پیدا کنیم. اتصال را چک کنید و دوباره تلاش کنید.';
        });
      }
    } finally {
      _attemptInFlight = false;
    }
  }

  Future<bool> _saveProfileCoreDataWithRetry({
    required String userId,
    required String normalizedPhone,
    required Map<String, dynamic> updates,
  }) async {
    final client = Supabase.instance.client;
    final emailForAuth =
        '${normalizedPhone.replaceAll(RegExp(r'\D'), '')}@gym.ai';
    final cleanUpdates = Map<String, dynamic>.from(updates)
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final updateResponse = await client
            .from('profiles')
            .update(cleanUpdates)
            .eq('id', userId)
            .select('id')
            .maybeSingle()
            .timeout(const Duration(seconds: 8));

        if (updateResponse != null) {
          SimpleProfileService.invalidateCache();
          return true;
        }

        final upsertPayload = <String, dynamic>{
          'id': userId,
          'username': widget.username,
          'phone_number': normalizedPhone,
          'email': emailForAuth,
          'role': 'athlete',
          ...cleanUpdates,
        };

        final upsertResponse = await client
            .from('profiles')
            .upsert(upsertPayload, onConflict: 'id')
            .select('id')
            .maybeSingle()
            .timeout(const Duration(seconds: 8));

        if (upsertResponse != null) {
          SimpleProfileService.invalidateCache();
          return true;
        }
      } catch (e) {
        debugPrint(
          '⚠️ REGISTRATION: profile save attempt $attempt failed: $e',
        );
      }

      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 350 * attempt));
      }
    }

    return false;
  }

  void _runPostRegistrationTasks({
    required String userId,
    required double weightValue,
  }) {
    unawaited(
      Future<void>(() async {
        try {
          await WeeklyWeightService.recordWeeklyWeight(userId, weightValue);
        } catch (e) {
          debugPrint('⚠️ Weekly weight post-task failed: $e');
        }
      }),
    );

    if (widget.referralCode.trim().isNotEmpty) {
      unawaited(
        Future<void>(() async {
          try {
            final referralService = ReferralService();
            final success = await referralService.registerReferral(
              referrerUsername: widget.referralCode.trim(),
              newUserId: userId,
            );
            if (success) {
              debugPrint('✅ Referral code registered: ${widget.referralCode}');
            } else {
              debugPrint(
                '⚠️ Failed to register referral code: ${widget.referralCode}',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Error registering referral code: $e');
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    _cancelStallWatchdog();
    _connectivitySub?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.goldColor,
                    size: 80.sp,
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  _isLoading
                      ? 'در حال تکمیل ثبت نام...'
                      : _isSuccess
                      ? 'ثبت نام با موفقیت انجام شد!'
                      : 'خطا در ثبت نام',
                  style: TextStyle(
                    fontSize: ResponsiveValue(
                      context,
                      defaultValue: 24.sp,
                      conditionalValues: [
                        Condition.smallerThan(name: MOBILE, value: 20.sp),
                        Condition.largerThan(name: TABLET, value: 28.sp),
                      ],
                    ).value,
                    fontWeight: FontWeight.bold,
                    color: _isSuccess
                        ? AppTheme.goldColor
                        : _isLoading
                        ? AppTheme.goldColor
                        : AppTheme.errorColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                SizedBox(height: 16.h),
                if (_isLoading)
                  Text(
                    'لطفاً صبر کنید...',
                    style: TextStyle(
                      fontSize: ResponsiveValue(
                        context,
                        defaultValue: 16.sp,
                        conditionalValues: [
                          Condition.smallerThan(name: MOBILE, value: 14.sp),
                          Condition.largerThan(name: TABLET, value: 18.sp),
                        ],
                      ).value,
                      color: AppTheme.lightTextSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  )
                else if (_isSuccess)
                  Text(
                    'در حال ورود به داشبورد...',
                    style: TextStyle(
                      fontSize: ResponsiveValue(
                        context,
                        defaultValue: 16.sp,
                        conditionalValues: [
                          Condition.smallerThan(name: MOBILE, value: 14.sp),
                          Condition.largerThan(name: TABLET, value: 18.sp),
                        ],
                      ).value,
                      color: AppTheme.lightTextSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 16.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 14.sp),
                            Condition.largerThan(name: TABLET, value: 18.sp),
                          ],
                        ).value,
                        color: AppTheme.errorColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_showRetryActions) ...[
                  SizedBox(height: 24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _attemptInFlight ? null : _onVerifyAndEnterApp,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.goldColor,
                              foregroundColor: AppTheme.onGoldColor,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              'ورود به اپ',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _attemptInFlight ? null : _onRetryPressed,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.goldColor,
                              side: BorderSide(
                                color: AppTheme.goldColor.withValues(alpha: 0.6),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              'تلاش مجدد',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 32.h),
                if (_isLoading || _isSuccess)
                  SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.goldColor,
                      ),
                    ),
                  )
                else if (!_showRetryActions)
                  Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
