import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isProfileComplete = false;
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();

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
  };

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
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
          });
        }
      }
    } catch (e) {
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
      'experience_level'
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
          // تبدیل فیلدهای عددی و تاریخ به مقدار مناسب
          final Map<String, dynamic> cleanProfileData = Map.from(_profileData);
          for (final key in [
            'height',
            'weight',
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

          await supabaseService.updateProfile(user.id, cleanProfileData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('اطلاعات با موفقیت ذخیره شد')),
            );
            setState(() {
              _isProfileComplete = _checkProfileCompletion();
            });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('پروفایل من'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isProfileComplete) _buildProfileCompletionCard(),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 24),
                        _buildPersonalInfoSection(),
                        const SizedBox(height: 24),
                        _buildBodyMeasurementsSection(),
                        const SizedBox(height: 24),
                        _buildTrainingPreferencesSection(),
                        const SizedBox(height: 24),
                        _buildHealthSection(),
                        const SizedBox(height: 32),
                        Center(
                          child: ElevatedButton(
                            style: AppTheme.primaryButtonStyle,
                            onPressed: _saveProfile,
                            child: const Text('ذخیره تغییرات'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withOpacity(0.8),
            AppTheme.darkGold.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تکمیل پروفایل',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'با تکمیل پروفایل خود از این مزایا بهره‌مند شوید:',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildBenefitItem('محاسبه دقیق شاخص‌های بدنی'),
          _buildBenefitItem('برنامه تمرینی شخصی‌سازی شده'),
          _buildBenefitItem('پیگیری دقیق پیشرفت'),
          _buildBenefitItem('توصیه‌های تغذیه‌ای متناسب'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.cardColor,
                  backgroundImage: () {
                    if (_avatarFile != null) {
                      return FileImage(_avatarFile!);
                    }
                    final avatarUrl = _profileData['avatar_url'] as String?;
                    if (avatarUrl?.isNotEmpty == true) {
                      return NetworkImage(avatarUrl!) as ImageProvider;
                    }
                    return null;
                  }(),
                  child: _avatarFile == null &&
                          ((_profileData['avatar_url'] as String?)?.isEmpty ??
                              true)
                      ? const Icon(Icons.person,
                          size: 50, color: AppTheme.goldColor)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.goldColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تصویر پروفایل',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('اطلاعات شخصی'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'نام',
                'first_name',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'نام را وارد کنید' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'نام خانوادگی',
                'last_name',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'نام خانوادگی را وارد کنید' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'درباره من',
          'bio',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildDatePicker(),
      ],
    );
  }

  Widget _buildBodyMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('اندازه‌گیری‌های بدن'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'قد (سانتی‌متر)',
                'height',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'قد را وارد کنید' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'وزن (کیلوگرم)',
                'weight',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'وزن را وارد کنید' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'دور بازو',
                'arm_circumference',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'دور سینه',
                'chest_circumference',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'دور کمر',
                'waist_circumference',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'دور باسن',
                'hip_circumference',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrainingPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ترجیحات تمرینی'),
        const SizedBox(height: 16),
        _buildDropdownField(
          'سطح تجربه',
          'experience_level',
          AppConfig.experienceLevels,
        ),
        const SizedBox(height: 16),
        _buildMultiSelect(
          'روزهای ترجیحی تمرین',
          'preferred_training_days',
          AppConfig.weekDays,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'زمان ترجیحی تمرین',
          'preferred_training_time',
          AppConfig.trainingTimes,
        ),
        const SizedBox(height: 16),
        _buildMultiSelect(
          'اهداف تناسب اندام',
          'fitness_goals',
          AppConfig.fitnessGoals,
        ),
      ],
    );
  }

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('سلامت و تغذیه'),
        const SizedBox(height: 16),
        _buildMultiSelect(
          'شرایط پزشکی خاص',
          'medical_conditions',
          AppConfig.medicalConditions,
        ),
        const SizedBox(height: 16),
        _buildMultiSelect(
          'ترجیحات غذایی',
          'dietary_preferences',
          AppConfig.dietaryPreferences,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppTheme.goldColor, width: 2),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
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
    return TextFormField(
      decoration: AppTheme.textFieldDecoration(label),
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      initialValue: _profileData[field]?.toString() ?? '',
      onSaved: (value) => _profileData[field] = value,
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        DateTime? initialDate;
        String? birthDateStr = _profileData['birth_date'];
        if (birthDateStr != null && birthDateStr.isNotEmpty) {
          try {
            initialDate = DateTime.parse(birthDateStr);
          } catch (_) {
            initialDate = null;
          }
        }
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate ??
              DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _profileData['birth_date'] = date.toIso8601String();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppTheme.goldColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            () {
              String? birthDateStr = _profileData['birth_date'];
              DateTime? birthDate;
              if (birthDateStr != null && birthDateStr.isNotEmpty) {
                try {
                  birthDate = DateTime.parse(birthDateStr);
                } catch (_) {
                  birthDate = null;
                }
              }
              return Text(
                birthDate != null
                    ? birthDate.toString().split(' ')[0]
                    : 'تاریخ تولد',
                style: TextStyle(
                  color: birthDate != null
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              );
            }(),
            const Icon(Icons.calendar_today, color: AppTheme.goldColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String field,
    Map<String, String> items,
  ) {
    return DropdownButtonFormField<String>(
      decoration: AppTheme.textFieldDecoration(label),
      value:
          _profileData[field]?.isNotEmpty == true ? _profileData[field] : null,
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
      dropdownColor: AppTheme.cardColor,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'لطفاً یک گزینه را انتخاب کنید';
        }
        return null;
      },
    );
  }

  Widget _buildMultiSelect(
    String label,
    String field,
    Map<String, String> items,
  ) {
    final List<String> selectedValues =
        List<String>.from(_profileData[field] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.entries.map((entry) {
            final isSelected = selectedValues.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedValues.add(entry.key);
                  } else {
                    selectedValues.remove(entry.key);
                  }
                  _profileData[field] = selectedValues;
                });
              },
              backgroundColor: AppTheme.cardColor,
              selectedColor: AppTheme.goldColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
