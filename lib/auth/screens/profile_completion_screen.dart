import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/auth/services/supabase_service.dart' as auth_supabase;
import 'package:gymaipro/theme/app_theme.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/services/referral_service.dart';
import 'package:gymaipro/utils/animation_utils.dart';
import 'package:gymaipro/utils/widget_safety_utils.dart';
import 'package:gymaipro/auth/widgets/profile_completion_widgets.dart';

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

  bool _isLoading = false;

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
          icon: Icon(
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
                  side: BorderSide(color: AppTheme.goldColor, width: 1.5),
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
                foregroundColor: Colors.black,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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
          fontSize: 16.sp,
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
            borderSide: BorderSide(color: AppTheme.lightDividerColor),
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
                  foregroundColor: Colors.black,
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
                            Colors.black,
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
      final client = Supabase.instance.client;
      final response = await client
          .from('profiles')
          .select('first_name, last_name, username')
          .eq('username', code)
          .maybeSingle();

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = true;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.safeForward();
    _completeRegistration();
  }

  Future<void> _completeRegistration() async {
    try {
      final supabaseService = auth_supabase.SupabaseService();
      final normalizedPhone = supabaseService.normalizePhoneNumber(
        widget.phoneNumber,
      );

      debugPrint('=== REGISTRATION LOADING: Starting registration ===');
      debugPrint('Phone: $normalizedPhone');
      debugPrint('Username: ${widget.username}');

      final session = await supabaseService.signUpWithPhone(
        normalizedPhone,
        widget.username,
      );

      if (session == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = false;
            _errorMessage = 'خطا در ثبت نام. لطفاً دوباره تلاش کنید';
          });
          await Future<void>.delayed(const Duration(seconds: 3));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
        return;
      }

      debugPrint('=== REGISTRATION LOADING: Registration successful ===');

      // Save auth state + phone for consistent profile fallback (login/signup behave the same)
      await AuthStateService().saveAuthState(
        session,
        phoneNumber: normalizedPhone,
      );

      final jalali = Jalali(
        widget.birthYear,
        widget.birthMonth,
        widget.birthDay,
      );
      final gregorian = jalali.toGregorian();
      final birthDate = gregorian.toDateTime();

      // تبدیل امن قد و وزن به double
      final heightValue = double.tryParse(widget.height.trim());
      final weightValue = double.tryParse(widget.weight.trim());

      if (heightValue == null || weightValue == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = false;
            _errorMessage = 'خطا در تبدیل مقادیر قد و وزن';
          });
          await Future<void>.delayed(const Duration(seconds: 3));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
        return;
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

      final success = await SimpleProfileService.updateProfile(updates);

      if (!success) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = false;
            _errorMessage = 'خطا در ذخیره اطلاعات';
          });
          await Future<void>.delayed(const Duration(seconds: 3));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
        return;
      }

      // Prefer profile id for user-scoped tables (legacy-safe). Fallback to auth id.
      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = (profile?['id'] as String?)?.trim();
      final userId = profileId?.isNotEmpty == true
          ? profileId
          : Supabase.instance.client.auth.currentUser?.id;

      try {
        // استفاده از weightValue که قبلاً parse شده است
        if (userId != null) {
          await WeeklyWeightService.recordWeeklyWeight(userId, weightValue);
        }
      } catch (_) {}

      // ثبت کد معرف اگر وارد شده باشد
      if (widget.referralCode.isNotEmpty && userId != null) {
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
      }

      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
          _isSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        WidgetSafetyUtils.safePushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error completing registration: $e');
      if (mounted) {
        WidgetSafetyUtils.safeSetState(this, () {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = 'خطا: $e';
        });
        await Future<void>.delayed(const Duration(seconds: 3));
        WidgetSafetyUtils.safePop(context);
      }
    }
  }

  @override
  void dispose() {
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
                        : Colors.red,
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
                  Text(
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
                      color: Colors.red,
                      fontFamily: AppTheme.fontFamily,
                    ),
                    textAlign: TextAlign.center,
                  ),
                SizedBox(height: 32.h),
                if (_isLoading || _isSuccess)
                  SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.goldColor,
                      ),
                    ),
                  )
                else
                  Icon(Icons.error_outline, color: Colors.red, size: 40.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
