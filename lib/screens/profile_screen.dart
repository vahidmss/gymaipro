import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // کلید اصلی فرم برای تب اطلاعات پایه
  final _formKey = GlobalKey<FormState>();
  // کلیدهای جداگانه برای سایر تب‌ها
  final _bodyFormKey = GlobalKey<FormState>();
  final _trainingFormKey = GlobalKey<FormState>();
  final _healthFormKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isProfileComplete = false;
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Map<String, dynamic> _profileData = {
    'first_name': '',
    'last_name': '',
    'avatar_url': '',
    'bio': '',
    'birth_date': null,
    'height': '',
    'weight': '',
    'arm_circumference': '',
    'chest_circumference': '',
    'waist_circumference': '',
    'hip_circumference': '',
    'experience_level': '',
    'preferred_training_days': <String>[],
    'preferred_training_time': '',
    'fitness_goals': <String>[],
    'medical_conditions': <String>[],
    'dietary_preferences': <String>[],
    'gender': 'male',
    'weight_history': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _loadProfileData();

    // Start animations after loading
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final supabaseService = SupabaseService();
        final profile = await supabaseService.getProfileByAuthId();

        if (profile != null && mounted) {
          setState(() {
            _profileData.addAll({
              'first_name': profile.firstName ?? '',
              'last_name': profile.lastName ?? '',
              'avatar_url': profile.avatarUrl ?? '',
              'bio': profile.bio ?? '',
              'birth_date': profile.birthDate?.toIso8601String() ?? '',
              'height': profile.height?.toString() ?? '',
              'weight': profile.weight?.toString() ?? '',
              'arm_circumference': profile.armCircumference?.toString() ?? '',
              'chest_circumference':
                  profile.chestCircumference?.toString() ?? '',
              'waist_circumference':
                  profile.waistCircumference?.toString() ?? '',
              'hip_circumference': profile.hipCircumference?.toString() ?? '',
              'experience_level': profile.experienceLevel ?? '',
              'preferred_training_days':
                  profile.preferredTrainingDays ?? <String>[],
              'preferred_training_time': profile.preferredTrainingTime ?? '',
              'fitness_goals': profile.fitnessGoals ?? <String>[],
              'medical_conditions': profile.medicalConditions ?? <String>[],
              'dietary_preferences': profile.dietaryPreferences ?? <String>[],
              'gender': profile.gender ?? 'male',
              'weight_history': profile.weightHistory ?? [],
            });

            // اطمینان از اینکه مقادیر dropdown ها معتبر هستند
            if (!AppConfig.experienceLevels
                .containsKey(_profileData['experience_level'])) {
              _profileData['experience_level'] = '';
            }
            if (!AppConfig.trainingTimes
                .containsKey(_profileData['preferred_training_time'])) {
              _profileData['preferred_training_time'] = '';
            }

            _isProfileComplete = _checkProfileCompletion();
            _isLoading = false;

            print('داده‌های پروفایل با موفقیت بارگذاری شدند:');
            print('تاریخ تولد: ${_profileData['birth_date']}');
            print('وزن: ${_profileData['weight']}');
            print('قد: ${_profileData['height']}');
          });
        }
      }
    } catch (e) {
      print('خطا در بارگذاری اطلاعات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری اطلاعات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _checkProfileCompletion() {
    final requiredFields = [
      'first_name',
      'last_name',
      'height',
      'weight',
      'birth_date',
      'experience_level',
      'gender',
    ];

    return requiredFields.every((field) =>
        _profileData[field] != null &&
        _profileData[field].toString().isNotEmpty);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
      });
      // TODO: Upload image to storage and update profile
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final supabaseService = SupabaseService();

          // بررسی اینکه آیا وزن جدیدی وارد شده است یا خیر
          final String? newWeightStr = _profileData['weight']?.toString();
          final double? newWeight =
              newWeightStr != null && newWeightStr.isNotEmpty
                  ? double.tryParse(newWeightStr)
                  : null;

          // بررسی اینکه آیا قبلا رکورد وزنی ثبت شده است
          final hasWeightRecord = _profileData['weight_history'] != null &&
              (_profileData['weight_history'] as List<dynamic>).isNotEmpty;

          print('ثبت وزن: نمایش وضعیت قبل از ذخیره:');
          print('وزن جدید: $newWeight');
          print('وضعیت قبلی وزن: $hasWeightRecord');
          print(
              'تعداد رکوردهای موجود: ${(_profileData['weight_history'] as List?)?.length ?? 0}');

          // تبدیل فیلدهای عددی و تاریخ به مقدار مناسب
          final Map<String, dynamic> cleanProfileData = Map.from(_profileData);
          for (final key in [
            'height',
            'arm_circumference',
            'chest_circumference',
            'waist_circumference',
            'hip_circumference',
          ]) {
            final value = cleanProfileData[key];
            cleanProfileData[key] =
                (value != null && value.toString().trim().isNotEmpty)
                    ? num.tryParse(value.toString())
                    : null;
          }
          // تاریخ تولد
          final birthDate = cleanProfileData['birth_date'];
          cleanProfileData['birth_date'] =
              (birthDate != null && birthDate.toString().trim().isNotEmpty)
                  ? birthDate.toString().split('T')[0] // فقط بخش تاریخ
                  : null;

          // اگر وزن جدید داریم و قبلا رکورد وزنی ثبت نشده، آن را به weight_records اضافه کنیم
          if (newWeight != null && !hasWeightRecord) {
            print('ثبت وزن اولیه: $newWeight');
            await supabaseService.addWeightRecord(user.id, newWeight);

            // وزن را از cleanProfileData حذف می‌کنیم چون دیگر نباید در پروفایل ذخیره شود
            cleanProfileData.remove('weight');
            cleanProfileData.remove(
                'weight_history'); // این را هم حذف می‌کنیم چون نباید در پروفایل ذخیره شود

            print('وزن اولیه به weight_records اضافه شد: $newWeight');
          } else if (hasWeightRecord) {
            // اگر قبلا رکورد وزنی داریم، وزن را از پروفایل حذف کنیم
            cleanProfileData.remove('weight');
            cleanProfileData.remove(
                'weight_history'); // این را هم حذف می‌کنیم چون نباید در پروفایل ذخیره شود
            print('وزن قبلاً ثبت شده - از پروفایل حذف شد');
          }

          await supabaseService.updateProfile(user.id, cleanProfileData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('اطلاعات با موفقیت ذخیره شد')),
            );
            setState(() {
              _isProfileComplete = _checkProfileCompletion();
            });

            // بارگذاری مجدد داده‌های پروفایل
            _loadProfileData();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در ذخیره اطلاعات: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _saveProfileData() async {
    // بررسی معتبر بودن فرم فعال براساس تب جاری
    bool isValid = false;
    switch (_tabController.index) {
      case 0:
        isValid = _formKey.currentState?.validate() ?? false;
        break;
      case 1:
        isValid = _bodyFormKey.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _trainingFormKey.currentState?.validate() ?? false;
        break;
      case 3:
        isValid = _healthFormKey.currentState?.validate() ?? false;
        break;
    }

    if (!isValid) {
      return;
    }

    // ذخیره مقادیر فرم فعال
    switch (_tabController.index) {
      case 0:
        _formKey.currentState?.save();
        break;
      case 1:
        _bodyFormKey.currentState?.save();
        break;
      case 2:
        _trainingFormKey.currentState?.save();
        break;
      case 3:
        _healthFormKey.currentState?.save();
        break;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final supabaseService = SupabaseService();

        // بررسی اینکه آیا وزن جدیدی وارد شده است یا خیر
        final String? newWeightStr = _profileData['weight']?.toString();
        final double? newWeight =
            newWeightStr != null && newWeightStr.isNotEmpty
                ? double.tryParse(newWeightStr)
                : null;

        // بررسی اینکه آیا قبلا رکورد وزنی ثبت شده است
        final hasWeightRecord = _profileData['weight_history'] != null &&
            (_profileData['weight_history'] as List<dynamic>).isNotEmpty;

        print('ثبت وزن: نمایش وضعیت قبل از ذخیره:');
        print('وزن جدید: $newWeight');
        print('وضعیت قبلی وزن: $hasWeightRecord');
        print(
            'تعداد رکوردهای موجود: ${(_profileData['weight_history'] as List?)?.length ?? 0}');

        // تبدیل فیلدهای عددی و تاریخ به مقدار مناسب
        final Map<String, dynamic> cleanProfileData = Map.from(_profileData);

        // حذف فیلدهای اضافی که در جدول profiles وجود ندارند
        cleanProfileData.remove('weight_history');

        // اطمینان از وجود نام و نام خانوادگی
        // اگر رشته خالی باشند، آنها را حذف نمی‌کنیم زیرا باید ذخیره شوند

        // تبدیل مقادیر عددی
        for (final key in [
          'height',
          'arm_circumference',
          'chest_circumference',
          'waist_circumference',
          'hip_circumference',
        ]) {
          final value = cleanProfileData[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            cleanProfileData[key] = num.tryParse(value.toString());
          } else {
            // حذف فیلدهای خالی به جای ارسال null یا رشته خالی
            cleanProfileData.remove(key);
          }
        }

        // بررسی صحت وزن
        if (newWeight != null) {
          // اگر وزن جدید داریم و قبلا رکورد وزنی ثبت نشده، آن را به weight_records اضافه کنیم
          if (!hasWeightRecord) {
            print('ثبت وزن اولیه: $newWeight');
            await supabaseService.addWeightRecord(user.id, newWeight);
            print('وزن اولیه به weight_records اضافه شد: $newWeight');
          }

          // وزن را در پروفایل هم نگه می‌داریم برای نمایش
          cleanProfileData['weight'] = newWeight;
        } else if (cleanProfileData['weight'] != null &&
            cleanProfileData['weight'].toString().trim().isEmpty) {
          // اگر رشته خالی باشد، آن را حذف می‌کنیم
          cleanProfileData.remove('weight');
        }

        // تاریخ تولد
        final birthDate = cleanProfileData['birth_date'];
        if (birthDate != null && birthDate.toString().trim().isNotEmpty) {
          cleanProfileData['birth_date'] =
              birthDate.toString().split('T')[0]; // فقط بخش تاریخ
        } else {
          cleanProfileData.remove('birth_date');
        }

        print('تاریخ تولد برای ذخیره: ${cleanProfileData['birth_date']}');

        // حذف فیلدهای خالی از لیست‌ها
        if (cleanProfileData['preferred_training_days'] != null &&
            (cleanProfileData['preferred_training_days'] as List).isEmpty) {
          cleanProfileData.remove('preferred_training_days');
        }

        if (cleanProfileData['fitness_goals'] != null &&
            (cleanProfileData['fitness_goals'] as List).isEmpty) {
          cleanProfileData.remove('fitness_goals');
        }

        if (cleanProfileData['medical_conditions'] != null &&
            (cleanProfileData['medical_conditions'] as List).isEmpty) {
          cleanProfileData.remove('medical_conditions');
        }

        if (cleanProfileData['dietary_preferences'] != null &&
            (cleanProfileData['dietary_preferences'] as List).isEmpty) {
          cleanProfileData.remove('dietary_preferences');
        }

        // چاپ داده‌های نهایی برای ارسال
        print('داده‌های نهایی برای ارسال به سرور:');
        print(cleanProfileData);

        // ذخیره اطلاعات پروفایل
        await supabaseService.updateProfile(user.id, cleanProfileData);
        print('پروفایل با موفقیت بروزرسانی شد');

        if (mounted) {
          // بارگذاری مجدد داده‌های پروفایل برای اطمینان از بروز بودن
          await _loadProfileData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'اطلاعات با موفقیت ذخیره شدند',
                style: GoogleFonts.vazirmatn(),
              ),
              backgroundColor: Colors.green,
            ),
          );

          setState(() {
            _isProfileComplete = _checkProfileCompletion();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('خطا در ذخیره پروفایل: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ذخیره اطلاعات: $e',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'پروفایل من',
          style: GoogleFonts.vazirmatn(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Profile Completion Indicator
        if (!_isProfileComplete)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildProfileCompletionIndicator(),
          ),

        // Avatar & Name - Now centered
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              // Centered Avatar
              Center(
                child: _buildSimpleAvatar(),
              ),
              const SizedBox(height: 16),
              // Name and Bio
              Center(
                child: Column(
                  children: [
                    Text(
                      "${_profileData['first_name']} ${_profileData['last_name']}",
                      style: GoogleFonts.vazirmatn(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (_profileData['bio']?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _profileData['bio'],
                          style: GoogleFonts.vazirmatn(
                            textStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stats Cards
        _buildStatsCards(),

        // Tab Bar & Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTabBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabBasicInfo(),
                        _buildTabPhysicalInfo(),
                        _buildTabTrainingInfo(),
                        _buildTabHealthInfo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          gradient: const LinearGradient(
            colors: [
              AppTheme.goldColor,
              Color(0xFFD4AF37),
            ],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        unselectedLabelStyle: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(
            fontSize: 13,
          ),
        ),
        dividerColor: Colors.transparent,
        indicatorPadding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        tabs: const [
          Tab(text: 'اطلاعات'),
          Tab(text: 'بدن'),
          Tab(text: 'تمرینات'),
          Tab(text: 'سلامت'),
        ],
      ),
    );
  }

  Widget _buildSimpleAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.goldColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          image: _getProfileImage(),
          color: const Color(0xFF1A1A1A),
        ),
        child: _avatarFile == null &&
                ((_profileData['avatar_url'] as String?)?.isEmpty ?? true)
            ? const Icon(Icons.person, size: 45, color: AppTheme.goldColor)
            : null,
      ),
    );
  }

  DecorationImage? _getProfileImage() {
    if (_avatarFile != null) {
      return DecorationImage(
        image: FileImage(_avatarFile!),
        fit: BoxFit.cover,
      );
    } else if (_profileData['avatar_url'] != null &&
        (_profileData['avatar_url'] as String).isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_profileData['avatar_url'] as String),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildProfileCompletionIndicator() {
    final requiredFields = [
      'first_name',
      'last_name',
      'height',
      'weight',
      'birth_date',
      'experience_level',
      'gender',
    ];

    int completedFields = 0;
    for (final field in requiredFields) {
      if (_profileData[field] != null &&
          _profileData[field].toString().isNotEmpty) {
        completedFields++;
      }
    }

    final completionPercentage =
        (completedFields / requiredFields.length) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تکمیل پروفایل',
              style: GoogleFonts.vazirmatn(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${completionPercentage.toInt()}%',
              style: GoogleFonts.vazirmatn(
                textStyle: const TextStyle(
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completionPercentage / 100,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildTabBasicInfo() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoSection(),
            const SizedBox(height: 16),
            _buildApplyButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('اطلاعات شخصی'),
          const SizedBox(height: 16),

          // First and Last Name
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'نام',
                  'first_name',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'نام الزامی است' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  'نام خانوادگی',
                  'last_name',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'نام خانوادگی الزامی است' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gender Selection
          _buildGenderSelector(),
          const SizedBox(height: 16),

          // Bio
          _buildTextField(
            'درباره من',
            'bio',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Date Picker
          _buildDatePicker(),
        ],
      ),
    );
  }

  Widget _buildTabPhysicalInfo() {
    final hasWeightRecord = _profileData['weight_history'] != null &&
        (_profileData['weight_history'] as List<dynamic>).isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _bodyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('اندازه‌گیری‌های بدن'),
            const SizedBox(height: 16),

            // Height and Weight
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'قد (سانتی‌متر)',
                    'height',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'قد الزامی است' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: hasWeightRecord
                      ? _buildReadOnlyWeightField()
                      : _buildTextField(
                          'وزن (کیلوگرم)',
                          'weight',
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'وزن الزامی است' : null,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionSubtitle('اندازه‌گیری‌های دقیق'),
            const SizedBox(height: 16),

            // Arm and Chest
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'دور بازو (سانتی‌متر)',
                    'arm_circumference',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'دور سینه (سانتی‌متر)',
                    'chest_circumference',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Waist and Hip
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'دور کمر (سانتی‌متر)',
                    'waist_circumference',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'دور باسن (سانتی‌متر)',
                    'hip_circumference',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            if (hasWeightRecord) ...[
              const SizedBox(height: 16),
              _buildInfoNote(
                  'برای ثبت وزن جدید لطفاً به بخش نمودار وزن در داشبورد مراجعه کنید.'),
            ],

            const SizedBox(height: 24),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabTrainingInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _trainingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ترجیحات تمرینی'),
            const SizedBox(height: 16),

            // Experience Level
            _buildDropdown(
              'سطح تجربه',
              'experience_level',
              AppConfig.experienceLevels,
              validator: (value) => value == null || value.isEmpty
                  ? 'انتخاب سطح تجربه الزامی است'
                  : null,
            ),
            const SizedBox(height: 24),

            _buildSectionSubtitle('اهداف تناسب اندام'),
            const SizedBox(height: 12),
            _buildMultiSelect(
              'fitness_goals',
              AppConfig.fitnessGoals,
            ),
            const SizedBox(height: 24),

            _buildSectionSubtitle('روزهای ترجیحی تمرین'),
            const SizedBox(height: 12),
            _buildMultiSelect(
              'preferred_training_days',
              AppConfig.weekDays,
            ),
            const SizedBox(height: 24),

            _buildDropdown(
              'زمان ترجیحی تمرین',
              'preferred_training_time',
              AppConfig.trainingTimes,
            ),

            const SizedBox(height: 24),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHealthInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _healthFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('سلامت و تغذیه'),
            const SizedBox(height: 16),
            _buildSectionSubtitle('شرایط پزشکی خاص'),
            const SizedBox(height: 12),
            _buildMultiSelect(
              'medical_conditions',
              AppConfig.medicalConditions,
            ),
            const SizedBox(height: 24),
            _buildSectionSubtitle('ترجیحات غذایی'),
            const SizedBox(height: 12),
            _buildMultiSelect(
              'dietary_preferences',
              AppConfig.dietaryPreferences,
            ),
            const SizedBox(height: 20),
            _buildInfoNote(
              'مصرف روزانه ۸ لیوان آب و ۳۰ دقیقه پیاده‌روی را فراموش نکنید.',
              icon: Icons.tips_and_updates_outlined,
            ),
            const SizedBox(height: 24),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  // Clean UI Components

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.vazirmatn(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionSubtitle(String title) {
    return Text(
      title,
      style: GoogleFonts.vazirmatn(
        textStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String field, {
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.vazirmatn(
            textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.goldColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(color: Colors.white),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        initialValue: _profileData[field]?.toString() ?? '',
        onSaved: (value) => _profileData[field] = value,
        validator: validator,
        cursorColor: AppTheme.goldColor,
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        // Get current date if birth date is not set
        String? birthDateStr = _profileData['birth_date'];
        DateTime initialGregorianDate;
        if (birthDateStr != null && birthDateStr.isNotEmpty) {
          try {
            initialGregorianDate = DateTime.parse(birthDateStr);
          } catch (_) {
            initialGregorianDate =
                DateTime.now().subtract(const Duration(days: 365 * 20));
          }
        } else {
          initialGregorianDate =
              DateTime.now().subtract(const Duration(days: 365 * 20));
        }

        // Convert to Jalali date
        Jalali initialJalaliDate = Jalali.fromDateTime(initialGregorianDate);

        // Show Persian date picker dialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return _buildPersianDatePickerDialog(initialJalaliDate);
          },
        ).then((_) {
          // بعد از بسته شدن دیالوگ، تغییرات را اعمال می‌کنیم
          setState(() {
            // state بروز می‌شود
          });
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.goldColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاریخ تولد',
                      style: GoogleFonts.vazirmatn(
                        textStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_profileData['birth_date'] != null &&
                        _profileData['birth_date'].toString().isNotEmpty)
                      _buildPersianDate(_profileData['birth_date'])
                    else
                      Text(
                        'انتخاب تاریخ تولد',
                        style: GoogleFonts.vazirmatn(
                          textStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
            if (_profileData['birth_date'] != null &&
                _profileData['birth_date'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildAgeInfo(_profileData['birth_date']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersianDatePickerDialog(Jalali initialDate) {
    Jalali selectedDate = initialDate;
    bool yearView = true; // Start with year selection view
    bool monthView = false;

    final persianMonthNames = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];

    int startYear = 1320; // 1941 in Persian calendar
    int endYear = Jalali.now().year;
    int selectedYear = selectedDate.year;
    int selectedMonth = selectedDate.month;

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'انتخاب تاریخ تولد',
                      style: GoogleFonts.vazirmatn(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),

                // Year selection view
                if (yearView)
                  SizedBox(
                    height: 300,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: endYear - startYear + 1,
                      itemBuilder: (context, index) {
                        final year = endYear - index;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedYear = year;
                              yearView = false;
                              monthView = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selectedYear == year
                                  ? AppTheme.goldColor
                                  : const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                year.toString(),
                                style: GoogleFonts.vazirmatn(
                                  textStyle: TextStyle(
                                    color: selectedYear == year
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Month selection view
                if (monthView)
                  Column(
                    children: [
                      Text(
                        'سال: $selectedYear',
                        style: GoogleFonts.vazirmatn(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final month = index + 1;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedMonth = month;
                                  selectedDate =
                                      Jalali(selectedYear, selectedMonth, 1);
                                  monthView = false;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedMonth == month
                                      ? AppTheme.goldColor
                                      : const Color(0xFF252525),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    persianMonthNames[index],
                                    style: GoogleFonts.vazirmatn(
                                      textStyle: TextStyle(
                                        color: selectedMonth == month
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            yearView = true;
                            monthView = false;
                          });
                        },
                        child: Text(
                          'بازگشت به انتخاب سال',
                          style: GoogleFonts.vazirmatn(
                            textStyle: const TextStyle(
                              color: AppTheme.goldColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // Day selection view (when neither year nor month view is active)
                if (!yearView && !monthView)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'سال: $selectedYear - ماه: ${persianMonthNames[selectedMonth - 1]}',
                            style: GoogleFonts.vazirmatn(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Days of week header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
                            .map((day) => Text(
                                  day,
                                  style: GoogleFonts.vazirmatn(
                                    textStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      // Calendar days grid
                      _buildDaysGrid(selectedDate, (day) {
                        final Jalali newSelectedDate =
                            Jalali(selectedYear, selectedMonth, day);
                        final DateTime gregorianDate =
                            newSelectedDate.toDateTime();
                        final String isoDate = gregorianDate.toIso8601String();

                        // بستن دیالوگ
                        Navigator.of(context).pop();

                        // آپدیت state والد با تاریخ جدید
                        this.setState(() {
                          _profileData['birth_date'] = isoDate;
                          // بلافاصله فرم را validate کنیم تا کاربر بازخورد فوری ببیند
                          _formKey.currentState?.validate();
                        });

                        // این لاگ برای دیباگ
                        print('تاریخ تولد جدید انتخاب شد: $isoDate');
                      }),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                monthView = true;
                              });
                            },
                            child: Text(
                              'بازگشت به انتخاب ماه',
                              style: GoogleFonts.vazirmatn(
                                textStyle: const TextStyle(
                                  color: AppTheme.goldColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaysGrid(Jalali jalaliDate, Function(int) onDaySelected) {
    // Get number of days in the month
    int daysInMonth = jalaliDate.monthLength;

    // Get the weekday of the first day of the month (0 = Saturday, 6 = Friday in Jalali)
    int firstDayWeekday = Jalali(jalaliDate.year, jalaliDate.month, 1).weekDay;

    // Create a grid with empty slots for days before the first day of the month
    // Changed to use growable list
    List<int?> days = List<int?>.filled(firstDayWeekday, null, growable: true);

    // Add the actual days of the month
    days.addAll(List.generate(daysInMonth, (index) => index + 1));

    // Calculate number of rows needed (ceiling of days / 7)
    int numRows = (days.length / 7).ceil();

    // Fill the remaining grid with nulls
    while (days.length < numRows * 7) {
      days.add(null);
    }

    return SizedBox(
      height: 220,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: days.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final day = days[index];

          return day == null
              ? const SizedBox() // Empty cell
              : InkWell(
                  onTap: () => onDaySelected(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: jalaliDate.day == day
                          ? AppTheme.goldColor
                          : const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: GoogleFonts.vazirmatn(
                          textStyle: TextStyle(
                            color: jalaliDate.day == day
                                ? Colors.black
                                : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildPersianDate(String dateStr) {
    try {
      final gregorianDate = DateTime.parse(dateStr);
      final persianDate = Jalali.fromDateTime(gregorianDate);

      // فرمت فارسی تاریخ: سال/ماه/روز
      final persianMonthNames = [
        'فروردین',
        'اردیبهشت',
        'خرداد',
        'تیر',
        'مرداد',
        'شهریور',
        'مهر',
        'آبان',
        'آذر',
        'دی',
        'بهمن',
        'اسفند'
      ];

      return Text(
        '${persianDate.day} ${persianMonthNames[persianDate.month - 1]} ${persianDate.year}',
        style: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } catch (e) {
      return Text(
        'تاریخ نامعتبر',
        style: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      );
    }
  }

  Widget _buildAgeInfo(String dateStr) {
    try {
      final birthDate = DateTime.parse(dateStr);
      final now = DateTime.now();

      // محاسبه سن
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // محاسبه ماه های باقیمانده
      int months = 0;
      if (now.day < birthDate.day) {
        months = now.month - birthDate.month - 1;
        if (months < 0) months += 12;
      } else {
        months = now.month - birthDate.month;
        if (months < 0) months += 12;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.goldColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.goldColor.withOpacity(0.3)),
        ),
        child: Text(
          'سن: $age سال و $months ماه',
          style: GoogleFonts.vazirmatn(
            textStyle: const TextStyle(
              color: AppTheme.goldColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDropdown(
    String label,
    String field,
    Map<String, String> items, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.vazirmatn(
            textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.goldColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: const Color(0xFF252525),
        style: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldColor),
        value: _profileData[field]?.isNotEmpty == true
            ? _profileData[field]
            : null,
        items: items.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _profileData[field] = value;
            });
          }
        },
        validator: validator,
      ),
    );
  }

  Widget _buildMultiSelect(
    String field,
    Map<String, String> items,
  ) {
    final List<String> selectedValues =
        List<String>.from(_profileData[field] ?? []);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.entries.map((entry) {
        final isSelected = selectedValues.contains(entry.key);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedValues.remove(entry.key);
              } else {
                selectedValues.add(entry.key);
              }
              _profileData[field] = selectedValues;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? AppTheme.goldColor : const Color(0xFF1A1A1A),
              border: Border.all(
                color: isSelected
                    ? AppTheme.goldColor
                    : Colors.white.withOpacity(0.3),
              ),
            ),
            child: Text(
              entry.value,
              style: GoogleFonts.vazirmatn(
                textStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'جنسیت',
            style: GoogleFonts.vazirmatn(
              textStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption('male', 'مرد', Icons.male_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child:
                    _buildGenderOption('female', 'زن', Icons.female_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _profileData['gender'] == value;

    return InkWell(
      onTap: () {
        setState(() {
          _profileData['gender'] = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppTheme.goldColor : const Color(0xFF1A1A1A),
          border: Border.all(
            color:
                isSelected ? AppTheme.goldColor : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.vazirmatn(
                textStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyWeightField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'وزن (کیلوگرم)',
                style: GoogleFonts.vazirmatn(
                  textStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                color: AppTheme.goldColor,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _profileData['weight']?.toString() ?? '-',
            style: GoogleFonts.vazirmatn(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.info_outline,
            color: AppTheme.goldColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.vazirmatn(
                textStyle: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.goldColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'ذخیره تغییرات',
          style: GoogleFonts.vazirmatn(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.accessibility,
              title: 'قد',
              value: _profileData['height']?.toString() ?? '-',
              unit: 'cm',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.monitor_weight,
              title: 'وزن',
              value: _profileData['weight']?.toString() ?? '-',
              unit: 'kg',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.fitness_center,
              title: 'تجربه',
              value: _profileData['experience_level']?.isNotEmpty == true
                  ? AppConfig
                          .experienceLevels[_profileData['experience_level']] ??
                      '-'
                  : '-',
              unit: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.goldColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.goldColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.vazirmatn(
                textStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.vazirmatn(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: GoogleFonts.vazirmatn(
                      textStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          gradient: const LinearGradient(
            colors: [
              AppTheme.goldColor,
              Color(0xFFD4AF37),
            ],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        unselectedLabelStyle: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(
            fontSize: 13,
          ),
        ),
        dividerColor: Colors.transparent,
        indicatorPadding:
            const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        tabs: const [
          Tab(text: 'اطلاعات'),
          Tab(text: 'بدن'),
          Tab(text: 'تمرینات'),
          Tab(text: 'سلامت'),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfileData,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: AppTheme.goldColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: AppTheme.goldColor.withOpacity(0.5),
          elevation: 5,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              )
            : Text(
                'ذخیره تغییرات',
                style: GoogleFonts.vazirmatn(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
    );
  }
}
