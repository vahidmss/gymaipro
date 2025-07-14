import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../services/sync_service.dart';

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
  bool _isDataLoaded = false;
  final bool _isProfileComplete = false;
  File? _avatarFile;
  String? _avatarUrl;
  String? _selectedGender;
  final ImagePicker _picker = ImagePicker();
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  double? _prevProfileWeight; // مقدار قبلی وزن برای مقایسه
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // دریافت پروفایل از سوپابیس
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // بروزرسانی وضعیت با داده‌های دریافتی
      setState(() {
        _isDataLoaded = true;

        // تنظیم فیلدهای پروفایل با داده‌های دریافتی
        _profileData['first_name'] = data['first_name'] ?? '';
        _profileData['last_name'] = data['last_name'] ?? '';
        _profileData['bio'] = data['bio'] ?? '';
        _profileData['avatar_url'] = data['avatar_url'] ?? '';
        _avatarUrl = data['avatar_url'];

        // تنظیم داده‌های بدنی
        _profileData['height'] = data['height']?.toString() ?? '';
        _profileData['weight'] = data['weight']?.toString() ?? '';

        // ذخیره مقدار قبلی وزن برای مقایسه
        _prevProfileWeight = data['weight'] != null
            ? double.tryParse(data['weight'].toString())
            : null;

        _profileData['arm_circumference'] =
            data['arm_circumference']?.toString() ?? '';
        _profileData['chest_circumference'] =
            data['chest_circumference']?.toString() ?? '';
        _profileData['waist_circumference'] =
            data['waist_circumference']?.toString() ?? '';
        _profileData['hip_circumference'] =
            data['hip_circumference']?.toString() ?? '';

        // تنظیم داده‌های تمرینی
        _profileData['experience_level'] = data['experience_level'] ?? '';
        _profileData['preferred_training_days'] =
            data['preferred_training_days'] ?? [];
        _profileData['preferred_training_time'] =
            data['preferred_training_time'] ?? '';
        _profileData['fitness_goals'] = data['fitness_goals'] ?? [];

        // تنظیم داده‌های سلامتی
        _profileData['medical_conditions'] = data['medical_conditions'] ?? [];
        _profileData['dietary_preferences'] = data['dietary_preferences'] ?? [];

        // تنظیم جنسیت
        _selectedGender = data['gender'];
        _profileData['gender'] = data['gender'] ?? '';

        // تنظیم تاریخ تولد اگر موجود باشد
        if (data['birth_date'] != null) {
          try {
            _profileData['birth_date'] = DateTime.parse(data['birth_date']);
          } catch (e) {
            print('خطا در تبدیل تاریخ تولد: $e');
            _profileData['birth_date'] = null;
          }
        }

        // تنظیم تاریخچه وزن
        if (data['weight_history'] != null) {
          _profileData['weight_history'] = data['weight_history'];
        }
      });

      // نمایش اطلاعات بارگذاری شده برای اشکال‌زدایی
      print('داده‌های پروفایل با موفقیت بارگذاری شدند:');
      print('تاریخ تولد: ${_profileData['birth_date']}');
      print('وزن: ${_profileData['weight']}');
      print('قد: ${_profileData['height']}');
    } catch (e) {
      print('خطا در بارگذاری پروفایل: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری پروفایل: ${e.toString()}')),
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
    if (!_formKey.currentState!.validate() &&
        !_bodyFormKey.currentState!.validate() &&
        !_trainingFormKey.currentState!.validate() &&
        !_healthFormKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // آماده‌سازی تاریخ تولد
      DateTime? birthDate;
      if (_profileData['birth_date'] != null &&
          _profileData['birth_date'].isNotEmpty) {
        try {
          birthDate = DateTime.parse(_profileData['birth_date']);
        } catch (e) {
          debugPrint('خطا در تبدیل تاریخ تولد: $e');
        }
      }

      // آماده‌سازی وزن
      double? weight;
      if (_profileData['weight'] != null && _profileData['weight'].isNotEmpty) {
        try {
          weight = double.parse(_profileData['weight']);

          // اضافه کردن وزن به تاریخچه وزن
          final hasWeightChanged = _prevProfileWeight != weight;

          // فقط اگر وزن تغییر کرده باشد آن را به تاریخچه اضافه کن
          if (hasWeightChanged) {
            final weightHistoryRecord = {
              'weight': weight,
              'date': DateTime.now().toIso8601String(),
            };

            final List<Map<String, dynamic>> weightHistory =
                _profileData['weight_history'] != null
                    ? List<Map<String, dynamic>>.from(
                        _profileData['weight_history'])
                    : [];

            weightHistory.add(weightHistoryRecord);
            _profileData['weight_history'] = weightHistory;
          }
        } catch (e) {
          debugPrint('خطا در تبدیل وزن: $e');
        }
      }

      // ساخت آبجکت داده‌های پروفایل با مقادیر تمیز شده
      final updatedProfileData = Map<String, dynamic>.from(_profileData);

      // اطمینان از اینکه فیلدهای خالی به null تبدیل نمی‌شوند
      updatedProfileData.forEach((key, value) {
        if (value is String && value.isEmpty) {
          updatedProfileData[key] = '';
        }
      });

      // چاپ داده‌های نهایی برای اشکال‌زدایی
      print('داده‌های نهایی برای ارسال به سرور:');
      print(updatedProfileData);

      // بروزرسانی پروفایل در سوپابیس
      print('در حال بروزرسانی پروفایل کاربر ${user.id} با داده‌های زیر:');
      print(updatedProfileData);

      // حذف فیلدهای اضافی و تمیز کردن داده‌ها
      final Map<String, dynamic> cleanProfileData = {
        'first_name': updatedProfileData['first_name'] ?? '',
        'last_name': updatedProfileData['last_name'] ?? '',
        'avatar_url': updatedProfileData['avatar_url'] ?? '',
        'bio': updatedProfileData['bio'] ?? '',
      };

      // اضافه کردن فیلدهای اختیاری اگر وجود داشته باشند
      if (birthDate != null) {
        cleanProfileData['birth_date'] = birthDate.toIso8601String();
      }

      if (weight != null) {
        cleanProfileData['weight'] = weight;
      }

      if (_profileData['height'] != null && _profileData['height'].isNotEmpty) {
        try {
          cleanProfileData['height'] = double.parse(_profileData['height']);
        } catch (e) {
          print('خطا در تبدیل قد: $e');
        }
      }

      if (_profileData['gender'] != null && _profileData['gender'].isNotEmpty) {
        cleanProfileData['gender'] = _profileData['gender'];
      }

      if (_profileData['experience_level'] != null &&
          _profileData['experience_level'].isNotEmpty) {
        cleanProfileData['experience_level'] = _profileData['experience_level'];
      }

      if (_profileData['preferred_training_time'] != null &&
          _profileData['preferred_training_time'].isNotEmpty) {
        cleanProfileData['preferred_training_time'] =
            _profileData['preferred_training_time'];
      }

      if (_profileData['weight_history'] != null) {
        cleanProfileData['weight_history'] = _profileData['weight_history'];
      }

      print('داده‌های تمیز شده برای ارسال به دیتابیس:');
      print(cleanProfileData);

      // بروزرسانی پروفایل در سوپابیس
      final response = await Supabase.instance.client
          .from('profiles')
          .update(cleanProfileData)
          .eq('id', user.id);

      print('پاسخ بروزرسانی پروفایل: $response');
      print('پروفایل با موفقیت به‌روزرسانی شد');

      // همگام‌سازی با وردپرس
      try {
        final syncService = SyncService();
        final userProfile = await SupabaseService().getProfileByAuthId();
        final phoneNumber = userProfile?.phoneNumber ?? '';

        if (phoneNumber.isNotEmpty) {
          print(
              'شروع همگام‌سازی پروفایل با وردپرس - شماره موبایل: $phoneNumber');

          // اضافه کردن فیلدهای مورد نیاز برای وردپرس
          cleanProfileData['profile_picture'] = cleanProfileData['avatar_url'];

          final syncResult =
              await syncService.syncUserProfile(phoneNumber, cleanProfileData);

          if (!syncResult['success']) {
            print(
                'هشدار: همگام‌سازی با وردپرس ناموفق بود: ${syncResult['message']}');
            // هشدار به کاربر
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'همگام‌سازی با سایت ناموفق بود: ${syncResult['message']}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            print(
                'همگام‌سازی با وردپرس موفقیت‌آمیز بود: ${syncResult['message']}');
            if (mounted) {
              // نمایش فیلدهای به‌روز شده در وردپرس
              if (syncResult.containsKey('updated_fields') &&
                  syncResult['updated_fields'] is List &&
                  (syncResult['updated_fields'] as List).isNotEmpty) {
                final fields =
                    (syncResult['updated_fields'] as List).join('، ');

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: Text(
                      'همگام‌سازی با وردپرس',
                      style: GoogleFonts.vazirmatn(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'اطلاعات با موفقیت در سایت به‌روز شد.',
                            style: GoogleFonts.vazirmatn(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'فیلدهای به‌روز شده:',
                            style: GoogleFonts.vazirmatn(
                              textStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            width: double.infinity,
                            child: Text(
                              fields,
                              style: GoogleFonts.vazirmatn(
                                textStyle: TextStyle(
                                  color: Colors.green.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.goldColor,
                        ),
                        child: Text(
                          'تایید',
                          style: GoogleFonts.vazirmatn(),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('اطلاعات با موفقیت در سایت نیز به‌روز شد'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        } else {
          print('هشدار: شماره موبایل برای همگام‌سازی با وردپرس یافت نشد');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('شماره موبایل برای همگام‌سازی با سایت یافت نشد'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        print('خطا در همگام‌سازی با وردپرس: $e');
        // این خطا نباید باعث توقف روند اصلی شود
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در همگام‌سازی با سایت: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پروفایل با موفقیت به‌روزرسانی شد')),
        );
        // بازگشت به صفحه قبل
        Navigator.pop(context);
      }
    } catch (e) {
      print('خطا در ذخیره پروفایل: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطا در به‌روزرسانی پروفایل: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        if (birthDate != null) {
          if (birthDate is DateTime) {
            cleanProfileData['birth_date'] = birthDate.toIso8601String();
            print('تاریخ تولد (DateTime): ${cleanProfileData['birth_date']}');
          } else if (birthDate.toString().trim().isNotEmpty) {
            // اگر نوع دیگری است، سعی کنید به رشته تبدیل کنید
            cleanProfileData['birth_date'] = birthDate.toString();
            print('تاریخ تولد (String): ${cleanProfileData['birth_date']}');
          } else {
            cleanProfileData.remove('birth_date');
          }
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

        // ذخیره اطلاعات پروفایل در سوپابیس
        await supabaseService.updateProfile(user.id, cleanProfileData);
        print('پروفایل با موفقیت بروزرسانی شد');

        // بارگذاری مجدد داده‌های پروفایل برای اطمینان از بروز بودن
        await _loadProfileData();

        // همگام‌سازی با وردپرس
        if (mounted) {
          try {
            // دریافت شماره موبایل کاربر
            final userProfile = await supabaseService.getProfileByAuthId();
            if (userProfile?.phoneNumber != null) {
              final syncService = SyncService();
              final syncResult = await syncService.syncUserProfile(
                  userProfile!.phoneNumber, cleanProfileData);

              print(
                  'همگام‌سازی با وردپرس: ${syncResult['success'] == true ? 'موفق' : 'ناموفق'}');
              print('پیام همگام‌سازی: ${syncResult['message']}');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('اطلاعات با موفقیت ذخیره شد',
                        style: GoogleFonts.vazirmatn()),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            print('خطا در همگام‌سازی با وردپرس: $e');
            // این خطا نباید باعث توقف روند اصلی شود
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'اطلاعات ذخیره شد، اما همگام‌سازی با سایت با خطا مواجه شد: $e',
                    style: GoogleFonts.vazirmatn(),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('خطا در ذخیره پروفایل: $e');
      if (e is PostgrestException) {
        print(
            'جزئیات خطای Postgrest: ${e.code}, ${e.details}, ${e.hint}, ${e.message}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ذخیره پروفایل: $e',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildSimpleAvatar(small: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_profileData['first_name']} ${_profileData['last_name']}",
                      style: GoogleFonts.vazirmatn(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_profileData['bio']?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _profileData['bio'],
                          style: GoogleFonts.vazirmatn(
                            textStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.start,
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

  Widget _buildSimpleAvatar({bool small = false}) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: small ? 56 : 100,
        width: small ? 56 : 100,
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
            ? Icon(Icons.person,
                size: small ? 28 : 45, color: AppTheme.goldColor)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          title: _buildSectionTitle('اطلاعات شخصی'),
          initiallyExpanded: true,
          children: [
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
                    validator: (value) => value?.isEmpty ?? true
                        ? 'نام خانوادگی الزامی است'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildGenderSelector(),
            const SizedBox(height: 8),
            _buildTextField(
              'درباره من',
              'bio',
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            _buildDatePicker(),
          ],
        ),
      ],
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
            ExpansionTile(
              title: _buildSectionTitle('اندازه‌گیری‌های اصلی'),
              children: [
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
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'وزن الزامی است'
                                  : null,
                            ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: _buildSectionSubtitle('اندازه‌گیری‌های دقیق'),
              children: [
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
                const SizedBox(height: 8),
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
              ],
            ),
            const SizedBox(height: 16),
            _buildApplyButton(),
            const SizedBox(height: 24),
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
            ExpansionTile(
              title: _buildSectionTitle('اطلاعات تمرینی'),
              initiallyExpanded: true,
              children: [
                _buildDropdown(
                  'سطح تجربه',
                  'experience_level',
                  AppConfig.experienceLevels,
                  validator: (value) => value == null || value.isEmpty
                      ? 'سطح تجربه الزامی است'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildMultiSelect(
                  'preferred_training_days',
                  AppConfig.weekDays,
                  title: 'روزهای ترجیحی تمرین',
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  'زمان ترجیحی تمرین',
                  'preferred_training_time',
                  AppConfig.trainingTimes,
                ),
                const SizedBox(height: 16),
                _buildMultiSelect(
                  'fitness_goals',
                  AppConfig.fitnessGoals,
                  title: 'اهداف تناسب اندام',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildApplyButton(),
            const SizedBox(height: 24),
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
            ExpansionTile(
              title: _buildSectionTitle('اطلاعات سلامتی'),
              initiallyExpanded: true,
              children: [
                _buildMultiSelect(
                  'medical_conditions',
                  AppConfig.medicalConditions,
                  title: 'شرایط پزشکی',
                ),
                const SizedBox(height: 16),
                _buildMultiSelect(
                  'dietary_preferences',
                  AppConfig.dietaryPreferences,
                  title: 'ترجیحات غذایی',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildApplyButton(),
            const SizedBox(height: 24),
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

                        // بستن دیالوگ
                        Navigator.of(context).pop();

                        // آپدیت state والد با تاریخ جدید و ذخیره آن در ISO8601 فرمت
                        this.setState(() {
                          _profileData['birth_date'] = gregorianDate;
                          print(
                              'تاریخ تولد انتخاب شده: ${gregorianDate.toIso8601String()}');
                        });

                        // اطمینان از بروزرسانی UI
                        if (_formKey.currentState != null) {
                          _formKey.currentState!.validate();
                        }
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

  Widget _buildPersianDate(dynamic dateValue) {
    try {
      DateTime gregorianDate;

      // اگر ورودی از نوع DateTime باشد
      if (dateValue is DateTime) {
        gregorianDate = dateValue;
      }
      // اگر ورودی از نوع String باشد
      else if (dateValue is String) {
        gregorianDate = DateTime.parse(dateValue);
      }
      // اگر ورودی نامعتبر باشد
      else {
        throw Exception('نوع داده نامعتبر: ${dateValue.runtimeType}');
      }

      final persianDate = Jalali.fromDateTime(gregorianDate);

      // فرمت فارسی تاریخ: سال/ماه/روز
      // تبدیل ماه و روز به فرمت دو رقمی با صفر در ابتدا اگر لازم باشد
      String day = persianDate.day.toString().padLeft(2, '0');
      String month = persianDate.month.toString().padLeft(2, '0');
      String year = persianDate.year.toString();

      return Text(
        '$year/$month/$day',
        style: GoogleFonts.vazirmatn(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } catch (e) {
      print('خطا در تبدیل تاریخ: $e');
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

  Widget _buildAgeInfo(dynamic dateValue) {
    try {
      DateTime birthDate;

      // اگر ورودی از نوع DateTime باشد
      if (dateValue is DateTime) {
        birthDate = dateValue;
      }
      // اگر ورودی از نوع String باشد
      else if (dateValue is String) {
        birthDate = DateTime.parse(dateValue);
      }
      // اگر ورودی نامعتبر باشد
      else {
        throw Exception('نوع داده نامعتبر: ${dateValue.runtimeType}');
      }

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
      print('خطا در محاسبه سن: $e');
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

  Widget _buildMultiSelect(String field, Map<String, String> items,
      {String? title}) {
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

  Widget _buildApplyButton() {
    return Column(
      children: [
        SizedBox(
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
        ),
      ],
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMiniStat(
                icon: Icons.accessibility,
                title: 'قد',
                value: _profileData['height']?.toString() ?? '-',
                unit: 'cm'),
            const SizedBox(width: 12),
            _buildMiniStat(
                icon: Icons.monitor_weight,
                title: 'وزن',
                value: _profileData['weight']?.toString() ?? '-',
                unit: 'kg'),
            const SizedBox(width: 12),
            _buildMiniStat(
                icon: Icons.fitness_center,
                title: 'تجربه',
                value: _profileData['experience_level']?.isNotEmpty == true
                    ? AppConfig.experienceLevels[
                            _profileData['experience_level']] ??
                        '-'
                    : '-',
                unit: ''),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
      {required IconData icon,
      required String title,
      required String value,
      required String unit}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.goldColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.vazirmatn(
                textStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.vazirmatn(
                  textStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 11),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.vazirmatn(
            textStyle:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
          ),
        ),
      ],
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
}
