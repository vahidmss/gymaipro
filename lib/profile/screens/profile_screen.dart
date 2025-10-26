import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/auth/services/supabase_service.dart';
import 'package:gymaipro/profile/screens/confidential_user_info_screen.dart';
import 'package:gymaipro/profile/widgets/profile_form_widgets.dart';
import 'package:gymaipro/profile/widgets/profile_image_widgets.dart';
import 'package:gymaipro/profile/widgets/profile_stats_widgets.dart';
import 'package:gymaipro/profile/widgets/profile_weight_controls_widget.dart';
import 'package:gymaipro/profile/widgets/weight_widgets.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  File? _avatarFile;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _showConfidential = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, dynamic> _profileData = {};
  final Map<String, dynamic> _originalData = {};
  Timer? _autoSaveDebounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.w, 0.3.h), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
    _loadProfileData();
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تست کاربر فعلی
      await SimpleProfileService.testCurrentUser();

      // استفاده از SimpleProfileService
      final profileData = await SimpleProfileService.getCurrentProfile();

      if (profileData != null) {
        if (!mounted) return;
        setState(() {
          _profileData.clear();
          _originalData.clear();
          _profileData.addAll(profileData);
          _originalData.addAll(profileData);
        });

        print('Profile loaded successfully: ${profileData['username']}');

        // بارگذاری آخرین وزن ثبت شده
        final userId = profileData['id'];
        if (userId != null) {
          final latestWeight = await WeeklyWeightService.getLatestWeight(
            userId as String,
          );
          if (mounted && latestWeight != null) {
            setState(() {
              _profileData['latest_weight'] = latestWeight;
            });
          }
        }
      } else {
        print('No profile found for current user');
      }
    } catch (e) {
      print('خطا در بارگذاری پروفایل: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _pickImage() {
    final hasImage =
        _avatarFile != null ||
        (_profileData.containsKey('avatar_url') &&
            _profileData['avatar_url'] != null &&
            _profileData['avatar_url'] is String &&
            (_profileData['avatar_url'] as String).isNotEmpty);

    ProfileImageWidgets.showImagePickerBottomSheet(
      context,
      _pickImageFromSource,
      _removeImage,
      hasImage,
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    ProfileImageWidgets.pickImageFromSource(source, context, (file) async {
      if (!mounted) return;
      setState(() {
        _avatarFile = file as File?;
        _isLoading = true;
      });

      try {
        await _saveProfileData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تصویر پروفایل ذخیره شد',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در ذخیره تصویر: $e',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _removeImage() {
    ProfileImageWidgets.showRemoveImageDialog(context, () {
      // حذف تصویر از state
      setState(() {
        _avatarFile = null;
        _profileData.remove('avatar_url');
        _originalData.remove('avatar_url');
      });

      // نمایش پیام موفقیت
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تصویر پروفایل حذف شد', style: GoogleFonts.vazirmatn()),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _showWeightGuidanceDialog() {
    WeightWidgets.showWeightGuidanceDialog(context, _addWeightRecord);
  }

  Future<void> _showWeightHistoryDialog() async {
    try {
      // دریافت user ID از SimpleProfileService
      final profileData = await SimpleProfileService.getCurrentProfile();
      if (profileData == null) return;

      final userId = profileData['id'];
      if (userId == null) return;

      final weightHistory = await WeeklyWeightService.getFullWeightHistory(
        userId as String,
      );
      WeightWidgets.showWeightHistoryDialog(context, weightHistory);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در بارگذاری تاریخچه وزن: $e',
            style: GoogleFonts.vazirmatn(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addWeightRecord(String weightStr) async {
    try {
      final weight = double.tryParse(weightStr);
      if (weight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لطفاً وزن معتبر وارد کنید',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // دریافت user ID از SimpleProfileService
      final profileData = await SimpleProfileService.getCurrentProfile();
      if (profileData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در شناسایی کاربر',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userId = profileData['id'];
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در شناسایی کاربر',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await WeeklyWeightService.recordWeeklyWeight(
        userId as String,
        weight,
      );

      if (success) {
        if (!mounted) return;
        setState(() {
          _profileData['weight'] = weight;
          _profileData['latest_weight'] = weight;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'وزن با موفقیت ثبت شد',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'در 7 روز گذشته قبلاً وزن ثبت شده است',
              style: GoogleFonts.vazirmatn(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ثبت وزن: $e', style: GoogleFonts.vazirmatn()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfileData() async {
    // استفاده داخلی توسط auto-save؛ فرم را اعتبارسنجی نمی‌کنیم تا کاربر در حین تایپ محدود نشود
    try {
      final profileData = await SimpleProfileService.getCurrentProfile();
      if (profileData == null) return;
      final userId = profileData['id'];
      if (userId == null) return;

      // آپلود تصویر پروفایل اگر انتخاب شده
      if (_avatarFile != null) {
        try {
          final supabaseService = SupabaseService();
          final imageUrl = await supabaseService.uploadProfileImage(
            userId as String,
            _avatarFile!,
          );
          if (imageUrl != null) {
            _profileData['avatar_url'] = imageUrl;
          }
        } catch (e) {
          // بی‌صدا؛ auto-save
        }
      }

      // پاکسازی فیلدهای عددی خالی
      final cleanData = Map<String, dynamic>.from(_profileData);
      for (final key in [
        'height',
        'weight',
        'arm_circumference',
        'chest_circumference',
        'waist_circumference',
        'hip_circumference',
      ]) {
        if (cleanData[key] == '' || cleanData[key] == null) {
          cleanData.remove(key);
        }
      }
      if (_originalData['username'] == cleanData['username']) {
        cleanData.remove('username');
      }
      await SimpleProfileService.updateProfile(cleanData);
      if (!mounted) return;
      setState(() {
        _originalData
          ..clear()
          ..addAll(_profileData);
      });
    } catch (_) {}
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _profileData[key] = value;
    });
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(
      const Duration(milliseconds: 800),
      _saveProfileData,
    );
  }

  // _cancelEdit حذف شد؛ حالت ویرایش حذف گردید و ذخیره خودکار فعال است

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // اطلاعات شخصی
          ProfileFormWidgets.buildFormSection('اطلاعات شخصی', [
            ProfileFormWidgets.buildTextField(
              'first_name',
              'نام',
              LucideIcons.user,
              _profileData,
              (value) => _onFieldChanged('first_name', value),
            ),
            ProfileFormWidgets.buildTextField(
              'last_name',
              'نام خانوادگی',
              LucideIcons.user,
              _profileData,
              (value) => _onFieldChanged('last_name', value),
            ),
            ProfileFormWidgets.buildTextField(
              'phone_number',
              'شماره تلفن',
              LucideIcons.phone,
              _profileData,
              (value) => _onFieldChanged('phone_number', value),
            ),
            ProfileFormWidgets.buildTextArea(
              'bio',
              'بیوگرافی',
              LucideIcons.fileText,
              _profileData,
              (value) => _onFieldChanged('bio', value),
            ),
          ]),

          // اطلاعات فیزیکی
          ProfileFormWidgets.buildFormSection('اطلاعات فیزیکی', [
            ProfileWeightControlsWidget(
              onAddWeightPressed: _showWeightGuidanceDialog,
              onWeightHistoryPressed: _showWeightHistoryDialog,
            ),
            ProfileFormWidgets.buildNumberField(
              'height',
              'قد (سانتی‌متر)',
              LucideIcons.ruler,
              _profileData,
              (value) => _onFieldChanged(
                'height',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildWeightField(
              'weight',
              'وزن فعلی',
              LucideIcons.scale,
              _profileData,
              () => WeightWidgets.showWeightGuidanceDialog(
                context,
                _addWeightRecord,
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'arm_circumference',
              'دور بازو (سانتی‌متر)',
              LucideIcons.circle,
              _profileData,
              (value) => _onFieldChanged(
                'arm_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'chest_circumference',
              'دور سینه (سانتی‌متر)',
              LucideIcons.heart,
              _profileData,
              (value) => _onFieldChanged(
                'chest_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'waist_circumference',
              'دور کمر (سانتی‌متر)',
              LucideIcons.circle,
              _profileData,
              (value) => _onFieldChanged(
                'waist_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
            ProfileFormWidgets.buildNumberField(
              'hip_circumference',
              'دور باسن (سانتی‌متر)',
              LucideIcons.circle,
              _profileData,
              (value) => _onFieldChanged(
                'hip_circumference',
                value.isEmpty ? null : double.tryParse(value),
              ),
            ),
          ]),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAppBarContent() {
    final hasImage =
        _avatarFile != null ||
        (_profileData.containsKey('avatar_url') &&
            _profileData['avatar_url'] != null &&
            _profileData['avatar_url'] is String &&
            (_profileData['avatar_url'] as String).isNotEmpty);

    return Container(
      padding: EdgeInsets.only(top: 60.h, left: 20.w, right: 20.w, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // تصویر پروفایل
          Stack(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withAlpha(50),
                        blurRadius: 15.r,
                        spreadRadius: 3.r,
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 8.r,
                        spreadRadius: 1.r,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? _avatarFile != null
                              ? Image.file(
                                  _avatarFile!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return ProfileImageWidgets.buildDefaultAvatar();
                                  },
                                )
                              : Image.network(
                                  _profileData['avatar_url'] as String,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return ColoredBox(
                                          color: const Color(0xFF2A2A2A),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              color: AppTheme.goldColor,
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return ProfileImageWidgets.buildDefaultAvatar();
                                  },
                                )
                        : ProfileImageWidgets.buildDefaultAvatar(),
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.goldColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // نام و نام خانوادگی
          Text(
            '${_profileData['first_name'] ?? ''} ${_profileData['last_name'] ?? ''}'
                .trim(),
            style: GoogleFonts.vazirmatn(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          // نام کاربری
          if (_profileData['username'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${_profileData['username']}',
              style: GoogleFonts.vazirmatn(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.goldColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: _isLoading && _profileData.isEmpty
          ? _buildLoadingView()
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: const Color(0xFF1A1A1A),
                  automaticallyImplyLeading: false,

                  actions: const [],
                  flexibleSpace: FlexibleSpaceBar(
                    background: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.goldColor.withAlpha(50),
                            const Color(0xFF1A1A1A),
                          ],
                        ),
                      ),
                      child: _buildAppBarContent(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Toggle row between overview / edit / confidential
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () => setState(() {
                                    _isEditing = true;
                                    _showConfidential = false;
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEditing
                                        ? AppTheme.goldColor
                                        : const Color(0xFF2A2A2A),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                  ),
                                  child: Text(
                                    'ویرایش',
                                    style: GoogleFonts.vazirmatn(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => setState(() {
                                    _isEditing = false;
                                    _showConfidential = false;
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        (!_isEditing && !_showConfidential)
                                        ? AppTheme.goldColor
                                        : const Color(0xFF2A2A2A),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                  ),
                                  child: Text(
                                    'نمای کلی',
                                    style: GoogleFonts.vazirmatn(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => setState(() {
                                    _isEditing = false;
                                    _showConfidential = true;
                                  }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _showConfidential
                                        ? AppTheme.goldColor
                                        : const Color(0xFF2A2A2A),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                  ),
                                  child: Text(
                                    'اطلاعات محرمانه',
                                    style: GoogleFonts.vazirmatn(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isEditing && !_showConfidential)
                            ProfileStatsWidgets.buildStatsGrid(_profileData),
                          if (!_isEditing && !_showConfidential)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 8.h,
                              ),
                              child: Card(
                                color: const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  side: BorderSide(
                                    color: AppTheme.goldColor.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    LucideIcons.dumbbell,
                                    color: AppTheme.goldColor,
                                  ),
                                  title: Text(
                                    'برنامه‌های من',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'مدیریت برنامه‌ها، فعال‌سازی و ورود به ثبت تمرین',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.grey[400],
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    LucideIcons.chevronLeft,
                                    color: AppTheme.goldColor,
                                  ),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/my-programs',
                                  ),
                                ),
                              ),
                            ),
                          if (_isEditing) _buildProfileForm(),
                          if (_showConfidential)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: ConfidentialUserInfoScreen(embedded: true),
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
